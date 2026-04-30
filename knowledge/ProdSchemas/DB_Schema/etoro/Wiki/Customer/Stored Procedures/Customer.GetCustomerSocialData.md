# Customer.GetCustomerSocialData

> Returns the minimal social identity fields (username, email, CID, GCID) for a customer identified by GCID; used by social and network features that need a lightweight customer identity record.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID (global customer ID to look up) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetCustomerSocialData retrieves the minimal customer identity fields needed by eToro's social and community features: username, email, integer CID, and GCID. It accepts a GCID (the cross-product group identifier) rather than a CID, making it suitable for callers that operate at the GCID level (e.g., social graph, feed, copy trading discovery).

The "Social" label indicates this is the data set needed for social interactions - displaying a user's profile in feeds, notifications, and community features - as opposed to financial or compliance data. The procedure is the GCID-based counterpart to Customer.GetCustomerSocialDataByCID (which accepts CID instead).

TOP 1 ensures a single row even if the underlying GCID maps to multiple CIDs (possible in multi-account edge cases).

---

## 2. Business Logic

### 2.1 GCID-Based Lookup with TOP 1 Guard

**What**: Returns a single customer record for a GCID, handling edge cases where GCID maps to multiple CIDs.

**Columns/Parameters Involved**: `@GCID`, `GCID`

**Rules**:
- WHERE GCID = @GCID - may match multiple rows if GCID is shared across real/demo accounts
- TOP 1 ensures exactly one row is returned; ordering is non-deterministic (no ORDER BY)
- Returns 0 rows if GCID not found

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | NO | - | CODE-BACKED | Global Customer ID (cross-product group identifier linking real and demo accounts for the same physical person). The procedure returns data from Customer.Customer filtered by this GCID. |

**Output result set:**

| Column | Source | Business Meaning |
|--------|--------|-----------------|
| UserName | Customer.Customer.UserName | Customer's public username on eToro (display name in social feed) |
| Email | Customer.Customer.Email | Customer's email address (PII - masked for unauthorized users) |
| GCID | Customer.Customer.GCID | Group Customer ID - cross-product identity returned alongside integer IDs |
| CID | Customer.Customer.CID | Integer Customer ID - the primary database key |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.Customer | Read | Returns social identity fields filtered by GCID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCustomerSocialData (procedure)
└── Customer.Customer (view)
      └── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | Source of UserName, Email, GCID, CID filtered by GCID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TOP 1 | Result cap | Returns one row even if multiple CIDs share the GCID; row is non-deterministically selected (no ORDER BY) |

---

## 8. Sample Queries

### 8.1 Get social identity by GCID

```sql
EXEC Customer.GetCustomerSocialData @GCID = 9876543
```

### 8.2 Compare with CID-based variant

```sql
-- By GCID:
EXEC Customer.GetCustomerSocialData @GCID = 9876543
-- By CID:
EXEC Customer.GetCustomerSocialDataByCID @CID = 12345678
```

### 8.3 Direct query equivalent

```sql
SELECT TOP 1 UserName, Email, GCID, CID
FROM Customer.Customer WITH (NOLOCK)
WHERE GCID = 9876543
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 8/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetCustomerSocialData | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetCustomerSocialData.sql*
