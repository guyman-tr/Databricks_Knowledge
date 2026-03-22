# Lineage — Dealing_dbo.V_RequestViewForBestExecution

## Source Mapping

| Layer | Object | Method |
|-------|--------|--------|
| **Dealing_staging** | `eToroLogs_Real_Hedge_RequestExecutionLog` | Hedge server execution requests |
| **Dealing_staging** | `eToroLogs_Real_Hedge_RequestLimitExecutionLog` | LEFT JOIN on RequestID for limit order details |
| **Dealing_staging** | `eToroLogs_Real_Hedge_EMSOrders` | EMS order executions |
| **CopyFromLake** | `PriceLog_History_CurrencyPrice` | JOIN on TriggerPriceRateID = PriceRateID |

## Column Lineage

| Column | Source (Hedge Path) | Source (EMS Path) | Confidence |
|--------|-------------------|------------------|------------|
| RequestID | REL.RequestID | EO.ExecutionID (aliased) | Tier 2 |
| RequestTime | REL.RequestTime | EO.RequestTime | Tier 2 |
| ClientViewRate | REL.ClientViewRate | EO.ClientViewRate | Tier 2 |
| IsManual | REL.IsManual (direct) | CASE WHEN FlowType=1 THEN 0 ELSE 1 END | Tier 2 |
| TriggerRate | RLEL.TriggerRate | EO.TriggerRate | Tier 2 |
| TriggerPriceRateID | RLEL.TriggerPriceRateID | EO.TriggerPriceRateID | Tier 2 |
| MarketTriggerRateTime | RLEL.MarketTriggerRateTime | HCP.ReceivedOnPriceServer | Tier 2 |
| MainTriggerRateTime | RLEL.MainTriggerRateTime | EO.Occurred | Tier 2 |

---

*Generated: 2026-03-21 | Batch 20*
