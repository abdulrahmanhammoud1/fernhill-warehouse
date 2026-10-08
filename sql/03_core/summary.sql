-- core row counts
select 'dim_venue' as tbl, count(*) as n from core.dim_venue
union all select 'dim_customer', count(*) from core.dim_customer
union all select 'dim_person', count(*) from core.dim_person
union all select 'dim_fx_daily', count(*) from core.dim_fx_daily
union all select 'fct_booking', count(*) from core.fct_booking
union all select 'fct_booking_version', count(*) from core.fct_booking_version
union all select 'fct_payment', count(*) from core.fct_payment
union all select 'mart_booking_takings', count(*) from core.mart_booking_takings
union all select 'quarantine.orphan_payments', count(*) from quarantine.orphan_payments;
