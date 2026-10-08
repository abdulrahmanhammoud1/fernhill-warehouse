-- Net takings per booking
-- Money is attributed to the bookings activity date and converted at that days rate whenever the money actually moved

create or replace table core.mart_booking_takings as
with money as (
    select booking_key,
           sum(amount) filter (payment_type = 'collection')  as collected,
           -sum(amount) filter (payment_type = 'refund')     as refunded,
           sum(amount)                                       as net_takings
    from core.fct_payment
    group by booking_key
)
select
    b.booking_key, b.platform, b.venue_key, v.venue_name, v.is_test,
    b.activity_date_local, b.is_cancelled, b.currency,
    coalesce(m.collected, 0)                        as collected,
    coalesce(m.refunded, 0)                         as refunded,
    coalesce(m.net_takings, 0)                      as net_takings,
    fx.usd_per_unit                                 as fx_rate,
    coalesce(m.net_takings, 0) * fx.usd_per_unit   as net_takings_usd
from core.fct_booking b
join core.dim_venue v using (venue_key)
left join money m using (booking_key)
left join core.dim_fx_daily fx
       on fx.currency = b.currency and fx.rate_date = b.activity_date_local;
