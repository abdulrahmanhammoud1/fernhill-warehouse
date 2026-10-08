-- each check = number of bad rows. 'error' stops the build, 'warn' just reports

create schema if not exists dq;

create or replace table dq.results as

-- keys are unique
select 'error' as severity, 'dim_venue key unique' as check_name,
       count(*) - count(distinct venue_key) as failures from core.dim_venue
union all select 'error', 'dim_customer key unique',
       count(*) - count(distinct customer_key) from core.dim_customer
union all select 'error', 'fct_booking key unique',
       count(*) - count(distinct booking_key) from core.fct_booking
union all select 'error', 'fct_booking_version key unique',
       count(*) - count(distinct (booking_key, version_no)) from core.fct_booking_version
union all select 'error', 'fct_payment key unique',
       count(*) - count(distinct payment_key) from core.fct_payment
union all select 'error', 'dim_fx_daily key unique',
       count(*) - count(distinct (rate_date, currency)) from core.dim_fx_daily

-- relationships
union all select 'error', 'booking has venue',
       count(*) from core.fct_booking b
       where not exists (select 1 from core.dim_venue v where v.venue_key = b.venue_key)
union all select 'error', 'booking has customer',
       count(*) from core.fct_booking b
       where not exists (select 1 from core.dim_customer c where c.customer_key = b.customer_key)
union all select 'error', 'customer belongs to booking venue',
       count(*) from core.fct_booking b join core.dim_customer c using (customer_key)
       where c.venue_key <> b.venue_key
union all select 'error', 'venue has timezone and currency',
       count(*) from core.dim_venue where tz is null or currency is null

-- time
union all select 'error', 'booking has local activity time',
       count(*) from core.fct_booking where activity_start_local is null or activity_start_utc is null
union all select 'error', 'booked before activity',
       count(*) from core.fct_booking where booked_at_utc > activity_start_utc
union all select 'error', 'cancelled after booked',
       count(*) from core.fct_booking where cancelled_at_utc < booked_at_utc

-- currency and FX
union all select 'error', 'booking currency = venue currency',
       count(*) from core.fct_booking b join core.dim_venue v using (venue_key)
       where b.currency <> v.currency
union all select 'error', 'payment currency = booking currency',
       count(*) from core.fct_payment p join core.fct_booking b using (booking_key)
       where p.currency <> b.currency
union all select 'error', 'FX rate exists for every activity date',
       count(*) from core.mart_booking_takings where fx_rate is null
union all select 'error', 'FX rate not stale (carried > 5 days)',
       count(*) from core.dim_fx_daily where rate_date - published_on > 5

-- history
union all select 'error', 'versions numbered 1..n without gaps',
       count(*) from (select booking_key from core.fct_booking_version
                      group by 1 having max(version_no) <> count(*) or min(version_no) <> 1)
union all select 'error', 'exactly one current version per booking',
       count(*) from (select b.booking_key from core.fct_booking b
                      left join core.fct_booking_version v on v.booking_key = b.booking_key and v.is_current
                      group by 1 having count(v.booking_key) <> 1)
union all select 'error', 'current version status = booking status',
       count(*) from core.fct_booking b
       join core.fct_booking_version v on v.booking_key = b.booking_key and v.is_current
       where v.is_cancelled <> b.is_cancelled
union all select 'error', 'cancelled bookings are never reinstated',
       count(*) from core.fct_booking_version a
       join core.fct_booking_version b on a.booking_key = b.booking_key and b.version_no > a.version_no
       where a.is_cancelled and not b.is_cancelled

-- money
union all select 'error', 'collections positive, refunds negative',
       count(*) from core.fct_payment
       where (payment_type = 'collection' and amount <= 0) or (payment_type = 'refund' and amount >= 0)
union all select 'error', 'refunds do not exceed collections',
       count(*) from core.mart_booking_takings where refunded > collected
union all select 'error', 'apex: money collected = ticket value',
       count(*) from core.mart_booking_takings t join core.fct_booking b using (booking_key)
       where b.platform = 'apex' and t.collected <> b.price_gross
union all select 'error', 'hopscotch: live booking with no refund nets to price',
       count(*) from core.mart_booking_takings t join core.fct_booking b using (booking_key)
       where b.platform = 'hopscotch' and not b.is_cancelled and t.refunded = 0
         and t.net_takings <> b.price_gross
union all select 'error', 'no money lost between staging and core',
       case when (select sum(amount) from staging.hopscotch_money_movements)
               + (select sum(amount) from staging.apex_settlements)
             = (select sum(amount) from core.fct_payment)
               + (select sum(amount) from quarantine.orphan_payments)
            then 0 else 1 end

-- known, handled
union all select 'warn', 'payments quarantined (booking not in extract)',
       count(*) from quarantine.orphan_payments
union all select 'warn', 'customers with no usable email (cannot be matched)',
       count(*) from core.dim_customer where email is null;

select severity, check_name, failures,
       case when failures = 0 then 'ok' when severity = 'error' then 'FAIL' else 'note' end as status
from dq.results
order by status = 'ok', severity, check_name;

select case when count(*) = 0 then 'all error-level checks passed'
            else error('Data quality checks failed: ' || string_agg(check_name, '; ')) end as dq_status
from dq.results
where severity = 'error' and failures > 0;
