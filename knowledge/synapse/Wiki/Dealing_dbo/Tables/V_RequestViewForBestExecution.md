# Dealing_dbo.V_RequestViewForBestExecution

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | V_RequestViewForBestExecution |
| **Type** | View |
| **Sources** | `Dealing_staging.eToroLogs_Real_Hedge_RequestExecutionLog` + `eToroLogs_Real_Hedge_EMSOrders` |
| **Filter** | Leg 1: last 24h; Leg 2: HedgeExecutionModeID ≠ 3 |
| **Distribution** | N/A (view) |
| **PII** | None |

---

## 1. Business Meaning

Near-real-time view combining **two hedge execution sources** for Best Execution compliance and monitoring:

- **Leg 1 (RequestExecutionLog)**: Manual and automated hedge requests processed through the traditional request pipeline — last 24 hours only
- **Leg 2 (EMSOrders)**: EMS (Execution Management System) hedge orders, enriched with price rate data from CopyFromLake, excluding fully-automated executions (HedgeExecutionModeID=3)

The union provides a consolidated view of recent real-stock hedge executions with consistent columns for: request timing, client-facing rates, trigger rates/times, and whether execution was manual or automated. Used for **Best Execution** regulatory reporting — demonstrating that client orders were executed at or better than quoted rates.

---

## 2. View Definition

```sql
SELECT REL.RequestID, RequestTime, ClientViewRate, IsManual, TriggerRate,
       TriggerPriceRateID, MarketTriggerRateTime, MainTriggerRateTime
FROM [Dealing_staging].[eToroLogs_Real_Hedge_RequestExecutionLog] REL
     LEFT JOIN [Dealing_staging].[eToroLogs_Real_Hedge_RequestLimitExecutionLog] RLEL
        ON REL.RequestID = RLEL.RequestID
           AND REL.RequestTime >= DATEADD(DAY,-1,GETDATE())
UNION
SELECT ExecutionID AS [RequestID], RequestTime, ClientViewRate,
       CASE WHEN FlowType = 1 THEN 0 ELSE 1 END AS [IsManual],
       TriggerRate, TriggerPriceRateID,
       ReceivedOnPriceServer AS MarketTriggerRateTime,
       Occurred AS MainTriggerRateTime
FROM [Dealing_staging].[eToroLogs_Real_Hedge_EMSOrders] EO
     JOIN CopyFromLake.PriceLog_History_CurrencyPrice HCP
        ON EO.TriggerPriceRateID = HCP.PriceRateID
WHERE HedgeExecutionModeID != 3;
```

---

## 3. Key Columns

| Column | Type | Description |
|--------|------|-------------|
| `RequestID` | bigint | Execution request identifier (ExecutionID aliased for EMS leg) |
| `RequestTime` | datetime | When the execution request was received |
| `ClientViewRate` | float | Price the client saw when placing the order |
| `IsManual` | bit | 1=Manual execution, 0=Automated (FlowType=1 → 0 for EMS) |
| `TriggerRate` | float | Price at which the order was triggered/executed |
| `TriggerPriceRateID` | bigint | FK to price rate record used for trigger |
| `MarketTriggerRateTime` | datetime | When the market price reached the trigger (ReceivedOnPriceServer for EMS) |
| `MainTriggerRateTime` | datetime | When the execution engine processed the trigger (Occurred for EMS) |

---

## 4. Common Query Patterns

```sql
-- Best execution: compare client view rate vs trigger rate
SELECT RequestID, RequestTime, ClientViewRate, TriggerRate, IsManual,
       TriggerRate - ClientViewRate AS Slippage
FROM Dealing_dbo.V_RequestViewForBestExecution
ORDER BY RequestTime DESC;

-- Recent manual executions
SELECT * FROM Dealing_dbo.V_RequestViewForBestExecution
WHERE IsManual = 1
ORDER BY RequestTime DESC;
```

> ⚠️ **Leg 1 is 24h only**: RequestExecutionLog data older than 24 hours is excluded from this view. For historical analysis, query the staging tables directly.

---

## 5. Known Issues & Quirks

- **Leg 1 time limit**: Only last 24 hours from RequestExecutionLog — this view is **not suitable for historical reporting**
- **Leg 2 HedgeExecutionModeID=3**: Fully-automated EMS executions are excluded (mode 3 = algorithm-driven, no human involvement)
- **FlowType mapping (EMS)**: FlowType=1 → IsManual=0 (automated flow); all other FlowType values → IsManual=1
- **UNION (not UNION ALL)**: Deduplication applied — if a request appears in both legs, it appears once
- **Near-real-time**: Sources are staging tables updated continuously; not end-of-day snapshots

---

## 6. Lineage Summary

UNION of `Dealing_staging.eToroLogs_Real_Hedge_RequestExecutionLog` (last 24h) and `eToroLogs_Real_Hedge_EMSOrders` (joined to `CopyFromLake.PriceLog_History_CurrencyPrice`). See `.lineage.md` for full column-level map.

---

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| `Dealing_staging.eToroLogs_Real_Hedge_RequestExecutionLog` | Source — traditional execution log (Leg 1) |
| `Dealing_staging.eToroLogs_Real_Hedge_EMSOrders` | Source — EMS execution orders (Leg 2) |
| `CopyFromLake.PriceLog_History_CurrencyPrice` | Source — price rate enrichment for EMS leg |

---

*Quality score: 7.0/10 — near-real-time best execution view, clearly structured UNION; 24h limit on Leg 1 requires awareness*
