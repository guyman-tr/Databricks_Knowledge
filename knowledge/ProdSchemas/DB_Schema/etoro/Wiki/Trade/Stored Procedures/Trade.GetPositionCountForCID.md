# Trade.GetPositionCountForCID

> Returns the count of currently open positions for a customer - a lightweight check used for limit enforcement and portfolio status queries.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer whose open position count to retrieve |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetPositionCountForCID` returns a single integer: the count of open positions (StatusID=1) for the given customer. It is a minimal utility SP for position count checks.

**WHY:** Before allowing a new position to be opened, trading systems check whether the customer has reached their open position limit. This SP provides an efficient count without returning full position data.

**HOW:** Single-column COUNT(*) from Trade.PositionTbl WHERE CID=@CID AND StatusID=1, with NOLOCK and ISNULL(COUNT,0) safety. No partition filter needed because CID-based queries scan across all PartitionCol values.

---

## 2. Business Logic

### 2.1 Open Position Count

**Rules:**
- `SELECT ISNULL(COUNT(*),0) AS NumberOfOpenedPositions FROM Trade.PositionTbl WHERE CID=@CID AND StatusID=1`
- StatusID=1 = open (comment in code explicitly states this)
- ISNULL(COUNT,0) = always returns a row with 0 if no open positions exist

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 2 | NumberOfOpenedPositions | INT | NO | 0 | CODE-BACKED | Count of open positions (StatusID=1) for the customer. Returns 0 if none. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Trade.PositionTbl | Aggregate | COUNT of StatusID=1 positions for this customer |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by position limit enforcement logic.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionCountForCID (procedure)
|- Trade.PositionTbl (table) - open position count
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | COUNT of StatusID=1 positions per CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by position open validation |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| StatusID = 1 | Filter | Only open positions |
| ISNULL(COUNT(*),0) | Safety | Returns 0 instead of NULL when no rows match |
| WITH (NOLOCK) | Performance | Dirty read acceptable for count check |
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Count open positions for a customer

```sql
EXEC Trade.GetPositionCountForCID @CID = 7234263
```

### 8.2 Check against a limit

```sql
DECLARE @count INT
EXEC @count = Trade.GetPositionCountForCID @CID = 7234263
IF @count >= 100
    PRINT 'Position limit reached'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 8.0/10, Logic: 7.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionCountForCID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionCountForCID.sql*
