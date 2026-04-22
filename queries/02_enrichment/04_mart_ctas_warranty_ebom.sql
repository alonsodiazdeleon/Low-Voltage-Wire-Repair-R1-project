-- Materialize warranty cohort + EBOM, then the join mart.
-- Same logic as `03_warranty_ebom_join.sql`, split so each step scans sources once
-- and the final join reads two tables (avoids re-reading full EBOM on every ad-hoc run).
--
-- 1) Target schema: `sandbox.adiazdeleon` (change here if you relocate tables).
-- 2) Run off-peak:  **A** and **B** in either order, then **C** (C depends on both).
-- 3) `ebom_match_type` and `ebom_*` column names match `03_warranty_ebom_join.sql`.
--
-- **Section A “no rows” in the result grid?**  In Databricks, `CREATE OR REPLACE TABLE ... AS
-- SELECT` often does **not** show a data preview; the result panel may be empty. That is normal.
-- **Always verify** with the “Verify A” queries *after* A finishes (separate cell).
--
-- **If the *table* is really empty** (`row_cnt = 0` on verify): run the “Smoke — source” query
-- below. If the source `COUNT(*)` is 0, the issue is the upstream dim (name/region/catalog)
-- or permissions, not this SQL. If the source is non-zero but the sandbox table is 0, the
-- CTAS may have failed silently only in a partial run—check the job for errors, or a wrong
-- schema name so you were reading a different table in the Data Explorer.

-- =============================================================================
-- Smoke — source (run in its own cell *before* section A, once)
-- =============================================================================
-- SELECT COUNT(*) AS n_rows FROM supply_chain.bom.dim_fct_catia_ebom_parts;
-- SELECT * FROM supply_chain.bom.dim_fct_catia_ebom_parts LIMIT 5;

-- =============================================================================
-- A) EBOM with child_pn_resolved  (full dim scan — same as 02; heavy)
-- =============================================================================
CREATE OR REPLACE TABLE sandbox.adiazdeleon.harness_ebom_dim_fct_catia_resolved AS
WITH ebom_base AS (
  SELECT
    e.program_key,
    e.ebom_display,
    e.ebom_type,
    e.parent_part_number,
    e.part_number,
    e.part_number_base,
    e.part_title,
    e.part_description,
    e.part_number_hierarchy_level,
    e.part_number_hierarchy_arr,
    e.parent_part_number_hierarchy,
    e.is_parent_part,
    e.is_latest_released,
    e.released_ca_number,
    e.traceability_type,
    e.engineering_system,
    e.engineering_subsystem,
    e.engineering_system_inherited,
    e.engineering_subsystem_inherited,
    e.organization,
    e.part_type,
    e.standard_component_type,
    e.design_responsible_engineer,
    e.maturity_state,
    e.supersession_type,
    e.lead_program,
    e.lead_subprogram,
    e.effectivity_date_range,
    e.variant_effectivity,
    e.qualified_filters_arr,
    e.is_end_item,
    e.is_procurable,
    e.supplier_name,
    e.purchasing_manager,
    e.supplier_quality_engineer,
    CASE
      WHEN e.is_parent_part = false
      THEN COALESCE(
        NULLIF(TRIM(CAST(e.part_number AS STRING)), ''),
        NULLIF(
          TRIM(
            element_at(
              split(TRIM(CAST(e.parent_part_number_hierarchy AS STRING)), ':'),
              -1
            )
          ),
          ''
        ),
        NULLIF(TRIM(RIGHT(TRIM(CAST(e.parent_part_number_hierarchy AS STRING)), 12)), '')
      )
    END AS child_pn_resolved
  FROM supply_chain.bom.dim_fct_catia_ebom_parts e
  WHERE 1 = 1
)
SELECT * FROM ebom_base;

-- =============================================================================
-- Verify A (separate cell, after the CREATE above succeeds)
-- =============================================================================
-- SELECT COUNT(*) AS row_cnt FROM sandbox.adiazdeleon.harness_ebom_dim_fct_catia_resolved;
-- SELECT * FROM sandbox.adiazdeleon.harness_ebom_dim_fct_catia_resolved LIMIT 10;
--
-- **Optional tiny smoke run:** duplicate section A, add at the *end* of the subquery
--   `... SELECT * FROM ebom_base` → `... SELECT * FROM ebom_base LIMIT 500`
--   into a temp table, inspect, then re-run the full A without `LIMIT` for production.

