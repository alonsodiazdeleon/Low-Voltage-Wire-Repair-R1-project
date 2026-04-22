-- Run in a **separate** Databricks SQL cell **after** `04_mart_ctas_warranty_ebom.sql` section C.
-- `CREATE OR REPLACE TABLE … AS SELECT` does not return a data grid in the UI; this does.
-- Copy into a draft notebook, or use as a saved query. Safe to re-run any time.
--
-- Notebook pattern:  [Cell] A  →  [Cell] B  →  [Cell] C  →  [Cell] this file (§1 then §2).

-- -------------------------------------------------------------------------
-- §1 — one-row “OK” summary (row counts; shows a result table in SQL editor)
-- -------------------------------------------------------------------------
SELECT
  '04 C complete' AS check_label,
  (SELECT COUNT(*) FROM sandbox.adiazdeleon.harness_mart_warranty_ebom) AS mart_row_count,
  (SELECT COUNT(*) FROM sandbox.adiazdeleon.harness_warranty_780095014_cohort) AS cohort_row_count,
  (SELECT COUNT(*) FROM sandbox.adiazdeleon.harness_ebom_dim_fct_catia_resolved) AS ebom_staging_row_count;

-- -------------------------------------------------------------------------
-- §2 — sample of the mart (optional second cell: easier to read than §1 only)
-- -------------------------------------------------------------------------
-- SELECT
--   sr_service_request_id,
--   pu_part_number,
--   ebom_match_type,
--   ebom_engineering_system,
--   ebom_lead_program
-- FROM sandbox.adiazdeleon.harness_mart_warranty_ebom
-- LIMIT 25
-- ;
