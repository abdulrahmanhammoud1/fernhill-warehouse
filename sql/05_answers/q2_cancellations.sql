-- Q2: cancellation rate by platform and lead time (activity in 2025)
-- lead time = calendar days from booking to activity, both in venue local time

create or replace view answers.q2_cancellations as
select
    b.platform,
    case when b.lead_time_days = 0 then '1. same day'
         when b.lead_time_days <= 7 then '2. 1-7 days'
         when b.lead_time_days <= 30 then '3. 8-30 days'
         else '4. 31+ days' end                         as lead_time,
    count(*)                                            as bookings,
    count(*) filter (b.is_cancelled)                    as cancelled,
    round(100.0 * count(*) filter (b.is_cancelled) / count(*), 1) as cancel_rate_pct
from core.fct_booking b
join core.dim_venue v using (venue_key)
where not v.is_test and year(b.activity_date_local) = 2025
group by all
order by platform, lead_time;

copy (select * from answers.q2_cancellations) to 'results/q2_cancellations.csv' (header);
select * from answers.q2_cancellations;
