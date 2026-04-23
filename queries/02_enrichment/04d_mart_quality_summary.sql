-- One-row EBOM join health check on `harness_mart_warranty_ebom` (after 04 A/B/C).
-- Run in a SQL cell after `04c_post_c_notebook_check.sql` or anytime. Read-only; no trailing `;`
-- (Genie / “run whole file” — same pattern as `01` / `02`).
--
-- Replace `sandbox.adiazdeleon` if your mart lives elsewhere.

SELECT
  COUNT(*) AS mart_row_count,
  COUNT(DISTINCT sr_service_request_id) AS distinct_sr_in_mart,
  COUNT(DISTINCT pu_part_number) AS distinct_pu_part_numbers,
  COUNT_IF(TRIM(UPPER(COALESCE(CAST(pu_part_number AS STRING), ''))) = '') AS rows_blank_pu,
  COUNT_IF(ebom_match_type IS NOT NULL) AS rows_with_ebom_match,
  ROUND(100.0 * COUNT_IF(ebom_match_type IS NOT NULL) / NULLIF(COUNT(*), 0), 2) AS pct_mart_rows_with_match,
  COUNT_IF(ebom_match_type = 'child_pn_resolved') AS match_via_child_pn_resolved,
  COUNT_IF(ebom_match_type = 'ebom_row_part_number') AS match_via_ebom_row_part_number,
  COUNT_IF(ebom_match_type = 'parent_part_number') AS match_via_parent_part_number,
  COUNT_IF(
    ebom_match_type IS NULL
    AND TRIM(UPPER(COALESCE(CAST(pu_part_number AS STRING), ''))) <> ''
  ) AS unmatched_but_pu_present

FROM sandbox.adiazdeleon.harness_mart_warranty_ebom
