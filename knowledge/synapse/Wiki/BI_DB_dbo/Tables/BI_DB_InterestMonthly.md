# BI_DB_dbo.BI_DB_InterestMonthly

> 4.86M-row monthly CID-level interest accrual table recording accumulated interest, tax percentage, and final taxed interest for completed (StatusID=3) interest periods. Sourced from the Interest database via External_Interest_Trade_InterestMonthly external table. Date range: Jul 2019 – Mar 2026 (80 months). Delete-insert by MonthOfInterest targeting 2 months prior. Author: Adi Meidan 2024-04-30.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Finance — Interest Accrual) |
| **Production Source** | Interest.Trade.InterestMonthly via External_Interest_Trade_InterestMonthly |
| **Refresh** | Daily delete-insert for MonthOfInterest = 2 months prior (SB_Daily) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (MonthOfInterest ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **OpsDB Priority** | 0 |
| **OpsDB Process** | SB_Daily, ProcessType 1 (SQL) |
| **Author** | Adi Meidan (2024-04-30); delete-insert logic change (2024-10-06) |

---

## 1. Business Meaning

`BI_DB_InterestMonthly` is a **monthly interest accrual report** at the CID level. Each row represents one customer's accumulated interest for a specific month, including the tax percentage applied and the final taxed interest amount.

The table holds 4.86M rows across 80 monthly periods from July 2019 to March 2026. The March 2026 snapshot shows ~227,804 CIDs with completed interest entries, predominantly under RegulationID 1 (CySEC, 69%), followed by RegulationID 2 (FCA, 22%), 9 (Seychelles, 5%), 10 (ASIC, 3%), and 11 (Abu Dhabi/FSRA, 2%).

### Source

Data comes from the **Interest database** (`Interest.Trade.InterestMonthly`) — a production system that calculates monthly interest on client cash balances. The data flows through the Generic Pipeline to an external table (`External_Interest_Trade_InterestMonthly`), then the SP filters to StatusID=3 (completed/approved interest calculations only).

### Load Pattern

- **Daily delete-insert**: The SP runs daily but targets `MonthOfInterest = 2 months prior` — e.g., running on Apr 13 processes the Feb 1 month
- This 2-month lag allows the Interest system to finalize and approve calculations
- `@StartOfMonth = DATEADD(DAY, 1, EOMONTH(DATEADD(month, -2, @date)))` — first day of the month that is 2 months before @date

---

## 2. Business Logic

### 2.1 Interest Status Filter

**What**: Only completed interest entries are loaded.
**Columns Involved**: StatusID
**Rules**:
- StatusID = 3 is the only status imported (completed/approved)
- Pending or rejected interest entries (other StatusID values) are excluded

### 2.2 Tax Calculation

**What**: Final interest is computed with tax deduction.
**Columns Involved**: MonthlyAccumulatedInterest, TaxPercentage, FinalTaxedlnterest
**Rules**:
- FinalTaxedlnterest = MonthlyAccumulatedInterest × (1 − TaxPercentage/100), rounded to 2 decimal places
- TaxPercentage varies by regulation — e.g., CySEC RegulationID=1 often has 0% tax; RegulationID=2 (FCA) has 20% withholding

### 2.3 Two-Month Lag

**What**: Data is loaded with a 2-month lag from the SP execution date.
**Columns Involved**: MonthOfInterest
**Rules**:
- SP execution on @date loads MonthOfInterest = first day of (month(@date) − 2)
- This ensures the Interest system has finalized its calculations before import

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on MonthOfInterest ASC. Always filter on MonthOfInterest for efficient index seeks.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total interest for a month | `SELECT SUM(FinalTaxedlnterest) FROM BI_DB_InterestMonthly WHERE MonthOfInterest = '2026-03-01'` |
| Interest by regulation | `GROUP BY RegulationID WHERE MonthOfInterest = '2026-03-01'` |
| Customer interest history | `WHERE CID = @CID ORDER BY MonthOfInterest` |
| Tax rate distribution | `GROUP BY TaxPercentage WHERE MonthOfInterest = '2026-03-01'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer details |
| DWH_dbo.Dim_Regulation | RegulationID = RegulationID | Regulation name |

### 3.4 Gotchas

- **Column name typo**: `FinalTaxedlnterest` uses lowercase 'l' (not 'I') — this is `lnterest` not `Interest` in the DDL
- **2-month lag**: Current month and previous month data are not yet available
- **StatusID always 3**: All rows have StatusID=3 by design (filter in SP). This column is a constant in this table
- **ValidFrom is source timestamp**: This is the Interest system's processing timestamp, not a DWH timestamp

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki with documented production source |
| Tier 2 | Derived from SP code analysis with high confidence |
| Tier 3 | Inferred from data patterns and naming conventions |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL metadata / infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID — unique identifier for a customer account in the eToro platform. FK to DWH_dbo.Dim_Customer.RealCID. (Tier 2 — SP_InterestMonthly, from Interest.Trade.InterestMonthly) |
| 2 | RegulationID | int | YES | Regulatory entity ID governing this customer. FK to DWH_dbo.Dim_Regulation. Values observed: 1=CySEC, 2=FCA, 4=ASIC, 9=Seychelles, 10=ASIC-new, 11=FSRA, 13=other. (Tier 2 — SP_InterestMonthly, from Interest.Trade.InterestMonthly) |
| 3 | StatusID | tinyint | YES | Interest calculation status. Always 3 in this table (completed/approved). SP filters to StatusID=3 before inserting. (Tier 2 — SP_InterestMonthly, from Interest.Trade.InterestMonthly) |
| 4 | MonthOfInterest | date | YES | First day of the month for which interest was calculated (e.g., 2026-03-01). Clustered index column — filter on this for efficient queries. (Tier 2 — SP_InterestMonthly, from Interest.Trade.InterestMonthly) |
| 5 | MonthlyAccumulatedInterest | numeric(15,6) | YES | Gross accumulated interest for this CID for this month, before tax deduction. In USD. (Tier 2 — SP_InterestMonthly, from Interest.Trade.InterestMonthly) |
| 6 | TaxPercentage | numeric(5,2) | YES | Withholding tax percentage applied to the interest. Varies by regulation: 0.00% for CySEC (RegulationID=1), 20.00% for FCA (RegulationID=2). (Tier 2 — SP_InterestMonthly, from Interest.Trade.InterestMonthly) |
| 7 | FinalTaxedlnterest | numeric(12,2) | YES | Net interest after tax deduction. Approximately MonthlyAccumulatedInterest × (1 − TaxPercentage/100). Note: column name has lowercase 'l' not uppercase 'I' (typo in source). (Tier 2 — SP_InterestMonthly, from Interest.Trade.InterestMonthly) |
| 8 | ValidFrom | datetime2(2) | YES | Timestamp from the Interest system indicating when this interest record was finalized/approved. Source system timestamp, not a DWH ETL timestamp. (Tier 2 — SP_InterestMonthly, from Interest.Trade.InterestMonthly) |
| 9 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_InterestMonthly. Set to GETDATE(). (Tier 5 — SP_InterestMonthly) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| CID | Interest.Trade.InterestMonthly | CID | Passthrough |
| RegulationID | Interest.Trade.InterestMonthly | RegulationID | Passthrough |
| StatusID | Interest.Trade.InterestMonthly | StatusID | Passthrough (filtered to 3) |
| MonthOfInterest | Interest.Trade.InterestMonthly | MonthOfInterest | Passthrough (filtered to 2 months prior) |
| MonthlyAccumulatedInterest | Interest.Trade.InterestMonthly | MonthlyAccumulatedInterest | Passthrough |
| TaxPercentage | Interest.Trade.InterestMonthly | TaxPercentage | Passthrough |
| FinalTaxedlnterest | Interest.Trade.InterestMonthly | FinalTaxedlnterest | Passthrough |
| ValidFrom | Interest.Trade.InterestMonthly | ValidFrom | Passthrough |

### 5.2 ETL Pipeline

```
Interest.Trade.InterestMonthly (production Interest database)
  |-- Generic Pipeline (Bronze export) --|
  v
Data Lake (Bronze/Interest/Trade/InterestMonthly)
  |-- External Table --|
  v
BI_DB_dbo.External_Interest_Trade_InterestMonthly
  |-- SP_InterestMonthly @date (daily, delete-insert by MonthOfInterest) --|
  |   Filter: StatusID = 3 (completed only)                                |
  |   Target: MonthOfInterest = first-of-month 2 months prior              |
  v
BI_DB_dbo.BI_DB_InterestMonthly (4.86M rows, 80 months, CID-level)
  (Not in Generic Pipeline — _Not_Migrated to UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer lookup |
| RegulationID | DWH_dbo.Dim_Regulation | Regulation name |
| All columns | BI_DB_dbo.External_Interest_Trade_InterestMonthly | External table source |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Total Interest by Regulation for Latest Month

```sql
SELECT RegulationID,
       COUNT(*) AS customers,
       SUM(MonthlyAccumulatedInterest) AS gross_interest,
       SUM(FinalTaxedlnterest) AS net_interest
FROM [BI_DB_dbo].[BI_DB_InterestMonthly]
WHERE MonthOfInterest = (SELECT MAX(MonthOfInterest) FROM [BI_DB_dbo].[BI_DB_InterestMonthly])
GROUP BY RegulationID
ORDER BY net_interest DESC
```

### 7.2 Monthly Interest Trend

```sql
SELECT MonthOfInterest,
       COUNT(*) AS cids,
       SUM(FinalTaxedlnterest) AS total_net_interest
FROM [BI_DB_dbo].[BI_DB_InterestMonthly]
GROUP BY MonthOfInterest
ORDER BY MonthOfInterest
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search permission denied).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 0 T1, 8 T2, 0 T3, 0 T4, 1 T5 | Elements: 9/9, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_InterestMonthly | Type: Table | Production Source: Interest.Trade.InterestMonthly via External Table*
