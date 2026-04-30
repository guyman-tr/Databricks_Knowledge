# Trade.MovePositionsHedgeServers

> Atomically reassigns a batch of open positions from one hedge server to another: updates Trade.PositionTbl, adjusts Trade.ExposuresForAllHedgeServers for old and new servers, logs each move to PositionsHedgeServerChangeLog, and marks the operation summary as complete.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionsToChange TVP + @OperationSummaryID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.MovePositionsHedgeServers implements the core position-rerouting transaction in eToro's hedging infrastructure. When the system needs to rebalance positions across hedge servers (due to server capacity, routing rule changes, or operational requirements), it calls this procedure with a batch of (PositionID, NewHedgeServerID, NewRootHedgeServerID, RuleID) tuples.

The procedure performs four coordinated writes in a single transaction: (1) updates Trade.PositionTbl to point each position at its new hedge server, (2) subtracts the moved positions' lot exposures from the old hedge servers in Trade.ExposuresForAllHedgeServers, (3) adds them to the new hedge servers via MERGE (insert or update), and (4) writes a per-position audit row to Trade.PositionsHedgeServerChangeLog tied to the @OperationSummaryID batch identifier.

Only open positions (StatusID=1) that have an actual server change (new != current) are processed; positions already on the target server are silently skipped. The partition-aware join (PositionID%50=PartitionCol) ensures SQL Server selects the correct partition on PositionTbl for all DML.

Data flows: called by PROD_BIadmins and RerouteService-User (hedge server reroute service). The companion procedure Trade.MovePositionsHedgeServersByRerouteService (same logic, different caller permissions) was also observed referencing these tables.

---

## 2. Business Logic

### 2.1 Open-Position Eligibility Filter

**What**: Loads only open, actually-changing positions into a temp table before any writes.

**Columns/Parameters Involved**: `Trade.PositionTbl.StatusID`, `Trade.PositionTbl.HedgeServerID`, `Trade.PositionTbl.RootHedgeServerID`, `@PositionsToChange.NewHedgeServerID`, `@PositionsToChange.NewRootHedgeServerID`

**Rules**:
- StatusID=1 (Open): closed/cancelled positions are excluded.
- Change check: (P.NewHedgeServerID <> TP.HedgeServerID OR P.NewRootHedgeServerID <> ISNULL(TP.RootHedgeServerID,-1)) - positions already on the target server are skipped.
- Partition join: PositionID%50=TP.PartitionCol - required for partition-pruned access on Trade.PositionTbl.
- Result captured in temp table #P with old and new server IDs for both position and root assignments.

### 2.2 PositionTbl Hedge Server Update

**What**: Reassigns each eligible position to its new hedge server and root hedge server.

**Columns/Parameters Involved**: `Trade.PositionTbl.HedgeServerID`, `Trade.PositionTbl.RootHedgeServerID`

**Rules**:
- UPDATE Trade.PositionTbl JOIN #P: sets HedgeServerID=NewHedgeServerID, RootHedgeServerID=NewRootHedgeServerID.
- @NumPositionsChanged OUTPUT accumulates: += @@ROWCOUNT after this UPDATE (cumulative across multiple calls if needed).
- Note: the UPDATE's OUTPUT INTO PositionsHedgeServerChangeLog is commented out in the DDL - the audit INSERT is performed separately (Step 2.4).

### 2.3 Exposure Ledger Rebalancing

**What**: Adjusts the exposure tracking table by subtracting moved lots from old servers and adding to new servers.

**Columns/Parameters Involved**: `Trade.ExposuresForAllHedgeServers.OpenedBuy`, `Trade.ExposuresForAllHedgeServers.OpenedSell`, `Trade.ExposuresForAllHedgeServers.HedgeServerID`

**Rules**:
- Step 1 - subtract from old: UPDATE Trade.ExposuresForAllHedgeServers joining aggregated #P (grouped by CID, ProviderID, InstrumentID, OldHedgeServerID): OpenedBuy -= SUM(buy lots), OpenedSell -= SUM(sell lots).
- Step 2 - add to new: MERGE Trade.ExposuresForAllHedgeServers with aggregated #P (grouped by NewHedgeServerID):
  - WHEN NOT MATCHED (new server has no row for this CID/Provider/Instrument): INSERT new row.
  - WHEN MATCHED: UPDATE OpenedBuy += buy lots, OpenedSell += sell lots.
- Exposure is maintained in lot-count units (LotCountDecimal).

### 2.4 Audit and Summary Logging

**What**: Records each position move and marks the batch operation as complete.

**Columns/Parameters Involved**: `Trade.PositionsHedgeServerChangeLog`, `Trade.PositionsHedgeServerChangeSummaryLog.EndTime`, `@OperationSummaryID`

**Rules**:
- INSERT Trade.PositionsHedgeServerChangeLog: one row per position in #P with PositionID, ADM_DATE=GETDATE(), FromHedgeServerID, ToHedgeServerID, FromRootHedgeServerID, ToRootHedgeServerID, RuleID, OperationSummaryID.
- UPDATE Trade.PositionsHedgeServerChangeSummaryLog SET EndTime=GETUTCDATE() WHERE ID=@OperationSummaryID: marks the batch as finished.
- All four writes (PositionTbl UPDATE, two ExposuresForAllHedgeServers changes, ChangeLog INSERT, SummaryLog UPDATE) are inside a single BEGIN TRAN.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionsToChange | HSPositionChange (READONLY TVP) | NO | - | CODE-BACKED | Batch of position reassignments. Each row: PositionID (bigint), NewHedgeServerID (int), NewRootHedgeServerID (int), RuleID (int). READONLY TVP of type HSPositionChange. |
| 2 | @OperationSummaryID | int | NO | - | CODE-BACKED | ID of the parent batch operation record in Trade.PositionsHedgeServerChangeSummaryLog. Used to link audit log rows and to mark the summary as EndTime=GETUTCDATE() on completion. |
| 3 | @NumPositionsChanged | INT | YES | 0 | CODE-BACKED | OUTPUT parameter. Accumulates the count of positions actually updated (open + changed only). Caller uses this to verify the batch result. Incremented by @@ROWCOUNT from the PositionTbl UPDATE. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionsToChange | HSPositionChange | UDT Reference | TVP type for input batch |
| PositionID | Trade.PositionTbl | Read/Write | Joins for eligibility (StatusID=1, partition-aware); UPDATEs HedgeServerID and RootHedgeServerID |
| CID, ProviderID, InstrumentID, HedgeServerID | Trade.ExposuresForAllHedgeServers | Write | UPDATEs old-server exposures; MERGEs new-server exposures |
| PositionID, RuleID | Trade.PositionsHedgeServerChangeLog | Write | INSERTs per-position audit row |
| @OperationSummaryID | Trade.PositionsHedgeServerChangeSummaryLog | Write | UPDATEs EndTime when batch completes |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No SP callers found in Trade schema) | - | - | Called by PROD_BIadmins and the hedge server reroute service (RerouteService-User permission). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.MovePositionsHedgeServers (procedure)
├── HSPositionChange (TVP type)
├── Trade.PositionTbl (table)
├── Trade.ExposuresForAllHedgeServers (table)
├── Trade.PositionsHedgeServerChangeLog (table)
└── Trade.PositionsHedgeServerChangeSummaryLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| HSPositionChange | User Defined Type | TVP parameter type |
| Trade.PositionTbl | Table | READ for eligibility filter; UPDATEd for HedgeServerID/RootHedgeServerID |
| Trade.ExposuresForAllHedgeServers | Table | UPDATEd (subtract old) and MERGEd (add new) for exposure rebalancing |
| Trade.PositionsHedgeServerChangeLog | Table | INSERTed with per-position move audit record |
| Trade.PositionsHedgeServerChangeSummaryLog | Table | UPDATEd to set EndTime on completion |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No stored procedure dependents found) | - | Called externally by reroute/hedge management services. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Relies on Trade.PositionTbl's partition scheme (PositionID%50=PartitionCol) for partition-pruned access on all DML.

### 7.2 Constraints

N/A for stored procedure. Single BEGIN TRAN wrapping all four DML operations. CATCH block: ROLLBACK if @@TRANCOUNT=1, COMMIT if @@TRANCOUNT>1 (nested transaction support), THROW to caller.

---

## 8. Sample Queries

### 8.1 Check hedge server assignment for a position

```sql
SELECT PT.PositionID, PT.HedgeServerID, PT.RootHedgeServerID, PT.StatusID
FROM Trade.PositionTbl AS PT WITH (NOLOCK)
WHERE PT.PositionID = <PositionID>
  AND PT.PositionID % 50 = PT.PartitionCol;
```

### 8.2 View positions moved in a specific operation batch

```sql
SELECT PCL.PositionID, PCL.FromHedgeServerID, PCL.ToHedgeServerID,
       PCL.FromRootHedgeServerID, PCL.ToRootHedgeServerID,
       PCL.RuleID, PCL.ADM_DATE
FROM Trade.PositionsHedgeServerChangeLog AS PCL WITH (NOLOCK)
WHERE PCL.OperationSummaryID = <OperationSummaryID>
ORDER BY PCL.ADM_DATE;
```

### 8.3 Check exposure summary for a hedge server

```sql
SELECT TE.CID, TE.ProviderID, TE.InstrumentID, TE.HedgeServerID,
       TE.OpenedBuy, TE.OpenedSell
FROM Trade.ExposuresForAllHedgeServers AS TE WITH (NOLOCK)
WHERE TE.HedgeServerID = <HedgeServerID>
ORDER BY TE.OpenedBuy + TE.OpenedSell DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SP callers | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.MovePositionsHedgeServers | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.MovePositionsHedgeServers.sql*
