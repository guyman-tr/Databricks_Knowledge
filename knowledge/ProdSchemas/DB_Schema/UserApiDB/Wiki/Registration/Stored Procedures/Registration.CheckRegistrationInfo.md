# Registration.CheckRegistrationInfo

> Alternative registration check using Real_CustomerStatic (legacy) instead of Customer tables, without NOLOCK for concurrency safety.

| Property | Value |
|----------|-------|
| **Schema** | Registration |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @email (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Registration.CheckRegistrationInfo is an alternative version of CheckRegistration that reads from Real_CustomerStatic (dbo synonym to legacy table) instead of Customer.BasicUserInfo + Customer.ContactUserInfo. Same purpose: verify email registration without NOLOCK. Returns GCID, RealCID, DemoCID, UserName.

---

## 2. Business Logic

Same as CheckRegistration but via legacy path (Real_CustomerStatic).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @email | varchar(50) (IN) | NO | - | CODE-BACKED | Email to check. |

Output: GCID, RealCID, DemoCID, UserName.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.CustomerIdentification | JOIN | CID mapping |
| - | Real_CustomerStatic (dbo synonym) | JOIN | User data + email |

### 5.2 Referenced By (other objects point to this)

Registration flow.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Registration.CheckRegistrationInfo (procedure)
  +-- Customer.CustomerIdentification (table) [done]
  +-- dbo.Real_CustomerStatic (synonym)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerIdentification | Table | JOIN |
| dbo.Real_CustomerStatic | Synonym | JOIN |

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

### 8.1 Check registration
```sql
EXEC Registration.CheckRegistrationInfo @email = 'user@example.com'
```

### 8.2 Compare with modern version
```sql
EXEC Registration.CheckRegistration @email = 'user@example.com' -- Modern
EXEC Registration.CheckRegistrationInfo @email = 'user@example.com' -- Legacy
```

### 8.3 Direct equivalent
```sql
SELECT i.GCID, i.CID AS RealCID, i.DemoCID, c.UserName
FROM Customer.CustomerIdentification i JOIN Real_CustomerStatic c ON i.GCID = c.GCID
WHERE c.LowerEmail = LOWER('user@example.com')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Registration.CheckRegistrationInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Registration/Stored Procedures/Registration.CheckRegistrationInfo.sql*
