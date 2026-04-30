# Trade.GetBlockedPlayerStatusIds

> Returns player status IDs that block trading - statuses where opening or closing positions is restricted.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns PlayerStatusID and Name for restricted statuses |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides the list of customer account statuses that prevent trading activity. Player statuses are assigned by compliance, risk management, or automated systems to restrict a customer's ability to open or close positions. The trading engine loads this list to validate whether a customer can trade before processing any order.

The procedure exists because the set of blocked statuses is configurable via the Dictionary.PlayerStatus table rather than hardcoded. When compliance adds a new restricted status, it takes effect immediately in the trading engine without code changes.

Data flows from `Dictionary.PlayerStatus` filtered to rows where either `CanOpenPosition = 0` OR `CanClosePosition = 0` - any status that restricts at least one trading direction.

---

## 2. Business Logic

### 2.1 Blocked Status Detection

**What**: Identifies statuses that restrict any form of trading.

**Columns/Parameters Involved**: `CanOpenPosition`, `CanClosePosition`

**Rules**:
- `WHERE CanOpenPosition = 0 OR CanClosePosition = 0`
- A status blocks trading if it prevents opening OR closing (or both)
- This is an OR condition - even if a status allows opening but blocks closing, it is included
- Used by the trading engine as a lookup list for pre-trade validation

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. Output columns:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlayerStatusID | INT | NO | - | CODE-BACKED | Primary key of the player status. FK target for customer status fields. Used by the trading engine to check if a customer's current status is in this blocked list. |
| 2 | Name | NVARCHAR | NO | - | CODE-BACKED | Display name of the blocked status (e.g., "Suspended", "Compliance Hold", "Fraud Review"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Dictionary.PlayerStatus | SELECT FROM | Source dictionary table for player statuses |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetBlockedPlayerStatusIds (procedure)
+-- Dictionary.PlayerStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PlayerStatus | Table | SELECT FROM with CanOpenPosition/CanClosePosition filter |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC Trade.GetBlockedPlayerStatusIds;
```

### 8.2 Query all statuses with their trading permissions
```sql
SELECT  PlayerStatusID, Name, CanOpenPosition, CanClosePosition
FROM    Dictionary.PlayerStatus WITH (NOLOCK)
ORDER BY PlayerStatusID;
```

### 8.3 Check if a specific customer is blocked from trading
```sql
SELECT  c.CID, ps.Name AS PlayerStatus, ps.CanOpenPosition, ps.CanClosePosition
FROM    Customer.Customer c WITH (NOLOCK)
        INNER JOIN Dictionary.PlayerStatus ps WITH (NOLOCK) ON c.PlayerStatusID = ps.PlayerStatusID
WHERE   c.CID = 12345
        AND (ps.CanOpenPosition = 0 OR ps.CanClosePosition = 0);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetBlockedPlayerStatusIds | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetBlockedPlayerStatusIds.sql*
