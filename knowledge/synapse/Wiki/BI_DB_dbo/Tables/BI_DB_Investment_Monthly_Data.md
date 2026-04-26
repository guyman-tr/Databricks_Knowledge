# BI_DB_dbo.BI_DB_Investment_Monthly_Data

> 2.11M-row monthly copy-trading investment performance analysis comparing copier (CID) and copied person (ParentCID) position equity, PnL, and instrument replication for every active mirror relationship. Covers 7 position lifecycle scenarios (full-month, opened during month, closed during month, opened-and-closed, last-day, same-day, partial close/detach). CopyType: PI (67%), Portfolio (31%), Non-PI (2%). Date range: Jan 2026 – Mar 2026 (3 months). Monthly EOM-only via SP_Investment_Monthly_Data. Referenced Google Sheet: Investment Monthly Data tracker.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Copy-Trading Analytics — Monthly) |
| **Production Source** | Derived — multi-source aggregate from Dim_Mirror, Dim_Position, BI_DB_PositionPnL, Fact_SnapshotCustomer by SP_Investment_Monthly_Data |
| **Refresh** | Monthly (EOM only; SP guards with `IF @date = @LastDayOfMonth`); delete-insert by Month |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **OpsDB Priority** | 0 |
| **OpsDB Process** | SB_Daily, ProcessType 1 (SQL) |
| **Author** | SP_Investment_Monthly_Data (reference: Google Sheets tracker) |

---

## 1. Business Meaning

`BI_DB_Investment_Monthly_Data` is a **monthly copy-trading investment performance report** at the mirror-relationship level. For each active copy relationship (CID copying ParentCID via MirrorID), it computes the copier's equity performance and compares it against the copied person's portfolio performance for the same month.

The table holds 2.11M rows across 3 monthly periods (Jan–Mar 2026). Each row represents one CID × ParentCID × MirrorID combination for a specific month. The analysis is split by CopyType: PI (Popular Investor, 67%), Portfolio (Smart Portfolios, 31%), and Non-PI (non-PI copiers, 2%).

### Position Lifecycle Coverage

The SP handles 7 distinct position lifecycle scenarios for accurate monthly PnL calculation:

1. **Full-month positions**: Open before month start, still open at month end
2. **Opened during month**: Opened mid-month, still open at month end
3. **Opened and closed during month**: Both opened and closed within the month
4. **Closed during month**: Open before month start, closed during month
5. **Last-day positions**: Opened on the last day of the month
6. **Same-day positions**: Opened and closed on the same day
7. **Partial close + detach**: Partial close child positions and detached copies

AirDrop positions are excluded from both copier and copied sides.

### Equity Calculation

- **StartEquity**: Position value at month start = Amount + PositionPnL (from BI_DB_PositionPnL at start date) or Amount alone for positions opened during the month
- **FinalEquity**: Position value at month end = Amount + PositionPnL (from BI_DB_PositionPnL at end date) or Amount + NetProfit for closed positions
- **%PnL**: ((FinalEquity − StartEquity) / StartEquity) × 100

---

## 2. Business Logic

### 2.1 Copier Population

**What**: Identifies valid depositor CIDs who are actively copying at month start.
**Columns Involved**: CID
**Rules**:
- From Fact_SnapshotCustomer: IsValidCustomer=1 AND IsDepositor=1
- Date range check via Dim_Range: active at month start

### 2.2 CopyType Classification

**What**: Classifies the copy relationship into PI, Portfolio, or Non-PI.
**Columns Involved**: CopyType, Type
**Rules**:
- AccountTypeID = 9 → 'Portfolio', Type = Dim_FundType.FundTypeName (e.g., Market, Thematic)
- GuruStatusID >= 2 → 'PI', Type = Dim_GuruStatus.GuruStatusName (e.g., Champion, Elite, Rising Star)
- GuruStatusID < 2 → 'Non-PI', Type = 'Other'

### 2.3 Instrument Replication Ratio

