# Customer.ActivateApplication

> Inserts a new application activation record for a user, recording the activation timestamp.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID + @ApplicationID (input params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.ActivateApplication records when a user activates a specific application or platform feature. It inserts a single row into Customer.ApplicationActivation with the current UTC timestamp. This is a simple write-only procedure with no return value.

---

## 2. Business Logic

No complex business logic. Single INSERT with GETUTCDATE() for activation timestamp.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int (IN) | NO | - | CODE-BACKED | Global Customer ID of the user activating the application. |
| 2 | @ApplicationID | int (IN) | NO | - | CODE-BACKED | Identifier of the application/feature being activated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.ApplicationActivation | INSERT INTO | Writes activation record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.ActivateApplication (procedure)
  +-- Customer.ApplicationActivation (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ApplicationActivation | Table | INSERT INTO |

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

### 8.1 Activate an application
```sql
EXEC Customer.ActivateApplication @GCID = 12345, @ApplicationID = 1
```

### 8.2 Check activation result
```sql
EXEC Customer.ActivateApplication @GCID = 12345, @ApplicationID = 2
SELECT * FROM Customer.ApplicationActivation WITH (NOLOCK) WHERE GCID = 12345
```

### 8.3 Idempotency check
```sql
-- Will fail on duplicate PK if already activated
EXEC Customer.ActivateApplication @GCID = 12345, @ApplicationID = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.ActivateApplication | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.ActivateApplication.sql*
