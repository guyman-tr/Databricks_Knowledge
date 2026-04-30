# Customer.GetCustomerDetails

> Returns the full customer profile with human-readable Country and State names resolved from Dictionary lookups, providing a single-call enriched customer record for BackOffice and service consumers.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer to query) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetCustomerDetails returns a complete, enriched customer record for a given CID. It selects all columns from Customer.Customer (the main customer view) and adds two human-readable lookup fields: the country name (from Dictionary.Country) and state name (from Dictionary.State). The result is a self-contained customer snapshot - callers receive the full profile plus resolved geographic labels in a single query.

The procedure exists as a convenient enriched accessor for services and BackOffice tools that need the full customer record with resolved geographic fields. Rather than running a multi-table JOIN themselves, callers get a single procedure call that returns everything needed to display a complete customer profile.

It is used by multiple eToro services: withdrawal (WithdrawalServiceUser), deposit (DepositUser), payout (PayoutUser), BackOffice management (BOManagementServiceUser), and BackTrader.

---

## 2. Business Logic

### 2.1 Geographic Name Resolution

**What**: CountryID and StateID are integer codes; this procedure resolves them to human-readable names for display.

**Columns/Parameters Involved**: `CountryID`, `StateID`, `Country` (output alias), `State` (output alias)

**Rules**:
- INNER JOIN to Dictionary.Country ON Cust.CountryID = DicCount.CountryID -> adds `Country` column (the country name string)
- INNER JOIN to Dictionary.State ON Cust.StateID = DicState.StateID -> adds `State` column (the state/region name string)
- Both joins are INNER JOIN: if CountryID or StateID has no matching Dictionary row, the customer record is excluded from the result set
- The output merges all Customer.Customer columns (SELECT Cust.*) with the two resolved names at the end

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID to look up. INNER JOINs to Dictionary tables mean a customer with an unmapped CountryID or StateID returns no row. |

**Output result set:**

| Column Group | Source | Business Meaning |
|---|---|---|
| Cust.* (all columns) | Customer.Customer | Full customer profile: identity, demographics, status, trading config, PII fields. See Customer.Customer documentation for all column descriptions. |
| Country | Dictionary.Country.Name | Human-readable country name resolved from Cust.CountryID (e.g., 'United Kingdom', 'Germany'). Added as alias `Country` in addition to the CountryID already present in Cust.*. |
| State | Dictionary.State.Name | Human-readable state/region name resolved from Cust.StateID (e.g., 'California', 'England'). Added as alias `State` in addition to StateID already in Cust.*. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Read (INNER JOIN base) | Full customer profile data |
| CountryID | Dictionary.Country | INNER JOIN (lookup) | Resolves CountryID to country name |
| StateID | Dictionary.State | INNER JOIN (lookup) | Resolves StateID to state/region name |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| WithdrawalServiceUser (SQL login) | EXECUTE | Permission | Withdrawal service reads enriched customer details |
| DepositUser (SQL login) | EXECUTE | Permission | Deposit service reads enriched customer details |
| PayoutUser (SQL login) | EXECUTE | Permission | Payout service reads enriched customer details |
| BOManagementServiceUser (SQL login) | EXECUTE | Permission | BackOffice management service reads full customer record |
| BackTrader (SQL login) | EXECUTE | Permission | BackTrader service has execute permission |
| PROD_BIadmins (SQL role) | EXECUTE | Permission | BI admin role has execute permission |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCustomerDetails (procedure)
├── Customer.Customer (view)
│     └── Customer.CustomerStatic (table)
├── Dictionary.Country (table - cross-schema)
└── Dictionary.State (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | Full customer profile (SELECT Cust.*) filtered by CID |
| Dictionary.Country | Table | INNER JOIN to resolve CountryID -> country name string |
| Dictionary.State | Table | INNER JOIN to resolve StateID -> state/region name string |

### 6.2 Objects That Depend On This

No stored procedure dependents found (called directly by external service accounts).

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| INNER JOIN to Dictionary | Implicit filter | Customers with unmapped CountryID or StateID return no result |
| WITH (NOLOCK) on all joins | Read consistency | Dirty read hints on all three sources; avoids lock waits in high-concurrency scenarios |

---

## 8. Sample Queries

### 8.1 Get full enriched customer record

```sql
EXEC Customer.GetCustomerDetails @CID = 12345678
-- Returns all Customer.Customer columns + Country name + State name
```

### 8.2 Reproduce the procedure query directly

```sql
SELECT Cust.*, DicCount.[Name] AS Country, DicState.[Name] AS State
FROM Customer.Customer AS Cust WITH (NOLOCK)
INNER JOIN Dictionary.Country AS DicCount WITH (NOLOCK)
    ON Cust.CountryID = DicCount.CountryID
INNER JOIN Dictionary.State AS DicState WITH (NOLOCK)
    ON Cust.StateID = DicState.StateID
WHERE Cust.CID = 12345678
```

### 8.3 Look up country and state codes for a customer

```sql
SELECT CID, CountryID, StateID
FROM Customer.Customer WITH (NOLOCK)
WHERE CID = 12345678
-- Then join to Dictionary.Country and Dictionary.State to resolve names
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 9/10, Logic: 6/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetCustomerDetails | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetCustomerDetails.sql*
