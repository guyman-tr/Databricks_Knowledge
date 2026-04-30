# Billing.GetMerchantValuesByDeposit

> Returns the merchant account credential parameters for a deposit by joining Billing.Deposit to Billing.MerchantAccountValues via the deposit's stored MerchantAccountID.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositID - returns (MerchantAccountID, ParameterID, Value) for the deposit's merchant account |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetMerchantValuesByDeposit` retrieves the merchant account credentials that were associated with a specific deposit when it was processed. Unlike `GetMerchantValues` (which resolves the merchant account dynamically from routing dimensions), this procedure reads the `MerchantAccountID` that was already stored in `Billing.Deposit.MerchantAccountID` at deposit time.

This is a retrospective lookup - useful for troubleshooting a completed or failed deposit by seeing exactly which merchant account's credentials were used to process it. Since the deposit record captures the `MerchantAccountID` at the time of processing, this procedure gives an authoritative answer even if routing rules have since changed.

Created by Shay Oren 27/12/2020 (PAYUS-2063) - the same day as `GetMerchantValues`.

---

## 2. Business Logic

### 2.1 Deposit-to-Credentials Lookup

**What**: Reads the MerchantAccountID from the deposit record and returns all associated credential parameters.

**Columns/Parameters Involved**: `@DepositID`, `bd.MerchantAccountID`, `mv.ParameterID`, `mv.Value`

**Rules**:
- `FROM Billing.Deposit bd JOIN Billing.MerchantAccountValues mv ON bd.MerchantAccountID = mv.MerchantAccountID`
- `WHERE DepositID = @DepositID` - single deposit
- INNER JOIN - returns no rows if `MerchantAccountID` is NULL in the deposit record
- Returns one row per credential parameter for the merchant account (same row structure as GetMerchantValues)
- No routing logic needed - the merchant account was already resolved and stored when the deposit was created

**Comparison with GetMerchantValues family**:

| Procedure | How MerchantAccountID is Resolved |
|-----------|----------------------------------|
| GetMerchantValues | Dynamic: from routing dimensions (depot, mode, regulation, country...) |
| GetMerchantValues_V2 | Dynamic: same + currency priority |
| **GetMerchantValuesByDeposit** | Stored: reads MerchantAccountID already in Billing.Deposit |
| GetMerchantValuesByMerchantID | Direct: caller provides MerchantAccountID |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INT | NO | - | CODE-BACKED | The deposit to retrieve merchant credentials for. FK to Billing.Deposit.DepositID. |

### Output Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | MerchantAccountID | int | NO | - | CODE-BACKED | The merchant account ID stored on the deposit. Confirms which account was used to process this deposit. |
| 3 | ParameterID | int | YES | - | CODE-BACKED | Credential parameter type (from Billing.Parameter). Examples: 9=entity name, 156=API key identifier, 167=boolean flag. |
| 4 | Value | varchar(4000) | NO | - | CODE-BACKED | The credential value as a string. Always VARCHAR regardless of actual type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Billing.Deposit | Direct Read | Reads MerchantAccountID stored on the deposit record |
| JOIN | Billing.MerchantAccountValues | Direct Read | Retrieves credential parameter values for the deposit's merchant account |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None found) | - | - | No SQL-layer callers found. Called from application code for deposit troubleshooting. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetMerchantValuesByDeposit (procedure)
├── Billing.Deposit (table)
└── Billing.MerchantAccountValues (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | FROM - reads MerchantAccountID for the given DepositID |
| Billing.MerchantAccountValues | Table | JOIN - retrieves credential parameters for the deposit's merchant account |

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

### 8.1 Get credentials used for a specific deposit

```sql
EXEC Billing.GetMerchantValuesByDeposit @DepositID = 12345678
-- Returns: MerchantAccountID, ParameterID, Value for each credential parameter
-- Empty if deposit has no MerchantAccountID or MerchantAccountID has no values
```

### 8.2 Equivalent ad-hoc query

```sql
SELECT mv.MerchantAccountID, mv.ParameterID, mv.Value
FROM Billing.Deposit bd WITH (NOLOCK)
JOIN Billing.MerchantAccountValues mv WITH (NOLOCK)
    ON bd.MerchantAccountID = mv.MerchantAccountID
WHERE bd.DepositID = 12345678
```

### 8.3 Check what merchant account a deposit used

```sql
-- Quick check without full parameter list:
SELECT MerchantAccountID FROM Billing.Deposit WITH (NOLOCK)
WHERE DepositID = 12345678
-- Then use GetMerchantValuesByMerchantID for full details
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetMerchantValuesByDeposit | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetMerchantValuesByDeposit.sql*
