# Customer.GetDetailsByApexID

> Resolves an APEX US stocks broker account ID to eToro internal identifiers (CID, GCID) and regulatory data; used by the APEX integration to link broker accounts back to eToro customer records.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @providerAccountId (APEX account ID to resolve) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetDetailsByApexID is the APEX broker integration lookup procedure. It resolves an APEX provider account ID (stored in CustomerStatic.ApexID) to the corresponding eToro CID, GCID, CountryID, and regulatory designation. APEX is eToro's US-registered stocks broker, and eToro customers who trade US stocks are assigned an APEX account. This procedure bridges the two identity systems.

The procedure exists for integration scenarios where an event arrives from APEX (e.g., trade execution confirmation, account statement) carrying the APEX account ID, and the receiving service needs to identify which eToro customer that APEX account belongs to. It returns CountryID and DesignatedRegulationID to enable regulatory routing decisions without requiring additional lookups.

Uses READ UNCOMMITTED isolation level (via SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED) - the most permissive isolation, trading consistency for speed. Acceptable for a lookup that reads non-financial identity data.

---

## 2. Business Logic

### 2.1 APEX Account ID Resolution

**What**: Maps an APEX-assigned account identifier to eToro's internal customer identifiers.

**Columns/Parameters Involved**: `@providerAccountId`, `ApexID`, `CID`, `GCID`, `CountryID`, `DesignatedRegulationID`

**Rules**:
- WHERE ApexID = @providerAccountId (exact string match on varchar(8))
- LEFT JOIN to BackOffice.Customer: provides DesignatedRegulationID (regulatory jurisdiction); NULL if no BackOffice record
- READ UNCOMMITTED: dirty reads permitted for performance
- Returns 0 or 1 rows (ApexID should be unique per customer)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @providerAccountId | varchar(8) | NO | - | CODE-BACKED | APEX broker account ID assigned to the customer by the APEX US stocks broker. Matched against Customer.CustomerStatic.ApexID. Length 8 matches APEX account ID format. |

**Output result set:**

| Column | Source | Business Meaning |
|--------|--------|-----------------|
| CID | Customer.CustomerStatic.CID | eToro internal integer customer ID |
| GCID | Customer.CustomerStatic.GCID | Global Customer ID - cross-product identity |
| CountryID | Customer.CustomerStatic.CountryID | Customer's registered country (integer code, resolve via Dictionary.Country) |
| ApexID | Customer.CustomerStatic.ApexID | The APEX account ID (echoed back in result for confirmation) |
| DesignatedRegulationID | BackOffice.Customer.DesignatedRegulationID | Regulatory jurisdiction assigned to the customer. NULL if no BackOffice record exists. Used for regulatory routing decisions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @providerAccountId | Customer.CustomerStatic.ApexID | Read (WHERE match) | Resolves APEX account ID to customer record |
| CID | BackOffice.Customer | LEFT JOIN (read) | Reads DesignatedRegulationID for regulatory context |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase (called by APEX integration services).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetDetailsByApexID (procedure)
├── Customer.CustomerStatic (table)
└── BackOffice.Customer (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Source of CID, GCID, CountryID, ApexID; filtered by ApexID |
| BackOffice.Customer | Table | LEFT JOIN to read DesignatedRegulationID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| READ UNCOMMITTED | Isolation level | Dirty reads permitted; no lock overhead on CustomerStatic |
| varchar(8) input | Type constraint | ApexID format is 8 characters maximum |
| LEFT JOIN to BackOffice | Nullable output | DesignatedRegulationID is NULL for customers without BackOffice records |

---

## 8. Sample Queries

### 8.1 Resolve an APEX account ID to eToro identifiers

```sql
EXEC Customer.GetDetailsByApexID @providerAccountId = 'AP123456'
```

### 8.2 Direct query equivalent

```sql
SELECT ccs.CID, ccs.GCID, ccs.CountryID, ccs.ApexID, boc.DesignatedRegulationID
FROM Customer.CustomerStatic ccs WITH (NOLOCK)
LEFT JOIN BackOffice.Customer boc WITH (NOLOCK) ON boc.CID = ccs.CID
WHERE ccs.ApexID = 'AP123456'
```

### 8.3 Find all customers with APEX accounts

```sql
SELECT TOP 20 CID, GCID, ApexID
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE ApexID IS NOT NULL
ORDER BY CID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 9/10, Logic: 6/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetDetailsByApexID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetDetailsByApexID.sql*
