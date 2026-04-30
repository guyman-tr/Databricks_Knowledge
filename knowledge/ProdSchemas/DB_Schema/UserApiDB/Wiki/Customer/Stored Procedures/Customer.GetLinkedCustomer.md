# Customer.GetLinkedCustomer

> Finds other customer accounts linked to the given CID via the same LinkedAccountHash - used for detecting related/duplicate accounts.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns CIDs of linked accounts |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetLinkedCustomer identifies other customer accounts that share the same LinkedAccountHash1 value as the given account. This hash-based linking is used to detect accounts that belong to the same person or household - for example, accounts created with the same device fingerprint, browser fingerprint, or other identifying characteristics.

This procedure exists to support fraud detection, compliance monitoring, and multi-account policy enforcement. When the system detects that a customer has linked accounts, it can apply restrictions or flag the accounts for review.

The procedure reads from dbo.Real_CustomerStatic, finding all CIDs where LinkedAccountHash1 matches the input CID's hash, excluding the input CID itself.

---

## 2. Business Logic

### 2.1 Hash-Based Account Linking

**What**: Accounts are linked by matching a precomputed hash value (LinkedAccountHash1), which may be derived from device fingerprints, IP patterns, or other identifying information.

**Columns/Parameters Involved**: `@CID`, `LinkedAccountHash1`

**Rules**:
- Finds the LinkedAccountHash1 for the given @CID via subquery
- Returns all OTHER CIDs with the same hash value
- Excludes the input CID from results (CID <> @CID)
- If no other accounts share the hash, returns empty result set

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID to find linked accounts for. Note: takes CID, not GCID. |
| 2 | CID (output) | int | - | - | CODE-BACKED | Customer IDs of other accounts sharing the same LinkedAccountHash1 value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | dbo.Real_CustomerStatic | Lookup | Reads LinkedAccountHash1 for hash-based account linking |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Called for fraud detection and multi-account checks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetLinkedCustomer (procedure)
+-- dbo.Real_CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_CustomerStatic | Table | FROM + subquery - matches LinkedAccountHash1 values |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called directly by application code |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find linked accounts
```sql
EXEC Customer.GetLinkedCustomer @CID = 100001
```

### 8.2 Direct query equivalent
```sql
SELECT CID
FROM dbo.Real_CustomerStatic WITH (NOLOCK)
WHERE CID <> @CID
    AND LinkedAccountHash1 = (
        SELECT LinkedAccountHash1
        FROM dbo.Real_CustomerStatic WITH (NOLOCK)
        WHERE CID = @CID
    )
```

### 8.3 Count linked accounts
```sql
SELECT COUNT(*) AS LinkedAccountCount
FROM dbo.Real_CustomerStatic WITH (NOLOCK)
WHERE CID <> @CID
    AND LinkedAccountHash1 = (
        SELECT LinkedAccountHash1
        FROM dbo.Real_CustomerStatic WITH (NOLOCK)
        WHERE CID = @CID
    )
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetLinkedCustomer | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetLinkedCustomer.sql*
