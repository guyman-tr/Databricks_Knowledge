# Dealing_dbo.Dealing_Unrealized_Open_CryptoRebate

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_Unrealized_Open_CryptoRebate |
| **Type** | Table |
| **ETL SP** | `Dealing_dbo.SP_M_CryptoRebateOpenUnrealized(@Date)` |
| **Refresh** | Monthly (Priority 0, SB_Daily — runs on last day of month) |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on `[MonthEndDate]` |
| **Rows** | ~63.5K |
| **Date Range** | 2022-08-31 → 2026-02-28 (active ✅) |
| **PII** | CID (client identifier) |

---

## 1. Business Meaning

Monthly rebate calculation for **Diamond club members** who hold open, unleveraged long crypto positions. For each eligible client at month-end, the table captures the mark-to-market value of their open crypto portfolio and applies a tiered rebate schedule based on total volume:

| Volume Bracket | Rate |
|----------------|------|
| $0 – $100K | No rebate |
| $100K – $1M | 0.15% |
| $1M – $5M | 0.25% |
| > $5M | 0.50% |

The rebate is zeroed if the total calculated amount is less than $5. The program started March 8, 2022 (hardcoded `OpenDateID >= 20220308`).

Migrated from Databricks to Synapse SQL (SR-242245, March 2024).

---

## 2. Grain

One row = one CID for one `MonthEndDate`. Covers Diamond-tier clients with open, unleveraged (Leverage=1), long (IsBuy=1), non-copy (MirrorID=0) crypto positions opened on or after 2022-03-08.

---

## 3. Key Columns & Elements

| Column | Type | Description |
|--------|------|-------------|
| `MonthEndDate` | date | Last day of the month (EOMONTH(@Date)) |
| `Club` | varchar | Always '1 Diamond' (PlayerLevelID=7) |
| `CID` | int | Client identifier |
| `IsCreditReportValidCB` | bit | Credit report validity flag from Fact_SnapshotCustomer |
| `IsGermanBaFin` | bit | 1 if client is under German BaFin regulation (from BI_DB_dbo.V_GermanBaFin) |
| `GuruStatus_ID` | int | PI/guru tier ID from Fact_SnapshotCustomer |
| `Country` | varchar | Client country name from Dim_Country |
| `Region` | varchar | Geographic region from Fact_SnapshotCustomer |
| `Regulation` | varchar | Regulatory jurisdiction name from Dim_Regulation |
| `OpenedVolume` | decimal(18,2) | SUM of open position values: AmountInUnitsDecimal × InitForexRate × InitForex_USDConversionRate |
| `ClosedVolume` | decimal(18,2) | Mark-to-market value at month-end using BidSpreaded × ConvertRateIsBuy_1 |
| `TotalVolume` | decimal(18,2) | OpenedVolume + ClosedVolume |
| `Markup` | decimal(18,2) | TotalVolume × 0.01 (1% reference markup) |
| `Bracket1_Volume` | decimal(18,2) | Volume within $100K–$1M bracket |
| `Bracket2_Volume` | decimal(18,2) | Volume within $1M–$5M bracket |
| `Bracket3_Volume` | decimal(18,2) | Volume above $5M |
| `Bracket1_Rebate` | decimal(18,2) | Bracket1_Volume × 0.0015 (0.15%) |
| `Bracket2_Rebate` | decimal(18,2) | Bracket2_Volume × 0.0025 (0.25%) |
| `Bracket3_Rebate` | decimal(18,2) | Bracket3_Volume × 0.005 (0.50%) |
| `TotalRebate` | decimal(18,2) | SUM(Bracket1+2+3) if ≥ $5, else 0 |
| `UPdatedate` | datetime | ETL metadata timestamp (**note: column name has capital P — typo in DDL**) |

---

## 4. Common Query Patterns

```sql
-- Monthly rebate totals
SELECT MonthEndDate, COUNT(*) AS EligibleClients,
       SUM(TotalVolume) AS TotalVolume, SUM(TotalRebate) AS TotalRebatePaid
FROM Dealing_dbo.Dealing_Unrealized_Open_CryptoRebate
WHERE TotalRebate > 0
GROUP BY MonthEndDate
ORDER BY MonthEndDate DESC;

-- Top rebate recipients for latest month
SELECT CID, Country, Regulation, TotalVolume, TotalRebate,
       Bracket1_Rebate, Bracket2_Rebate, Bracket3_Rebate
FROM Dealing_dbo.Dealing_Unrealized_Open_CryptoRebate
WHERE MonthEndDate = '2026-02-28'
  AND TotalRebate > 0
ORDER BY TotalRebate DESC;
```

> ⚠️ Column name typo: `UPdatedate` (capital P) — use exact spelling in SELECT or ORDER BY.

---

## 5. Known Issues & Quirks

- **Column name typo**: `UPdatedate` — capital P in middle of "update" — preserved from DDL
- **FCA excluded**: Regulation = 'FCA' clients are excluded from rebate eligibility
- **Country exclusions**: Austria, France, Finland, Greece, Luxembourg, Malta, Portugal, Sweden, United Kingdom excluded
- **IsGermanBaFin flag**: German BaFin clients are included (not excluded) but flagged separately for downstream analysis
- **$5 minimum**: TotalRebate set to 0 if < $5 — avoids micro-payments
- **Rebate start date hardcoded**: `OpenDateID >= 20220308` — positions opened before March 8, 2022 are never eligible
- **Monthly only**: SP checks internally to run only on the last day of the month (EOMONTH logic)

---

## 6. Lineage Summary

Sources: DWH_dbo.Fact_SnapshotCustomer (Diamond eligibility) + BI_DB_dbo.BI_DB_PositionPnL (crypto open positions) + DWH_dbo.Fact_CurrencyPriceWithSplit (month-end prices) + DWH_dbo.Dim_Regulation + Dim_Country + BI_DB_dbo.V_GermanBaFin. See `.lineage.md` for full column-level map.

---

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| `DWH_dbo.Fact_SnapshotCustomer` | Diamond club membership validation |
| `BI_DB_dbo.BI_DB_PositionPnL` | Open crypto position source |
| `DWH_dbo.Fact_CurrencyPriceWithSplit` | Month-end mark-to-market prices |
| `DWH_dbo.Dim_Regulation` | Regulation name + FCA exclusion |

---

*Quality score: 8.0/10 — active monthly ETL, clear tiered logic, well-governed*
