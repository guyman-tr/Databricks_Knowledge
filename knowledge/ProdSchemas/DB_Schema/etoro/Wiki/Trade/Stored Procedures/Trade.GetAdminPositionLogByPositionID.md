# Trade.GetAdminPositionLogByPositionID

> Retrieves all admin position log entries associated with a specific trading position.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all admin position log columns filtered by PositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves all admin position log records linked to a specific trading position by PositionID. Multiple admin operations can be associated with a single position (e.g., open + modify + close), so this returns all historical admin actions for that position.

The procedure exists to support position-centric auditing. When investigating a specific position's admin history - why it was opened, who opened it, whether any modifications were made - this procedure provides the complete admin operation trail.

Data flows from Trade.AdminPositionLog filtered by the PositionID column, returning all matching records with NOLOCK for non-blocking reads.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple filtered lookup returning all columns from Trade.AdminPositionLog for all admin operations targeting a specific position.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | Trading position ID to look up admin operations for. May return multiple rows if multiple admin actions were performed on this position. |

**Output columns:** Same 27 columns as Trade.GetAdminPositionLogByAdminPositionID (AdminPositionID, AdminPositionRequestID, CID, InstrumentID, OpenActionType, AdminPositionEventID, AmountInUnits, Amount, HedgeServerID, RequestOccurred, UserName, ExecutionOccurred, PositionID, State, FailReason, ErrorCode, Cusip, ApexID, Rate, RateTime, CheckBalance, IsComputeForHedge, IsFunded, CompensationReasonID, ValidatePositionWorth, CompensationCreditID, OrderID).

See [Trade.GetAdminPositionLogByAdminPositionID](Trade.GetAdminPositionLogByAdminPositionID.md) Section 4 for full column descriptions.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.AdminPositionLog | Direct Read | Reads admin position log entries by PositionID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAdminPositionLogByPositionID (procedure)
└── Trade.AdminPositionLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.AdminPositionLog | Table | SELECT with NOLOCK - filtered by PositionID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get admin history for a position

```sql
EXEC Trade.GetAdminPositionLogByPositionID @PositionID = 987654321;
```

### 8.2 Check if a position was admin-created

```sql
SELECT  AdminPositionID,
        UserName,
        OpenActionType,
        RequestOccurred
FROM    Trade.AdminPositionLog WITH (NOLOCK)
WHERE   PositionID = 987654321;
```

### 8.3 Find all admin-opened positions for a customer

```sql
SELECT  PositionID,
        AdminPositionID,
        InstrumentID,
        UserName,
        RequestOccurred,
        State
FROM    Trade.AdminPositionLog WITH (NOLOCK)
WHERE   CID = 12345678
    AND PositionID IS NOT NULL
ORDER BY RequestOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAdminPositionLogByPositionID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAdminPositionLogByPositionID.sql*
