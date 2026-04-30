# Customer.GetCustomersByOriginalCID

> Finds all customers who share the same OriginalCID (affiliate acquisition origin) as a given username; used to identify co-acquired customer groups or affiliate referral clusters.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UserNameLower (lowercased username to look up) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetCustomersByOriginalCID finds all customers whose OriginalCID matches that of a given customer (identified by lowercased username). It answers the question: "Who else was acquired by the same referral source as this customer?"

OriginalCID stores the CID of the referring customer - the person or affiliate account that brought the queried customer to eToro. By finding all customers sharing the same OriginalCID, the procedure reveals a group of customers that were all referred by the same source, which is valuable for: affiliate fraud investigations (if many accounts share an OriginalCID pointing to an inactive account), duplicate account detection (multiple accounts referring each other), and affiliate performance analysis.

Despite the name "GetCustomersByOriginalCID", the input is a username - the procedure first resolves the username to its OriginalCID via a subquery, then returns all customers sharing that OriginalCID.

---

## 2. Business Logic

### 2.1 Username-to-OriginalCID Resolution

**What**: Converts the input username to an OriginalCID, then finds all customers sharing that OriginalCID.

**Columns/Parameters Involved**: `@UserNameLower`, `UserName_LOWER`, `OriginalCID`, `GCID`

**Rules**:
- Step 1 (subquery): SELECT OriginalCID WHERE UserName_LOWER = @UserNameLower -> resolves username to OriginalCID
- Step 2 (outer query): SELECT GCID, UserName_LOWER WHERE OriginalCID = (result) -> returns all co-acquired customers
- If username not found: subquery returns NULL -> outer query returns all rows where OriginalCID IS NULL (unintended behavior - callers should validate username exists first)
- If username is not unique: subquery may return multiple values -> causes runtime error (UserName_LOWER has a unique index so this should not occur in practice)
- Includes the queried customer themselves in the results (no self-exclusion)
- UserName_LOWER is the case-folded version of UserName for consistent case-insensitive matching

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserNameLower | varchar(20) | NO | - | CODE-BACKED | Lowercased username of the customer whose OriginalCID is used as the lookup key. Matched against Customer.CustomerStatic.UserName_LOWER (the computed lower-case column). Caller must provide pre-lowercased input. |

**Output result set:**

| Column | Source | Business Meaning |
|--------|--------|-----------------|
| GCID | Customer.CustomerStatic.GCID | Global Customer ID of each co-acquired customer |
| UserName_LOWER | Customer.CustomerStatic.UserName_LOWER | Lowercased username of each co-acquired customer |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @UserNameLower | Customer.CustomerStatic.UserName_LOWER | Read (subquery) | Resolves username to OriginalCID |
| OriginalCID | Customer.CustomerStatic | Read (WHERE match) | Finds all customers with matching OriginalCID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCustomersByOriginalCID (procedure)
└── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Subquery: resolve username -> OriginalCID. Outer query: find all with matching OriginalCID. |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Subquery scalar | Implicit | If @UserNameLower matches 0 rows, OriginalCID in outer query = NULL (returns all NULL-OriginalCID customers) |
| No result cap | Design | No TOP N limit - large referral networks could return thousands of rows |

---

## 8. Sample Queries

### 8.1 Find all customers with same affiliate origin as a given user

```sql
EXEC Customer.GetCustomersByOriginalCID @UserNameLower = 'johndoe'
```

### 8.2 Reproduce the lookup directly

```sql
DECLARE @OrigCID INT
SELECT @OrigCID = OriginalCID
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE UserName_LOWER = 'johndoe'

SELECT GCID, UserName_LOWER
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE OriginalCID = @OrigCID
```

### 8.3 Check OriginalCID for a group of customers

```sql
SELECT OriginalCID, COUNT(*) AS CustomerCount
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE OriginalCID IS NOT NULL
GROUP BY OriginalCID
ORDER BY CustomerCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetCustomersByOriginalCID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetCustomersByOriginalCID.sql*