-- =============================================================================
-- B) Wiring-harness warranty cohort (FPM, labor 780095014, start date) + QA
-- =============================================================================
CREATE OR REPLACE TABLE sandbox.adiazdeleon.harness_warranty_780095014_cohort AS
WITH tt AS (
  SELECT DISTINCT
    service_request_id,
    tier3,
    MAX(CASE WHEN qa_q = '1. Which wiring harness repair(s) did you perform?' THEN qa_a[0] END) AS repair_type,
    MAX(CASE WHEN qa_q = '2. Which connector numbers were worked on?' THEN qa_a[0] END) AS connector_number,
    MAX(CASE WHEN qa_q = '3. Which circuit numbers were worked on?' THEN qa_a[0] END) AS circuit,
    MAX(CASE WHEN qa_q = '4. Where is the location of the repair in relation to the vehicle body?' THEN qa_a[0] END) AS reapair_location,
    MAX(CASE WHEN qa_q = '5. Upload image of the defect found BEFORE repairs are performed.' THEN has_image_keys END) AS image_before_repair,
    MAX(CASE WHEN qa_q = '5. Upload image of the defect found AFTER repairs are performed.' THEN has_image_keys END) AS image_after_repair
  FROM main.vehicle_services.vs_event_schema_flattened
  WHERE 1 = 1
    AND (tier1 = 'Wiring Harness Repair' OR tier3 = 'Wiring Harness Repair')
  GROUP BY service_request_id, tier3
),

warranty_cohort AS (
  SELECT DISTINCT
    s.v_vin,
    s.v_vehicle_model,
    s.v_veh_program,
    s.v_vehicle_platform,
    s.days_to_sr,
    s.wo_workorder_id,
    s.sr_service_request_number,
    s.sr_service_request_id,
    s.sr_created_date,
    s.sr_completed_date,
    s.mapped_endpoint,
    s.sr_concern,
    s.sr_technician_notes,
    s.sr_internal_technician_notes,
    tier3,
    tt.repair_type,
    tt.connector_number,
    tt.circuit,
    tt.reapair_location,
    tt.image_before_repair,
    tt.image_after_repair,
    s.vehicle_breakdown_grouping,
    s.sr_pri_fail_labor_sys,
    s.sr_pri_fail_labor_subsys,
    s.sr_pri_fail_part_number,
    s.sr_pri_fail_part_descr,
    s.cr_labor_code,
    s.cr_labor_description,
    s.pu_part_number,
    s.pu_part_description,
    s.pu_part_rpt_group,
    s.pu_part_quantity,
    s.pu_individual_part_cost,
    s.pu_total_part_cost,
    CASE WHEN s.vehicle_breakdown_grouping = 'Tow VBR' THEN TRUE ELSE FALSE END AS is_tow,
    CASE WHEN s.days_to_sr <= 90 THEN TRUE ELSE FALSE END AS is_3MIS
  FROM main.vehicle_services.vs_rpt_flat_view s
  LEFT JOIN tt ON s.sr_service_request_id = tt.service_request_id
  WHERE 1 = 1
    AND s.is_field_performance_metric_included = 1
    AND s.cr_labor_code = '780095014'
    -- Default: 2026 pilot. If B returns 0 rows, temporarily use e.g. `2020-01-01` to confirm
    --   the pipeline, then set back; see diagnostic block at end of this file.
    AND s.sr_completed_date >= '2026-01-01'
  --   AND s.v_vehicle_model LIKE 'R1%'
  --   AND s.v_veh_program LIKE 'R1%'
)
SELECT * FROM warranty_cohort;

-- Verify B (separate cell): if row_cnt = 0, Section C *must* be 0 (LEFT join from an empty w).
-- SELECT COUNT(*) AS row_cnt FROM sandbox.adiazdeleon.harness_warranty_780095014_cohort;
-- SELECT * FROM sandbox.adiazdeleon.harness_warranty_780095014_cohort LIMIT 10;

