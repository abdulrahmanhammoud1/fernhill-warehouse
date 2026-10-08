-- Payments: one row per money movement
-- Rows whose booking is not in the extract cant be placed on a venue or date so they go to quarantine instead of core

create schema if not exists quarantine;

create or replace temp table all_payments as
select
    md5('hopscotch|movement|' || movement_key)              as payment_key,
    md5('hopscotch|reservation|' || reservation_key)        as booking_key,
    'hopscotch'                                             as platform,
    movement_key::varchar                                   as source_payment_id,
    reservation_key::varchar                                as source_booking_id,
    payment_type, amount, currency, method, memo, paid_at_utc
from staging.hopscotch_money_movements
union all
select
    md5('apex|site=' || site_no || '|settlement|' || settle_no),
    md5('apex|site=' || site_no || '|ticket|' || ticket_no),
    'apex',
    site_no || '-' || settle_no,
    site_no || '-' || ticket_no,
    payment_type, amount, currency, method, null, paid_at_utc
from staging.apex_settlements;

create or replace table core.fct_payment as
select
    p.payment_key, p.booking_key, b.venue_key, p.platform, p.source_payment_id,
    p.payment_type, p.amount, p.currency, p.method, p.memo, p.paid_at_utc,
    staging.utc_to_local(p.paid_at_utc, v.tz)   as paid_at_local
from all_payments p
join core.fct_booking b using (booking_key)
join core.dim_venue v on v.venue_key = b.venue_key;

create or replace table quarantine.orphan_payments as
select p.*, 'booking not found in extract' as reason
from all_payments p
where not exists (select 1 from core.fct_booking b where b.booking_key = p.booking_key);
