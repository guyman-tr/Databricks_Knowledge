# Dealing_dbo.V_RequestViewForBestExecution

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | V_RequestViewForBestExecution |
| **Type** | View |
| **Sources** | `Dealing_staging.eToroLogs_Real_Hedge_RequestExecutionLog`, `Dealing_staging.eToroLogs_Real_Hedge_RequestLimitExecutionLog`, `Dealing_staging.eToroLogs_Real_Hedge_EMSOrders`, `CopyFromLake.PriceLog_History_CurrencyPrice` |
| **Columns** | 8 |
| **PII** | NO |
| **Tags** | dealing, best-execution, regulatory, mifid, latency, slippage, hedge, execution |

---

## 1. Business Meaning

`V_RequestViewForBestExecution` is a **regulatory reporting view** that provides execution quality metrics for MiFID II Best Execution compliance. It merges two execution flows:

1. **Hedge Server (legacy) requests**: From `eToroLogs_Real_Hedge_RequestExecutionLog` joined with limit execution details — filtered to the last 24 hours (`RequestTime >= DATEADD(DAY,-1,GETDATE())`)
2. **EMS (Execution Management System) orders**: From `eToroLogs_Real_Hedge_EMSOrders` joined with `PriceLog_History_CurrencyPrice` to get the trigger price metadata — excludes `HedgeExecutionModeID = 3`

The UNION of these two sources creates a unified view of all hedge execution requests with their timing metrics, enabling Best Execution analysis of latency (time between request and market trigger) and slippage (difference between client view rate and trigger rate).

---

## 2. Business Logic

### Hedge Server Path (Top UNION)

```sql
SELECT REL.RequestID, RequestTime, ClientViewRate, IsManual,
       TriggerRate, TriggerPriceRateID, MarketTriggerRateTime, MainTriggerRateTime
FROM Dealing_staging.eToroLogs_Real_Hedge_RequestExecutionLog REL
LEFT JOIN Dealing_staging.eToroLogs_Real_Hedge_RequestLimitExecutionLog RLEL
  ON REL.RequestID = RLEL.RequestID
  AND REL.RequestTime >= DATEADD(DAY,-1,GETDATE())
```

### EMS Path (Bottom UNION)

```sql
SELECT ExecutionID AS RequestID, RequestTime, ClientViewRate,
       CASE WHEN FlowType = 1 THEN 0 ELSE 1 END AS IsManual,
       TriggerRate, TriggerPriceRateID,
       ReceivedOnPriceServer AS MarketTriggerRateTime,
       Occurred AS MainTriggerRateTime
FROM Dealing_staging.eToroLogs_Real_Hedge_EMSOrders EO
JOIN CopyFromLake.PriceLog_History_CurrencyPrice HCP
  ON EO.TriggerPriceRateID = HCP.PriceRateID
WHERE HedgeExecutionModeID != 3
```

### Key Transformations

- **IsManual**: EMS path maps `FlowType = 1` → `0` (automated), else `1` (manual). Hedge Server path reads `IsManual` directly.
- **MarketTriggerRateTime**: EMS path maps `ReceivedOnPriceServer` to this field.
- **MainTriggerRateTime**: EMS path maps `Occurred` to this field.
- **HedgeExecutionModeID != 3**: Excludes a specific execution mode (likely internal/test).

---

## 3. Relationships

| Related Table | Join Key | Relationship |
|---------------|----------|--------------|
| `Dealing_staging.eToroLogs_Real_Hedge_RequestExecutionLog` | — | Hedge server execution requests |
| `Dealing_staging.eToroLogs_Real_Hedge_RequestLimitExecutionLog` | `RequestID` | Limit order execution details |
| `Dealing_staging.eToroLogs_Real_Hedge_EMSOrders` | — | EMS order execution records |
| `CopyFromLake.PriceLog_History_CurrencyPrice` | `TriggerPriceRateID = PriceRateID` | Price snapshot at trigger time |

---

## 4. Elements

| # | Element | Type | Description |
|---|---------|------|-------------|
| 1 | RequestID | int/bigint | Unified execution request identifier. From Hedge Server path: `REL.RequestID`. From EMS path: `ExecutionID` aliased as RequestID. (Tier 2 — DDL) |
| 2 | RequestTime | datetime | When the execution request was initiated by the trading system. Used to compute latency metrics. (Tier 2 — DDL) |
| 3 | ClientViewRate | decimal | The rate displayed to the client at the time they triggered the trade. Compared to `TriggerRate` to measure slippage. (Tier 2 — DDL) |
| 4 | IsManual | bit/int | Whether the execution was manual (1) or automated (0). EMS path: `FlowType = 1 → 0`, else `1`. (Tier 2 — DDL) |
| 5 | TriggerRate | decimal | The actual rate at which the hedge execution was triggered. `ClientViewRate - TriggerRate` = slippage. (Tier 2 — DDL) |
| 6 | TriggerPriceRateID | int/bigint | FK to price log — identifies the specific price snapshot used to trigger the execution. Joined to `PriceLog_History_CurrencyPrice.PriceRateID`. (Tier 2 — DDL) |
| 7 | MarketTriggerRateTime | datetime | Timestamp when the trigger price was received on the price server. Hedge Server: `MarketTriggerRateTime`. EMS: `ReceivedOnPriceServer`. Key for latency = `MarketTriggerRateTime - RequestTime`. (Tier 2 — DDL) |
| 8 | MainTriggerRateTime | datetime | Timestamp of the main trigger event. Hedge Server: `MainTriggerRateTime`. EMS: `Occurred`. (Tier 2 — DDL) |

---

## 5. Usage Notes

**Best Execution metrics**: This view enables two key regulatory measurements:
- **Latency**: `MarketTriggerRateTime - RequestTime` — how long between the client's trade request and the market price that triggered the hedge
- **Slippage**: `ClientViewRate - TriggerRate` — the price difference between what the client saw and the actual execution trigger

**Rolling 24-hour window**: The Hedge Server path filters `RequestTime >= DATEADD(DAY,-1,GETDATE())`. The EMS path has NO time filter — it returns all records where `HedgeExecutionModeID != 3`.

**UNION (not UNION ALL)**: The use of `UNION` deduplicates between the two paths. If a request appears in both the Hedge Server log and the EMS log, only one row is returned.

**Confluence reference**: "Best Execution-Summarize Tables-Daily Procedure" documents the operational monitoring process for latency and slippage alerts.

---

## 6. Governance

| Property | Value |
|----------|-------|
| **Regulatory** | MiFID II Best Execution |
| **Sources** | Dealing_staging (Hedge Server logs, EMS orders), CopyFromLake (price history) |
| **PII** | NO |
| **Owner** | Dealing / Compliance |

---

## 7. Quality Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Structure | 5/5 | Full DDL analyzed |
| Logic | 5/5 | UNION semantics, CASE mapping, JOIN logic documented |
| Business Context | 4/5 | Confluence "Best Execution" page found; MiFID context clear |
| Upstream Wiki | 2/5 | Source tables are in Dealing_staging (no wiki) |
| **Total** | **7.5/10** | Multi-source UNION view with regulatory significance |

---

*Generated: 2026-03-21 | Batch 20 | Schema: Dealing_dbo*
