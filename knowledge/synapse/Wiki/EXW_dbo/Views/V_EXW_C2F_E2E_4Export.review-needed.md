---
object: EXW_dbo.V_EXW_C2F_E2E_4Export
review_date: 2026-04-20
batch: 12
priority: LOW — passthrough view, base table fully documented
---

# Review Notes — V_EXW_C2F_E2E_4Export

## Key Observations

1. **Export-only view — no analytical logic**: The entire purpose of this view is to cast two uniqueidentifier columns to varchar(50). Documentation is entirely inherited from EXW_C2F_E2E. No independent documentation value beyond recording the type cast rationale.

2. **varchar(50) for GUID columns**: A GUID string representation is exactly 36 characters (`XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`), well within varchar(50). No truncation risk.

3. **No filter, no exclusions**: This is a complete pass-through. Any schema change in EXW_C2F_E2E will require a matching update to this view.

## Open Questions

4. **Who consumes this view?**: The `_4Export` suffix suggests a specific downstream process — Power BI, an ADF export pipeline, or a reporting data mart. The consumer is not documented in the SSDT repo. Identifying the consumer would clarify whether the view is actively needed and whether UC migration will require recreating it.

5. **No UC target**: If/when EXW_C2F_E2E is migrated to Unity Catalog, the uniqueidentifier type becomes STRING natively in Databricks SQL (no cast needed). Confirm whether this view should be recreated in UC or if the base UC table is sufficient.
