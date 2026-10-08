-- FX staging: one row per business day per currency (USD per 1 unit).
-- Weekends/holidays are missing in the source; gaps are filled in core.

create or replace view staging.rates_daily as
select
    as_of::date                   as rate_date,
    base_ccy                      as currency,
    usd_per_unit::decimal(18,6)   as usd_per_unit
from raw.rates_daily
where quote_ccy = 'USD';
