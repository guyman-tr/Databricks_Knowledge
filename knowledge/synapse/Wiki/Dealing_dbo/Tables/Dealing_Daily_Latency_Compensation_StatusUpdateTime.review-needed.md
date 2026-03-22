---
object: Dealing_dbo.Dealing_Daily_Latency_Compensation_StatusUpdateTime
review_status: pending
documented: 2026-03-21
---

# Review Needed: Dealing_Daily_Latency_Compensation_StatusUpdateTime

## Auto-Generated Flags

- [ ] **3-month window only**: Confirm if Jul–Oct 2024 was an intentional pilot for the compensation workflow.
- [ ] **`SlippageInDollar` formula**: Inferred as (Kusto_Rate − Price_Requested) × AmountInUnitsDecimal × ConversionRate — confirm sign convention and exact formula from SP code.
- [ ] **`Kusto_Rate` source**: Documented as Kusto/CopyFromLake reference. Confirm exact source table and join key used in SP_Latency_Report_StatusUpdateTime.
- [ ] **`HedgingType` varchar(5)**: Narrower than varchar(10) in other latency tables — confirm no truncation risk for values beyond `HBC`/`CBH`.
- [ ] **Compensation threshold**: What `ClientToExecutionLatency` threshold determines inclusion in this table vs. `Dealing_Daily_Latency_ClientOrder_WithDelay_StatusUpdateTime` (5.1M rows vs 4.6M here)?

## Reviewer Corrections

<!-- Add corrections here. -->
