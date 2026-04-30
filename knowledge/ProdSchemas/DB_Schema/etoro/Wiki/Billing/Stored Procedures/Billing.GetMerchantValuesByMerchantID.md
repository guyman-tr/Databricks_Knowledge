# Billing.GetMerchantValuesByMerchantID

> Returns all credential parameters for a specific merchant account directly by MerchantAccountID - the simplest member of the GetMerchantValues family with no routing or deposit context needed.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MerchantAccountID - returns all (ParameterID, Value) pairs for the account |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetMerchantValuesByMerchantID` is the direct lookup variant in the GetMerchantValues family. When the caller already knows which merchant account they want (e.g., from a previously resolved `GetMerchantValues` call or a stored value), this procedure retrieves all associated credential parameters without any routing logic.

Common use cases: administrative tools inspecting merchant account configurations, debugging by merchant account ID, or internal service calls that cache the resolved MerchantAccountID and re-use it.

Created by Elrom Behar 27/12/2021 (PAYIL-3650) - one year after the other GetMerchantValues procedures.

---

## 2. Business Logic

### 2.1 Direct Credential Lookup by MerchantAccountID

**What**: Returns every parameter-value pair stored for the given merchant account.

**Columns/Parameters Involved**: `@MerchantAccountID`, `MerchantAccountValues.ParameterID`, `MerchantAccountValues.Value`

**Rules**:
- `WHERE MerchantAccountID = @MerchantAccountID` - exact match, no wildcards
- No routing logic, no BIN resolution, no country/currency priority
- Returns all rows for the merchant account (one per parameter type)
- Returns empty set if MerchantAccountID doesn't exist in `Billing.MerchantAccountValues`

**GetMerchantValues family comparison**:

| Procedure | MerchantAccountID Source | Routing Logic |
|-----------|-------------------------|---------------|
| GetMerchantValues | Resolved from depot/mode/regulation/country/currency | Full routing + BIN resolution |
| GetMerchantValues_V2 | Resolved from routing + currency priority | Full routing + BIN + currency |
| GetMerchantValuesByDeposit | Read from Billing.Deposit.MerchantAccountID | None (stored at deposit time) |
| **GetMerchantValuesByMerchantID** | Provided directly by caller | None |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MerchantAccountID | INT | NO | - | CODE-BACKED | The merchant account to retrieve credentials for. Direct FK to Billing.MerchantAccountValues.MerchantAccountID. |

### Output Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | MerchantAccountID | int | NO | - | CODE-BACKED | The merchant account ID (echoed from input, same for all rows). |
| 3 | ParameterID | int | YES | - | CODE-BACKED | Credential parameter type identifier. Examples: 9=entity name, 156=API key name, 167=boolean flag. NULL only for the test row (MerchantAccountID=0). |
| 4 | Value | varchar(4000) | NO | - | CODE-BACKED | The credential value as string. Examples: "EU LTD" (entity), "ApiKeyCheckoutEU" (API key name), "false" (flag). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Billing.MerchantAccountValues | Direct Read | All credential parameters for the given merchant account |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None found) | - | - | No SQL-layer callers found. Used by admin tooling and application code. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetMerchantValuesByMerchantID (procedure)
└── Billing.MerchantAccountValues (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.MerchantAccountValues | Table | SELECT - all parameter rows for the given MerchantAccountID |

### 6.2 Objects That Depend On This

No dependents found in the SQL layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get all credentials for a merchant account

```sql
EXEC Billing.GetMerchantValuesByMerchantID @MerchantAccountID = 1
-- Returns: all ParameterID/Value pairs for merchant account 1
```

### 8.2 Equivalent ad-hoc query

```sql
SELECT MerchantAccountID, ParameterID, Value
FROM Billing.MerchantAccountValues WITH (NOLOCK)
WHERE MerchantAccountID = 1
ORDER BY ParameterID
```

### 8.3 Inspect all merchant accounts and their parameter counts

```sql
SELECT MerchantAccountID, COUNT(*) AS ParameterCount
FROM Billing.MerchantAccountValues WITH (NOLOCK)
GROUP BY MerchantAccountID
ORDER BY MerchantAccountID
-- Use GetMerchantValuesByMerchantID for each ID to see full details
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetMerchantValuesByMerchantID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetMerchantValuesByMerchantID.sql*
