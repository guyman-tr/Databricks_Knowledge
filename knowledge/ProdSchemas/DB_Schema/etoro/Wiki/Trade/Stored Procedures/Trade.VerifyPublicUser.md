# Trade.VerifyPublicUser

> Returns 'PUBLIC' or 'PRIVATE' for a given CID by checking whether OperationTypeID=3 exists in Customer.BlockedCustomerOperations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT; reads Customer.BlockedCustomerOperations WHERE OperationTypeID=3 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

On eToro's social trading platform, users can be either "public" (their trading activity is visible to other users and can be copied) or "private" (their profile and positions are hidden). This procedure is the authoritative lookup for that public/private status.

The mechanism: a customer is "PRIVATE" if there is a row in Customer.BlockedCustomerOperations with their CID and OperationTypeID=3. OperationTypeID=3 represents the "public profile" operation being blocked - when this block exists, the user's profile is private. When no such block exists, the user is public.

This procedure is called by the TAPI (Trading API) and TDAPI user roles, indicating it is part of the API layer that serves trading platform clients checking whether a user's portfolio is visible (e.g., before displaying their profile or allowing copy trading).

---

## 2. Business Logic

### 2.1 Public/Private Status Check

**What**: A single conditional check - returns 'PRIVATE' if a block record exists, 'PUBLIC' otherwise.

**Columns/Parameters Involved**: `@CID`, `Customer.BlockedCustomerOperations`, `OperationTypeID`

**Rules**:
- IF EXISTS (SELECT CID FROM Customer.BlockedCustomerOperations WHERE CID = @CID AND OperationTypeID = 3) -> RETURN 'PRIVATE'
- ELSE -> RETURN 'PUBLIC'
- OperationTypeID = 3 is the "public profile" operation. When this operation is blocked, the user is private.
- The result is a scalar string column in a single-row result set

**Diagram**:
```
Customer.BlockedCustomerOperations
  EXISTS(CID = @CID AND OperationTypeID = 3)?
    YES -> 'PRIVATE'
    NO  -> 'PUBLIC'
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID to check. The procedure checks Customer.BlockedCustomerOperations for a row with this CID and OperationTypeID=3. If found, the customer is PRIVATE; if not found, PUBLIC. |

**Output columns:**

| # | Column | Description |
|---|--------|-------------|
| 1 | (unnamed CASE result) | Either 'PRIVATE' (block exists) or 'PUBLIC' (no block). Single-row, single-column result set. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Public/private check | Customer.BlockedCustomerOperations | Reader (cross-schema) | EXISTS check on OperationTypeID=3 for the given CID to determine public/private status |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| TDAPIUserProd | EXECUTE permission | Permission grant | Production TDAPI user - calls this when serving profile visibility checks |
| TDAPIUser | EXECUTE permission | Permission grant | TDAPI user role - same purpose |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.VerifyPublicUser (procedure)
└── Customer.BlockedCustomerOperations (table - public/private check, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table | EXISTS check - OperationTypeID=3 + CID to determine public/private user status |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| TDAPIUserProd / TDAPIUser | DB roles / external services | Trading Dashboard API calls this to check user visibility status before serving profile or copy trading data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OperationTypeID = 3 | Business logic | Hardcoded constant - "public profile" operation. The BlockedCustomerOperations table contains blocks for multiple operation types; only type 3 determines public/private status. |
| No NOLOCK hint | Design | The EXISTS check reads without a NOLOCK hint, using the default isolation level. Public/private status is a correctness-sensitive read (incorrect result could expose a private user's data). |

---

## 8. Sample Queries

### 8.1 Check if a specific customer is public or private

```sql
EXEC Trade.VerifyPublicUser @CID = 12345
```

### 8.2 Directly query the underlying data

```sql
-- Check public/private status without the SP
SELECT
    CASE
        WHEN EXISTS (
            SELECT 1 FROM Customer.BlockedCustomerOperations WITH (NOLOCK)
            WHERE CID = 12345 AND OperationTypeID = 3
        ) THEN 'PRIVATE'
        ELSE 'PUBLIC'
    END AS PublicStatus
```

### 8.3 Find all private customers

```sql
-- All customers with OperationTypeID=3 blocked (private profiles)
SELECT DISTINCT CID
FROM Customer.BlockedCustomerOperations WITH (NOLOCK)
WHERE OperationTypeID = 3
ORDER BY CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.VerifyPublicUser | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.VerifyPublicUser.sql*