**What**: Measures how many instruments the copier traded vs how many the copied person traded.
**Columns Involved**: Num_CopyInstruments, Num_CopiedInstruments, %ofCopiedInstruments
**Rules**:
- Num_CopyInstruments = COUNT(DISTINCT InstrumentID) in copier's positions for this mirror
- Num_CopiedInstruments = COUNT(InstrumentID) in copied person's positions
- %ofCopiedInstruments = (Num_CopyInstruments / Num_CopiedInstruments) × 100

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP. Medium table (2.11M rows). Filter on Year_Month or Month for date selection.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Average copier vs copied PnL by CopyType | `SELECT CopyType, AVG([%PnL_copy]), AVG([%PnL_copied]) GROUP BY CopyType WHERE Year_Month = 202603` |
| Top PIs by copier count | `SELECT ParentUserName, COUNT(DISTINCT CID) FROM ... WHERE CopyType='PI' GROUP BY ParentUserName` |
| Instrument replication quality | `WHERE [%ofCopiedInstruments] < 50 — copiers replicating <50% of instruments` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Mirror | MirrorID | Full mirror relationship details |
| DWH_dbo.Dim_Customer | CID = RealCID or ParentCID = RealCID | Customer details |

### 3.4 Gotchas

- **Column names with special characters**: `[%PnL_copy]`, `[%PnL_copied]`, `[%ofCopiedInstruments]` require square brackets
- **Month vs Year_Month**: `Month` is a DATE (first of month), `Year_Month` is an INT (YYYYMM). Use either for filtering
- **EOM only**: Only 3 months of data currently (Jan-Mar 2026). Data appears only after month-end processing
- **AirDrop exclusion**: Crypto AirDrop positions are excluded — PnL numbers do not include airdrop gains
- **20 columns, not 17**: DDL has 20 columns including Year_Month, Month, and UpdateDate

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
| 1 | Year_Month | int | NO | Year and month in YYYYMM format (e.g., 202603). Computed as YEAR(@date)*100+MONTH(@date). Used for filtering and partitioning. (Tier 2 — SP_Investment_Monthly_Data) |
| 2 | Month | date | NO | First day of the reporting month (e.g., 2026-03-01). Computed as DATEFROMPARTS(YEAR,MONTH,1). (Tier 2 — SP_Investment_Monthly_Data) |
| 3 | CID | int | NO | Copier customer ID — the user who allocates money to copy the ParentCID. (Tier 2 — SP_Investment_Monthly_Data, from Dim_Mirror) |
| 4 | ParentUserName | varchar(max) | YES | Username of the copied person (Popular Investor or Smart Portfolio). From Dim_Customer.UserName via ParentCID. (Tier 2 — SP_Investment_Monthly_Data, from Dim_Customer) |
| 5 | ParentCID | int | NO | Copied person's customer ID — the PI or Smart Portfolio account being copied. (Tier 2 — SP_Investment_Monthly_Data, from Dim_Mirror) |
| 6 | MirrorID | int | YES | Copy relationship identifier from Dim_Mirror. Unique per CID-ParentCID copy instance. (Tier 2 — SP_Investment_Monthly_Data, from Dim_Mirror) |
| 7 | StartCopy | int | YES | Date the copy relationship started, in YYYYMMDD int format. From Dim_Mirror.OpenDateID. (Tier 2 — SP_Investment_Monthly_Data, from Dim_Mirror) |
| 8 | EndCopy | int | YES | Date the copy relationship ended, in YYYYMMDD int format. 0 = still active. From Dim_Mirror.CloseDateID. (Tier 2 — SP_Investment_Monthly_Data, from Dim_Mirror) |
| 9 | CopyType | varchar(100) | YES | Copy relationship classification: 'PI' (Popular Investor, GuruStatusID>=2), 'Portfolio' (AccountTypeID=9, Smart Portfolios), 'Non-PI' (GuruStatusID<2). (Tier 2 — SP_Investment_Monthly_Data) |
| 10 | Type | varchar(100) | YES | Sub-type within CopyType. For PI: GuruStatusName (Champion, Elite, Rising Star, etc.). For Portfolio: FundTypeName (Market, Thematic, etc.). For Non-PI: 'Other'. (Tier 2 — SP_Investment_Monthly_Data) |
| 11 | StartEquity_copy | float | YES | Copier's total position equity at the start of the month. SUM of (Amount + PositionPnL) across all copy positions for this mirror at month start. In USD. (Tier 2 — SP_Investment_Monthly_Data, from BI_DB_PositionPnL) |
| 12 | FinalEquity_copy | float | YES | Copier's total position equity at the end of the month. SUM of (Amount + PositionPnL) or (Amount + NetProfit) for closed positions. In USD. (Tier 2 — SP_Investment_Monthly_Data) |
| 13 | %PnL_copy | float | YES | Copier's percentage PnL for the month. ((FinalEquity_copy − StartEquity_copy) / StartEquity_copy) × 100. NULL if StartEquity is zero. (Tier 2 — SP_Investment_Monthly_Data) |
| 14 | StartEquity_copied | float | YES | Copied person's total position equity at the start of the month. Same calculation as copier but for the ParentCID's own positions. (Tier 2 — SP_Investment_Monthly_Data) |
| 15 | FinalEquity_copied | float | YES | Copied person's total position equity at the end of the month. (Tier 2 — SP_Investment_Monthly_Data) |
| 16 | %PnL_copied | float | YES | Copied person's percentage PnL for the month. ((FinalEquity_copied − StartEquity_copied) / StartEquity_copied) × 100. (Tier 2 — SP_Investment_Monthly_Data) |
| 17 | Num_CopyInstruments | int | YES | Count of distinct instruments in the copier's positions for this mirror during the month. (Tier 2 — SP_Investment_Monthly_Data, from Dim_Position) |
| 18 | Num_CopiedInstruments | int | YES | Count of instruments in the copied person's positions during the month. (Tier 2 — SP_Investment_Monthly_Data, from Dim_Position) |
| 19 | %ofCopiedInstruments | float | YES | Instrument replication ratio: (Num_CopyInstruments / Num_CopiedInstruments) × 100. Shows what percentage of the copied person's instruments the copier also traded. (Tier 2 — SP_Investment_Monthly_Data) |
| 20 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_Investment_Monthly_Data. Set to GETDATE(). (Tier 5 — SP_Investment_Monthly_Data) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| CID, ParentCID, MirrorID | DWH_dbo.Dim_Mirror | CID, ParentCID, MirrorID | Passthrough |
| ParentUserName | DWH_dbo.Dim_Customer | UserName | Via ParentCID JOIN |
| StartCopy, EndCopy | DWH_dbo.Dim_Mirror | OpenDateID, CloseDateID | Passthrough |
| CopyType, Type | Fact_SnapshotCustomer, Dim_GuruStatus, Dim_FundType | AccountTypeID, GuruStatusID, FundTypeName | CASE classification |
| Equity columns | BI_DB_PositionPnL + Dim_Position | Amount, PositionPnL, NetProfit | SUM across 7 lifecycle scenarios |
| Instrument counts | Dim_Position | InstrumentID | COUNT/COUNT DISTINCT |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Mirror (copy relationships)
  + DWH_dbo.Fact_SnapshotCustomer (valid depositors)
  + DWH_dbo.Dim_Position (copy + copied positions)
  + BI_DB_dbo.BI_DB_PositionPnL (daily position equity)
  + DWH_dbo.Dim_Customer (ParentUserName)
  + DWH_dbo.Dim_GuruStatus + Dim_Fund + Dim_FundType
    |-- SP_Investment_Monthly_Data @date (monthly EOM, delete-insert) --|
    |   7 lifecycle scenarios × 2 sides (copy + copied)                |
    |   UNION ALL → aggregate per CID×ParentCID×MirrorID              |
    |   JOIN copy aggregates to copied aggregates on ParentCID=CID     |
    v
