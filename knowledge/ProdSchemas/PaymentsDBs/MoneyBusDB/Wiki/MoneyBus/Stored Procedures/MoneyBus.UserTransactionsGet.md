# MoneyBus.UserTransactionsGet

> Retrieves a user's transactions with optional time range and status filters, with a configurable row limit (default 500), ordered by creation date ascending - built for cashflow enrichment (PAYIL-9375).

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns filtered, limited result set from Transactions by GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.UserTransactionsGet retrieves a user's transaction history with flexible filtering. Created for the cashflow enrichment feature (PAYIL-9375), it supports time-range filtering (@StartTime/@EndTime), optional status filtering, and a configurable row limit (default 500). Results are ordered by Created ASC (oldest first) for chronological cashflow analysis.

Unlike TransactionsGetByParams which filters by transfer direction, this procedure focuses on a user's complete transaction history across all directions, making it suitable for account statements and cashflow reports.

---

## 2. Business Logic

### 2.1 Bounded Result Set

**What**: The procedure caps results using TOP(@LimitCount) to prevent excessive data retrieval.

**Columns/Parameters Involved**: `@LimitCount`, `@StartTime`, `@EndTime`, `@StatusID`

**Rules**:
- Default limit is 500 rows - sufficient for typical cashflow views
- All filters use NULL-safe comparisons: NULL means "no filter on this dimension"
- Created ASC ordering supports chronological analysis
- The GCID index (IX_Transactions_GCID) drives the primary lookup

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | bigint | NO | - | CODE-BACKED | Customer ID. Required. Uses IX_Transactions_GCID. |
| 2 | @StartTime | datetime | YES | NULL | CODE-BACKED | Optional inclusive start of time range on Created. NULL means no lower bound. |
| 3 | @EndTime | datetime | YES | NULL | CODE-BACKED | Optional inclusive end of time range on Created. NULL means no upper bound. |
| 4 | @StatusID | int | YES | NULL | CODE-BACKED | Optional status filter. NULL returns all statuses. |
| 5 | @LimitCount | int | YES | 500 | CODE-BACKED | Maximum rows to return. Default 500. Passed to TOP(). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT target) | MoneyBus.Transactions | Reader | Reads user's transactions with filters |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.UserTransactionsGet (procedure)
└── MoneyBus.Transactions (table) [SELECT FROM]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Transactions | Table | SELECT TOP(@LimitCount) with GCID + time filters |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get last 500 transactions for a user
```sql
EXEC MoneyBus.UserTransactionsGet @GCID = 12345;
```

### 8.2 Get successful transactions in a date range
```sql
EXEC MoneyBus.UserTransactionsGet @GCID = 12345,
    @StartTime = '2026-01-01', @EndTime = '2026-04-15', @StatusID = 2;
```

### 8.3 Get limited recent transactions
```sql
EXEC MoneyBus.UserTransactionsGet @GCID = 12345, @LimitCount = 50,
    @StartTime = '2026-04-01';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.UserTransactionsGet | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.UserTransactionsGet.sql*
