# Customer.IsCIDExists

> Returns a BIT output parameter indicating whether a given CID exists in the Customer.Customer view - a lightweight customer existence check.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID -> @Result (OUTPUT BIT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.IsCIDExists checks whether a customer with the given CID exists in Customer.Customer. It returns the result via an OUTPUT parameter (@Result) rather than a result set, following a common eToro pattern for boolean existence checks. The caller passes @Result with the default 0; the procedure sets it to 1 if the CID is found, leaving it 0 if not.

This procedure is used by services that need to validate a CID before performing operations on it - for example, preventing downstream errors when an invalid or deleted CID is passed. Used by BI administrators for data validation.

---

## 2. Business Logic

No complex multi-column business logic detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | VERIFIED | Internal Customer ID to check for existence in Customer.Customer. |
| 2 | @Result | bit (OUTPUT) | NO | 0 | VERIFIED | Output parameter: 1 = the CID exists in Customer.Customer; 0 = not found (default). The caller must declare this as OUTPUT and read it after the EXEC. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Reader (EXISTS) | Checks for the presence of a row with the given CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | EXECUTE permission | Caller | BI administrators use for CID validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.IsCIDExists (procedure)
└── Customer.Customer (view)
      ├── Customer.CustomerStatic (table)
      └── Customer.CustomerMoney (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | EXISTS check - returns BIT result based on CID presence |

### 6.2 Objects That Depend On This

No dependents found in the codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Note: no SET NOCOUNT ON and no BEGIN...END block.

---

## 8. Sample Queries

### 8.1 Check if a CID exists using OUTPUT parameter
```sql
DECLARE @exists BIT = 0;
EXEC Customer.IsCIDExists @CID = 12345678, @Result = @exists OUTPUT;
SELECT @exists AS CustomerExists;  -- 1 = found, 0 = not found
```

### 8.2 Direct equivalent query for debugging
```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM Customer.Customer WITH (NOLOCK) WHERE CID = 12345678
) THEN 1 ELSE 0 END AS CustomerExists;
```

### 8.3 Validate a list of CIDs
```sql
-- For each CID in a known list, check existence
DECLARE @exists BIT;
EXEC Customer.IsCIDExists @CID = 12345678, @Result = @exists OUTPUT;
IF @exists = 0 PRINT 'CID 12345678 not found';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.IsCIDExists | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.IsCIDExists.sql*
