-- Q4: people who booked at more than one venue / on both platforms in 2025
-- person = same cleaned email; records with no usable email can't be matched
-- main answer counts cancelled bookings too (they still booked), second column without them

create or replace view answers.q4_shared_customers as
with b as (
    select b.person_key, b.venue_key, b.platform, b.is_cancelled
    from core.fct_booking b
    join core.dim_venue v using (venue_key)
    where not v.is_test and year(b.activity_date_local) = 2025
),
per_person as (
    select person_key,
           count(distinct venue_key)                          as venues_all,
           count(distinct platform)                           as platforms_all,
           count(distinct venue_key) filter (not is_cancelled) as venues_live,
           count(distinct platform)  filter (not is_cancelled) as platforms_live
    from b group by person_key
)
select 'people who booked in 2025' as metric,
       count(*) as incl_cancelled, count(*) filter (venues_live > 0) as excl_cancelled
from per_person
union all
select 'booked at more than one venue',
       count(*) filter (venues_all > 1), count(*) filter (venues_live > 1)
from per_person
union all
select 'booked on both Hopscotch and Apex',
       count(*) filter (platforms_all = 2), count(*) filter (platforms_live = 2)
from per_person;

copy (select * from answers.q4_shared_customers) to 'results/q4_shared_customers.csv' (header);
select * from answers.q4_shared_customers;
