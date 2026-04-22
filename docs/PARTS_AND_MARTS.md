# Parts data, marts, and mapping (project alignment)

## Summary

| Need | Use this (you have access) | Do **not** depend on for MVP |
|------|----------------------------|------------------------------|
| Per **part line** (PN, qty, line cost) on a WO/SR | `main.vehicle_services.vs_rpt_flat_view` — `pu_part_*` | `commercial.serviceos_legacy.fct_sos_detailed_service_rpt` (restricted; redundant for this use case) |
| **Event-level** repair rate / system / exposure / one primary part | `main.rel_field.vs_rpt_repair_rates_mv` (claim rows: `is_vin_pop = 0`) | Same — not a substitute for **multi-part** line detail |
| **Connector / child PN → parent (EBOM)** | `dim_fct_catia_ebom_parts` — unfiltered in repo; **harnesses come from all orgs**, not LVE only; **filter in join** (system, program) | — |
| **LVE / model / classification in SBOM** | `dim_sbom_parts`, optional `main.adhoc.sbom_mapping`, supersession flags | — |
| **Service vs engineering BOM** | `datalake` serviceable child views (optional) | — |
| **2D PDF link** | `commercial.staging.stg_service_npi__parts_drawing_links` | — |

## `vs_rpt_flat_view` (primary fact for this program)

- **Grain:** multiple rows per SR (labor lines, part lines, etc.) — the canonical harness query filters **`cr_labor_code = '780095014'`** to the wiring-harness–repair labor context.
- **Part columns (typical):** `pu_part_number`, `pu_part_description`, `pu_part_rpt_group`, `pu_part_quantity`, `pu_individual_part_cost`, `pu_total_part_cost`, (and serials as exposed in your environment).  
  **Confirm** with `DESCRIBE TABLE main.vehicle_services.vs_rpt_flat_view`.
- **If** `pu_part_number` is null on the 780095014 row but parts exist on **other** rows for the same SR, use a second pass: all `vs_rpt_flat_view` rows for those `sr_service_request_id` with `pu_part_number IS NOT NULL` (see commented block in `queries/02_enrichment/01_base_with_flat_view_parts.sql`).

## `vs_rpt_repair_rates_mv` (reliability gold)

- **Grain:** not per part line for claims — event/SR level with rolled-up costs and **`primary_failed_part`**, not every replaced part.
- **Use for:** `vehicle_system`, `vehicle_subsystem`, `days_to_failure`, `endpoint_*`, `sr_paytype` filters, population (`is_vin_pop`) when you compute rates — **join** to your harness cohort on **`vin` + `sr_service_request_number`** (or your org’s standard keys).  
- **Do not use** as the only source for “which harness and which connector PN were on this job” when multiple parts were used.

## Free text (Q2 / Q3 / Q4) → part numbers

Neither flat view nor repair rates encodes **circuit** or **connector name** as a stable ID. Flow:

1. **Profile** free text (`02_free_text_profile.sql`) → **alias / rules** in `mapping/`.
2. Map to **connector PN** (or service PN) via your engineering sources.
3. Join **`dim_fct_catia_ebom_parts`** (child = connector, parent = harness assembly) and **`dim_sbom_parts`** for LVE / R1T / R1S / Gen2 program filters.

## R1 Gen1 vs Gen2

- Filter vehicles with fields you already have: `v_vehicle_platform`, `v_veh_program`, `v_vehicle_model`, or `model_name` in SBOM — **align** with how your org labels Peregrine (Gen2) vs Gen1; confirm in `dim_sbom_parts` and flat view.

## When commercial SOS fact might still be requested (optional)

See `docs/OPTIONAL_SOS_ACCESS.md` — only for cross-checks or alignment with Carabiner/commercial, not for core PD harness analytics in this repo.
