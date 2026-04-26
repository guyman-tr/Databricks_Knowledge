# Column Lineage — BI_DB_dbo.BI_DB_ASIC_ClientBalanceFinance
<!-- Refreshed 2026-04-23 batch 61 -->

**Writer SP**: `BI_DB_dbo.SP_ASIC_ClientBalanceFinance` (Priority 99 — FinanceReportSPS)
**ETL Pattern**: DELETE-INSERT by Date (daily incremental, one day per execution)
**Population Filter**: ASIC-regulated clients only (RegulationID IN (4, 10)) with IsCreditReportValidCB = 1

---

## Source Tables (DWH layer)

| Source | Role | Join Path |
|--------|------|-----------|
| DWH_dbo.Fact_SnapshotCustomer | Customer dimension snapshot by date | DateRangeID → V_M2M_Date_DateRange, filtered to ASIC regulation |
| DWH_dbo.V_Liabilities | Balance/equity/margin/crypto positions | DateID = current/prev day, joined via CID |
| DWH_dbo.Fact_CustomerAction | Deposits, withdrawals, closed PnL | DateID = current day, ActionTypeID filter |
| DWH_dbo.Dim_Customer | ExternalID (hashed customer identifier) | RealCID join |
| DWH_dbo.Dim_Label | Label names (eToro brand variants) | LabelID join |
| DWH_dbo.Dim_Country | Country abbreviation (ISO code) | CountryID join |
| DWH_dbo.Dim_Regulation | Regulation name (ASIC / ASIC & GAML) | DWHRegulationID join |
| DWH_dbo.V_M2M_Date_DateRange | Date key to DateRange resolution | DateRangeID join |
| BI_DB_dbo.V_GermanBaFin | German BaFin indicator by CID+Date | DateID + CID existence check |

---

## Column-Level Lineage

### A. Identity & Date Columns (3 columns)

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| DateID | computed | @StartDate parameter | CONVERT(VARCHAR(8), @StartDate, 112) — YYYYMMDD integer |
| CID | Fact_SnapshotCustomer → #cid_cur → #Customer | RealCID | Direct. Filtered to ASIC regulation (RegulationID IN 4,10) and IsCreditReportValidCB = 1 |
| Date | computed | @StartDate parameter | Direct assignment of SP input parameter |

### B. Customer Identification (1 column)

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| Customer | Dim_Customer (dc) | ExternalID | Direct read. Hashed/encoded customer identifier (varchar 50) |

### C. Balance Columns (4 columns — V_Liabilities derived)

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| PreviuosDayBalance | V_Liabilities (prev day) | Liabilities | ROUND(ISNULL(OpeningBalance,0), 2). OpeningBalance = Liabilities minus negative-liability adjustment (chargeback/other) |
| CurrentDayBalance | computed | multiple | ROUND(OpeningBalance + deposit_Amount + ChargebackLoss + OtherNegative + ClosedPnL, 2). Full day reconciliation formula |
| Equity | V_Liabilities (current day) | Liabilities | ROUND(ClosingBalance, 2). ClosingBalance = Liabilities minus negative adjustments |
| TotalOpenMargin | V_Liabilities (current day) | TotalPositionsAmount | ROUND(ISNULL(Amount,0), 2). Total open position margin value |

### D. Action Columns (3 columns — Fact_CustomerAction derived)

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| Deposit | Fact_CustomerAction + V_Liabilities | Amount + ChargebackLoss + OtherNegative | ROUND(SUM(ActionAmount for deposit types) + ChargebackLoss + OtherNegative, 2). Deposit ActionTypeIDs: 7,11,12,13,35,36 minus withdrawal(8) minus commission(30) |
| Withdrawal | Fact_CustomerAction | Amount | ROUND(ISNULL(SUM(Amount) for ActionTypeID=8 negated, 0), 2) |
| ClosedPnL | Fact_CustomerAction | NetProfit | ROUND(ISNULL(SUM(NetProfit) for ActionTypeIDs 4,5,6,28,40, 0), 2) |

### E. Position & Crypto Columns (2 columns)

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| OpenPosition | V_Liabilities (both days) | PositionPnL | ROUND(ISNULL(today.PositionPnL - yesterday.PositionPnL, 0), 2). Daily delta |
| RealAssetEquity | V_Liabilities (current day) | TotalRealCrypto + PositionPnLCryptoReal | ROUND(ISNULL(TotalRealCrypto + PositionPnLCryptoReal, 0), 2). Real crypto holdings plus real crypto PnL |

### F. Classification Columns (5 columns)

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| CurrentLabel | Dim_Label (current day) | Name | CASE WHEN Name LIKE '%eToro%' THEN 'eToro' ELSE Name END. Simplified brand label |
| PrevLabel | Dim_Label (prev day) | Name | Same simplification applied to previous-day label |
| Country | Dim_Country | Abbreviation | Direct. ISO country code (AU, MY, PE, etc.) |
| RegulationName | Dim_Regulation | Name | Direct. Values: "ASIC" or "ASIC & GAML" |
| IsGermanBaFin | V_GermanBaFin | CID existence | CASE WHEN gb.CID IS NOT NULL THEN 1 ELSE 0 END. Flag for German BaFin applicability |

### G. Metadata (1 column)

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| UpdateDate | computed | GETDATE() | SP execution timestamp |

---

## ETL Flow Diagram

```
Fact_SnapshotCustomer ──→ #cid_cur (today, ASIC reg)
                        ──→ #cid_prev (yesterday, ASIC reg)
                                    ↓
Dim_Customer + Dim_Regulation ──→ #Customer (merged CID list)
                                    ↓
V_Liabilities (today) + #Customer ──→ #ClosingBalance
V_Liabilities (yesterday) + #Customer ──→ #OpeningBalance
                                    ↓
                              #liability (balance delta)
                                    ↓
Fact_CustomerAction + #Customer ──→ #action ──→ #action_agg
                                    ↓
V_GermanBaFin ──→ #GermanBafin
                                    ↓
             FINAL INSERT: #Customer + #liability + #action_agg + #GermanBafin
                    → DELETE/INSERT into BI_DB_ASIC_ClientBalanceFinance
```
