# Optional: `fct_sos_detailed_service_rpt` access

**Default for this project:** you do **not** need `commercial.serviceos_legacy.fct_sos_detailed_service_rpt`. Per-line part numbers and costs for warranty analytics come from **`main.vehicle_services.vs_rpt_flat_view`** (`pu_part_*`).

Request narrow read access to the commercial fact **only** if you must:

- Reconcile line-level part history with **Carabiner** or commercial reporting, or
- Debug cases where **SR part lines** are edited and you need **raw SOS** line timestamps/serials not visible in the reliability flattening.

## Minimal column ask (example — confirm names in dbt / data catalog)

- Identifiers: `vin`, `sr_number` (or equivalent SR key), `sr_status`, `sr_created_at_utc`
- Context: `sr_concern`, `sr_laborcode`
- Part line: `sr_part_num`, `sr_part_desc`, `sr_part_serial_number`, `part_order_updated_at_utc`

## Short business justification (edit for your ticket)

*Field Quality / Reliability — LVE wiring harness warranty: primary analysis uses `vs_rpt_flat_view` and `vs_rpt_repair_rates_mv` (existing access). For a **subset** of SRs, we need read-only access to the **ServiceOS line-level** part fields in `fct_sos_detailed_service_rpt` to reconcile multi-line harness/connector jobs with commercial or Carabiner views and to validate part-line history when SRs are edited. Day-to-day KPIs remain in the reliability marts; this access is for **targeted reconciliation and debugging**, not to replace governed reporting.*
