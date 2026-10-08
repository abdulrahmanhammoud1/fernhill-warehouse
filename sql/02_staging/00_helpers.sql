-- Shared cleaning rules, defined once and used by both sources.

create schema if not exists staging;

-- Trim + lowercase; known placeholder addresses become NULL (not a real person).
create or replace macro staging.clean_email(e) as
    case
        when nullif(lower(trim(e)), '') in ('none@none.com', 'noemail@apexvenue.invalid') then null
        else nullif(lower(trim(e)), '')
    end;

-- UTC -> venue local wall-clock time
create or replace macro staging.utc_to_local(ts_utc, tz) as
    timezone(tz, timezone('UTC', ts_utc));

-- venue local wall-clock time -> UTC
create or replace macro staging.local_to_utc(ts_local, tz) as
    timezone('UTC', timezone(tz, ts_local));
