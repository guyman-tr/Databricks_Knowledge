# Customer.GetLinkedCustomer

> Finds all other customer accounts sharing the same LinkedAccountHash1 as the given CID; used for duplicate account detection and linked account investigation.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (anchor customer for hash lookup) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetLinkedCustomer identifies other eToro customer accounts that are likely controlled by the same person as a given CID, based on a shared LinkedAccountHash1 fingerprint. It is a duplicate account detection utility: when compliance, fraud, or customer service needs to know whether a customer has registered under multiple identities, this procedure finds all sibling accounts.

LinkedAccountHash1 is a hash derived from personally identifiable registration signals (device fingerprint, IP, email domain, or similar PII-adjacent attributes) stored in Customer.CustomerStatic. Accounts that share the same hash value were likely registered using the same underlying identity or device, even if they used different email addresses or usernames.

The self-exclusion (`CID <> @CID`) ensures the result contains only OTHER accounts - not the anchor customer itself. The result is a flat list of CIDs that the caller can use for further investigation (e.g., checking sanctions, block status, or trade activity across linked accounts).

---

## 2. Business Logic

### 2.1 Hash-Based Duplicate Account Discovery

**What**: Returns CIDs of all accounts sharing the same LinkedAccountHash1 as the input customer.

**Columns/Parameters Involved**: `@CID`, `CID`, `LinkedAccountHash1`

**Rules**:
- Outer WHERE: `CID <> @CID` - excludes the anchor customer from results
- AND `LinkedAccountHash1 = (SELECT LinkedAccountHash1 FROM CustomerStatic WHERE CID = @CID)` - subquery resolves the anchor's hash, outer query matches it
- If the anchor customer has NULL LinkedAccountHash1 (hash not computed): the subquery returns NULL, and `NULL = NULL` evaluates to UNKNOWN (not TRUE in SQL), so no rows are returned
- Returns only CID - the caller is expected to join further for account details if needed
- No NOLOCK hint: reads are locking (default READ COMMITTED) - appropriate for compliance use where consistent reads matter

### 2.2 Null Hash Behavior

LinkedAccountHash1 may be NULL for customers where the hash was not computed (legacy accounts, incomplete registration data). In that case, the procedure returns no rows - which prevents false positives from incorrectly linking all NULL-hash customers together. This is by design.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the anchor account whose linked siblings to find. The procedure resolves this CID's LinkedAccountHash1 and returns all other CIDs with the same hash. |

**Output result set:**

| Column | Source | Business Meaning |
|--------|--------|-----------------|
| CID | Customer.CustomerStatic.CID | Customer ID of each account that shares the same LinkedAccountHash1 as the input @CID. Excludes the input @CID itself. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerStatic | Read (subquery) | Resolves the anchor CID's LinkedAccountHash1 |
| LinkedAccountHash1 | Customer.CustomerStatic | Read (outer query) | Matches hash value to find sibling accounts |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase (called by compliance, fraud investigation, and customer service tooling).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetLinkedCustomer (procedure)
└── Customer.CustomerStatic (table)
      └── LinkedAccountHash1 (column - hash for duplicate detection)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Subquery resolves anchor CID's hash; outer query matches hash across all other CIDs |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CID <> @CID | Self-exclusion | The anchor customer is excluded from results - only sibling accounts returned |
| NULL hash safety | SQL semantics | If LinkedAccountHash1 is NULL for the anchor, the = comparison returns no rows (NULL != NULL in SQL) - prevents false mass-linking |
| No NOLOCK | Isolation | Default READ COMMITTED - consistent reads for compliance use cases |

---

## 8. Sample Queries

### 8.1 Find all accounts linked to a customer

```sql
EXEC Customer.GetLinkedCustomer @CID = 12345678
-- Returns CIDs of all other accounts sharing the same LinkedAccountHash1
```

### 8.2 Direct query equivalent

```sql
SELECT CID
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE CID <> 12345678
AND LinkedAccountHash1 = (
    SELECT LinkedAccountHash1
    FROM Customer.CustomerStatic WITH (NOLOCK)
    WHERE CID = 12345678
)
```

### 8.3 Get details of linked accounts

```sql
CREATE TABLE #Linked (CID INT)
INSERT INTO #Linked EXEC Customer.GetLinkedCustomer @CID = 12345678
SELECT cs.CID, cs.UserName_LOWER, cs.GCID, cs.CreateDate
FROM Customer.CustomerStatic cs WITH (NOLOCK)
INNER JOIN #Linked l ON cs.CID = l.CID
DROP TABLE #Linked
```

### 8.4 Check LinkedAccountHash1 for a customer

```sql
SELECT CID, GCID, LinkedAccountHash1
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE CID = 12345678
-- If NULL: GetLinkedCustomer will return no rows (safe, no false links)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetLinkedCustomer | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetLinkedCustomer.sql*
