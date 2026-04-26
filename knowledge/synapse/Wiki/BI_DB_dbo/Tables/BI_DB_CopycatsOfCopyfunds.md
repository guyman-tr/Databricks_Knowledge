# BI_DB_dbo.BI_DB_CopycatsOfCopyfunds

**Generated**: 2026-04-23  
**Schema**: BI_DB_dbo  
**Object Type**: Table  
**Writer SP**: SP_CopycatsOfCopyfunds  
**Load Pattern**: TRUNCATE + INSERT (daily snapshot, no history)  
**Distribution**: ROUND_ROBIN  
**Index**: CLUSTERED INDEX (CID ASC)  
**Column Count**: 9  
**Row Count**: 234,571  
**Distinct CIDs**: 74,476 (multiple rows per CID — one per CopyFund copy relationship)  
**Priority**: 0 (OpsDB)  
**Frequency**: Daily  
**UC Migration**: Not Migrated  

---

## 1. Overview

Daily snapshot identifying **retail customers who have ≥80% of their account equity concentrated in CopyFund investments**. Each row represents one **copy relationship** (a customer copying a specific CopyFund), not one customer — a single customer with multiple CopyFund positions that each exceed 80% of their equity will appear multiple rows.

**Population criteria**:
- The copied entity must be a CopyFund account (`AccountTypeID=9`)
- The copier must NOT be a CopyFund account (`AccountTypeID != 9`)
- The copier must NOT be a Diamond Club member (`PlayerLevelID != 4`)
- This copy's equity / total account equity > 80% (and total equity > 0)
- The copier must NOT be on the blocked-copy-operations list (`OperationTypeID=2`)

**IS PI ?** flag: 76 out of 234,571 rows (0.03%) belong to PIs (`GuruStatusID IN 2,3,4,5`).

**Purpose**: Operational feed for the PI Analytics and account management teams to identify retail clients heavily concentrated in CopyFunds, enabling proactive outreach and risk monitoring.

---

## 2. Business Logic

### 2.1 @Date Parameter Off-by-One

The SP adds 1 day to the input `@Date` parameter at entry: `set @Date = DateAdd(Day, 1, @Date)`. The internal `@YesterdayDateID` is then computed as `@Date - 1`, which equals the original input date. If the orchestration passes "yesterday" as @Date, the SP effectively queries data for "yesterday" from `V_Liabilities` and `etoroGeneral_History_GuruCopiers`. This is an unusual design — downstream callers must account for it.

### 2.2 CID Is Not Unique

CID is not unique in this table. Multiple rows for the same CID occur when a customer has separate open mirror relationships with multiple CopyFunds, and each mirror's `RealizedEquity / AccountEquity > 0.8`. This is mathematically unusual (one person's equity cannot truly be 80% in each of 3 different CopyFunds simultaneously), and typically results from V_Liabilities refreshing at a different time than Dim_Mirror. The observed average of ~3.1 rows per CID reflects this artifact.

### 2.3 `% Copying` Outliers

`% Copying = tm.RealizedEquity / vl.RealizedEquity * 100`. The SP filters `vl.RealizedEquity > 0` but allows very small values (e.g., $0.01), which can produce extreme percentages (observed average for Not PI: 753,100%). This occurs when V_Liabilities shows near-zero equity but Dim_Mirror has a large RealizedEquity value due to data timing differences. Treat the `% Copying` column as directionally useful (>80% expected) but not precise.

### 2.4 `# of Copiers` and `AUM` columns

These columns reflect the CopyFund's investor count and total AUM, not the customer's own copier base. Sourced from `general.etoroGeneral_History_GuruCopiers` where `ParentCID` matches the CopyFund's CID. The join `#CopyAUM_Data.ParentCID = c.CID` means these columns populate only when the copier (`c.CID`) is themselves a CopyFund manager being tracked in `etoroGeneral_History_GuruCopiers` as a parent — which yields data primarily for the 76 PI-status rows. For standard Not-PI copiers, `# of Copiers` and `AUM` will be 0 (from `ISNULL(..., 0)`).

---

## 3. Query Advisory

- **No history**: This is a daily-refresh snapshot. There is no `Date` column — all rows are current. Do not SUM or compare across days.
- **CID is not unique**: Use `SUM(ThisCopyEquity)` or deduplicate before joining to customer-level tables.
- **ROUND_ROBIN distributed**: Joins on CID require data movement. Filter on a small subset first.
- **`% Copying` outliers**: Do not trust raw values as accurate percentages. Use only as a ≥80% qualifier flag.
- **Column names with special characters**: `[% Copying]`, `[# of Copiers]`, `[IS PI ?]` require bracket quoting in all SQL.

---

## 4. Elements

| Column | Nullable | Type | Description |
|--------|----------|------|-------------|
| CID | NOT NULL | int | Customer ID of the COPIER (the person investing in CopyFunds). Not unique in this table — one row per copy relationship. Customer ID — platform-internal primary key. (Tier 1 — DWH_dbo.Dim_Customer via DWH_dbo.Dim_Mirror) |
| UserName | NULL | varchar(20) | Login username of the copier. From Dim_Customer.UserName. Customer login username — unique (case-insensitive). (Tier 1 — DWH_dbo.Dim_Customer via Customer.CustomerStatic) |
| AccountEquity | NOT NULL | money | Copier's total account equity as of yesterday: V_Liabilities.RealizedEquity. Denominator for % Copying calculation. (Tier 2 — DWH_dbo.V_Liabilities.RealizedEquity) |
| ThisCopyEquity | NOT NULL | money | Equity held in THIS CopyFund copy relationship: Dim_Mirror.RealizedEquity for this specific mirror. Numerator for % Copying calculation. (Tier 2 — DWH_dbo.Dim_Mirror.RealizedEquity) |
| % Copying | NULL | money | Proportion of total equity in this CopyFund copy: ThisCopyEquity / AccountEquity × 100. Always > 80 by population filter. NOTE: extreme outliers exist (see section 2.3) when V_Liabilities and Dim_Mirror have timing differences. Column name requires bracket quoting: [% Copying]. (Tier 2 — derived: Dim_Mirror.RealizedEquity / V_Liabilities.RealizedEquity * 100) |
| # of Copiers | NOT NULL | int | Number of copiers of the CopyFund (NOT the customer's own copier count). Sourced from general.etoroGeneral_History_GuruCopiers for the CopyFund (ParentCID). ISNULL → 0 when the CopyFund has no copier history record. Column name requires bracket quoting: [# of Copiers]. (Tier 2 — general.etoroGeneral_History_GuruCopiers) |
| AUM | NOT NULL | money | Total Assets Under Management for the CopyFund the customer is copying: SUM(Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL) from etoroGeneral_History_GuruCopiers. ISNULL → 0 for CopyFunds with no copier history. (Tier 2 — general.etoroGeneral_History_GuruCopiers) |
| IS PI ? | NOT NULL | varchar(6) | Whether the copier themselves is a Popular Investor: 'PI' if GuruStatusID IN (2,3,4,5); 'Not PI' otherwise. Observed: Not PI=234,495 (99.97%), PI=76 (0.03%). Column name requires bracket quoting: [IS PI ?]. (Tier 2 — DWH_dbo.Dim_Customer.GuruStatusID) |
| UpdateDate | NOT NULL | datetime | ETL metadata: timestamp when this row was inserted by the ETL pipeline (GETDATE() at TRUNCATE+INSERT time). (Propagation) |

---

## 5. Lineage Summary

| Source | Columns Derived |
|--------|-----------------|
| DWH_dbo.Dim_Mirror | CID (via tm.CID), ThisCopyEquity (via tm.RealizedEquity) |
| DWH_dbo.Dim_Customer (copier) | CID validation (AccountTypeID!=9, PlayerLevelID!=4), UserName, GuruStatusID → IS PI ? |
| DWH_dbo.V_Liabilities | AccountEquity, % Copying denominator |
| general.etoroGeneral_History_GuruCopiers | # of Copiers, AUM |
| BI_DB_dbo.External_etoro_Customer_BlockedCustomerOperations | Exclusion filter (OperationTypeID=2) |
| ETL metadata | UpdateDate (= GETDATE()) |

---

## 6. OpsDB Orchestration

| Property | Value |
|---|---|
| OpsDB Priority | 0 (base layer) |
| Frequency | Daily |
| Writer SP | SP_CopycatsOfCopyfunds |
| ProcessType | SQL (1) |

---

## 7. Quality Notes

- CID is not unique — always aggregate or deduplicate before customer-level joins.
- `% Copying` column is `money` type (not decimal/float) — arithmetic operations may lose precision. Expected range > 80 by filter, but extreme outliers observed.
- `# of Copiers` and `AUM` reflect the CopyFund's metrics, not the copier's own performance.
- `IS PI ?` values: 'PI' (6 chars) and 'Not PI' (6 chars) — varchar(6) is exactly sized.
- `@Date` parameter: the SP internally increments by 1 day. Orchestration callers pass yesterday's date; the SP processes data for yesterday via @YesterdayDateID = DateAdd(Day,-1, @Date+1) = original input.
