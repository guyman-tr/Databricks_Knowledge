# Customer.UpdateBasicUserInfo

> Legacy basic profile update - delegates to dbo.Real_UpdateBasicUserInfoRemote and queues async demo update via ActionsToExecute_Registration (ActionID=9).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | EXEC Real_UpdateBasicUserInfoRemote + async action queue |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateBasicUserInfo is the legacy version of UpdateBasicInfo. It delegates to dbo.Real_UpdateBasicUserInfoRemote for the actual update, then queues an async action (ActionID=9) in ActionsToExecute_Registration to sync the changes to the demo environment. Returns SELECT 1 on success.

---

## 2. Business Logic

### 2.1 Async Demo Sync

**What**: After the real account update, queues an XML action for demo sync.

**Rules**:
- EXEC Real_UpdateBasicUserInfoRemote (synchronous update)
- Build XML with all parameters using FOR XML Path
- INSERT into ActionsToExecute_Registration with ActionID=9
- Demo sync happens asynchronously via the action processing system

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @cid | int | YES | NULL | CODE-BACKED | CID (not used directly). |
| 3 | @uName | varchar(20) | YES | NULL | CODE-BACKED | Username (not used). |
| 4 | @fName | nvarchar(50) | YES | NULL | CODE-BACKED | First name. |
| 5 | @lName | nvarchar(50) | YES | NULL | CODE-BACKED | Last name. |
| 6 | @mName | nvarchar(50) | YES | NULL | CODE-BACKED | Middle name. |
| 7 | @languageId | int | YES | NULL | CODE-BACKED | Language. |
| 8 | @dob | datetime | YES | NULL | CODE-BACKED | Date of birth. |
| 9 | @gender | char(1) | YES | NULL | CODE-BACKED | Gender. |
| 10 | @level | int | YES | NULL | CODE-BACKED | Player level. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | dbo.Real_UpdateBasicUserInfoRemote | EXEC | Legacy update |
| XML | dbo.ActionsToExecute_Registration | INSERT | Async demo sync (ActionID=9) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Legacy profile updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateBasicUserInfo (procedure)
+-- dbo.Real_UpdateBasicUserInfoRemote (procedure)
+-- dbo.ActionsToExecute_Registration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_UpdateBasicUserInfoRemote | Procedure | EXEC |
| dbo.ActionsToExecute_Registration | Table | INSERT (async action) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Legacy callers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH | Error handling | Catches action queue insert failures, re-throws |

---

## 8. Sample Queries

### 8.1 Update basic info (legacy)
```sql
EXEC Customer.UpdateBasicUserInfo @gcid=12345, @fName=N'John', @lName=N'Doe', @languageId=2
```

### 8.2 Prefer new version
```sql
-- Use Customer.UpdateBasicInfo for new development
```

### 8.3 Check async queue
```sql
SELECT * FROM dbo.ActionsToExecute_Registration WITH (NOLOCK)
WHERE ActionID = 9 ORDER BY InsertedToQueue DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.UpdateBasicUserInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.UpdateBasicUserInfo.sql*
