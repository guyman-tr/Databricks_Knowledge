# Customer.IsGCIDExists

> Returns a BIT output parameter indicating whether a given GCID exists in Customer.Customer - a cross-product customer identity existence check.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID -> @Result (OUTPUT BIT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.IsGCIDExists checks whether a customer with the given GCID (Group Customer ID) exists in Customer.Customer. It is the GCID-based counterpart to Customer.IsCIDExists. GCID is the cross-product customer identity used by external systems and modern services; this procedure allows those systems to verify GCID existence before performing operations.

Notable: unlike the CID-based version, this procedure does NOT use WITH (NOLOCK) on Customer.Customer. This means it uses the default READ COMMITTED isolation, providing a more consistent read but potentially blocking under high write concurrency.

---

## 2. Business Logic

No complex multi-column business logic detected. See element descriptions in Section 4.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | VERIFIED | Group Customer ID to check for existence in Customer.Customer. GCID is the cross-product identity that links the same person across eToro products. |
| 2 | @Result | bit (OUTPUT) | NO | 0 | VERIFIED | Output parameter: 1 = a customer with this GCID exists; 0 = not found (default). Note: unlike IsCIDExists, this procedure reads Customer.Customer WITHOUT NOLOCK (uses READ COMMITTED). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.Customer | Reader (EXISTS) | Checks for the presence of a row with the given GCID - uses READ COMMITTED (no NOLOCK) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | EXECUTE permission | Caller | BI administrators use for GCID validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.IsGCIDExists (procedure)
└── Customer.Customer (view)
      ├── Customer.CustomerStatic (table)
      └── Customer.CustomerMoney (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | EXISTS check - returns BIT result based on GCID presence (READ COMMITTED) |

### 6.2 Objects That Depend On This

No dependents found in the codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Note: no NOLOCK hint - uses READ COMMITTED isolation.

---

## 8. Sample Queries

### 8.1 Check if a GCID exists using OUTPUT parameter
```sql
DECLARE @exists BIT = 0;
EXEC Customer.IsGCIDExists @GCID = 12345678, @Result = @exists OUTPUT;
SELECT @exists AS GCIDExists;  -- 1 = found, 0 = not found
```

### 8.2 Direct equivalent query for debugging
```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM Customer.Customer WITH (NOLOCK) WHERE GCID = 12345678
) THEN 1 ELSE 0 END AS GCIDExists;
```

### 8.3 Compare CID and GCID existence for the same customer
```sql
DECLARE @cidExists BIT = 0, @gcidExists BIT = 0;
EXEC Customer.IsCIDExists @CID = 12345678, @Result = @cidExists OUTPUT;
EXEC Customer.IsGCIDExists @GCID = 12345678, @Result = @gcidExists OUTPUT;
SELECT @cidExists AS CIDExists, @gcidExists AS GCIDExists;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.IsGCIDExists | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.IsGCIDExists.sql*
