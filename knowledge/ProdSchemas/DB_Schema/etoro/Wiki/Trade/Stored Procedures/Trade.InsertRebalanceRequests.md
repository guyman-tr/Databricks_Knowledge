# Trade.InsertRebalanceRequests

> Bulk-inserts a set of rebalance requests from a table-valued parameter into Trade.RebalanceRequests, recording who triggered the rebalance, when, and any per-request comment.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RebalanceTbl TVP (Trade.RebalanceTbl) drives all INSERTs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertRebalanceRequests is the write endpoint for the rebalancing workflow on eToro. Rebalancing is the process of adjusting position sizes or closing positions to realign a copy portfolio or fund allocation with a target weighting. When a rebalance operation is triggered - by back-office tools, a fund manager, or an automated service - one or more positions must be queued for closure at specified rates. This procedure accepts a batch of such positions in a single call and persists them to Trade.RebalanceRequests for downstream processing.

Without this procedure there would be no consistent, auditable entry point for rebalance operations. All rate snapshots, direction flags, discount flags, and per-row errors are captured atomically per batch. The caller supplies who triggered the rebalance (@OccurredByUser), when it was recorded (@Occurred), and an optional comment (@Comment) that applies to the entire batch.

Data flow: Application or back-office tooling builds a Trade.RebalanceTbl TVP from position data and current pricing, then calls this procedure. The procedure executes a single INSERT..SELECT that materialises all rows into Trade.RebalanceRequests. No subsequent UPDATE or DELETE operations are performed - the table is append-only from this procedure's perspective. Trade.GetRebalancePositions reads the inserted rows for further processing or display.

---

## 2. Business Logic

### 2.1 Batch Insert Pattern

**What**: All rebalance positions in the TVP are inserted in a single statement - no row-by-row processing.

**Columns/Parameters Involved**: `@RebalanceTbl`, `@OccurredByUser`, `@Occurred`, `@Comment`

**Rules**:
- Every row in @RebalanceTbl maps 1:1 to a new row in Trade.RebalanceRequests.
- @OccurredByUser and @Occurred are injected at the batch level - all rows in the batch share the same triggering user and timestamp.
- @Comment is also batch-level; it provides a free-form audit note attached to every row inserted by this call.
- Error column from the TVP is passed through as-is: NULL = no error, non-NULL = per-position error message supplied by the caller.

**Diagram**:
```
Caller builds Trade.RebalanceTbl TVP
  (PositionID, CID, IsBuy, IsDiscounted, PriceRateID, Bid, Ask, CloseRate, Error)
        |
        v
Trade.InsertRebalanceRequests(
    @RebalanceTbl    -- TVP rows
    @OccurredByUser  -- who triggered
    @Occurred        -- when triggered
    @Comment         -- batch audit note
)
        |
        v
INSERT INTO Trade.RebalanceRequests
  (all TVP columns + @OccurredByUser + @Occurred + @Comment)
        |
        v
Trade.RebalanceRequests rows available for Trade.GetRebalancePositions
```

### 2.2 Caller-Injected Audit Context

**What**: The caller provides three pieces of audit metadata that are not in the TVP itself but are stamped on every inserted row.

**Columns/Parameters Involved**: `@OccurredByUser`, `@Occurred`, `@Comment`

