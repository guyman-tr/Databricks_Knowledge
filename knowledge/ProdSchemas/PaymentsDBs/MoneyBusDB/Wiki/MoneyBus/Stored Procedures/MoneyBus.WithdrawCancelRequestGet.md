# MoneyBus.WithdrawCancelRequestGet

> Retrieves a withdrawal's cancellation request by WithdrawID, returning the cancellation source, manager, comments, and timestamp.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single row from WithdrawCancelRequest by WithdrawID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.WithdrawCancelRequestGet retrieves the cancellation request details for a specific withdrawal. Used by the withdrawal service to check whether a cancellation has been requested for a given withdrawal, and if so, who initiated it and why. The lookup is by WithdrawID (the clustered unique key), providing optimal single-row access.

Returns all columns: ID, WithdrawID, ManagerID, CancellationSource, Comments, Created.

---

## 2. Business Logic

No complex business logic. Simple clustered key lookup.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | bigint | NO | - | CODE-BACKED | The withdrawal to look up. Maps to WithdrawCancelRequest.WithdrawID (clustered unique key). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT target) | MoneyBus.WithdrawCancelRequest | Reader | Reads cancellation details by WithdrawID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.WithdrawCancelRequestGet (procedure)
└── MoneyBus.WithdrawCancelRequest (table) [SELECT FROM]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.WithdrawCancelRequest | Table | SELECT FROM - reads cancel request by WithdrawID |

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

### 8.1 Get cancellation request for a withdrawal
```sql
EXEC MoneyBus.WithdrawCancelRequestGet @WithdrawID = 773480;
```

### 8.2 Check if withdrawal has been cancelled
```sql
DECLARE @result TABLE (ID int, WithdrawID bigint, ManagerID int, CancellationSource int, Comments varchar(200), Created datetime);
INSERT INTO @result EXEC MoneyBus.WithdrawCancelRequestGet @WithdrawID = 773480;
IF EXISTS (SELECT 1 FROM @result)
    PRINT 'Withdrawal has a cancellation request';
```

### 8.3 Direct equivalent with source name resolved
```sql
SELECT wcr.*, wcs.Name AS SourceName
FROM MoneyBus.WithdrawCancelRequest wcr WITH (NOLOCK)
JOIN Dictionary.WithdrawCancellationSources wcs WITH (NOLOCK) ON wcs.ID = wcr.CancellationSource
WHERE wcr.WithdrawID = 773480;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.WithdrawCancelRequestGet | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.WithdrawCancelRequestGet.sql*
