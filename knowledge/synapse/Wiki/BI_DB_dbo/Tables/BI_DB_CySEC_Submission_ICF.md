# BI_DB_dbo.BI_DB_CySEC_Submission_ICF

> 178.9M-row monthly CySEC Investor Compensation Fund (ICF) regulatory submission dataset tracking end-of-month client balances (adjusted to exclude real crypto), EUR-converted via ECB rates, with the EUR 20,000 ICF threshold flag, for 6.8M distinct CIDs across 29 months (December 2023 to present). Refreshed daily by SP_CySEC_Submission_ICF via DELETE+INSERT for the current end-of-month.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New (balances) + BI_DB_ECB_RateExtractFromAPI (EUR rate) + DWH_dbo.Fact_SnapshotCustomer (customer attributes) via SP_CySEC_Submission_ICF |
| **Refresh** | Daily (SB_Daily, Priority 0). DELETE current EOMONTH → INSERT aggregated balances |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_CySEC_Submission_ICF` supports the CySEC (Cyprus Securities and Exchange Commission) Investor Compensation Fund regulatory submission. Under CySEC rules, investment firms must participate in the ICF, which covers eligible clients up to EUR 20,000. This table computes each client's end-of-month closing balance, adjusts it by removing real crypto positions (which are excluded from ICF coverage), converts to EUR using the latest ECB exchange rate, and flags whether the adjusted balance exceeds the EUR 20,000 threshold.

The grain is (CID, EndOfMonth) — one row per customer per month. Balances are sourced from `BI_DB_Client_Balance_CID_Level_New` (filtered to TransferDirection=1, ClosingBalance IS NOT NULL), aggregated by EOMONTH. The EUR conversion uses the latest ECB rate on or before the execution date from `BI_DB_ECB_RateExtractFromAPI`.

Customer attributes (MifidCategory, Regulation, IsCreditReportValidCB, Club) are enriched from Fact_SnapshotCustomer via dimension lookups at the execution date. MifidCategory distinguishes Retail (ICF-eligible) from Professional/Elective Professional (potentially different coverage).

The SP also calculates Real Stocks balance separately (RealStocksBalance_USD/EUR), with its own EUR 20,000 threshold flag, supporting additional regulatory analysis.

---

## 2. Business Logic

### 2.1 ICF Balance Adjustment (Crypto Exclusion)

**What**: Real crypto positions are excluded from the ICF-eligible balance because crypto assets are not covered by the Investor Compensation Fund.
**Columns Involved**: `ClosingBalance`, `RealCryptoClosingBalance`, `ClosingBalanceAdj_USD`, `ClosingBalanceAdj_EUR`
**Rules**:
- `ClosingBalanceAdj_USD = SUM(ClosingBalance) - SUM(RealCryptoClosingBalance)` — subtracts real crypto
- `ClosingBalanceAdj_EUR = ClosingBalanceAdj_USD / ECB_Rate` — converts to EUR
- ECB rate = latest ECBRate from BI_DB_ECB_RateExtractFromAPI WHERE Date <= @Date (ROW_NUMBER DESC)

### 2.2 EUR 20,000 ICF Threshold

**What**: The ICF covers eligible clients up to EUR 20,000. This flag identifies clients whose adjusted balance meets or exceeds that threshold.
**Columns Involved**: `ISClosingBalanceAdj_EUR>20000`, `ISRealStocksBalanceAdj_EUR>20000`
**Rules**:
- `ISClosingBalanceAdj_EUR>20000` = 'Yes' if ClosingBalanceAdj_EUR >= 20000, else 'No'
- `ISRealStocksBalanceAdj_EUR>20000` = 'Yes' if RealStocksBalance_EUR >= 20000, else 'No'
- Distribution (March 2026): Yes/Yes = 593K, Yes/No = 193K, No/No = 5.98M, No/Yes = 83

### 2.3 MiFID Client Classification

**What**: Clients are classified under MiFID II categories which affect ICF eligibility and coverage levels.
**Columns Involved**: `MifidCategory`
**Rules**:
- Values: Retail (63%), Retail Pending (37%), Pending (<1%), Elective Professional (<0.01%), Professional (<0.01%), None (<0.01%)
- Retail clients are the primary ICF-eligible population
- Professional clients may have different coverage terms

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on CID. CID-based lookups are efficient. EOMONTH-based filtering requires full scan but data is relatively compact per month (~6.8M rows/month).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total ICF-eligible balance by regulation | `SELECT Regulation, SUM(ClosingBalanceAdj_EUR) WHERE EndOfMonth = @month GROUP BY Regulation` |
| Clients above EUR 20K threshold | `WHERE [ISClosingBalanceAdj_EUR>20000] = 'Yes' AND EndOfMonth = @month` |
| Monthly trend of ICF exposure | `SELECT EndOfMonth, SUM(ClosingBalanceAdj_EUR) GROUP BY EndOfMonth` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Full customer profile |
| BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | CID = CID | Detailed daily balance breakdown |

### 3.4 Gotchas

- **Column names with special characters**: `[ISClosingBalanceAdj_EUR>20000]` and `[ISRealStocksBalanceAdj_EUR>20000]` contain `>` in the name — MUST be bracket-quoted in queries.
- **CID, not RealCID**: This table uses `CID` (not `RealCID`) as the customer identifier, consistent with the BI_DB_Client_Balance_CID_Level_New source.
- **TransferDirection=1 filter**: Only one transfer direction is included. This filters the source balance data.
- **Not CySEC-specific despite name**: The table contains ALL regulations (CySEC, FCA, BVI, FinCEN+FINRA, ASIC, etc.), not just CySEC. The name reflects its original purpose for CySEC ICF submission.
- **ECB rate is point-in-time**: The EUR conversion uses the latest available ECB rate, not necessarily the EOMONTH rate. Running the SP on different days may produce different EUR values for the same month.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (production DB documentation) | Highest |
| Tier 2 | SP code analysis | High |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID. Passthrough from BI_DB_Client_Balance_CID_Level_New. Note: this column is CID (not RealCID) consistent with the source balance table. FK to Dim_Customer.RealCID. (Tier 2 — SP_CySEC_Submission_ICF) |
| 2 | EndOfMonth | date | YES | End-of-month date for the balance snapshot. ETL-computed: EOMONTH(Date) from source. Range: 2023-12-31 to 2026-04-30. Used for DELETE+INSERT partitioning. (Tier 2 — SP_CySEC_Submission_ICF) |
| 3 | ClosingBalance | decimal(38,6) | YES | Total closing balance in USD. SUM(ISNULL(ClosingBalance,0)) aggregated across TransferDirection=1 records for the month. Includes all asset types (equities, crypto, CFD). (Tier 2 — SP_CySEC_Submission_ICF) |
| 4 | RealCryptoClosingBalance | decimal(38,6) | YES | Real crypto closing balance in USD. SUM(ISNULL(RealCryptoClosingBalance,0)). Subtracted from ClosingBalance to compute ICF-eligible adjusted balance (crypto excluded from ICF). (Tier 2 — SP_CySEC_Submission_ICF) |
| 5 | ClosingBalanceAdj_USD | decimal(38,6) | YES | ICF-adjusted closing balance in USD. Computed: ClosingBalance - RealCryptoClosingBalance. Excludes real crypto positions which are not covered by the Investor Compensation Fund. (Tier 2 — SP_CySEC_Submission_ICF) |
| 6 | ClosingBalanceAdj_EUR | numeric(38,6) | YES | ICF-adjusted closing balance converted to EUR. Computed: ClosingBalanceAdj_USD / ECB exchange rate. ECB rate from BI_DB_ECB_RateExtractFromAPI (latest rate <= execution date). (Tier 2 — SP_CySEC_Submission_ICF) |
| 7 | MifidCategory | varchar(30) | YES | MiFID II client classification. Values: Retail, Retail Pending, Pending, Elective Professional, Professional, None. From Dim_MifidCategorization.Name via Fact_SnapshotCustomer.MifidCategorizationID JOIN. (Tier 2 — SP_CySEC_Submission_ICF via Dim_MifidCategorization) |
| 8 | Regulation | varchar(30) | YES | Regulatory entity governing this customer. Values: CySEC, FCA, BVI, FinCEN+FINRA, ASIC & GAML, FSA Seychelles, FinCEN, FSRA, ASIC, eToroUS. From Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID JOIN. (Tier 2 — SP_CySEC_Submission_ICF via Dim_Regulation) |
| 9 | IsCreditReportValidCB | int | YES | Flag indicating whether the client's credit report is valid for closing balance purposes. Passthrough from Fact_SnapshotCustomer. 1=valid, 0=invalid. (Tier 2 — SP_CySEC_Submission_ICF) |
| 10 | Club | varchar(30) | YES | eToro Club tier name at the snapshot date. Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal. From Dim_PlayerLevel.Name via Fact_SnapshotCustomer.PlayerLevelID JOIN. (Tier 2 — SP_CySEC_Submission_ICF via Dim_PlayerLevel) |
| 11 | UpdateDate | date | YES | ETL metadata: date when this row was last updated by the ETL pipeline. Set to GETDATE() (truncated to date). (Tier 5 — Propagation) |
| 12 | RealStocksBalance_USD | decimal(38,6) | YES | Real stocks closing balance in USD. SUM(ISNULL(RealStocksClosingBalance,0)) from source. Separate from crypto and CFD balances. (Tier 2 — SP_CySEC_Submission_ICF) |
| 13 | RealStocksBalance_EUR | decimal(38,6) | YES | Real stocks closing balance converted to EUR. Computed: RealStocksBalance_USD / ECB exchange rate. (Tier 2 — SP_CySEC_Submission_ICF) |
| 14 | ISRealStocksBalanceAdj_EUR>20000 | varchar(30) | YES | Flag indicating whether the real stocks balance in EUR meets or exceeds the EUR 20,000 ICF threshold. Values: Yes, No. CASE WHEN RealStocksBalance_EUR >= 20000 THEN 'Yes' ELSE 'No'. Must be bracket-quoted in queries due to `>` in column name. (Tier 2 — SP_CySEC_Submission_ICF) |
| 15 | ISClosingBalanceAdj_EUR>20000 | varchar(30) | YES | Flag indicating whether the ICF-adjusted closing balance in EUR meets or exceeds the EUR 20,000 ICF threshold. Values: Yes, No. CASE WHEN ClosingBalanceAdj_EUR >= 20000 THEN 'Yes' ELSE 'No'. Must be bracket-quoted in queries due to `>` in column name. (Tier 2 — SP_CySEC_Submission_ICF) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | BI_DB_Client_Balance_CID_Level_New | CID | Passthrough (GROUP BY) |
| EndOfMonth | BI_DB_Client_Balance_CID_Level_New | Date | EOMONTH(Date) |
| ClosingBalance | BI_DB_Client_Balance_CID_Level_New | ClosingBalance | SUM(ISNULL) |
| RealCryptoClosingBalance | BI_DB_Client_Balance_CID_Level_New | RealCryptoClosingBalance | SUM(ISNULL) |
| ClosingBalanceAdj_USD | — | — | ClosingBalance - RealCryptoClosingBalance |
| ClosingBalanceAdj_EUR | — | — | ClosingBalanceAdj_USD / ECB rate |
| MifidCategory | DWH_dbo.Dim_MifidCategorization | Name | Lookup via Fact_SnapshotCustomer |
| Regulation | DWH_dbo.Dim_Regulation | Name | Lookup via Fact_SnapshotCustomer |
| IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB | Passthrough |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Lookup via Fact_SnapshotCustomer |
| UpdateDate | — | — | GETDATE() |
| RealStocksBalance_USD | BI_DB_Client_Balance_CID_Level_New | RealStocksClosingBalance | SUM(ISNULL) |
| RealStocksBalance_EUR | — | — | RealStocksBalance_USD / ECB rate |
| ISRealStocksBalanceAdj_EUR>20000 | — | — | CASE WHEN >= 20000 |
| ISClosingBalanceAdj_EUR>20000 | — | — | CASE WHEN >= 20000 |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New
  (TransferDirection=1, ClosingBalance IS NOT NULL, EOMONTH=@Month)
  |-- SUM by CID, EOMONTH ---|
  v
BI_DB_dbo.BI_DB_ECB_RateExtractFromAPI
  (latest ECBRate <= @Date)
  |-- EUR conversion (/ ECB rate) ---|
  v
#prefinaltable (balance metrics + threshold flags)
  |
  + DWH_dbo.Fact_SnapshotCustomer (customer snapshot at @DateID)
  + DWH_dbo.Dim_Range (date range resolution)
  + DWH_dbo.Dim_MifidCategorization (MifidCategory name)
  + DWH_dbo.Dim_Regulation (Regulation name)
  + DWH_dbo.Dim_PlayerLevel (Club name)
  |-- #finaltable ---|
  v
BI_DB_dbo.BI_DB_CySEC_Submission_ICF (DELETE+INSERT for EOMONTH)

UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension (CID = RealCID) |

### 6.2 Referenced By (other objects point to this)

No known consumers identified in this batch.

---

## 7. Sample Queries

### 7.1 Total ICF Exposure by Regulation for Latest Month

```sql
SELECT Regulation,
       COUNT(DISTINCT CID) AS clients,
       SUM(ClosingBalanceAdj_EUR) AS total_icf_balance_eur,
       SUM(CASE WHEN [ISClosingBalanceAdj_EUR>20000] = 'Yes' THEN 1 ELSE 0 END) AS above_threshold
