# dbo.InsertGlobalCustomer

> Generates a new GCID by inserting into GlobalCustomer and returning the IDENTITY value. Logs errors to History.LogErrorGeneral on failure.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UserName + @Email (input params), returns GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.InsertGlobalCustomer is the GCID generation entry point. Inserts a new row into dbo.GlobalCustomer with the username and email, and returns the new SCOPE_IDENTITY() as the GCID. On error, logs to History.LogErrorGeneral via the InsertLogErrorGeneral synonym and returns -1.

---

## 2. Business Logic

INSERT -> SCOPE_IDENTITY() -> RETURN. Error handling logs to History.LogErrorGeneral.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserName | varchar(20) (IN) | NO | - | CODE-BACKED | Username for the new user. |
| 2 | @Email | varchar(50) (IN) | NO | - | CODE-BACKED | Email for the new user. |
| 3 | RETURN | int | NO | - | CODE-BACKED | New GCID on success, -1 on error. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.GlobalCustomer | INSERT INTO | Creates GCID |
| - | dbo.InsertLogErrorGeneral | EXEC (synonym) | Error logging |

### 5.2 Referenced By (other objects point to this)

Registration flow.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.InsertGlobalCustomer (procedure)
  +-- dbo.GlobalCustomer (table) [done]
  +-- dbo.InsertLogErrorGeneral (synonym)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.GlobalCustomer | Table | INSERT INTO |
| dbo.InsertLogErrorGeneral | Synonym | Error logging |

### 6.2 Objects That Depend On This

Registration procedures.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Generate GCID
```sql
DECLARE @newGCID INT
EXEC @newGCID = dbo.InsertGlobalCustomer @UserName = 'testuser', @Email = 'test@example.com'
SELECT @newGCID AS NewGCID
```

### 8.2 Error handling
```sql
DECLARE @result INT
EXEC @result = dbo.InsertGlobalCustomer @UserName = 'testuser', @Email = 'test@example.com'
IF @result = -1 PRINT 'Error occurred'
```

### 8.3 Verify
```sql
SELECT TOP 1 * FROM dbo.GlobalCustomer WITH (NOLOCK) ORDER BY GlobalCID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: dbo.InsertGlobalCustomer | Type: Stored Procedure | Source: UserApiDB/UserApiDB/dbo/Stored Procedures/dbo.InsertGlobalCustomer.sql*
