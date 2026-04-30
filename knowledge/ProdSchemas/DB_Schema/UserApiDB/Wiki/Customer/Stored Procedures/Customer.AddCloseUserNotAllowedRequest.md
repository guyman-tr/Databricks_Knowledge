# Customer.AddCloseUserNotAllowedRequest

> Inserts a record when a user's account closure is blocked by a specific condition.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Gcid + @CloseUserNotAllowedReasonId (input params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.AddCloseUserNotAllowedRequest logs a blocked account closure attempt. When the system determines a user cannot close their account (open positions, high equity, etc.), this procedure records the specific blocking reason. The Occurred timestamp defaults from the table's DEFAULT constraint.

---

## 2. Business Logic

No complex business logic. Single INSERT into Customer.CloseUserNotAllowedRequest.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | int (IN) | NO | - | CODE-BACKED | Global Customer ID of the user whose closure was blocked. |
| 2 | @CloseUserNotAllowedReasonId | int (IN) | NO | - | CODE-BACKED | Blocking condition. FK to Dictionary.CloseUserNotAllowedReason: 1=TooHighEquity, 2=OpenOrders, 3=OpenPositions, 4=OpenMirrors, 5=OpenCashouts, 6=WalletNotAllowedToClose. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.CloseUserNotAllowedRequest | INSERT INTO | Writes blocked closure record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.AddCloseUserNotAllowedRequest (procedure)
  +-- Customer.CloseUserNotAllowedRequest (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CloseUserNotAllowedRequest | Table | INSERT INTO |

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

### 8.1 Record a blocked closure
```sql
EXEC Customer.AddCloseUserNotAllowedRequest @Gcid = 12345, @CloseUserNotAllowedReasonId = 3 -- OpenPositions
```

### 8.2 Record multiple blocking conditions
```sql
EXEC Customer.AddCloseUserNotAllowedRequest @Gcid = 12345, @CloseUserNotAllowedReasonId = 3
EXEC Customer.AddCloseUserNotAllowedRequest @Gcid = 12345, @CloseUserNotAllowedReasonId = 5
```

### 8.3 Verify the record
```sql
EXEC Customer.AddCloseUserNotAllowedRequest @Gcid = 12345, @CloseUserNotAllowedReasonId = 1
SELECT * FROM Customer.CloseUserNotAllowedRequest WITH (NOLOCK) WHERE Gcid = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.AddCloseUserNotAllowedRequest | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.AddCloseUserNotAllowedRequest.sql*
