-- Q1: net takings (USD) per venue per month of 2025
-- month = activity date in venue local time, fx at the activity date

create schema if not exists answers;

create or replace view answers.q1_net_takings as
select venue_name, platform,
       strftime(activity_date_local, '%Y-%m') as month,
       round(sum(net_takings_usd), 2)         as net_takings_usd
from core.mart_booking_takings
where not is_test and year(activity_date_local) = 2025
group by all;

copy (
    pivot answers.q1_net_takings on month using sum(net_takings_usd)
    order by platform, venue_name
) to 'results/q1_net_takings_usd.csv' (header);

pivot answers.q1_net_takings on month using sum(net_takings_usd) order by platform, venue_name;
