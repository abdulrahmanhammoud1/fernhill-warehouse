-- Raw layer: source files loaded as-is (all text, no cleaning).
-- Typing, dedup and cleaning happen in staging.

create schema if not exists raw;

-- Hopscotch
create or replace table raw.hopscotch_operators as
select *, current_timestamp as _loaded_at
from read_csv('data/hopscotch/operators.csv', header = true, all_varchar = true, filename = '_source_file');

create or replace table raw.hopscotch_patrons as
select *, current_timestamp as _loaded_at
from read_csv('data/hopscotch/patrons.csv', header = true, all_varchar = true, filename = '_source_file');

create or replace table raw.hopscotch_reservation_versions as
select *, current_timestamp as _loaded_at
from read_csv('data/hopscotch/reservation_versions.csv', header = true, all_varchar = true, filename = '_source_file');

create or replace table raw.hopscotch_money_movements as
select *, current_timestamp as _loaded_at
from read_csv('data/hopscotch/money_movements.csv', header = true, all_varchar = true, filename = '_source_file');

-- Apex
create or replace table raw.apex_sites as
select *, current_timestamp as _loaded_at
from read_csv('data/apex/sites.csv', header = true, all_varchar = true, filename = '_source_file');

create or replace table raw.apex_profiles as
select *, current_timestamp as _loaded_at
from read_csv('data/apex/profiles.csv', header = true, all_varchar = true, filename = '_source_file');

create or replace table raw.apex_tickets as
select *, current_timestamp as _loaded_at
from read_csv('data/apex/tickets.csv', header = true, all_varchar = true, filename = '_source_file');

create or replace table raw.apex_settlements as
select *, current_timestamp as _loaded_at
from read_csv('data/apex/settlements.csv', header = true, all_varchar = true, filename = '_source_file');

-- FX
create or replace table raw.rates_daily as
select *, current_timestamp as _loaded_at
from read_csv('data/rates_daily.csv', header = true, all_varchar = true, filename = '_source_file');

-- row counts
select 'hopscotch_operators' as tbl, count(*) as n from raw.hopscotch_operators
union all select 'hopscotch_patrons', count(*) from raw.hopscotch_patrons
union all select 'hopscotch_reservation_versions', count(*) from raw.hopscotch_reservation_versions
union all select 'hopscotch_money_movements', count(*) from raw.hopscotch_money_movements
union all select 'apex_sites', count(*) from raw.apex_sites
union all select 'apex_profiles', count(*) from raw.apex_profiles
union all select 'apex_tickets', count(*) from raw.apex_tickets
union all select 'apex_settlements', count(*) from raw.apex_settlements
union all select 'rates_daily', count(*) from raw.rates_daily;