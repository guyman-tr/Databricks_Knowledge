# Billing.FundingTypeToCurrency

> Junction table mapping payment methods (funding types) to the currencies they support; currently empty - currency-to-funding-type mappings are now managed via the Depot/DepotToCurrency system.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (FundingTypeID, CurrencyID) - composite PK CLUSTERED |
| **Partition** | N/A - PRIMARY filegroup |
| **Indexes** | 2 (composite PK + nonclustered on CurrencyID) |

---

## 1. Business Meaning

`Billing.FundingTypeToCurrency` is a many-to-many junction table that maps payment methods to the currencies they support. A row (FundingTypeID=1, CurrencyID=2) would mean "credit card deposits (FundingType 1) support EUR (Currency 2)."

The table is currently empty (0 rows) - it has been superseded by the Depot/DepotToCurrency architecture. The current system uses `Billing.Depot` and `Billing.DepotToCurrency` to manage currency-to-funding-type relationships (as seen in `GetFundingTypesByCountry` and `GetFundingTypesWithOverrides`). This table is retained in the schema as a historical artifact.

No stored procedures in the Billing schema reference this table.

---

## 2. Business Logic

No active business logic (table is empty and inactive).

When active, this table would have enforced: "a payment method can only offer currencies in this whitelist." The composite PK (FundingTypeID, CurrencyID) would ensure no duplicate mappings.

---

## 3. Data Overview

Table is empty (0 rows). Currency-to-funding-type mappings are now managed via `Billing.Depot` and `Billing.DepotToCurrency`.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type. Part of composite PK. Implicit FK to Dictionary.FundingType(FundingTypeID). Identifies which payment method supports the currency. |
| 2 | CurrencyID | int | NO | - | CODE-BACKED | Currency supported by this funding type. Part of composite PK. Explicit FK to Dictionary.Currency(CurrencyID). Identifies which currency is available for this payment method. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID | Dictionary.FundingType | Implicit | Payment method definition |
| CurrencyID | Dictionary.Currency | FK (explicit) | Currency supported by the payment method |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views reference this table. It is inactive.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingTypeToCurrency (table)
|- Dictionary.Currency (table) [FK: CurrencyID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Currency | Table | FK target - valid currencies |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FundingTypeToCurrency | CLUSTERED PK | FundingTypeID ASC, CurrencyID ASC | - | - | Active (FILLFACTOR 90) |
| i_CureenyID | NONCLUSTERED | CurrencyID ASC | - | - | Active - note: index name has typo ("Cureeny" not "Currency"), same typo as in Billing.Del_Account |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_FundingTypeToCurrency | PRIMARY KEY CLUSTERED | (FundingTypeID, CurrencyID) - unique pairing |
| FK (unnamed) | FOREIGN KEY | CurrencyID must exist in Dictionary.Currency |

### 7.3 Architecture Note

The `i_CureenyID` typo (identical to the same index in `Billing.Del_Account`) suggests both indexes were created by the same developer at a similar time. This is a legacy artifact.

Currency-to-funding-type relationships are now managed through:
- `Billing.Depot`: Maps FundingTypeID to DepotID
- `Billing.DepotToCurrency`: Maps DepotID to active CurrencyIDs

---

## 8. Sample Queries

### 8.1 Verify the table is empty
```sql
SELECT COUNT(*) AS RowCount FROM Billing.FundingTypeToCurrency WITH (NOLOCK);
```

### 8.2 Current currency-to-funding-type mapping (via active Depot system)
```sql
SELECT DISTINCT depot.FundingTypeID, d2c.CurrencyID, DC.Name AS CurrencyName
FROM   Billing.Depot depot WITH (NOLOCK)
INNER JOIN Billing.DepotToCurrency d2c WITH (NOLOCK) ON depot.DepotID = d2c.DepotID
INNER JOIN Dictionary.Currency DC WITH (NOLOCK) ON d2c.CurrencyID = DC.CurrencyID
WHERE  d2c.IsActive = 1
ORDER BY depot.FundingTypeID, d2c.CurrencyID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 6.5/10 (Elements: 7/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingTypeToCurrency | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.FundingTypeToCurrency.sql*