BI_DB_dbo.BI_DB_Investment_Monthly_Data (2.11M rows, monthly)
  (Not in Generic Pipeline — _Not_Migrated to UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID, ParentCID, MirrorID | DWH_dbo.Dim_Mirror | Copy relationship source |
| CID, ParentCID | DWH_dbo.Dim_Customer | Customer details |
| Equity columns | BI_DB_dbo.BI_DB_PositionPnL | Daily position PnL source |
| Position data | DWH_dbo.Dim_Position | Position lifecycle |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Average Copier vs Copied PnL by CopyType

```sql
SELECT CopyType,
       AVG([%PnL_copy]) AS avg_copier_pnl,
       AVG([%PnL_copied]) AS avg_copied_pnl,
       COUNT(*) AS relationships
FROM [BI_DB_dbo].[BI_DB_Investment_Monthly_Data]
WHERE Year_Month = 202603
GROUP BY CopyType
```

### 7.2 Top Popular Investors by Copier Count

```sql
SELECT ParentUserName, ParentCID, Type,
       COUNT(DISTINCT CID) AS copier_count,
       AVG([%PnL_copied]) AS avg_pi_pnl
FROM [BI_DB_dbo].[BI_DB_Investment_Monthly_Data]
WHERE Year_Month = 202603 AND CopyType = 'PI'
GROUP BY ParentUserName, ParentCID, Type
ORDER BY copier_count DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search permission denied).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 0 T1, 19 T2, 0 T3, 0 T4, 1 T5 | Elements: 20/20, Logic: 9/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Investment_Monthly_Data | Type: Table | Production Source: Derived — multi-source copy-trading aggregate*
