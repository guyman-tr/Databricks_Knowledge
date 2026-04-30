# Customer.GetUsersPlayerStatus

> Returns player status details (blocked flag, status reason, sub-reason) for multiple customers - batch check for account blocking status.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns blocking info for a GCID list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetUsersPlayerStatus retrieves the account blocking status and status reasons for multiple customers. It joins Real_Customer (for player status and reasons) with Dictionary_PlayerStatus (to resolve the IsBlocked flag). This is used by features that need to check whether multiple users are blocked and why.

---

## 2. Business Logic

### 2.1 IsBlocked Resolution

**What**: The IsBlocked flag comes from Dictionary_PlayerStatus, not directly from the customer record.

**Rules**:
- Joins dbo.Dictionary_PlayerStatus ON PlayerStatusID
- Returns ps.IsBlocked (bit) - computed from the status dictionary
- Also returns PlayerStatusReasonID and PlayerStatusSubReasonID for blocked accounts

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcids | dbo.IdList (TVP) | NO | - | CODE-BACKED | List of GCIDs to check. |
| 2 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID (from @Gcids.Id). |
| 3 | IsBlocked (output) | bit | YES | - | CODE-BACKED | Whether the account is blocked, from Dictionary_PlayerStatus. |
| 4 | PlayerStatusReasonId (output) | int | YES | - | CODE-BACKED | Reason for current player status. FK to Dictionary.PlayerStatusReasons. |
| 5 | PlayerStatusSubReasonId (output) | int | YES | - | CODE-BACKED | Sub-reason for status. FK to Dictionary.PlayerStatusSubReasons. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Gcids | dbo.Real_Customer | JOIN | Customer data + status IDs |
| PlayerStatusID | dbo.Dictionary_PlayerStatus | JOIN | IsBlocked flag resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Batch blocking status check |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetUsersPlayerStatus (procedure)
+-- dbo.Real_Customer (table)
+-- dbo.Dictionary_PlayerStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | JOIN - status IDs |
| dbo.Dictionary_PlayerStatus | Table | JOIN - IsBlocked resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called by application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check player status
```sql
DECLARE @ids dbo.IdList
INSERT @ids VALUES (1001), (1002), (1003)
EXEC Customer.GetUsersPlayerStatus @Gcids = @ids
```

### 8.2 Direct query
```sql
SELECT rc.GCID, ps.IsBlocked, rc.PlayerStatusReasonID, rc.PlayerStatusSubReasonID
FROM dbo.Real_Customer rc WITH (NOLOCK)
JOIN dbo.Dictionary_PlayerStatus ps ON ps.PlayerStatusID = rc.PlayerStatusID
WHERE rc.GCID IN (1001, 1002, 1003)
```

### 8.3 Find blocked users
```sql
SELECT rc.GCID, ps.IsBlocked
FROM dbo.Real_Customer rc WITH (NOLOCK)
JOIN dbo.Dictionary_PlayerStatus ps ON ps.PlayerStatusID = rc.PlayerStatusID
JOIN @ids ids ON ids.Id = rc.GCID
WHERE ps.IsBlocked = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetUsersPlayerStatus | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetUsersPlayerStatus.sql*
