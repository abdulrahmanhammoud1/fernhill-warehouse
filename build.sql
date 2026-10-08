-- Run from repo root: duckdb warehouse.duckdb -f build.sql
.bail on
set TimeZone = 'UTC';

.read sql/01_raw/load_raw.sql

.read sql/02_staging/00_helpers.sql
.read sql/02_staging/hopscotch.sql
.read sql/02_staging/apex.sql
.read sql/02_staging/fx.sql
.read sql/02_staging/summary.sql