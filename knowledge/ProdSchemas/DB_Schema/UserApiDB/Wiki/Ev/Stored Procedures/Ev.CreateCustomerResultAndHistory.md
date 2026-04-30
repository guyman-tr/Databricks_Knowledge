# Ev.CreateCustomerResultAndHistory

> Transactionally creates an EV customer result record and its associated request/response history entries in a single atomic operation.

| Property | Value |
|----------|-------|
| **Schema** | Ev |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID + @EvStatusId + @EvProviderId (input params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Ev.CreateCustomerResultAndHistory is the primary procedure for recording EV verification outcomes. Within a transaction, it: (1) inserts a new row into Ev.CustomerResult with the verification outcome, (2) inserts one or more request/response XML pairs from the History.EvRequestRow TVP into History.EvRequest, linking them to the newly created result ID. This ensures atomicity - either both the result and its history are recorded, or neither.

---

## 2. Business Logic

### 2.1 Atomic Result + History Creation

**What**: Single transaction creates result and all associated history entries.

**Columns/Parameters Involved**: `@EvStatusId`, `@EvProviderId`, `@GCID`, `@HistoryEntries`, `@TransactioID`, `@FunnelId`

**Rules**:
- INSERT into Ev.CustomerResult -> SCOPE_IDENTITY() gets new CustomerEvResultId
- INSERT into History.EvRequest using the TVP rows, linking to the new result ID
- ROLLBACK on any error

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @EvStatusId | int (IN) | NO | - | CODE-BACKED | EV outcome status. Maps to Dictionary.EvStatus. |
| 2 | @EvProviderId | int (IN) | NO | - | CODE-BACKED | Which provider performed the verification. Maps to Dictionary.EvProvider. |
| 3 | @GCID | int (IN) | NO | - | CODE-BACKED | User being verified. |
| 4 | @HistoryEntries | History.EvRequestRow READONLY (IN) | NO | - | CODE-BACKED | TVP with Request/Response XML pairs. |
| 5 | @TransactioID | varchar(50) (IN) | YES | NULL | CODE-BACKED | Provider transaction reference. |
| 6 | @FunnelId | int (IN) | YES | -1 | CODE-BACKED | Verification funnel/flow ID. Default: -1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Ev.CustomerResult | INSERT INTO | Creates result record |
| - | History.EvRequest | INSERT INTO | Creates history entries |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Ev.CreateCustomerResultAndHistory (procedure)
  +-- Ev.CustomerResult (table) [done in this batch]
  +-- History.EvRequest (table) [done]
  +-- History.EvRequestRow (UDT) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Ev.CustomerResult | Table | INSERT INTO |
| History.EvRequest | Table | INSERT INTO |
| History.EvRequestRow | UDT | Parameter type |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Create result with history
```sql
DECLARE @H History.EvRequestRow
INSERT INTO @H VALUES ('<request>data</request>', '<response>result</response>')
EXEC Ev.CreateCustomerResultAndHistory @EvStatusId = 5, @EvProviderId = 2, @GCID = 12345,
  @HistoryEntries = @H, @TransactioID = 'TXN-123', @FunnelId = 1
```

### 8.2 Multiple history entries
```sql
DECLARE @H History.EvRequestRow
INSERT INTO @H VALUES ('<req1/>', '<resp1/>'), ('<req2/>', '<resp2/>')
EXEC Ev.CreateCustomerResultAndHistory @EvStatusId = 1, @EvProviderId = 8, @GCID = 12345, @HistoryEntries = @H
```

### 8.3 Verify result was created
```sql
SELECT TOP 1 * FROM Ev.CustomerResult WITH (NOLOCK) WHERE GCID = 12345 ORDER BY CustomerEvResultId DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Ev.CreateCustomerResultAndHistory | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Ev/Stored Procedures/Ev.CreateCustomerResultAndHistory.sql*
