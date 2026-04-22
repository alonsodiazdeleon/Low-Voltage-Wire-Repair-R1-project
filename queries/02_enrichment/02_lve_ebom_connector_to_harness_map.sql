-- Child / connector PN → immediate parent assembly PN from `supply_chain.bom.dim_fct_catia_ebom_parts`
-- **No** engineering-system, program, or R1 filter — harnesses are released by many orgs; you filter
-- (e.g. LVE, R1) when you **join to warranty** or in a view, on `part_number` / `engineering_system` / `program_key`.
--
-- Parent vs child (row-level rules in EBOM):
--   * `is_parent_part` = true  → parent rows in the BOM tree
--   * `is_parent_part` = false → child rows; `child_pn_resolved` = part_number, else hierarchy/last-12 per below
--
-- Join to warranty: match `pu_part_number` to `child_pn_resolved`, `part_number`, and/or `parent_part_number`
-- (see `01_base_with_flat_view_parts.sql`). Use `engineering_system` / `lead_program` in the join or post-filter.
--
-- See: docs/PARTS_AND_MARTS.md
--
-- WARNING: `SELECT *` is the full table shape — large. For ad-hoc, add `LIMIT` or `WHERE` in a saved view
-- in your own schema. Do not commit a LIMIT here unless you cap for CI only.

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

SELECT *
FROM ebom_base
;

-- =============================================================================
-- Optional: only rows with a resolved child PN (tighter “edge list” for joins)
-- =============================================================================
/*
SELECT *
FROM ebom_base
WHERE is_parent_part = false
  AND child_pn_resolved IS NOT NULL
;
*/

-- =============================================================================
-- Example: join to warranty part lines
-- =============================================================================
/*
SELECT
  w.pu_part_number,
  w.sr_service_request_id,
  m.child_pn_resolved,
  m.parent_part_number,
  m.engineering_system,
  m.lead_program
FROM <warranty_with_parts> w
LEFT JOIN ebom_base m
  ON TRIM(UPPER(COALESCE(CAST(w.pu_part_number AS STRING), ''))) <> ''
  AND (
    TRIM(UPPER(COALESCE(CAST(w.pu_part_number AS STRING), ''))) = TRIM(UPPER(COALESCE(CAST(m.child_pn_resolved AS STRING), '')))
    OR TRIM(UPPER(COALESCE(CAST(w.pu_part_number AS STRING), ''))) = TRIM(UPPER(COALESCE(CAST(m.part_number AS STRING), '')))
    OR TRIM(UPPER(COALESCE(CAST(w.pu_part_number AS STRING), ''))) = TRIM(UPPER(COALESCE(CAST(m.parent_part_number AS STRING), '')))
  )
*/
