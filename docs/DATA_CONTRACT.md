# Data contract — canonical ingress

## Purpose

All harness warranty marts and notebooks **build on this contract** unless versioned with stakeholders/DE.

## Sources

- **`main.vehicle_services.vs_event_schema_flattened`** — QA pivot (`tt` CTE).
- **`main.vehicle_services.vs_rpt_flat_view`** — SR/WO line grain; join to `tt`.

## `tt` CTE rules

- Filter: `tier1 = 'Wiring Harness Repair' OR tier3 = 'Wiring Harness Repair'`.
- Group by: `service_request_id`, `tier3`.
- Fields:
  - Q1 → `repair_type`
  - Q2 → `connector_number` (**free text — primary mapping target**)
  - Q3 → `circuit` (**free text — primary mapping target**)
  - Q4 → `reapair_location` (column name matches source typo; **primary mapping target**)
  - Q5 → `image_before_repair`, `image_after_repair` (has_image_keys)

## Outer query filters

- `is_field_performance_metric_included = 1`
- `cr_labor_code = '780095014'`
- `sr_completed_date >= '<start_date>'` (parameterize; **repo default `2026-01-01`** for the current pilot. If the cohort is empty, widen the date in dev only—see diagnostics in `04_mart_ctas_warranty_ebom.sql` comments.)

## Pilot scope (R1) — optional

**Default in repo:** no program/model filter (broadest claims set that passes labor/FPM/date filters).

**To limit to R1S/R1T**, uncomment **one** line in `01_canonical_ingress.sql` (validated on model):

```sql
AND v_vehicle_model LIKE 'R1%'
```

**Alternative** if your dashboard uses program instead of model:

```sql
AND v_veh_program LIKE 'R1%'
```

## Column qualification (Databricks / Spark)

Aligned with the **current claims / dashboard** query: columns are mostly **unqualified**; use `s.` only where required (e.g. `sr_completed_date` in `WHERE`). **`tier3`** is kept as plain `tier3` to match the source (tier dropdown / sub-menus).

## Grain warning

`vs_rpt_flat_view` is **multi-row per SR** (labor lines, parts, etc.). This dashboard query uses `SELECT DISTINCT` on the join result — understand grain before **summing** costs or times; use aggregated cost fields or `vs_rpt_repair_rates_mv` for SR-level repair-rate KPIs.

## Mapping focus

Wrap **EBOM/SBOM/parts/drawing links** around **Q2, Q3, Q4** free text; use Q1 and images for classification and reporting.

## Part numbers on the SR (no commercial SOS table required)

Per-line part consumption and costs: use **`pu_part_*` fields on** `main.vehicle_services.vs_rpt_flat_view` (see `docs/PARTS_AND_MARTS.md`). The enrichment query `queries/02_enrichment/01_base_with_flat_view_parts.sql` adds them to the harness-labor filter set.

## Event-level repair metrics

Use **`main.rel_field.vs_rpt_repair_rates_mv`** (claim rows) joined on your standard VIN + SR keys when you need `vehicle_system`, `endpoint_*`, `days_to_failure`, etc. — not as a full substitute for per-part line detail; see `docs/PARTS_AND_MARTS.md`.
