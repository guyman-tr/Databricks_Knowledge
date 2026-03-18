# Review Sidecar — DWH_dbo.Dim_BillingProtocolMIDSettingsID

## Unverified Columns (Tier 4)

_None — all columns inherited from upstream Billing.ProtocolMIDSettings wiki (Tier 1) or ETL-generated (Tier 2)._

## Open Questions

### Structural
1. **DWH consumer coverage** — Which DWH fact tables JOIN to this dimension on ProtocolMIDSettingsID? Confirm usage in deposit/withdrawal analytics.
2. **Row count growth** — Production wiki documented ~1,470 rows; DWH now has ~1,851. Growth is expected but worth noting for freshness.

### Clarification
3. **Value sensitivity** — The `Value` column contains MID/API key strings. Confirm whether these are considered sensitive in the DWH context (they are configuration identifiers, not secrets, but worth verifying).

---

*Generated: 2026-03-18*
