-- staging row counts vs raw (difference = duplicates removed)
select 'hopscotch_reservation_versions' as tbl,
       (select count(*) from raw.hopscotch_reservation_versions) as raw_rows,
       (select count(*) from staging.hopscotch_reservation_versions) as staged_rows
union all select 'hopscotch_money_movements',
       (select count(*) from raw.hopscotch_money_movements), (select count(*) from staging.hopscotch_money_movements)
union all select 'apex_tickets',
       (select count(*) from raw.apex_tickets), (select count(*) from staging.apex_tickets)
union all select 'apex_settlements',
       (select count(*) from raw.apex_settlements), (select count(*) from staging.apex_settlements);
