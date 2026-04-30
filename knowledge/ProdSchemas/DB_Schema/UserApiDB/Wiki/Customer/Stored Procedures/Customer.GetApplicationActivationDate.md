# Customer.GetApplicationActivationDate

> Returns application activation dates for a user, optionally filtered by a specific application ID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID + @ApplicationID (input params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetApplicationActivationDate retrieves when a user activated specific applications. When @ApplicationID is provided, returns that specific activation; when NULL, returns all activations for the user.

---

## 2. Business Logic

No complex business logic. SELECT with optional filter (ApplicationID = @ApplicationID OR @ApplicationID IS NULL).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int (IN) | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @ApplicationID | int (IN) | YES | NULL | CODE-BACKED | Optional: specific application to filter. NULL returns all. |

Output: ApplicationID, ActivationDate.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.ApplicationActivation | SELECT FROM | Reads activation records |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetApplicationActivationDate (procedure)
  +-- Customer.ApplicationActivation (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ApplicationActivation | Table | SELECT FROM WITH NOLOCK |

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

### 8.1 Get all activations
```sql
EXEC Customer.GetApplicationActivationDate @GCID = 12345
```

### 8.2 Get specific activation
```sql
EXEC Customer.GetApplicationActivationDate @GCID = 12345, @ApplicationID = 1
```

### 8.3 Direct query
```sql
SELECT ApplicationID, ActivationDate FROM Customer.ApplicationActivation WITH (NOLOCK) WHERE GCID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetApplicationActivationDate | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetApplicationActivationDate.sql*
