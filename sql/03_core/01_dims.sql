-- Core dimensions: venue, customer (source record), person (matched identity)
-- Keys are unique across both platforms and stable across reloads
-- Apex keys include site_no because Apex ids are only unique within a site

create schema if not exists core;

create or replace table core.dim_venue as
select
    md5('hopscotch|operator|' || operator_key)  as venue_key,
    'hopscotch'                                 as platform,
    operator_key::varchar                       as source_venue_id,
    venue_name, vertical, country, currency, tz, is_test
from staging.hopscotch_operators
union all
select
    md5('apex|site|' || site_no),
    'apex',
    site_no::varchar,
    venue_name, vertical, country, currency, tz, is_test
from staging.apex_sites;

-- One row per customer record as the source holds it
-- person_key: same cleaned email = same person. 
-- Records with no usable email cant be matched so each one becomes its own person
create or replace table core.dim_customer as
with c as (
    select
        md5('hopscotch|patron|' || patron_key)          as customer_key,
        'hopscotch'                                     as platform,
        md5('hopscotch|operator|' || operator_key)      as venue_key,
        patron_key::varchar                             as source_customer_id,
        email, first_name, last_name, registered_at_utc
    from staging.hopscotch_patrons
    union all
    select
        md5('apex|site=' || site_no || '|profile|' || profile_no),
        'apex',
        md5('apex|site|' || site_no),
        site_no || '-' || profile_no,
        email, first_name, last_name, registered_at_utc
    from staging.apex_profiles
)
select
    *,
    case when email is not null then md5('email|' || email)
         else md5('unmatched|' || customer_key) end     as person_key
from c;

create or replace table core.dim_person as
select
    person_key,
    any_value(email)                                    as email,
    case when any_value(email) is null then 'unmatched' else 'email' end as match_method,
    count(*)                                            as customer_records,
    count(distinct platform)                            as platforms
from core.dim_customer
group by person_key;
