# Customer.GetCIDByGCID

> Resolves a GCID (Group Customer ID) to its CID (Customer ID) via an OUTPUT parameter, returning 0 (default) if @GCID is 0 or the GCID is not found. A duplicate exists as Trade.GetCIDByGCID with the same logic.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID (group ID to resolve), @CID OUTPUT (resolved CID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetCIDByGCID is the canonical GCID-to-CID resolver for the Customer schema. Given a GCID (the cross-product Group Customer ID), it returns the local environment's CID (Customer ID) via an OUTPUT parameter.

The procedure exists because eToro's dual-environment architecture (real and demo) requires frequent cross-key lookups. Systems that receive a GCID need to resolve it to the local CID to query Customer-schema tables (which are keyed by CID). The OUTPUT parameter pattern allows callers to store the result directly into a variable without parsing a result set.

The @GCID > 0 guard is a safety check: GCID = 0 is used as a sentinel for "no GCID assigned" in some contexts, and resolving 0 would return an unpredictable customer. When @GCID <= 0, @CID remains at its default value of 0 (indicating not resolved).

A duplicate procedure exists as Trade.GetCIDByGCID - both are granted to `pdtservice`, and `MainRates` has EXECUTE on Trade.GetCIDByGCID. The Customer schema version is the reference implementation; Trade's is a copy for schema-local access patterns.

---

## 2. Business Logic

### 2.1 GCID-to-CID Resolution

**What**: Looks up the CID for a given GCID in Customer.Customer.

**Columns/Parameters Involved**: `@GCID`, `@CID` (OUTPUT), `Customer.Customer.GCID`, `Customer.Customer.CID`

**Rules**:
- Guard: IF @GCID > 0 (skip resolution if GCID is 0 or negative)
- SELECT @CID = CID FROM Customer.Customer WITH (NOLOCK) WHERE GCID = @GCID
- If @GCID is found: @CID = resolved CID
- If @GCID not found (no matching row): @CID remains at default 0
- If @GCID <= 0: @CID remains at default 0
- No RAISERROR - callers must check if @CID = 0 to detect not-found

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | NO | - | CODE-BACKED | Group Customer ID to resolve. Values <= 0 are not resolved (guard prevents lookup). GCID = 0 is used as "not assigned" sentinel in the broader system. |
| 2 | @CID | INT | YES | 0 | CODE-BACKED | OUTPUT parameter. Set to the CID matching @GCID if found. Remains at 0 if @GCID <= 0 or no matching customer found. Callers must check for @CID = 0 to detect resolution failure. |

**No result set - returns via OUTPUT parameter only.**

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.Customer | Read | Looks up CID WHERE GCID = @GCID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| pdtservice (service role) | GRANT EXECUTE | Caller | Price data/PDT service resolves GCID to CID |
| Trade.GetCIDByGCID | Duplicate | Parallel implementation | Same logic in Trade schema for Trade-context callers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCIDByGCID (procedure)
+-- Customer.Customer (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | GCID -> CID lookup (WHERE GCID = @GCID) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| pdtservice service | External service | GCID-to-CID resolution for price/data operations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IF @GCID > 0 guard | Safety | Prevents lookup on GCID=0 (sentinel for "unassigned") |
| @CID OUTPUT default = 0 | Convention | Callers distinguish "not found" as @CID = 0 (not NULL) |
| No result set | Design | OUTPUT parameter pattern - not result set |
| WITH (NOLOCK) | Hint | Non-blocking read |
| Trade.GetCIDByGCID duplicate | Architecture | Same procedure exists in Trade schema - no cross-schema call, each schema maintains its own copy |

---

## 8. Sample Queries

### 8.1 Resolve a GCID to CID

```sql
DECLARE @CID INT
EXEC Customer.GetCIDByGCID @GCID = 9876543, @CID = @CID OUTPUT
SELECT @CID AS ResolvedCID  -- 0 if not found
```

### 8.2 Equivalent inline resolution

```sql
SELECT CID
FROM Customer.Customer WITH (NOLOCK)
WHERE GCID = 9876543
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetCIDByGCID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetCIDByGCID.sql*
