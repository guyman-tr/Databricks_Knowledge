# Customer.GetCustomerComments

> Returns the free-text internal comments field for a single customer from Customer.CustomerStatic; used by BackOffice agents for manual notes and compliance annotations.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer to query) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetCustomerComments is a simple accessor that retrieves the Comments free-text field from Customer.CustomerStatic for a given CID. The Comments column holds manual annotations written by BackOffice agents, compliance officers, and support staff - notes about account actions, investigations, special agreements, or compliance flags.

The procedure exists as a dedicated, permission-controlled entry point for reading Comments. Having a separate procedure means the BackOffice management service (BOManagementServiceUser) and other internal roles can read comments without needing broad SELECT access to the full CustomerStatic table.

A parallel procedure exists in the BackOffice schema (BackOffice.GetCustomerComments), which likely augments comments from the BackOffice.Customer table; this Customer schema version reads only from the Customer schema source.

---

## 2. Business Logic

### 2.1 Single-Column Read with No Guard

**What**: Retrieves one field from the master customer record with no validation.

**Columns/Parameters Involved**: `@CID`, `Comments`

**Rules**:
- Returns empty result set if CID does not exist (no RAISERROR or NULL substitution)
- Returns at most 1 row (CustomerStatic has unique CID)
- Comments column may be NULL for customers with no annotations

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to look up. No NULL guard; non-existent CID returns empty result set. |

**Output result set:**

| Column | Source | Business Meaning |
|--------|--------|-----------------|
| Comments | Customer.CustomerStatic.Comments | Free-text internal notes field. Written by BackOffice agents and compliance staff. May contain: account action notes, investigation details, special handling instructions, compliance flags, or manual annotations. NULL for customers with no notes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerStatic | Read | Retrieves the Comments column for the given customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetCustomerComments | EXEC (likely) | Caller | BackOffice-schema procedure that extends or wraps comment retrieval |
| BOManagementServiceUser (SQL login) | EXECUTE | Permission | BackOffice management service reads customer comments |
| BackTrader (SQL login) | EXECUTE | Permission | BackTrader service has execute permission |
| PROD_BIadmins (SQL role) | EXECUTE | Permission | BI admin role has execute permission |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCustomerComments (procedure)
└── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Reads the Comments column filtered by CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetCustomerComments | Procedure | Likely calls or wraps this procedure (BackOffice-schema variant) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. SET NOCOUNT ON suppresses row count messages. No NULL guard or error handling.

---

## 8. Sample Queries

### 8.1 Get comments for a specific customer

```sql
EXEC Customer.GetCustomerComments @CID = 12345678
```

### 8.2 Check comments directly on CustomerStatic

```sql
SELECT CID, Comments
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE CID = 12345678
```

### 8.3 Find customers with non-null comments (direct table query)

```sql
SELECT TOP 20 CID, Comments
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE Comments IS NOT NULL
ORDER BY CID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetCustomerComments | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetCustomerComments.sql*
