# Customer.GetCustomerSocialDataByCID

> Returns the minimal social identity fields (username, email, CID, GCID) for a customer identified by CID; CID-based counterpart to Customer.GetCustomerSocialData.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer ID to look up) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetCustomerSocialDataByCID retrieves the minimal social identity data (username, email, CID, GCID) for a customer by their integer CID. It is the CID-based counterpart to Customer.GetCustomerSocialData (which accepts GCID).

The two procedures serve different callers: services operating with integer CIDs use this version; services operating with GCIDs use GetCustomerSocialData. The returned columns are functionally identical (UserName, Email, CID, GCID), just with the column order slightly different (CID before GCID in this version).

---

## 2. Business Logic

### 2.1 CID-Based Lookup with TOP 1 Guard

**What**: Returns a single row for the given CID.

**Columns/Parameters Involved**: `@CID`

**Rules**:
- WHERE CID = @CID - CID is a unique key in Customer.Customer; only 1 row expected
- TOP 1 is a safety guard
- Returns 0 rows if CID not found

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Integer Customer ID (primary database key). Used to look up the customer's social identity fields. |

**Output result set:**

| Column | Source | Business Meaning |
|--------|--------|-----------------|
| UserName | Customer.Customer.UserName | Customer's public username on eToro |
| Email | Customer.Customer.Email | Customer's email address (PII - masked for unauthorized users) |
| CID | Customer.Customer.CID | Integer Customer ID |
| GCID | Customer.Customer.GCID | Global Customer ID - cross-product identity |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Read | Returns social identity fields filtered by CID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCustomerSocialDataByCID (procedure)
└── Customer.Customer (view)
      └── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | Source of UserName, Email, CID, GCID filtered by CID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TOP 1 | Safety guard | CID is a unique key; TOP 1 is a defensive measure only |

---

## 8. Sample Queries

### 8.1 Get social identity by CID

```sql
EXEC Customer.GetCustomerSocialDataByCID @CID = 12345678
```

### 8.2 Compare both social data procedures

```sql
-- CID-based:
EXEC Customer.GetCustomerSocialDataByCID @CID = 12345678
-- GCID-based (use when CID is unknown):
EXEC Customer.GetCustomerSocialData @GCID = 9876543
```

### 8.3 Direct query equivalent

```sql
SELECT TOP 1 UserName, Email, CID, GCID
FROM Customer.Customer WITH (NOLOCK)
WHERE CID = 12345678
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 8/10, Logic: 4/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetCustomerSocialDataByCID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetCustomerSocialDataByCID.sql*
