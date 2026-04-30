# Trade.MovePositionsHedgeServersByRerouteService

> RerouteService variant of Trade.MovePositionsHedgeServers: reassigns open positions across hedge servers with a 3,000-position batch cap, an @UpdateRealPositionInDB dry-run flag, and a result set returning the processed position IDs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionsToChange TVP + @OperationSummaryID + @UpdateRealPositionInDB |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.MovePositionsHedgeServersByRerouteService is the RerouteService-facing variant of Trade.MovePositionsHedgeServers. It performs the same core operation - atomically reassigning open positions to new hedge servers and updating the exposure ledger - but adds three production-safety features:

1. **Batch cap**: Immediately returns -1 if the input TVP contains more than 3,000 positions, preventing runaway bulk moves.
2. **Dry-run mode** (@UpdateRealPositionInDB=0): Logs the intended changes to Trade.PositionsHedgeServerChangeLog and updates the summary log without actually modifying Trade.PositionTbl or Trade.ExposuresForAllHedgeServers. Allows the RerouteService to pre-validate a rerouting plan.
3. **Result set**: Returns the list of position IDs that were eligible (open + actually-changing) from the input batch, allowing the caller to reconcile which positions were processed.

RerouteService-User database login is specifically granted EXEC on this procedure (not on the original MovePositionsHedgeServers). The shared logic (partition-aware join, eligibility filter, exposure MERGE, audit log) is identical to the parent procedure.

---

## 2. Business Logic

### 2.1 Batch Size Guard

**What**: Rejects input batches exceeding 3,000 positions before any DML.

**Columns/Parameters Involved**: `@PositionsToChange` row count

**Rules**:
- Load @PositionsToChange into temp table #HSPositionChange.
- IF COUNT(*) > 3000: RETURN -1 immediately (no writes performed).
- This prevents the caller from accidentally submitting very large batches that could cause lock contention or long-running transactions.

### 2.2 Open-Position Eligibility Filter

**What**: Joins input batch against Trade.PositionTbl to identify open positions with actual server changes.

**Columns/Parameters Involved**: `Trade.PositionTbl.StatusID`, `Trade.PositionTbl.HedgeServerID`, `Trade.PositionTbl.RootHedgeServerID`

**Rules**:
- StatusID=1 (Open): closed positions excluded.
- Actual change required: NewHedgeServerID <> HedgeServerID OR NewRootHedgeServerID <> ISNULL(RootHedgeServerID,-1).
- Partition-aware join: PositionID%50=PartitionCol.
- Eligible rows loaded into #P (same structure as parent procedure).

### 2.3 Conditional Real-DB Updates (@UpdateRealPositionInDB flag)

**What**: The PositionTbl and ExposuresForAllHedgeServers writes are gated by @UpdateRealPositionInDB.

**Columns/Parameters Involved**: `@UpdateRealPositionInDB`, `Trade.PositionTbl.HedgeServerID`, `Trade.ExposuresForAllHedgeServers.OpenedBuy/OpenedSell`

**Rules**:
- @UpdateRealPositionInDB=1 (live mode): UPDATE PositionTbl + UPDATE ExposuresForAllHedgeServers (subtract old) + MERGE ExposuresForAllHedgeServers (add new) all execute.
- @UpdateRealPositionInDB=0 (dry-run mode): both IF blocks are skipped; only the ChangeLog INSERT and SummaryLog UPDATE run.
- Audit log INSERT and SummaryLog UPDATE always run regardless of @UpdateRealPositionInDB - the reroute service always records what it would have done.
- ADM_DATE uses GETUTCDATE() (vs GETDATE() in Trade.MovePositionsHedgeServers).

**Diagram**:
```
@UpdateRealPositionInDB:
  1 -> PositionTbl UPDATE + ExposuresForAllHedgeServers UPDATE + MERGE (live move)
  0 -> Audit INSERT + SummaryLog UPDATE only (dry-run - plan recorded, no positions moved)
```

### 2.4 Result Set Output

**What**: After the transaction commits, returns a result set of position IDs that were eligible and processed.

**Columns/Parameters Involved**: `#HSPositionChange.PositionID`, `#P.PositionID`

**Rules**:
- SELECT P.PositionID FROM #HSPositionChange JOIN #P ON PositionID: returns only positions that were in both the input AND the eligible set.
- Positions skipped (already on target server, closed, or not found) are absent from the result set.
- Caller uses this to verify which positions were actually acted on vs. sent.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionsToChange | HSPositionChange (READONLY TVP) | NO | - | CODE-BACKED | Batch of position reassignments. Each row: PositionID (bigint), NewHedgeServerID (int), NewRootHedgeServerID (int), RuleID (int), OperationSummaryID (int). Limited to 3,000 rows; larger batches cause immediate RETURN -1. |
| 2 | @OperationSummaryID | int | NO | - | CODE-BACKED | ID of the parent batch in Trade.PositionsHedgeServerChangeSummaryLog. Linked to each ChangeLog row; SummaryLog.EndTime set on completion. |
| 3 | @UpdateRealPositionInDB | bit | NO | - | CODE-BACKED | Dry-run flag: 1=live mode (all writes execute), 0=audit-only mode (PositionTbl and ExposuresForAllHedgeServers not updated, only ChangeLog and SummaryLog written). Allows the RerouteService to preview rerouting decisions without committing them. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionsToChange | HSPositionChange | UDT Reference | TVP type for input batch |
| PositionID | Trade.PositionTbl | Read/Write (conditional) | Eligibility filter; UPDATEd only when @UpdateRealPositionInDB=1 |
| CID, ProviderID, InstrumentID, HedgeServerID | Trade.ExposuresForAllHedgeServers | Write (conditional) | UPDATEd and MERGEd only when @UpdateRealPositionInDB=1 |
| PositionID, RuleID | Trade.PositionsHedgeServerChangeLog | Write (always) | Audit INSERT regardless of dry-run flag |
| @OperationSummaryID | Trade.PositionsHedgeServerChangeSummaryLog | Write (always) | EndTime updated regardless of dry-run flag |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RerouteService (external) | - | Caller | Hedge server reroute service; has dedicated database login (RerouteService-User) with EXEC permission. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.MovePositionsHedgeServersByRerouteService (procedure)
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
| Trade.PositionTbl | Table | READ for eligibility; UPDATEd when @UpdateRealPositionInDB=1 |
| Trade.ExposuresForAllHedgeServers | Table | UPDATEd/MERGEd when @UpdateRealPositionInDB=1 |
| Trade.PositionsHedgeServerChangeLog | Table | Always INSERTed (live or dry-run) |
| Trade.PositionsHedgeServerChangeSummaryLog | Table | Always UPDATEd EndTime |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RerouteService (external) | External Application | Submits hedge server rerouting batches; uses dry-run flag for pre-validation. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Partition-aware joins use PositionID%50=PartitionCol for efficient partition-pruned DML on Trade.PositionTbl.

### 7.2 Constraints

N/A for stored procedure. 3,000-row hard cap (RETURN -1 before transaction). Single BEGIN TRAN around all conditional DML + unconditional audit writes. CATCH: ROLLBACK if @@TRANCOUNT=1, COMMIT if >1, THROW.

---

## 8. Sample Queries

### 8.1 Dry-run: preview positions to be rerouted without committing

```sql
-- Pass @UpdateRealPositionInDB=0 to log without moving
EXEC Trade.MovePositionsHedgeServersByRerouteService
    @PositionsToChange = <TVP>,
    @OperationSummaryID = <SummaryID>,
    @UpdateRealPositionInDB = 0;
-- Check ChangeLog to see what would have moved
SELECT * FROM Trade.PositionsHedgeServerChangeLog WHERE OperationSummaryID = <SummaryID>;
```

### 8.2 Check summary log for a completed reroute operation

```sql
SELECT ID, StartTime, EndTime, DATEDIFF(SECOND, StartTime, EndTime) AS DurationSec
FROM Trade.PositionsHedgeServerChangeSummaryLog WITH (NOLOCK)
WHERE ID = <OperationSummaryID>;
```

### 8.3 Verify exposure was rebalanced after live reroute

```sql
SELECT HedgeServerID, SUM(OpenedBuy) AS TotalBuy, SUM(OpenedSell) AS TotalSell
FROM Trade.ExposuresForAllHedgeServers WITH (NOLOCK)
WHERE HedgeServerID IN (<OldHedgeServerID>, <NewHedgeServerID>)
GROUP BY HedgeServerID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SP callers | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.MovePositionsHedgeServersByRerouteService | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.MovePositionsHedgeServersByRerouteService.sql*
