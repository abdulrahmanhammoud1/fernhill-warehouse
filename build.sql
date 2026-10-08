-- Run from repo root: duckdb warehouse.duckdb -f build.sql
.bail on

.read sql/01_raw/load_raw.sql