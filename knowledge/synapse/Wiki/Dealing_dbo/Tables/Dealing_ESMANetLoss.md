---
object: Dealing_ESMANetLoss
schema: Dealing_dbo
type: Table
description: Position-level ESMA net-loss detail for closed positions where the client lost ≥95% of invested amount. Captures actual vs hypothetical (no-stop-protection) P&L to quantify the DeltaLoss protection benefit. Used for ESMA regulatory reporting by regulation and MiFID category.
etl_sp: Dealing_dbo.SP_ESMANetLoss
frequency: Daily
status: Active (last: 2026-03-10)
row_count: 118,590
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.0
---

# Dealing_ESMANetLoss

Position-level regulatory reporting table for ESMA stop-loss protection. Captures every closed position where the client lost ≥95% of their invested amount and the position closed naturally (not by stop-out). For each such position, it records the **actual P&L** (with eToro's stop-loss protection) and the **hypothetical P&L** without protection (`NoRestrictionNetProfit`), with the difference (`DeltaLoss`) quantifying how much the stop-loss mechanism protected the client.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Position source | `DWH_dbo.Dim_Position` | Closed positions: NetProfit<0 AND ABS(NetProfit)/Amount≥0.95 AND ClosePositionReasonID=1 AND EndForexPriceRateID=0 AND IsComputeForHedge=1 |
| Instrument dim | `DWH_dbo.Dim_Instrument` | InstrumentType, InstrumentName |
| Regulation dim | `DWH_dbo.Dim_Regulation` | Regulatory jurisdiction lookup (CySEC, FCA, ASIC, etc.) |
| MiFID dim | `DWH_dbo.Dim_MifidCategorization` | Retail / Professional categorization |
| Price source | `CopyFromLake.PriceLog_History_CurrencyPrice` | NoProtectionRate — market price at close time without stop-out |
| Writer | `Dealing_dbo.SP_ESMANetLoss` | Daily, OpsDB Priority 0 |

## 1. Business Purpose

- ESMA regulations require brokers to track and report extreme client losses (≥95% of invested amount)
- `DeltaLoss = NoRestrictionNetProfit − NetProfit` quantifies how much stop-loss protection saved the client
- Segmented by Regulation (CySEC, FCA, ASIC) and MiFID (Retail/Professional) for EU regulatory submissions
- Only positions where `ClosePositionReasonID=1` (natural close) — not triggered by stop-out

## 2. Key Concepts

| Concept | Explanation |
|---------|-------------|
| ≥95% loss filter | ABS(NetProfit)/Amount ≥ 0.95 — position lost nearly all invested capital |
| NoRestrictionNetProfit | Hypothetical P&L if stop-loss protection had not intervened |
| DeltaLoss | `NoRestrictionNetProfit − NetProfit` — the additional loss the client was protected from |
| NoProtectionRate | Actual market price at close time from PriceLog, ignoring stop rate |
| IsComputeForHedge=1 | Only hedged positions included |
| EndForexPriceRateID=0 | No forex rate adjustment at close — pure price-loss positions |

## 3. Grain

One row per **PositionID on its CloseOccurred date**. Only extreme-loss positions are included (118K total across ~4 years).

## 4. Elements

| Column | Type | Description | Tier | Notes |
|--------|------|-------------|------|-------|
| Date | date | Position close date | Tier 2 | Clustered index key |
| Regulation | varchar(50) | Regulatory jurisdiction (CySEC, FCA, ASIC, etc.) | Tier 1 | From Dim_Regulation per CID |
| MifID | varchar(50) | MiFID categorization (Retail / Professional) | Tier 2 | From Dim_MifidCategorization |
| PositionID | bigint | Position identifier | Tier 1 | FK to DWH_dbo.Dim_Position |
| InstrumentType | varchar(50) | Instrument asset class | Tier 2 | From Dim_Instrument |
| InstrumentID | int | Instrument identifier | Tier 1 | FK to DWH_dbo.Dim_Instrument |
| InstrumentName | varchar(50) | Instrument display name | Tier 2 | From Dim_Instrument |
| IsBuy | int | Position direction: 1=long, 0=short | Tier 2 | From Dim_Position |
| AmountInUnitsDecimal | decimal(16,8) | Position size in instrument units | Tier 2 | From Dim_Position |
| CloseOccurred | datetime | Position close timestamp | Tier 2 | From Dim_Position |
| Amount | money | Invested amount (USD) at open | Tier 2 | From Dim_Position |
| NetProfit | money | Actual realized P&L with stop-loss protection (always negative here) | Tier 1 | From Dim_Position |
| NoRestrictionNetProfit | money | Hypothetical P&L without stop-loss protection | Tier 1 | Computed: NoProtectionRate × units × conversion |
| InitForexRate | numeric(16,8) | Opening price of the position | Tier 2 | From Dim_Position |
| EndForexRate | numeric(16,8) | Closing price with protection applied | Tier 2 | From Dim_Position |
| StopRate | numeric(16,8) | Stop-loss rate that was active | Tier 2 | From Dim_Position |
| NoProtectionRate | numeric(16,8) | Market price at close time ignoring stop — what price would have been | Tier 2 | From PriceLog_History_CurrencyPrice |
| LastOpConversionRate | numeric(16,8) | USD conversion rate at position close | Tier 2 | From Dim_Position |
| DeltaLoss | money | Additional loss prevented by stop-loss: NoRestrictionNetProfit − NetProfit (positive = client protected) | Tier 1 | SP-computed |
| UpdateDate | datetime | ETL metadata: row write timestamp | Tier 1 | ETL metadata (blacklist canonical) |

## 5. Common Query Patterns

```sql
-- Total DeltaLoss protection by regulation and month
SELECT CONVERT(varchar(7), Date, 126) AS Month,
       Regulation, MifID,
       COUNT(*) AS PositionCount,
       SUM(DeltaLoss) AS TotalProtection,
       SUM(NetProfit) AS TotalActualLoss
FROM Dealing_dbo.Dealing_ESMANetLoss
GROUP BY CONVERT(varchar(7), Date, 126), Regulation, MifID
ORDER BY Month DESC;

-- Positions with largest DeltaLoss for today
SELECT TOP 20 PositionID, InstrumentName, Regulation, MifID,
       NetProfit, NoRestrictionNetProfit, DeltaLoss
FROM Dealing_dbo.Dealing_ESMANetLoss
WHERE Date = CAST(GETDATE() AS DATE)
ORDER BY DeltaLoss DESC;
```

> **Performance note**: 118.6K rows — small table. ROUND_ROBIN/CI. Date predicates for targeted queries; full scans are fast at this size.

## 6. Data Quality & Caveats

- Only positions losing ≥95% of invested amount are captured — partial losses not here
- `ClosePositionReasonID=1` means only natural closes qualify; stop-triggered extreme losses are excluded
- NoProtectionRate from PriceLog may be null/stale for illiquid instruments
- 118.6K rows across 4 years — very sparse; spikes may correlate with market dislocations

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| `DWH_dbo.Dim_Position` | Primary source for all position data |
| `DWH_dbo.Dim_Regulation` | Regulatory jurisdiction lookup |
| `DWH_dbo.Dim_MifidCategorization` | MiFID categorization |

## 8. Operational Notes

- **ETL**: `SP_ESMANetLoss` runs daily (OpsDB Priority 0). DELETE + INSERT for current date
- **Author**: Jenia Simonovitch
- **Table design**: ROUND_ROBIN/CI appropriate for small regulatory reporting table

---
*Quality score: 8.0/10 — Clear ESMA regulatory purpose. Filter criteria well-documented. DeltaLoss formula clearly traced. NoProtectionRate source should be confirmed for sparse instruments.*
