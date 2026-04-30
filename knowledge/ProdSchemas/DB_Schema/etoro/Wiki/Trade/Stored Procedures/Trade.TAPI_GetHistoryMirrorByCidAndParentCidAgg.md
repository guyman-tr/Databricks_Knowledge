# Trade.TAPI_GetHistoryMirrorByCidAndParentCidAgg

> Trading API procedure that returns aggregate totals for all closed copy-trading sessions between a customer and a specific Popular Investor - total count, invested amounts, net profit, deposits, withdrawals, and accumulated holding fees.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @parentCid INT (required) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the aggregation companion to `Trade.TAPI_GetHistoryMirrorByCidAndParentCid`. While that procedure returns the paginated list of individual copy sessions, this one returns a single row of summary totals: total number of sessions, total initial investment, total net profit, total deposits, total withdrawals, and total holding fees across all sessions.

This powers the summary statistics shown at the top of the copy history page for a specific trader: "You copied trader X 3 times, investing $5,000 total with $420 net profit and $35 in fees."

The procedure uses a two-step approach:
1. Aggregate mirror data into temp table #t (with a covering index created if data exists)
2. If there is data (@@ROWCOUNT > 0), join to History.Position for fees and return the aggregate row

The conditional logic (IF @@ROWCOUNT > 0) means the procedure returns an empty result set if there are no closed mirrors matching the filter - the client should handle this empty case.

---

## 2. Business Logic

### 2.1 Mirror Aggregation

**What**: Aggregates financial summaries across all closed mirror sessions with a specific trader.

**Columns/Parameters Involved**: `MirrorOperationID`, `CID`, `ParentCID`, `ModificationDate`

**Rules**:
- `MirrorOperationID = 2`: Closed mirrors only
- `CID = @cid AND ParentCID = @parentCid`: Filter to specific customer-trader pair
- `ModificationDate >= @startTime OR @startTime IS NULL`: Time window filter on closure date
- Group by CID, ParentCID, MirrorID: one row per mirror in temp table (then summed in output query)
- Aggregates: COUNT(MirrorID) = number of sessions, SUM(InitialInvestment), SUM(NetProfit), SUM(DepositSummary), SUM(WithdrawalSummary)

### 2.2 Conditional Execution

**What**: Avoids unnecessary queries when no matching mirrors exist.

**Rules**:
- After the INSERT INTO #t, checks `IF @@ROWCOUNT > 0` before proceeding
- If no rows: procedure returns nothing (empty result set)
- If rows exist: creates index `#IDX ON #t (CID, MirrorID)`, then queries History.Position for fees

### 2.3 Fees Aggregation from History.Position

**What**: Computes total EndOfWeekFee from all positions across all matching mirror sessions.

**Rules**:
- INNER JOIN #t to History.Position on CID + MirrorID
- SUM(EndOfWeekFee) across all positions in all mirror sessions
- ISNULL-defaulted to 0
- This adds up holding fees that are not stored in History.Mirror itself

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. The customer who was copying. |
| 2 | @parentCid | INT | NO | - | CODE-BACKED | The Popular Investor CID being copied. Aggregation scoped to this trader. |
| 3 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional time filter on mirror close date (ModificationDate >= @startTime). When NULL: aggregates all time. |

### Output - Result Set 1 (Aggregate Totals - 0 or 1 row)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Total | INT | NO | - | CODE-BACKED | Total number of closed copy sessions (mirrors) between this customer and trader. SUM of COUNT(MirrorID) from #t. |
| 2 | TotalInitialInvestmentDollars | MONEY | NO | - | CODE-BACKED | Sum of initial investments across all sessions. ISNULL-defaulted to 0. |
| 3 | TotalNetProfitDollars | MONEY | NO | - | CODE-BACKED | Sum of net profit from closed positions across all sessions. ISNULL-defaulted to 0. |
| 4 | TotalDepositedDollars | MONEY | NO | - | CODE-BACKED | Sum of additional deposits made into copy sessions after initial investment. ISNULL-defaulted to 0. |
| 5 | TotalWithdrewDollars | MONEY | NO | - | CODE-BACKED | Sum of withdrawals made from copy sessions. ISNULL-defaulted to 0. |
| 6 | TotalFeesDollars | MONEY | NO | - | CODE-BACKED | Total holding fees (EndOfWeekFee) accumulated across all positions in all sessions. From History.Position. ISNULL-defaulted to 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, ParentCID, MirrorOperationID | History.Mirror | Lookup (READ) | Source for closed copy session financial data |
| CID, MirrorID | History.Position | Lookup (INNER JOIN via #t) | Aggregate holding fees from positions in matching mirror sessions |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Companion to `Trade.TAPI_GetHistoryMirrorByCidAndParentCid`. Called by TDAPIUser service account.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetHistoryMirrorByCidAndParentCidAgg (procedure)
├── History.Mirror (table - cross-schema)
└── History.Position (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Mirror | Table (cross-schema) | Aggregate closed mirror session counts and financial sums |
| History.Position | Table (cross-schema) | Aggregate EndOfWeekFee across positions in matching mirrors |

### 6.2 Objects That Depend On This

No SQL dependents. Companion: `Trade.TAPI_GetHistoryMirrorByCidAndParentCid`. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

Dynamically created temp table index: `#IDX ON #t (CID, MirrorID)` - created only when @@ROWCOUNT > 0 after the #t insert.

### 7.2 Constraints

None. Important behavior: if no closed mirrors exist for the @cid/@parentCid pair, the procedure returns an empty result set (no rows). The client must handle this case.

---

## 8. Sample Queries

### 8.1 Get aggregate copy summary with a specific trader

```sql
EXEC Trade.TAPI_GetHistoryMirrorByCidAndParentCidAgg
    @cid = 12345,
    @parentCid = 67890,
    @startTime = NULL
```

### 8.2 Preview aggregate directly

```sql
SELECT
    COUNT(*) AS Total,
    ISNULL(SUM(hm.InitialInvestment), 0) AS TotalInitialInvestment,
    ISNULL(SUM(hm.NetProfit), 0) AS TotalNetProfit,
    ISNULL(SUM(hm.DepositSummary), 0) AS TotalDeposited,
    ISNULL(SUM(hm.WithdrawalSummary), 0) AS TotalWithdrew
FROM History.Mirror hm WITH (NOLOCK)
WHERE hm.CID = 12345
    AND hm.ParentCID = 67890
    AND hm.MirrorOperationID = 2
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetHistoryMirrorByCidAndParentCidAgg | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetHistoryMirrorByCidAndParentCidAgg.sql*
