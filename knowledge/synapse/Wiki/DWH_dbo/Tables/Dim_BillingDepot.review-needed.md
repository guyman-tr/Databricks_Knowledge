# Review Sidecar — DWH_dbo.Dim_BillingDepot

## Unverified Columns (Tier 4)

_None — all columns inherited from upstream Billing.Depot wiki (Tier 1) or ETL-generated (Tier 2)._

## Open Questions

### Structural
1. **DWH consumer coverage** — Which fact tables in DWH_dbo actually JOIN to Dim_BillingDepot on DepotID? Need to verify consumer list beyond assumed deposit/cashout facts.
2. **Column pruning rationale** — PayoutGeneration and Features were dropped from the DWH copy. Confirm these are truly unused in analytics (no downstream report needs them).

### Clarification
3. **IsActive NULLability** — The DDL allows NULL for IsActive, but the upstream source defaults to 0. Are there actual NULL rows in the DWH copy, and should they be treated as Inactive?

---

*Generated: 2026-03-18*