**Rules**:
- @OccurredByUser (VARCHAR(50)) identifies the Windows user or service account that initiated the rebalance. Maps to Trade.RebalanceRequests.OccurredByUser.
- @Occurred (datetime2(7)) is the business timestamp of the rebalance trigger. This is NOT a DB server timestamp - it is supplied by the caller, allowing the caller to record the precise moment the operation was decided rather than when the INSERT executed.
- @Comment (VARCHAR(500)) is optional (nullable in the target) and serves as a reason or context note for the entire batch.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RebalanceTbl | Trade.RebalanceTbl | NO | - | CODE-BACKED | READONLY TVP containing one row per position to rebalance. Each row carries PositionID, CID, IsBuy, IsDiscounted, PriceRateID, Bid, Ask, CloseRate, and Error. See Trade.RebalanceTbl for full element details. |
| 2 | @OccurredByUser | varchar(50) | NO | - | CODE-BACKED | Windows or service account identity of the user who triggered this rebalance batch. Stamped on every inserted row. E.g., "trad\be-user". Maps to RebalanceRequests.OccurredByUser. |
| 3 | @Occurred | datetime2(7) | NO | - | CODE-BACKED | Business timestamp of when the rebalance was triggered. Caller-supplied (not server time). Stamped on every inserted row. Maps to RebalanceRequests.Occurred. |
| 4 | @Comment | varchar(500) | NO | - | CODE-BACKED | Free-form audit comment for the entire batch. Propagated to every inserted row. Maps to RebalanceRequests.Comment. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RebalanceTbl | Trade.RebalanceTbl | Parameter (TVP) | Source of all position rows to insert. |
| INSERT target | Trade.RebalanceRequests | Writer | Inserts all TVP rows into this table. |

### 5.2 Referenced By (other objects point to this)

Not discovered in SQL codebase - this procedure is called directly from application or back-office tooling (not from another stored procedure in the repo).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertRebalanceRequests (procedure)
├── Trade.RebalanceTbl (type) - TVP parameter type
└── Trade.RebalanceRequests (table) - INSERT target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.RebalanceTbl | User Defined Type | TVP parameter type for @RebalanceTbl |
| Trade.RebalanceRequests | Table | INSERT target - all TVP rows written here |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application / back-office tooling | External | Calls this procedure to submit rebalance batches (no SQL caller found in repo) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Submit a single-position rebalance request

```sql
DECLARE @Tbl Trade.RebalanceTbl;
INSERT INTO @Tbl (PositionID, CID, IsBuy, IsDiscounted, PriceRateID, Bid, Ask, CloseRate, Error)
VALUES (900000001, 12345, 1, 0, 1000001, 150.50, 150.55, 150.52, NULL);

EXEC Trade.InsertRebalanceRequests
    @RebalanceTbl    = @Tbl,
    @OccurredByUser  = 'trad\be-user',
    @Occurred        = '2026-03-17 10:00:00',
    @Comment         = 'Manual rebalance - fund reallocation Q1 2026';
```

### 8.2 Submit a batch of positions for rebalance with pricing

```sql
DECLARE @Tbl Trade.RebalanceTbl;
INSERT INTO @Tbl (PositionID, CID, IsBuy, IsDiscounted, PriceRateID, Bid, Ask, CloseRate, Error)
SELECT
    p.PositionID,
    p.CID,
    p.IsBuy,
    0 AS IsDiscounted,
    @PriceRateID,
    @Bid,
    @Ask,
    @CloseRate,
    NULL
FROM Trade.PositionTbl p WITH (NOLOCK)
WHERE p.InstrumentID = @InstrumentID
  AND p.IsOpen = 1;

EXEC Trade.InsertRebalanceRequests
    @RebalanceTbl    = @Tbl,
    @OccurredByUser  = 'rebalance-service',
    @Occurred        = GETUTCDATE(),
    @Comment         = 'Automated rebalance batch';
```

### 8.3 Verify inserted rebalance requests after execution

```sql
SELECT TOP 50
    rr.RebalanceRequestsId,
    rr.PositionID,
    rr.CID,
    rr.IsBuy,
    rr.IsDiscounted,
    rr.CloseRate,
    rr.OccurredByUser,
    rr.Occurred,
    rr.Error,
    rr.Comment
FROM Trade.RebalanceRequests rr WITH (NOLOCK)
WHERE rr.OccurredByUser = 'trad\be-user'
ORDER BY rr.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.InsertRebalanceRequests | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertRebalanceRequests.sql*
