-- Hopscotch staging: typed, deduplicated, UTC + venue-local timestamps.
-- Source timestamps are UTC ('...Z'); stored here as naive UTC timestamps.

create or replace view staging.hopscotch_operators as
select
    operator_key::int        as operator_key,
    trim(trading_name)       as venue_name,
    vertical,
    iso_country              as country,
    iso_currency             as currency,
    tz_name                  as tz,
    is_sandbox::boolean      as is_test
from raw.hopscotch_operators;

create or replace view staging.hopscotch_patrons as
select
    p.patron_key::int                                   as patron_key,
    p.operator_key::int                                 as operator_key,
    p.contact_email                                     as email_raw,
    staging.clean_email(p.contact_email)                as email,
    trim(p.given_name)                                  as first_name,
    trim(p.family_name)                                 as last_name,
    timezone('UTC', p.registered_ts::timestamptz)       as registered_at_utc
from raw.hopscotch_patrons p;

-- 40 rows are exact duplicates of another row (same key, same content) -> distinct.
-- If a duplicate key ever arrives with *different* content, distinct keeps both
-- and the uniqueness check in 04_checks fails the build.
create or replace view staging.hopscotch_reservation_versions as
with dedup as (
    select distinct
        reservation_key, version_seq, operator_key, patron_key, offering,
        session_start_ts, booked_ts, valid_from_ts, lifecycle, party_size,
        price_net, price_tax, iso_currency
    from raw.hopscotch_reservation_versions
)
select
    d.reservation_key::bigint                               as reservation_key,
    d.version_seq::int                                      as version_seq,
    d.operator_key::int                                     as operator_key,
    d.patron_key::int                                       as patron_key,
    trim(d.offering)                                        as product,
    d.lifecycle,
    d.lifecycle = 'CANCELLED'                               as is_cancelled,
    d.party_size::int                                       as party_size,
    d.price_net::decimal(12,2)                              as price_net,
    d.price_tax::decimal(12,2)                              as price_tax,
    d.price_net::decimal(12,2) + d.price_tax::decimal(12,2) as price_gross,
    d.iso_currency                                          as currency,
    timezone('UTC', d.session_start_ts::timestamptz)        as activity_start_utc,
    timezone('UTC', d.booked_ts::timestamptz)               as booked_at_utc,
    timezone('UTC', d.valid_from_ts::timestamptz)           as valid_from_utc,
    staging.utc_to_local(timezone('UTC', d.session_start_ts::timestamptz), o.tz_name) as activity_start_local,
    staging.utc_to_local(timezone('UTC', d.booked_ts::timestamptz), o.tz_name)        as booked_at_local,
    staging.utc_to_local(timezone('UTC', d.valid_from_ts::timestamptz), o.tz_name)    as valid_from_local
from dedup d
left join raw.hopscotch_operators o on o.operator_key = d.operator_key;

-- Signed amount: IN = money collected (+), OUT = money refunded (-).
create or replace view staging.hopscotch_money_movements as
select
    movement_key::bigint                                    as movement_key,
    reservation_key::bigint                                 as reservation_key,
    case direction when 'IN' then 'collection' when 'OUT' then 'refund' end as payment_type,
    case direction when 'IN' then 1 else -1 end * value::decimal(12,2)      as amount,
    iso_currency                                            as currency,
    lower(rail)                                             as method,
    memo,
    timezone('UTC', moved_ts::timestamptz)                  as paid_at_utc
from raw.hopscotch_money_movements;
