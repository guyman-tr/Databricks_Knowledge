# Customer.CustomerAvatarsGetCIDsToDelete

> Returns CIDs of users whose avatars should be deleted as part of GDPR right-to-be-forgotten execution.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No input params, returns CID list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.CustomerAvatarsGetCIDsToDelete reads from dbo.GDPR_UserExecution to get the list of user CIDs queued for avatar deletion under GDPR right-to-be-forgotten processing. The avatar cleanup service calls this to determine which user photos to remove from CDN and the Avatars table.

---

## 2. Business Logic

No complex business logic. Single SELECT from dbo.GDPR_UserExecution.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters. Returns result set with CID column.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.GDPR_UserExecution | SELECT FROM | Reads GDPR deletion queue |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.CustomerAvatarsGetCIDsToDelete (procedure)
  +-- dbo.GDPR_UserExecution (table, external)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.GDPR_UserExecution | Table | SELECT FROM |

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

### 8.1 Get CIDs to delete
```sql
EXEC Customer.CustomerAvatarsGetCIDsToDelete
```

### 8.2 Count pending deletions
```sql
SELECT COUNT(*) FROM dbo.GDPR_UserExecution WITH (NOLOCK)
```

### 8.3 Delete avatars for returned CIDs
```sql
DECLARE @CIDs TABLE (CID INT)
INSERT INTO @CIDs EXEC Customer.CustomerAvatarsGetCIDsToDelete
DELETE a FROM Customer.Avatars a JOIN @CIDs c ON a.CID = c.CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.CustomerAvatarsGetCIDsToDelete | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.CustomerAvatarsGetCIDsToDelete.sql*
