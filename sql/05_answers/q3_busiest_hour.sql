-- Q3: busiest start hour per venue (local time), non-cancelled bookings in 2025
-- ties are all shown

create or replace view answers.q3_busiest_hour as
with by_hour as (
    select v.platform, v.venue_name, hour(b.activity_start_local) as hour, count(*) as bookings
    from core.fct_booking b
    join core.dim_venue v using (venue_key)
    where not v.is_test and not b.is_cancelled and year(b.activity_date_local) = 2025
    group by all
)
select platform, venue_name,
       lpad(hour::varchar, 2, '0') || ':00' as busiest_hour,
       bookings
from by_hour
qualify rank() over (partition by venue_name order by bookings desc) = 1
order by platform, venue_name;

copy (select * from answers.q3_busiest_hour) to 'results/q3_busiest_hour.csv' (header);
select * from answers.q3_busiest_hour;
