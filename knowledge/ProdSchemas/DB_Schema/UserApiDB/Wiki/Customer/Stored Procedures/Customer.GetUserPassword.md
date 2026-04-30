# Customer.GetUserPassword

> Retrieves the username and password hash for a customer - used for authentication/login validation.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns UserName + Password for a GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetUserPassword retrieves the stored username and password (hash) for authentication purposes. This is called during the login flow to validate user credentials. The password field contains a hash, not the plaintext password.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple credential lookup.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | UserName (output) | varchar | YES | - | CODE-BACKED | Account username. |
| 3 | Password (output) | varchar | YES | - | CODE-BACKED | Password hash (not plaintext). Used for authentication validation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | dbo.Real_Customer | FROM | Credential lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Login/authentication |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetUserPassword (procedure)
+-- dbo.Real_Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | FROM - credentials |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Authentication service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get credentials
```sql
EXEC Customer.GetUserPassword @gcid = 12345
```

### 8.2 Direct query
```sql
SELECT UserName, Password FROM dbo.Real_Customer WITH (NOLOCK) WHERE GCID = @gcid
```

### 8.3 Check if user exists
```sql
SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.Real_Customer WITH (NOLOCK) WHERE GCID = @gcid) THEN 1 ELSE 0 END AS UserExists
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetUserPassword | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetUserPassword.sql*
