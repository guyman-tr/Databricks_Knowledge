# Customer.UpdateBasicInfo

> Updates basic profile fields in Customer.BasicUserInfo (new-style) with session context and ISNULL partial update pattern.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE Customer.BasicUserInfo with session context |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateBasicInfo updates basic demographic data (names, gender, language, birth date, player level) in the normalized Customer.BasicUserInfo table. Uses ISNULL for partial updates and sets session context for audit trail. Returns SELECT 1 on success. This is the new-style version; UpdateBasicUserInfo is the legacy equivalent.

---

## 2. Business Logic

### 2.1 Session Context + Partial Update

**Rules**:
- Sets correlationId/clientRequestId/requestTime in session context before UPDATE
- Each column uses ISNULL(@param, col) - only non-NULL params are applied
- Returns SELECT 1 if @@RowCount > 0

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @cid | int | YES | NULL | CODE-BACKED | CID (not used in UPDATE - interface compatibility). |
| 3 | @uName | varchar(20) | YES | NULL | CODE-BACKED | Username (not used in UPDATE - interface compatibility). |
| 4 | @fName | nvarchar(50) | YES | NULL | CODE-BACKED | First name. |
| 5 | @lName | nvarchar(50) | YES | NULL | CODE-BACKED | Last name. |
| 6 | @mName | nvarchar(50) | YES | NULL | CODE-BACKED | Middle name. |
| 7 | @languageId | int | YES | NULL | CODE-BACKED | Language. FK to Dictionary.Language. |
| 8 | @dob | datetime | YES | NULL | CODE-BACKED | Date of birth. |
| 9 | @gender | char(1) | YES | NULL | CODE-BACKED | Gender (M/F). |
| 10 | @level | int | YES | NULL | CODE-BACKED | Player level. FK to Dictionary.PlayerLevel. |
| 11 | @correlationId | varchar(50) | YES | NULL | CODE-BACKED | Audit trail correlation. |
| 12 | @clientRequestId | varchar(50) | YES | NULL | CODE-BACKED | Audit trail client request. |
| 13 | @requestTime | datetime | YES | NULL | CODE-BACKED | Audit trail timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.BasicUserInfo | UPDATE | Basic profile data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Profile updates (new path) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateBasicInfo (procedure)
+-- Customer.BasicUserInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BasicUserInfo | Table | UPDATE |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update language only
```sql
EXEC Customer.UpdateBasicInfo @gcid=12345, @languageId=2
```

### 8.2 Update name with audit trail
```sql
EXEC Customer.UpdateBasicInfo @gcid=12345, @fName=N'John', @lName=N'Doe',
    @correlationId='abc-123', @clientRequestId='req-456', @requestTime=GETUTCDATE()
```

### 8.3 Compare with legacy
```sql
-- UpdateBasicInfo: Customer.BasicUserInfo (new, with session context)
-- UpdateBasicUserInfo: dbo.Real_UpdateBasicUserInfoRemote (legacy, with async action queue)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.UpdateBasicInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.UpdateBasicInfo.sql*
