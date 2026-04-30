# MoneyBus.WithdrawGetListV2

> V2 withdrawal list retrieval with server-side filtering (status, account, date range) and pagination (OFFSET/FETCH), extending the V1 batch-by-IDs pattern with richer query capabilities.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns paginated, filtered result set from Withdrawals |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.WithdrawGetListV2 is the enhanced version of WithdrawGetList that adds server-side filtering and pagination. While V1 only supports lookup by a batch of IDs, V2 accepts optional filters for GCID, StatusID, StatusReasonID, AccountID, date range (FromUtc/ToUtc), and supports OFFSET/FETCH pagination. This enables richer querying patterns like "get all in-process withdrawals for a customer in the last 30 days, page 2 of 100."

The procedure uses a defensive design: if filtering by status or account without providing IDs or GCID, it throws an error (50001) to prevent unbounded full-table scans. Pagination is clamped to 1-100 rows per page. Results are ordered by ID DESC (newest first). Uses NOLOCK for read performance.

---

## 2. Business Logic

### 2.1 Filter Safety Guard

**What**: Prevents unbounded queries by requiring IDs or GCID when filtering by status/account.

**Columns/Parameters Involved**: `@Ids`, `@GCID`, `@StatusID`, `@StatusReasonID`, `@AccountID`

**Rules**:
- If any of @StatusID, @StatusReasonID, or @AccountID are provided, THEN at least one of @Ids (non-empty) or @GCID must also be provided
- Violation throws: `THROW 50001, 'IDs or GCID must be provided when filtering by status or account.', 1`
- This prevents expensive full-table scans on the 773K+ row Withdrawals table

### 2.2 Pagination Bounds

**What**: Enforces safe pagination limits.

**Columns/Parameters Involved**: `@Top`, `@Offset`

**Rules**:
- @Top is clamped to [1, 100] - NULL or <1 defaults to 1, >100 capped at 100
- @Offset is clamped to [0, MAX] - NULL or <0 defaults to 0
- Uses OFFSET/FETCH for standard SQL pagination
- Results ordered by ID DESC (newest first)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Ids | MoneyBus.IDs (TVP) | READONLY | - | CODE-BACKED | Optional list of specific withdrawal IDs to filter by. When empty, filtering uses @GCID and other parameters. See [MoneyBus.IDs](../User Defined Types/MoneyBus.IDs.md). |
| 2 | @GCID | bigint | YES | NULL | CODE-BACKED | Optional customer filter. When set, returns only this customer's withdrawals. |
| 3 | @StatusID | int | YES | NULL | CODE-BACKED | Optional status filter: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Cancelled. Requires @Ids or @GCID. |
| 4 | @StatusReasonID | int | YES | NULL | CODE-BACKED | Optional status reason filter. Requires @Ids or @GCID. |
| 5 | @AccountID | nvarchar(50) | YES | NULL | CODE-BACKED | Optional account filter for specific external account. Requires @Ids or @GCID. |
| 6 | @FromUtc | datetime2(7) | YES | NULL | CODE-BACKED | Optional start of date range filter (inclusive) on Created column. |
| 7 | @ToUtc | datetime2(7) | YES | NULL | CODE-BACKED | Optional end of date range filter (exclusive) on Created column. |
| 8 | @Offset | int | YES | 0 | CODE-BACKED | Pagination offset (number of rows to skip). Default 0. Clamped to >= 0. |
| 9 | @Top | int | YES | 100 | CODE-BACKED | Page size (number of rows to return). Default 100. Clamped to [1, 100]. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Ids | MoneyBus.IDs | Parameter Type | Optional ID batch filter |
| (SELECT target) | MoneyBus.Withdrawals | Reader | Reads filtered/paginated withdrawal set |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.WithdrawGetListV2 (procedure)
├── MoneyBus.Withdrawals (table) [SELECT FROM with filters]
└── MoneyBus.IDs (type) [@Ids parameter]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Withdrawals | Table | SELECT FROM - reads filtered/paginated withdrawals |
| MoneyBus.IDs | User Defined Type | @Ids READONLY parameter |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| THROW 50001 | Runtime guard | Prevents unbounded queries - IDs or GCID required when status/account filters are used |

---

## 8. Sample Queries

### 8.1 Get in-process withdrawals for a customer
```sql
DECLARE @Ids MoneyBus.IDs; -- empty
EXEC MoneyBus.WithdrawGetListV2 @Ids = @Ids, @GCID = 12345, @StatusID = 1;
```

### 8.2 Paginated retrieval of recent withdrawals
```sql
DECLARE @Ids MoneyBus.IDs;
EXEC MoneyBus.WithdrawGetListV2 @Ids = @Ids, @GCID = 12345,
    @FromUtc = '2026-04-01', @ToUtc = '2026-04-16', @Offset = 0, @Top = 50;
```

### 8.3 Get specific IDs with status filter
```sql
DECLARE @Ids MoneyBus.IDs;
INSERT INTO @Ids (ID) VALUES (773487), (773486), (773485);
EXEC MoneyBus.WithdrawGetListV2 @Ids = @Ids, @StatusID = 2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.WithdrawGetListV2 | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.WithdrawGetListV2.sql*
