-- One row per currency per calendar day
-- Rates are only published on business days, so weekends and holidays carry the last published rate forward

create or replace table core.dim_fx_daily as
with days as (
    select unnest(generate_series(min(rate_date), max(rate_date), interval 1 day))::date as rate_date
    from staging.rates_daily
),
grid as (
    select d.rate_date, c.currency
    from days d
    cross join (select distinct currency from staging.rates_daily) c
),
filled as (
    select
        g.rate_date,
        g.currency,
        last_value(r.usd_per_unit ignore nulls) over w  as usd_per_unit,
        last_value(r.rate_date    ignore nulls) over w  as published_on
    from grid g
    left join staging.rates_daily r using (rate_date, currency)
    window w as (partition by g.currency order by g.rate_date
                 rows between unbounded preceding and current row)
)
select rate_date, currency, usd_per_unit, published_on,
       published_on <> rate_date as is_carried_forward
from filled
union all
select rate_date, 'USD', 1.0, rate_date, false
from days;
