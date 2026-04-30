# Customer.DeleteAvatarsByCid

> Deletes all avatar images (all sizes and versions) for a user by CID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.DeleteAvatarsByCid removes all avatar image records for a user, covering all sizes and versions. Used during GDPR right-to-be-forgotten processing and account cleanup. Note: uses CID (legacy ID), not GCID.

---

## 2. Business Logic

No complex business logic. Single DELETE by CID.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | int (IN) | NO | - | CODE-BACKED | Legacy Customer ID. Deletes all avatars for this CID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.Avatars | DELETE FROM | Removes all avatar records for the CID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.DeleteAvatarsByCid (procedure)
  +-- Customer.Avatars (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Avatars | Table | DELETE FROM |

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

### 8.1 Delete all avatars
```sql
EXEC Customer.DeleteAvatarsByCid @cid = 12345
```

### 8.2 Check before and after
```sql
SELECT COUNT(*) FROM Customer.Avatars WITH (NOLOCK) WHERE CID = 12345
EXEC Customer.DeleteAvatarsByCid @cid = 12345
SELECT COUNT(*) FROM Customer.Avatars WITH (NOLOCK) WHERE CID = 12345
```

### 8.3 Bulk cleanup (from GDPR queue)
```sql
DECLARE @CIDs TABLE (CID INT)
INSERT INTO @CIDs EXEC Customer.CustomerAvatarsGetCIDsToDelete
DECLARE @cid INT
DECLARE cur CURSOR FOR SELECT CID FROM @CIDs
OPEN cur; FETCH NEXT FROM cur INTO @cid
WHILE @@FETCH_STATUS = 0 BEGIN EXEC Customer.DeleteAvatarsByCid @cid = @cid; FETCH NEXT FROM cur INTO @cid END
CLOSE cur; DEALLOCATE cur
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.DeleteAvatarsByCid | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.DeleteAvatarsByCid.sql*
