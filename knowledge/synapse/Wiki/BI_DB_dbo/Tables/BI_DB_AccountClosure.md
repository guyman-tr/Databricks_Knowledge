# BI_DB_dbo.BI_DB_AccountClosure

> Daily point-in-time snapshot of 965,173 customers currently in a pending account closure state (Approved for Closure or Suggested for Closure), containing their loyalty tier, regulation, country, the date they entered closure status, and their lifetime financial summary (deposits, cashouts, P&L, equity). Refreshed daily via TRUNCATE+INSERT by SP_AccountClosure. One row per CID — no historical data retained. Designed for Customer Service (CS) account closure workflow management.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer (via SP_AccountClosure) |
| **Refresh** | Daily TRUNCATE+INSERT — SP_AccountClosure @dd (Priority 20, SB_Daily) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — Synapse-only CS operational report |
| **Row Count** | 965,173 (as of 2026-04-11) |
| **Author** | Shir Yablon (2022-03-02) |

---

## 1. Business Meaning

This table is the daily operational snapshot of all eToro customers who are in an active account closure process — either **Approved for Closure** (963,128, ~99.8%) or **Suggested for Closure** (2,045, ~0.2%). It is used by the Customer Service team to manage and prioritise account closure workflows.

Each row represents **one customer** at the current date snapshot. The table is rebuilt daily (TRUNCATE+INSERT) from `Fact_SnapshotCustomer` — only the latest snapshot is retained; no history is preserved. As of 2026-04-11, 965,173 customers are in closure status across all regulations.

The regulation breakdown reflects the full global eToro customer base: CySEC leads (64%), followed by FCA (15%), ASIC variants (~14%), and FinCEN/FINRA US regulation (~5%). This is notably different from BI_DB_AML_SAR_Report_FCA (FCA-only) — AccountClosure is all-regulation.

The financial summary columns (TotalDeposits, TotalCashouts, PnL_Total, Equity, TotalCoFee, Revenue_Total) are sourced from `BI_DB_CID_DailyPanel_FullData` for the run date, giving CS a single-row financial picture of each closing customer.

`PendingClosureChangeDate` records when the customer **first entered their current closure status** — derived from the earliest DateRangeID in Fact_SnapshotCustomer where this PendingClosureStatusName was assigned.

---

## 2. Business Logic

### 2.1 Population Selection (Pending Closure Filter)

**What**: Identifies all valid customers currently flagged for closure at the run date.  
**Columns Involved**: CID, PendingClosureStatusName, Date, DateID  
**Rules**:
- Source: Fact_SnapshotCustomer WHERE DateRangeID covers @dd (FromDateID ≤ @ddINT ≤ ToDateID)
- Filter: PendingClosureStatusID ≠ 1 (excludes "Normal"/"None" status)
- Filter: IsValidCustomer = 1
- One row per CID — DISTINCT guaranteed by ROW_NUMBER logic in #pendingClosure

### 2.2 Most Recent Non-Normal Status

