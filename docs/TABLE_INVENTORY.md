# Table inventory (reference)

Tables discussed for this program. Confirm columns in Databricks before production joins.

## Claims / ingress

| Table | Role |
|-------|------|
| `main.vehicle_services.vs_rpt_flat_view` | SR/WO detail; multi-row per SR — watch double-counts on sums. |
| `main.vehicle_services.vs_event_schema_flattened` | QA schema for `tt` pivot. |
| `main.rel_field.vs_rpt_repair_rates_mv` | SR/VIN-level repair metrics; 3MIS / repair-rate dashboards. |

## EBOM / SBOM

| Table | Role |
|-------|------|
| `commercial.service_bom.dim_sbom_parts` | Harness assemblies, connectors, LVE filter, `model_name`, etc. |
| `supply_chain.bom.dim_fct_catia_ebom_parts` | Parent harness → child connector (Catia EBOM). |
| `main.adhoc.sbom_mapping` | Parts ↔ engineering systems / responsibility. |
| `main.adhoc.sbom_report_supersession_audit_flags` | Current PN / supersession. |

## Service hierarchy

| Table | Role |
|-------|------|
| `datalake.VIEW_LATEST_SERVICEABLE_CHILD_PARTS` | Serviceable child mapping. |
| `datalake.SERVICEABLE_ASSEMBLY_SUBCOMPONENTS_CHILDREN_VIEW` | Assembly → children (JSON/exploded). |

## Parts on SR

| Table | Role |
|-------|------|
| `commercial.serviceos_legacy.fct_sos_detailed_service_rpt` | Parts consumed per VIN/WO/SR. |

## Drawings (heat map / PDF)

| Table | Role |
|-------|------|
| `commercial.staging.stg_service_npi__parts_drawing_links` | `part_number`, `revision`, `drawing_link` (PDF URL). |
