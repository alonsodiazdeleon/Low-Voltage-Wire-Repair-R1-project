-- Warranty (harness labor 780095014 + QA) joined to full Catia EBOM by part number.
-- Sources: `01_base_with_flat_view_parts.sql` + `02_lve_ebom_connector_to_harness_map.sql` (same CTEs inlined).
--
-- Modes:
--   1) All-in-one SELECT below — can be **heavy** (scans full EBOM). For first test, add LIMIT on the outer
--      SELECT or materialize EBOM to a view first (Option 2).
--   2) Commented blocks at bottom: create tables/views in *your* catalog/schema, then a thin join across them.
--
-- Match rule: `pu_part_number` equals (case-insensitive) `child_pn_resolved` OR `part_number` OR `parent_part_number`
-- on the EBOM side. Multiple EBOM matches per warranty row are possible; dedupe in a downstream mart if needed.

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
    AND s.sr_completed_date >= '2026-01-01'
  --   AND s.v_vehicle_model LIKE 'R1%'
  --   AND s.v_veh_program LIKE 'R1%'
),

ebom_base AS (
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

SELECT
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
FROM warranty_cohort w
LEFT JOIN ebom_base m
  -- Non-blank PN only: otherwise `''` matches every EBOM row with null/empty keys (hundreds of M rows).
  ON TRIM(UPPER(COALESCE(CAST(w.pu_part_number AS STRING), ''))) <> ''
  AND (
    TRIM(UPPER(COALESCE(CAST(w.pu_part_number AS STRING), ''))) = TRIM(UPPER(COALESCE(CAST(m.child_pn_resolved AS STRING), '')))
    OR TRIM(UPPER(COALESCE(CAST(w.pu_part_number AS STRING), ''))) = TRIM(UPPER(COALESCE(CAST(m.part_number AS STRING), '')))
    OR TRIM(UPPER(COALESCE(CAST(w.pu_part_number AS STRING), ''))) = TRIM(UPPER(COALESCE(CAST(m.parent_part_number AS STRING), '')))
  )
-- Optional: filter in reporting — LVE, R1, program, etc.
-- WHERE w.v_vehicle_model LIKE 'R1%'  AND m.engineering_system = 'LVE'
;
-- For a first test only, you can add on the **outer** SELECT:  LIMIT 5000
--
-- Materialized tables + mart (A→B or B→A, then C):  `04_mart_ctas_warranty_ebom.sql` (`sandbox.adiazdeleon`; edit file if you use another schema, run off-peak).
