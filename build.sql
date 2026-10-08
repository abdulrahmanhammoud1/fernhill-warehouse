-- Run from repo root: duckdb warehouse.duckdb -f build.sql
.bail on
set TimeZone = 'UTC';

.read sql/01_raw/load_raw.sql

.read sql/02_staging/00_helpers.sql
.read sql/02_staging/hopscotch.sql
.read sql/02_staging/apex.sql
.read sql/02_staging/fx.sql
.read sql/02_staging/summary.sql

.read sql/03_core/01_dims.sql
.read sql/03_core/02_fx.sql
.read sql/03_core/03_bookings.sql
.read sql/03_core/04_payments.sql
.read sql/03_core/05_marts.sql
.read sql/03_core/summary.sql

.read sql/04_checks/checks.sql
