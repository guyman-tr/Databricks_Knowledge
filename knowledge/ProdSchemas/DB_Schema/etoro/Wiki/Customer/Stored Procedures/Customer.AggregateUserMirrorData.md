# Customer.AggregateUserMirrorData

> Aggregates copy-trading (mirror) activity for a given time window into the BackOffice summary tables BackOffice.MirrorComulative and BackOffice.MirrorUniqueTraders.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Output: @LastDate (max mirror event timestamp processed) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.AggregateUserMirrorData` is the BackOffice aggregation job for eToro's CopyTrader ("mirror") feature. When a customer copies another trader, every open/close/adjust event is recorded in `History.Mirror`. This procedure reads those historical events for a given time slice and rolls them up into two BackOffice summary tables: `BackOffice.MirrorComulative` (one row per copier with lifetime and current copy statistics) and `BackOffice.MirrorUniqueTraders` (a de-duplicated set of every copier-to-trader pairing ever created).

The procedure exists to keep the BackOffice summary tables current without requiring ad-hoc aggregation queries across the large `History.Mirror` and `Trade.Mirror` tables at report time. BackOffice dashboards and reports query the pre-aggregated data from `MirrorComulative` instead of computing sums and counts on the fly.

This procedure is designed to be called repeatedly by a scheduled job (SQL Agent or external scheduler), passing a sliding @Occurred window. Each run processes the events since the last run. @LastDate is set to MAX(Occurred) from `Trade.Mirror` at the start of each run and returned to the caller so the next invocation can use it as the new @Occurred boundary.

---

## 2. Business Logic

### 2.1 Time Window Scoping via #ActiveCopiersInRelevantTime

**What**: All updates are scoped to customers who had mirror activity within the [@Occurred, @LastDate) window, preventing full-table updates on every run.

**Columns/Parameters Involved**: `@Occurred`, `@LastDate`, `History.Mirror.Occurred`, `History.Mirror.CID`

**Rules**:
- @LastDate is computed as MAX(Occurred) from `Trade.Mirror` (live current state) at procedure start
- Only CIDs with `History.Mirror.Occurred >= @Occurred AND Occurred < @LastDate` are included
- A temp table `#ActiveCopiersInRelevantTime(CID)` with a non-clustered index is built first, then JOINed in every subsequent statement - ensuring only affected customers are updated/inserted
- This design prevents re-processing customers who had no activity in the window

**Diagram**:
```
Time axis:
  [prior run @Occurred] -----> [this run @Occurred] ----> [@LastDate = MAX(Trade.Mirror.Occurred)]
                                      |                              |
                                      |----  #ActiveCopiers  -------|
                                            (History.Mirror CIDs)
```

### 2.2 MirrorComulative Update Sequence (5 steps)

**What**: The procedure performs multiple UPDATE and INSERT statements in order to correctly handle both existing copiers and brand-new copiers.

**Columns/Parameters Involved**: `BackOffice.MirrorComulative.*`, `History.Mirror.MirrorOperationID`, `History.Mirror.Amount`

**Rules**:
- **Step 1 (UPDATE existing - DateOfLastCopy/Totals)**: Runs BEFORE new copier INSERT to avoid processing new rows twice. Updates `DateOfLastCopy` (max Occurred where MirrorOperationID=1), `NumOfTotalCopies` (COUNT DISTINCT MirrorID), `TotalInvestedAmount` (SUM Amount where MirrorOperationID IN (1,3) AND Amount > 0)
- **Step 2 (INSERT BackOffice.MirrorUniqueTraders)**: Adds new (CID, ParentCID) pairs not yet in the table
- **Step 3 (INSERT BackOffice.MirrorComulative)**: Inserts rows for copiers not yet in MirrorComulative, with initial zero values for CurrentInvestedAmount, NumOfCurrentCopies, NumOfUniqueCopiedTraders (populated in subsequent steps)
- **Step 4 (UPDATE - NumOfUniqueCopiedTraders)**: Re-aggregates from BackOffice.MirrorUniqueTraders after the new pairs have been inserted
- **Step 5 (UPDATE - CurrentInvestedAmount/NumOfCurrentCopies)**: Reads from `Trade.Mirror` (live positions, not history) to compute current state

**Diagram**:
```
Step 1: UPDATE existing MirrorComulative rows (totals/last-copy)
Step 2: INSERT new rows into MirrorUniqueTraders
Step 3: INSERT new copiers into MirrorComulative (initial zeros)
Step 4: UPDATE MirrorComulative.NumOfUniqueCopiedTraders (from MirrorUniqueTraders)
Step 5: UPDATE MirrorComulative.CurrentInvestedAmount + NumOfCurrentCopies (from Trade.Mirror)
```

### 2.3 MirrorOperationID Semantics

**What**: Determines which mirror events count toward totals and which count toward the DateOfLastCopy.

**Columns/Parameters Involved**: `History.Mirror.MirrorOperationID`, `History.Mirror.Amount`

**Rules**:
- MirrorOperationID = 1: Copy start event. Used for DateOfLastCopy (the most recent copy start). Also counted in TotalInvestedAmount if Amount > 0
- MirrorOperationID = 3: Also counted toward TotalInvestedAmount (reinvestment or copy amount adjustment)
- Only MirrorOperationID IN (1, 3) with ISNULL(Amount, 0) > 0 contribute to TotalInvestedAmount
- DateOfLastCopy uses `MAX(CASE MirrorOperationID WHEN 1 THEN Occurred ELSE '19900101' END)` - effectively ignoring non-type-1 events for the last-copy date

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Occurred | DATETIME | NO | - | CODE-BACKED | Start of the time window to process. The caller passes the @LastDate returned by the previous run. Events in History.Mirror with Occurred >= @Occurred AND < @LastDate are included. |
| 2 | @LastDate | DATETIME OUTPUT | YES | NULL | CODE-BACKED | Output parameter. Set inside the procedure to MAX(Occurred) from Trade.Mirror before processing begins. Returns the upper bound of the window just processed - the caller should use this as @Occurred for the next invocation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Occurred / @LastDate window | History.Mirror | Read | Source of historical copy events - provides the CID, ParentCID, MirrorOperationID, Amount, Occurred for all mirror operations |
| @LastDate boundary | Trade.Mirror | Read | Source of current live mirror positions - used to compute CurrentInvestedAmount and NumOfCurrentCopies |
| Copier lookup | BackOffice.MirrorComulative | Read + Write | Primary output target - updated or inserted for every active copier in the window |
| Pair tracking | BackOffice.MirrorUniqueTraders | Read + Write | Secondary output target - receives new (CID, ParentCID) pairs not previously recorded |
| OriginalCID / OriginalProviderID | Customer.Customer | Read | Joined on CID to retrieve OriginalCID and OriginalProviderID when inserting new rows into MirrorComulative |

### 5.2 Referenced By (other objects point to this)

Likely called by a SQL Agent scheduled job or external BackOffice worker process. No SQL SP callers found in the Customer schema. `UsersPermissions/PROD_BIadmins.sql` grants EXECUTE permission (indicating BackOffice BI admin accounts run this).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.AggregateUserMirrorData (procedure)
├── History.Mirror (table)
├── Trade.Mirror (table)
├── BackOffice.MirrorComulative (table)
├── BackOffice.MirrorUniqueTraders (table)
└── Customer.Customer (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Mirror | Table | Source of historical copy events. CIDs for the active window are selected from here; also JOINed in Copyers CTEs for DateOfFirstCopy, DateOfLastCopy, NumOfTotalCopies, TotalInvestedAmount |
| Trade.Mirror | Table | Source of live/current open mirror positions. Used to set @LastDate (MAX Occurred) and to compute CurrentInvestedAmount + NumOfCurrentCopies in Step 5 |
| BackOffice.MirrorComulative | Table | Primary output. Existing rows are updated (Steps 1, 4, 5); new rows are inserted (Step 3) |
| BackOffice.MirrorUniqueTraders | Table | Secondary output. New (CID, ParentCID) pairs are inserted (Step 2); aggregated in Step 4 for NumOfUniqueCopiedTraders |
| Customer.Customer | View | JOINed on CID during new copier INSERT to retrieve OriginalCID and OriginalProviderID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Agent job / BackOffice scheduler | External | Calls this procedure on a scheduled basis, passing the @LastDate from the previous run as @Occurred |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

Temp table `#ActiveCopiersInRelevantTime(CID)` is created with a NONCLUSTERED INDEX `ACIRtemp` on `CID` for efficient JOIN performance in subsequent statements.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute for a specific time window

```sql
DECLARE @LastDate DATETIME
EXEC [Customer].[AggregateUserMirrorData]
    @Occurred = '2026-03-01 00:00:00',
    @LastDate = @LastDate OUTPUT
SELECT @LastDate AS ProcessedUpTo
```

### 8.2 Check aggregated copy stats for a customer after the job runs

```sql
SELECT
    mc.CID,
    mc.DateOfFirstCopy,
    mc.DateOfLastCopy,
    mc.NumOfCurrentCopies,
    mc.NumOfTotalCopies,
    mc.NumOfUniqueCopiedTraders,
    mc.CurrentInvestedAmount,
    mc.TotalInvestedAmount,
    mc.UpdateTime
FROM BackOffice.MirrorComulative mc WITH (NOLOCK)
WHERE mc.CID = 12345
```

### 8.3 Find unique traders a customer has ever copied

```sql
SELECT
    ut.CID,
    ut.ParentCID,
    ut.RunTime
FROM BackOffice.MirrorUniqueTraders ut WITH (NOLOCK)
WHERE ut.CID = 12345
ORDER BY ut.RunTime
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 9B-skipped, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.AggregateUserMirrorData | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.AggregateUserMirrorData.sql*