-- =============================================================================
-- C) Mart: warranty LEFT JOIN EBOM on pu_part_number
--     (multiple EBOM rows per warranty row are possible; dedupe downstream if needed)
--     **Join must require non-blank `pu_part_number`**, or `''` = `''` explodes the join.
-- =============================================================================
CREATE OR REPLACE TABLE sandbox.adiazdeleon.harness_mart_warranty_ebom AS
SELECT /*+ BROADCAST (w) */
  w.*,
  m.program_key         AS ebom_program_key,
  m.ebom_display        AS ebom_ebom_display,
  m.ebom_type           AS ebom_ebom_type,
  m.parent_part_number  AS ebom_immediate_parent_pn,
  m.part_number         AS ebom_row_part_number,
  m.parent_part_number_hierarchy AS ebom_parent_part_number_hierarchy,
  m.is_parent_part      AS ebom_is_parent_part,
  m.is_latest_released  AS ebom_is_latest_released,
  m.engineering_system  AS ebom_engineering_system,
  m.engineering_subsystem AS ebom_engineering_subsystem,
  m.engineering_system_inherited AS ebom_engineering_system_inherited,
  m.lead_program        AS ebom_lead_program,
  m.lead_subprogram     AS ebom_lead_subprogram,
  m.released_ca_number  AS ebom_released_ca_number,
  m.child_pn_resolved   AS ebom_child_pn_resolved,
  CASE
    WHEN TRIM(UPPER(COALESCE(CAST(w.pu_part_number AS STRING), ''))) = TRIM(UPPER(COALESCE(CAST(m.child_pn_resolved AS STRING), '')))
      AND TRIM(UPPER(COALESCE(CAST(w.pu_part_number AS STRING), ''))) <> ''
    THEN 'child_pn_resolved'
    WHEN TRIM(UPPER(COALESCE(CAST(w.pu_part_number AS STRING), ''))) = TRIM(UPPER(COALESCE(CAST(m.part_number AS STRING), '')))
      AND TRIM(UPPER(COALESCE(CAST(w.pu_part_number AS STRING), ''))) <> ''
    THEN 'ebom_row_part_number'
    WHEN TRIM(UPPER(COALESCE(CAST(w.pu_part_number AS STRING), ''))) = TRIM(UPPER(COALESCE(CAST(m.parent_part_number AS STRING), '')))
      AND TRIM(UPPER(COALESCE(CAST(w.pu_part_number AS STRING), ''))) <> ''
    THEN 'parent_part_number'
  END AS ebom_match_type
FROM sandbox.adiazdeleon.harness_warranty_780095014_cohort w
LEFT JOIN sandbox.adiazdeleon.harness_ebom_dim_fct_catia_resolved m
  ON TRIM(UPPER(COALESCE(CAST(w.pu_part_number AS STRING), ''))) <> ''
  AND (
    TRIM(UPPER(COALESCE(CAST(w.pu_part_number AS STRING), ''))) = TRIM(UPPER(COALESCE(CAST(m.child_pn_resolved AS STRING), '')))
    OR TRIM(UPPER(COALESCE(CAST(w.pu_part_number AS STRING), ''))) = TRIM(UPPER(COALESCE(CAST(m.part_number AS STRING), '')))
    OR TRIM(UPPER(COALESCE(CAST(w.pu_part_number AS STRING), ''))) = TRIM(UPPER(COALESCE(CAST(m.parent_part_number AS STRING), '')))
  )
;

-- After C: the cell often shows no grid (CTAS only). For a **visible** result, run
--   `04c_post_c_notebook_check.sql` in the next cell (one-row summary + optional sample).
--
-- Verify C (separate cell): CTAS may show “no rows” in the result grid; COUNT is truth.
-- SELECT COUNT(*) AS row_cnt FROM sandbox.adiazdeleon.harness_mart_warranty_ebom;
-- If row_cnt = 0, fix B (warranty_cohort) first; C cannot have rows if B is empty.
--
-- =============================================================================
-- If cohort (B) is empty — run these *once* in separate cells to see which filter bites
-- =============================================================================
-- SELECT
--   COUNT_IF(s.is_field_performance_metric_included = 1) AS fpm1,
--   COUNT_IF(s.is_field_performance_metric_included = 1 AND s.sr_completed_date >= '2026-01-01') AS fpm1_and_2026,
--   COUNT_IF(s.is_field_performance_metric_included = 1 AND s.sr_completed_date >= '2020-01-01') AS fpm1_and_2020,
--   MIN(s.sr_completed_date) AS min_sr_date,
--   MAX(s.sr_completed_date) AS max_sr_date
-- FROM main.vehicle_services.vs_rpt_flat_view s
-- WHERE s.cr_labor_code = '780095014';