FROM BI_DB_dbo.BI_DB_CySEC_Submission_ICF
WHERE EndOfMonth = (SELECT MAX(EndOfMonth) FROM BI_DB_dbo.BI_DB_CySEC_Submission_ICF)
GROUP BY Regulation
ORDER BY total_icf_balance_eur DESC
```

### 7.2 Monthly ICF Threshold Trend (CySEC Retail Only)

```sql
SELECT EndOfMonth,
       COUNT(DISTINCT CID) AS total_clients,
       SUM(CASE WHEN [ISClosingBalanceAdj_EUR>20000] = 'Yes' THEN 1 ELSE 0 END) AS above_20k,
       SUM(ClosingBalanceAdj_EUR) AS total_adjusted_eur
FROM BI_DB_dbo.BI_DB_CySEC_Submission_ICF
WHERE Regulation = 'CySEC' AND MifidCategory = 'Retail'
GROUP BY EndOfMonth
ORDER BY EndOfMonth
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 0 T1, 13 T2, 0 T3, 0 T4, 1 T5 | Elements: 15/15, Logic: 9/10, Completeness: 10/10*
*Object: BI_DB_dbo.BI_DB_CySEC_Submission_ICF | Type: Table | Production Source: BI_DB_Client_Balance_CID_Level_New + ECB rates via SP_CySEC_Submission_ICF*
