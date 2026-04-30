# BackOffice.GetCustomerLeiDetails

> Sets an OUTPUT parameter with the Legal Entity Identifier (LEI) code for a corporate customer account.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID input; @Lei OUTPUT parameter |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

A Legal Entity Identifier (LEI) is a 20-character alphanumeric code that uniquely identifies a legal entity (company or organization) in financial transactions, as required by ESMA (European Securities and Markets Authority) regulations.

This procedure retrieves the LEI code stored against a corporate customer account. It is called by BackOffice workflows that need to verify or display the LEI for corporate account processing - for example, when processing a corporate customer's trades or verifying their regulatory compliance status.

Created November 2017 (case 49513, "OPS0351 Corporate account LEI - BackOffice UI & Backend changes - DB Changes") as part of the ESMA corporate account LEI requirement implementation.

The procedure uses an OUTPUT parameter pattern rather than a result set - callers pass `@Lei OUTPUT` and read the value after execution.

---

## 2. Business Logic

Single statement: `SET @Lei = (SELECT Lei FROM BackOffice.Customer WHERE CID = @CID)`.

If no record exists for @CID, @Lei remains NULL. If the customer has no LEI recorded, @Lei is NULL (the column allows NULL for non-corporate or non-LEI-required accounts).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Parameters** | | | | | | |
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to look up. |
| 2 | @Lei | NVARCHAR(50) | YES | NULL | CODE-BACKED | OUTPUT parameter. Set to BackOffice.Customer.Lei for the given CID. NULL if no LEI is recorded or if the CID does not exist. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | Direct READ | Reads the Lei column for the given CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application (BO) | N/A | Application call | Reads LEI for corporate account display and regulatory verification |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerLeiDetails (procedure)
+-- BackOffice.Customer (Lei column)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | Source of the Lei column |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (BO) | External application | Corporate account LEI verification |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- `SET NOCOUNT ON`
- OUTPUT parameter pattern: caller must declare `@Lei NVARCHAR(50) OUTPUT`

---

## 8. Sample Queries

### 8.1 Get LEI for a corporate customer

```sql
DECLARE @Lei NVARCHAR(50);
EXEC BackOffice.GetCustomerLeiDetails @CID = 12345678, @Lei = @Lei OUTPUT;
SELECT @Lei AS LEI;
```

### 8.2 Direct base-table query

```sql
SELECT Lei FROM BackOffice.Customer WITH(NOLOCK) WHERE CID = 12345678;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Case 49513 - OPS0351 (inferred from comment) | Jira | Nov 2017 ESMA corporate account LEI requirement. The LEI must be recorded for all corporate accounts that trade on regulated EU venues. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerLeiDetails | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerLeiDetails.sql*
