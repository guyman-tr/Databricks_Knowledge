# Customer.DeleteFailedUser

> Transactionally deletes all profile data for a failed registration, removing rows from 7 core Customer tables.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.DeleteFailedUser performs a complete cleanup of a failed user registration. When a registration fails mid-process, partial data may exist across multiple Customer tables. This procedure transactionally removes all traces: BasicUserInfo, ContactUserInfo, AccountUserInfo, RiskUserInfo, UserSettings, CustomerIdentification, and ApplicationActivation. The transaction ensures either all data is removed or none (atomic cleanup).

---

## 2. Business Logic

### 2.1 Transactional Multi-Table Cleanup

**What**: Atomic deletion across 7 tables within a transaction.

**Columns/Parameters Involved**: `@GCID`

**Rules**:
- Wrapped in BEGIN TRAN / COMMIT
- Deletes from 7 tables in order: BasicUserInfo, ContactUserInfo, AccountUserInfo, RiskUserInfo, UserSettings, CustomerIdentification, ApplicationActivation
- On error: ROLLBACK (all or nothing)
- Returns 0 on success, Error_Number() on failure

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int (IN) | NO | - | CODE-BACKED | Global Customer ID of the failed registration to clean up. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.BasicUserInfo | DELETE FROM | Removes basic info |
| - | Customer.ContactUserInfo | DELETE FROM | Removes contact info |
| - | Customer.AccountUserInfo | DELETE FROM | Removes account info |
| - | Customer.RiskUserInfo | DELETE FROM | Removes risk info |
| - | Customer.UserSettings | DELETE FROM | Removes settings |
| - | Customer.CustomerIdentification | DELETE FROM | Removes ID mapping |
| - | Customer.ApplicationActivation | DELETE FROM | Removes activation records |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.DeleteFailedUser (procedure)
  +-- Customer.BasicUserInfo (table) [done]
  +-- Customer.ContactUserInfo (table) [done]
  +-- Customer.AccountUserInfo (table) [done]
  +-- Customer.RiskUserInfo (table) [done]
  +-- Customer.UserSettings (table) [done]
  +-- Customer.CustomerIdentification (table) [done]
  +-- Customer.ApplicationActivation (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BasicUserInfo | Table | DELETE FROM |
| Customer.ContactUserInfo | Table | DELETE FROM |
| Customer.AccountUserInfo | Table | DELETE FROM |
| Customer.RiskUserInfo | Table | DELETE FROM |
| Customer.UserSettings | Table | DELETE FROM |
| Customer.CustomerIdentification | Table | DELETE FROM |
| Customer.ApplicationActivation | Table | DELETE FROM |

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

### 8.1 Clean up a failed registration
```sql
EXEC Customer.DeleteFailedUser @GCID = 12345
```

### 8.2 Check return code
```sql
DECLARE @ReturnCode INT
EXEC @ReturnCode = Customer.DeleteFailedUser @GCID = 12345
SELECT @ReturnCode AS Result -- 0 = success
```

### 8.3 Verify cleanup
```sql
SELECT 'BasicUserInfo' AS Tbl, COUNT(*) AS Cnt FROM Customer.BasicUserInfo WITH (NOLOCK) WHERE GCID = @GCID
UNION ALL SELECT 'ContactUserInfo', COUNT(*) FROM Customer.ContactUserInfo WITH (NOLOCK) WHERE GCID = @GCID
UNION ALL SELECT 'AccountUserInfo', COUNT(*) FROM Customer.AccountUserInfo WITH (NOLOCK) WHERE GCID = @GCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.DeleteFailedUser | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.DeleteFailedUser.sql*
