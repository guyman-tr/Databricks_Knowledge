---
object: Dealing_dbo.Dealing_OccurredAtProvider_Latency_Instrument
review_status: pending
documented: 2026-03-21
---

# Review Needed: Dealing_OccurredAtProvider_Latency_Instrument

## Auto-Generated Flags

- [ ] **STALE since 2025-01-11**: Confirm if `CopyFromLake.PriceLog_History_CurrencyPrice` feed has been permanently decommissioned or is pending restoration.
- [ ] **`Date` is datetime**: The column stores a datetime, not a date — confirm whether the time component is meaningful (e.g., first event time) or an artifact of the source table.
- [ ] **Negative latency handling**: `DATEDIFF(ss, OccurredOnProvider, ReceivedOnPriceServer)` can be negative (LP clock skew / out-of-order). Confirm if negative values are included in AVGLatency and MaxLatency or filtered to positive only.
- [ ] **`CountInstances > 1` threshold**: Confirm why single-instance events are excluded — is this a noise filter or an SLA definition?

## Reviewer Corrections

<!-- Add corrections here. -->
