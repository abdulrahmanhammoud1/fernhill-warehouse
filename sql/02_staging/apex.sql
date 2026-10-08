-- Apex staging: typed, deduplicated, venue-local + UTC timestamps.
-- Source timestamps are site-local with no offset; converted with the site's tz.
-- Keys (profile_no, ticket_no, settle_no) are only unique within a site.

create or replace view staging.apex_sites as
select
    site_no::int             as site_no,
    trim(site_title)         as venue_name,
    'Go-karting'             as vertical,
    iso_country              as country,
    iso_currency             as currency,
    olson_tz                 as tz,
    is_training = '1'        as is_test
from raw.apex_sites;

create or replace view staging.apex_profiles as
select
    p.site_no::int                                      as site_no,
    p.profile_no::int                                   as profile_no,
    p.mail                                              as email_raw,
    staging.clean_email(p.mail)                         as email,
    trim(p.first)                                       as first_name,
    trim(p.surname)                                     as last_name,
    p.joined_local::timestamp                           as registered_at_local,
    staging.local_to_utc(p.joined_local::timestamp, s.olson_tz) as registered_at_utc
from raw.apex_profiles p
left join raw.apex_sites s on s.site_no = p.site_no;

-- gross_minor is in minor units (cents/pence) -> divide by 100.
-- All Apex currencies (USD, GBP, AUD) have 2 decimal places.
create or replace view staging.apex_tickets as
select
    t.site_no::int                                      as site_no,
    t.ticket_no::int                                    as ticket_no,
    t.profile_no::int                                   as profile_no,
    trim(t.product_label)                               as product,
    t.outcome,
    t.outcome = 'WITHDRAWN'                             as is_cancelled,
    t.head_count::int                                   as party_size,
    (t.gross_minor::bigint / 100.0)::decimal(12,2)      as price_gross,
    s.iso_currency                                      as currency,
    t.session_local::timestamp                          as activity_start_local,
    t.opened_local::timestamp                           as booked_at_local,
    t.withdrawn_local::timestamp                        as cancelled_at_local,
    staging.local_to_utc(t.session_local::timestamp,   s.olson_tz) as activity_start_utc,
    staging.local_to_utc(t.opened_local::timestamp,    s.olson_tz) as booked_at_utc,
    staging.local_to_utc(t.withdrawn_local::timestamp, s.olson_tz) as cancelled_at_utc
from raw.apex_tickets t
left join raw.apex_sites s on s.site_no = t.site_no;

-- 18 rows are exact duplicates (same site + settle_no, same content) -> distinct.
-- settle_value is already in major units and already signed (negative = refund).
create or replace view staging.apex_settlements as
with dedup as (
    select distinct site_no, settle_no, ticket_no, settle_value, settle_local, instrument
    from raw.apex_settlements
)
select
    d.site_no::int                                      as site_no,
    d.settle_no::int                                    as settle_no,
    d.ticket_no::int                                    as ticket_no,
    case when d.settle_value::decimal(12,2) < 0 then 'refund' else 'collection' end as payment_type,
    d.settle_value::decimal(12,2)                       as amount,
    s.iso_currency                                      as currency,
    lower(d.instrument)                                 as method,
    d.settle_local::timestamp                           as paid_at_local,
    staging.local_to_utc(d.settle_local::timestamp, s.olson_tz) as paid_at_utc
from dedup d
left join raw.apex_sites s on s.site_no = d.site_no;
