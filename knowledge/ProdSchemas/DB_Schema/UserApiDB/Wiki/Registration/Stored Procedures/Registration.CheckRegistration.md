# Registration.CheckRegistration

> Checks if a user is registered by email (without NOLOCK for concurrency safety), returning GCID, CIDs, and username.

| Property | Value |
|----------|-------|
| **Schema** | Registration |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @email (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Registration.CheckRegistration verifies during the registration flow whether an email is already registered. Importantly, it does NOT use NOLOCK hints - this prevents phantom reads that could allow duplicate registrations. Joins CustomerIdentification, BasicUserInfo, and ContactUserInfo on GCID.

---

## 2. Business Logic

No complex logic. JOIN on GCID with email filter on LowerEmail (case-insensitive). No NOLOCK intentionally for data consistency during registration.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @email | varchar(50) (IN) | NO | - | CODE-BACKED | Email to check. Converted to lowercase for comparison. |

Output: GCID, RealCID, DemoCID, UserName.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.CustomerIdentification | JOIN | CID mapping |
| - | Customer.BasicUserInfo | JOIN | Username |
| - | Customer.ContactUserInfo | JOIN | Email lookup (LowerEmail) |

### 5.2 Referenced By (other objects point to this)

Registration flow application services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Registration.CheckRegistration (procedure)
  +-- Customer.CustomerIdentification (table) [done]
  +-- Customer.BasicUserInfo (table) [done]
  +-- Customer.ContactUserInfo (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerIdentification | Table | JOIN |
| Customer.BasicUserInfo | Table | JOIN |
| Customer.ContactUserInfo | Table | JOIN (LowerEmail filter) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Intentionally no NOLOCK for registration consistency.

---

## 8. Sample Queries

### 8.1 Check registration
```sql
EXEC Registration.CheckRegistration @email = 'user@example.com'
```

### 8.2 Verify empty result (not registered)
```sql
EXEC Registration.CheckRegistration @email = 'nonexistent@example.com'
-- Empty result = email not registered
```

### 8.3 Direct equivalent
```sql
SELECT i.GCID, i.CID AS RealCID, i.DemoCID, b.UserName
FROM Customer.CustomerIdentification i JOIN Customer.BasicUserInfo b ON i.GCID = b.GCID
JOIN Customer.ContactUserInfo c ON i.GCID = c.GCID WHERE c.LowerEmail = LOWER('user@example.com')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Registration.CheckRegistration | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Registration/Stored Procedures/Registration.CheckRegistration.sql*
