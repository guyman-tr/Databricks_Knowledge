# Dealing_dbo.Dealing_Supposed_LPFees

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_Supposed_LPFees |
| **Type** | Table |
| **ETL SP** | None found — no active writer SP in SSDT repository |
| **Refresh** | ⚠️ STALE — last data 2023-09-11 (~30 months stale) |
| **Distribution** | REPLICATE |
| **Index** | CLUSTERED on `[Date]` |
| **Rows** | ~603K |
| **Date Range** | 2021-09-01 → 2023-09-11 (stale ⚠️) |
| **PII** | None |

---

## 1. Business Meaning

Theoretical LP (Liquidity Provider) fee estimates for Real Stocks and ETFs by instrument and date. The "supposed" in the name indicates these are **calculated/expected fees** rather than actual invoiced fees — used for reconciliation or validation against real LP invoices.

Each row represents an instrument × LP × date combination with the theoretical fee in both local currency and USD, alongside the position size and total commission. The table covers the period from September 2021 through September 2023, when the ETL pipeline appears to have been discontinued.

The REPLICATE distribution suggests the table was originally designed as a small reference/lookup table, but at 603K rows it is larger than typical REPLICATE use cases.

---

## 2. Grain

One row = one InstrumentID × one LP (LiquidityAccountID / HS) × one Date.

---

## 3. Key Columns & Elements

| Column | Type | Description |
|--------|------|-------------|
| `Date` | date | Report date |
| `DateID` | int | Date as integer key (YYYYMMDD) |
| `InstrumentID` | int | Instrument identifier |
| `InstrumentDisplayName` | nvarchar | Instrument display name |
| `ISINCode` | varchar | International Securities Identification Number |
| `Currency` | varchar | Instrument base currency |
| `Units` | decimal | Position size in units |
| `LocalAmount` | money | Position value in local currency |
| `Fee` | money | Calculated LP fee in local currency |
| `LP` | varchar | Liquidity provider name (e.g., 'IB', 'GS', 'JP') |
| `HS` | int | HedgeServerID — which LP server processed the hedge |
| `FeeUSD` | money | Fee converted to USD |
| `TotalCommission` | money | Total commission charged on these positions |
| `UpdateDate` | datetime | ETL metadata timestamp |

---

## 4. Common Query Patterns

```sql
-- Fee breakdown by LP (historical only — data ends Sep 2023)
SELECT LP, SUM(FeeUSD) AS TotalFeeUSD, SUM(Units) AS TotalUnits,
       COUNT(DISTINCT InstrumentID) AS Instruments
FROM Dealing_dbo.Dealing_Supposed_LPFees
WHERE Date >= '2023-01-01'
GROUP BY LP
ORDER BY TotalFeeUSD DESC;

-- Fee vs commission comparison per instrument
SELECT InstrumentDisplayName, Currency, SUM(FeeUSD) AS TotalFeeUSD,
       SUM(TotalCommission) AS TotalCommission
FROM Dealing_dbo.Dealing_Supposed_LPFees
GROUP BY InstrumentDisplayName, Currency
ORDER BY TotalFeeUSD DESC;
```

> ⚠️ **Stale ~30 months** — data ends 2023-09-11. Not suitable for current operational use; useful only for historical analysis up to September 2023.

---

## 5. Known Issues & Quirks

- **No writer SP in SSDT**: ETL pipeline no longer exists — table cannot be refreshed
- **REPLICATE distribution**: Chosen for fast cross-node joins on a "small" reference table, but 603K rows is larger than ideal for REPLICATE; may impact memory on all nodes
- **Fee calculation methodology unknown**: Without the writer SP, the exact formula for `Fee` and `FeeUSD` cannot be verified
- **LP naming**: `LP` column contains short codes (e.g., 'IB' = Interactive Brokers) — no FK to a reference table visible from DDL

---

## 6. Lineage Summary

Source unknown — no writer SP found in SSDT repository. Likely derived from hedge execution logs + LP fee rate schedules. See `.lineage.md` for available details.

---

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| `DWH_dbo.Dim_Instrument` | Likely source — instrument metadata (ISINCode, Currency) |

---

*Quality score: 3.5/10 — stale ~30 months, no active ETL, fee methodology unverifiable*