**What**: For each customer, picks the most recently entered non-Normal closure status.  
**Columns Involved**: PendingClosureStatusName, PendingClosureChangeDateID, PendingClosureChangeDate  
**Rules**:
- Step 1 (#changePendingClosure): Gets the FIRST occurrence (earliest DateRangeID) of each unique (RealCID, PendingClosureStatusName) pair from Fact_SnapshotCustomer history
- Step 2 (#pendingClosure): Among those first-occurrences, picks the one with the MOST RECENT DateID (DESC) where PendingClosureStatusID ≠ 1
- Result: PendingClosureChangeDateID = YYYYMMDD of when customer first entered their current closure status
- PendingClosureChangeDate = FullDate from Dim_Date (calendar date from DateKey)

### 2.3 Financial Summary from BI_DB_CID_DailyPanel_FullData

**What**: Appends all-time financial metrics for each customer as of the run date.  
**Columns Involved**: TotalDeposits, TotalCashouts, PnL_Total, Equity, TotalCoFee, Revenue_Total  
**Rules**:
- INNER JOIN on BI_DB_CID_DailyPanel_FullData WHERE CID=RealCID AND DateID=@ddINT
- Only customers present in BI_DB_CID_DailyPanel_FullData for @ddINT are included — if a customer is in closure status but not in DailyPanel for that date, they are excluded from the output

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution — no hash advantage. CLUSTERED INDEX (Date ASC) — however, since all rows have the same Date (TRUNCATE+INSERT daily), the clustered index provides no filtering benefit. Range queries by CID require full scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All customers approved for closure | `WHERE PendingClosureStatusName = 'Approved for Closure'` |
| High-equity customers in closure process | `ORDER BY Equity DESC` |
| Closure customers by regulation | `GROUP BY Regulation ORDER BY COUNT(*) DESC` |
| Customers who entered closure recently | `ORDER BY PendingClosureChangeDateID DESC` |
| Revenue impact of closing accounts | `SELECT SUM(Revenue_Total) FROM BI_DB_AccountClosure WHERE PendingClosureStatusName = 'Approved for Closure'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `CID = RealCID` | Additional customer attributes (email, name, etc.) |
| BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes | `CID = CID` | Player status change history for context |
| BI_DB_dbo.BI_DB_CID_DailyPanel_FullData | `CID = CID AND DateID = DateID` | Additional financial detail beyond the summary columns |

### 3.4 Gotchas

- **Single date only** — TRUNCATE+INSERT daily. No historical data. All rows have the same Date value; querying by Date is meaningless.
- **Fact_SnapshotCustomer INNER JOIN** — customers in closure status but absent from BI_DB_CID_DailyPanel_FullData for the run DateID are excluded from the table. This means some closure-status customers may be missing.
- **PendingClosureChangeDateID is the FIRST occurrence** — not the most recent status change. A customer who toggled between statuses has the date of first entry into their current status, not their most recent transition.
- **Dim_Regulation joined on dr.ID** — unlike most BI_DB SPs which join on `dr.DWHRegulationID`, this SP uses `dr.ID`. Verify the join column is correct if regulation values look unexpected.
- **Financial columns are decimal(38,4) / decimal(32,8)** — high-precision decimal. Aggregations may overflow in some SQL environments.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production wiki (Customer.CustomerStatic). Origin source is authoritative. |
| Tier 2 | Derived from SP code analysis or DWH transformation (join-enriched, computed, hardcoded). |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | Date | date | YES | Run date parameter (@dd) — the date for which this snapshot was generated. All rows have the same value in a given daily load. (Tier 2 — SP_AccountClosure) |
| 3 | DateID | int | YES | Run date as YYYYMMDD integer: CAST(CONVERT(VARCHAR(8), @dd, 112) AS INT). Matches DWH date key conventions. (Tier 2 — SP_AccountClosure) |
| 4 | Tier | varchar(50) | YES | Customer loyalty tier (PlayerLevel) from Dim_PlayerLevel. Values: Bronze (97%), Silver (1.2%), Gold (1.0%), Platinum (0.4%), Platinum Plus (0.3%), Diamond (<0.1%). (Tier 2 — SP_AccountClosure) |
| 5 | PendingClosureStatusName | varchar(50) | YES | Current account closure status for this customer. Values: Approved for Closure (963,128 ≈ 99.8%), Suggested for Closure (2,045 ≈ 0.2%). Excludes PendingClosureStatusID=1 (Normal). (Tier 2 — SP_AccountClosure) |
| 6 | PendingClosureChangeDateID | int | YES | Date (YYYYMMDD int) when the customer FIRST entered their current closure status. Derived from earliest DateRangeID in Fact_SnapshotCustomer history for this (CID, PendingClosureStatusName) pair. (Tier 2 — SP_AccountClosure) |
| 7 | PendingClosureChangeDate | date | YES | Full calendar date equivalent of PendingClosureChangeDateID. Resolved via Dim_Date.FullDate JOIN on DateKey. (Tier 2 — SP_AccountClosure) |
| 8 | Regulation | varchar(50) | YES | Regulatory jurisdiction from Dim_Regulation. Values: CySEC (64%), FCA (15%), ASIC & GAML (10%), ASIC (3.3%), FinCEN+FINRA (3.3%), FSA Seychelles (2.6%), FinCEN (1.3%), FSRA (0.8%), NFA, MAS, FINRAONLY, BVI, eToroUS (<0.1% each). (Tier 2 — SP_AccountClosure) |
| 9 | Country | varchar(50) | YES | Customer country of registration from Dim_Country. Resolved from CountryID in Fact_SnapshotCustomer at run date. (Tier 2 — SP_AccountClosure) |
| 10 | TotalDeposits | decimal(32,8) | YES | Customer's total approved deposits (USD, all time) from BI_DB_CID_DailyPanel_FullData at run DateID. (Tier 2 — SP_AccountClosure) |
| 11 | TotalCashouts | decimal(32,8) | YES | Customer's total approved cashouts (USD, all time) from BI_DB_CID_DailyPanel_FullData at run DateID. (Tier 2 — SP_AccountClosure) |
| 12 | PnL_Total | decimal(38,4) | YES | Customer's total realized P&L (USD, all time) from BI_DB_CID_DailyPanel_FullData at run DateID. (Tier 2 — SP_AccountClosure) |
| 13 | Equity | decimal(23,4) | YES | Customer's current equity balance (USD) from BI_DB_CID_DailyPanel_FullData at run DateID. (Tier 2 — SP_AccountClosure) |
| 14 | TotalCoFee | money | YES | Customer's total copy-order (CO) fee charged (USD, all time) from BI_DB_CID_DailyPanel_FullData at run DateID. (Tier 2 — SP_AccountClosure) |
| 15 | Revenue_Total | decimal(38,4) | YES | Customer's total revenue generated for eToro (USD, all time) from BI_DB_CID_DailyPanel_FullData at run DateID. (Tier 2 — SP_AccountClosure) |
| 16 | UpdateDate | datetime | YES | ETL metadata: GETDATE() at SP execution time. Same value for all rows in a given daily run. (Tier 2 — SP_AccountClosure) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| CID | Customer.CustomerStatic | CID | Via Fact_SnapshotCustomer.RealCID relay |
| PendingClosureStatusName | DWH_dbo.Dim_PendingClosureStatus | PendingClosureStatusName | Most recent non-Normal status (ROW_NUMBER logic) |
| PendingClosureChangeDateID | DWH_dbo.Fact_SnapshotCustomer | DateRangeID | First occurrence DateID for current status |
| Tier | DWH_dbo.Dim_PlayerLevel | Name | JOIN on PlayerLevelID |
| Regulation | DWH_dbo.Dim_Regulation | Name | JOIN on dr.ID = RegulationID |
| Country | DWH_dbo.Dim_Country | Name | JOIN on CountryID |
| TotalDeposits, TotalCashouts, PnL_Total, Equity, TotalCoFee, Revenue_Total | BI_DB_dbo.BI_DB_CID_DailyPanel_FullData | Same names | INNER JOIN (CID + DateID) |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer
  [Filter: PendingClosureStatusID != 1, IsValidCustomer=1, DateRange covers @dd]
  |
  +-- ROW_NUMBER history logic → first occurrence of each status per CID
  +-- ROW_NUMBER → most recent non-Normal status per CID (#pendingClosure)
  +
DWH_dbo.Dim_PlayerLevel + Dim_Regulation + Dim_Country + Dim_PendingClosureStatus + Dim_Date
  +
BI_DB_dbo.BI_DB_CID_DailyPanel_FullData (financial snapshot at @dd)
  |-- SP_AccountClosure @dd (TRUNCATE+INSERT daily, SB_Daily, Priority 20) --|
  v
BI_DB_dbo.BI_DB_AccountClosure (965,173 rows, ROUND_ROBIN CLUSTERED(Date))
  |-- _Not_Migrated (no UC target) --|
```

---

## 6. Relationships

### 6.1 References To (this table reads from)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID, closure status, tier, country | DWH_dbo.Fact_SnapshotCustomer | Customer daily snapshots — primary data source |
| Tier | DWH_dbo.Dim_PlayerLevel | Loyalty tier name |
| Regulation | DWH_dbo.Dim_Regulation | Regulatory jurisdiction name |
| Country | DWH_dbo.Dim_Country | Country of registration |
| PendingClosureStatusName | DWH_dbo.Dim_PendingClosureStatus | Closure status lookup |
| PendingClosureChangeDate | DWH_dbo.Dim_Date | Full date from date key |
| Financial metrics | BI_DB_dbo.BI_DB_CID_DailyPanel_FullData | All-time financial summary per CID |

### 6.2 Referenced By (other objects read from this table)

No stored procedures or views in the SSDT repo reference this table. It is a terminal report table used directly by the CS team.

---

## 7. Sample Queries

### Account Closure Priority Queue (High-Equity First)

```sql
-- CS queue: Approved for Closure customers sorted by equity descending
SELECT
    CID,
    PendingClosureStatusName,
    PendingClosureChangeDate,
    Tier,
    Regulation,
    Country,
    Equity,
    TotalDeposits,
    TotalCashouts,
    Revenue_Total
FROM [BI_DB_dbo].[BI_DB_AccountClosure]
WHERE PendingClosureStatusName = 'Approved for Closure'
ORDER BY Equity DESC;
```

### Closure Backlog by Regulation and Status Change Date

```sql
-- Distribution of pending closure accounts by regulation and year they were flagged
SELECT
    Regulation,
    YEAR(PendingClosureChangeDate) AS YearFlagged,
    COUNT(*) AS CustomerCount,
    SUM(Equity) AS TotalEquityAtRisk
FROM [BI_DB_dbo].[BI_DB_AccountClosure]
GROUP BY Regulation, YEAR(PendingClosureChangeDate)
ORDER BY Regulation, YearFlagged;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources queried. Table was created by Shir Yablon (2022-03-02) for CS account closure workflow; migrated to Synapse by Tom B (2023-04-24). Business context is fully derivable from SP code.

---

*Generated: 2026-04-21 | Quality: 8.5/10 | Phases: 13/14*  
*Tiers: 1 T1, 15 T2, 0 T3, 0 T4, 0 T5 | Elements: 16/16, Logic: 8/10, Sources: 8/10*  
*Object: BI_DB_dbo.BI_DB_AccountClosure | Type: Table | Production Source: DWH_dbo.Fact_SnapshotCustomer (via SP_AccountClosure)*
