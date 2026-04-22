# Table inventory (reference)

Confirm column names in Databricks with `DESCRIBE TABLE` / data catalog.

## Claims / ingress

| Table | Role |
|-------|------|
| `main.vehicle_services.vs_rpt_flat_view` | **Primary fact** for this program: multi-row per SR. Includes **`pu_part_number`**, `pu_part_quantity`, `pu_total_part_cost` (and related part-line fields) for consumed parts, plus labor lines, FPM, pay type, VIN, WO, SR. **Does not** embed circuit/connector as structured IDs; use QA + EBOM for that. |
| `main.vehicle_services.vs_event_schema_flattened` | QA pivot for `tt` (Q1–Q5). |
| `main.rel_field.vs_rpt_repair_rates_mv` | **Event/SR level** (not every part line): primary failed part, rolled-up part cost, `vehicle_system` / `vehicle_subsystem`, `days_to_failure`, exposure (`is_vin_pop`). Use with flat view for rate-style KPIs. |

## Commercial SOS (optional / not default)

| Table | Role |
|-------|------|
| `commercial.serviceos_legacy.fct_sos_detailed_service_rpt` | **Restricted**; raw line-level SOS. **Not required** for LVE harness scope if you use `pu_part_*` on `vs_rpt_flat_view`. See `docs/OPTIONAL_SOS_ACCESS.md` if you need read access for reconciliation. |

## EBOM / SBOM (connector / harness PNs)

| Table | Role |
|-------|------|
| `commercial.service_bom.dim_sbom_parts` | LVE, model/program, `cad_classification`, engineering systems. |
| `supply_chain.bom.dim_fct_catia_ebom_parts` | **Parent (harness) ↔ child (connector)** in Catia EBOM. |
| `main.adhoc.sbom_mapping` | Systems / responsibility. |
| `main.adhoc.sbom_report_supersession_audit_flags` | Current / superseded service PNs. |

## Service hierarchy (optional)

| Table | Role |
|-------|------|
| `datalake.VIEW_LATEST_SERVICEABLE_CHILD_PARTS` | Serviceable child mapping. |
| `datalake.SERVICEABLE_ASSEMBLY_SUBCOMPONENTS_CHILDREN_VIEW` | Service assembly → children. |

## Drawings (heat map / PDF)

| Table | Role |
|-------|------|
| `commercial.staging.stg_service_npi__parts_drawing_links` | `part_number`, `revision`, `drawing_link` (PDF URL). |

## Read next

- **`docs/PARTS_AND_MARTS.md`** — how flat view, repair rates, and EBOM fit the project goal.
- **`docs/OPTIONAL_SOS_ACCESS.md`** — when the SOS fact might be worth requesting.
