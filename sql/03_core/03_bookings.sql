-- Bookings: Hopscotch reservations and Apex tickets in one 

-- History (SCD type 2): one row per version, valid_from -> valid_to
-- Hopscotch sends real versions. Apex keeps no history, so it is rebuilt from what we know
-- a LIVE version from opened time, plus a CANCELLED version from withdrawn time when the ticket was withdrawn (is_inferred = true)
create or replace table core.fct_booking_version as
with v as (
    select
        md5('hopscotch|reservation|' || reservation_key) as booking_key,
        version_seq        as version_no,
        valid_from_utc,
        is_cancelled, party_size, price_gross, currency,
        false              as is_inferred
    from staging.hopscotch_reservation_versions
    union all
    select
        md5('apex|site=' || site_no || '|ticket|' || ticket_no),
        1, booked_at_utc, false, party_size, price_gross, currency, true
    from staging.apex_tickets
    union all
    select
        md5('apex|site=' || site_no || '|ticket|' || ticket_no),
        2, cancelled_at_utc, true, party_size, price_gross, currency, true
    from staging.apex_tickets
    where is_cancelled
)
select
    booking_key, version_no, valid_from_utc,
    lead(valid_from_utc) over (partition by booking_key order by version_no) as valid_to_utc,
    lead(valid_from_utc) over (partition by booking_key order by version_no) is null as is_current,
    is_cancelled, party_size, price_gross, currency, is_inferred
from v;

-- Current state is one row per booking
create or replace table core.fct_booking as
with hop as (
    select
        md5('hopscotch|reservation|' || reservation_key)    as booking_key,
        'hopscotch'                                         as platform,
        md5('hopscotch|operator|' || operator_key)          as venue_key,
        md5('hopscotch|patron|' || patron_key)              as customer_key,
        reservation_key::varchar                            as source_booking_id,
        max_by(product, version_seq)                    as product,
        max_by(party_size, version_seq)                 as party_size,
        max_by(price_gross, version_seq)                as price_gross,
        max_by(currency, version_seq)                   as currency,
        any_value(booked_at_utc)                        as booked_at_utc,
        any_value(booked_at_local)                      as booked_at_local,
        max_by(activity_start_utc, version_seq)         as activity_start_utc,
        max_by(activity_start_local, version_seq)       as activity_start_local,
        max_by(is_cancelled, version_seq)               as is_cancelled,
        min(valid_from_utc)   filter (is_cancelled)     as cancelled_at_utc,
        min(valid_from_local) filter (is_cancelled)     as cancelled_at_local,
        count(*)                                        as version_count
    from staging.hopscotch_reservation_versions
    group by all
),
apx as (
    select
        md5('apex|site=' || site_no || '|ticket|' || ticket_no)   as booking_key,
        'apex'                                                  as platform,
        md5('apex|site|' || site_no)                            as venue_key,
        md5('apex|site=' || site_no || '|profile|' || profile_no) as customer_key,
        site_no || '-' || ticket_no                             as source_booking_id,
        product, party_size, price_gross, currency,
        booked_at_utc, booked_at_local,
        activity_start_utc, activity_start_local,
        is_cancelled, cancelled_at_utc, cancelled_at_local,
        case when is_cancelled then 2 else 1 end                as version_count
    from staging.apex_tickets
)
select
    b.*,
    c.person_key,
    b.activity_start_local::date                                        as activity_date_local,
    date_diff('day', b.booked_at_local::date, b.activity_start_local::date) as lead_time_days
from (select * from hop union all select * from apx) b
left join core.dim_customer c using (customer_key);
