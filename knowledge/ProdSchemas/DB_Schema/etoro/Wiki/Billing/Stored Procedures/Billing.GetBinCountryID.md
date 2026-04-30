# Billing.GetBinCountryID

> Resolves a credit card BIN (Bank Identification Number) code to its issuing country ID via an OUTPUT parameter, used in payment routing and validation flows to identify the card's country of origin.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | OUTPUT parameter @CountryID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetBinCountryID` looks up the issuing country of a credit card from its BIN (Bank Identification Number) code — typically the first 6 digits of the card number. Given a BIN code, it returns the CountryID of the bank that issued the card via an OUTPUT parameter.

BIN-to-country resolution is a fundamental step in payment routing and fraud prevention. Knowing a card's issuing country enables eToro to apply country-specific deposit rules, route the transaction through the appropriate payment processor, enforce regulatory restrictions, and detect suspicious activity (e.g., a card issued in Country A being used by a customer registered in Country B). The `Dictionary.CountryBin` table holds BIN ranges mapped to country IDs.

The procedure uses an OUTPUT parameter pattern (common in older SQL Server APIs) rather than returning a result set. The caller must declare `@CountryID` as an OUTPUT variable. `NULL` in the output means no BIN record was found in the database (unknown card issuer country).

This procedure is granted to `FundingUser` and `CashoutTool` roles, indicating it is called during deposit funding operations and cashout/withdrawal processing.

---

## 2. Business Logic

### 2.1 BIN Code Country Resolution

**What**: Maps a BIN (first 6 digits of a credit card) to its issuing country using the Dictionary.CountryBin reference table.

**Columns/Parameters Involved**: `@BinCode`, `@CountryID`

**Rules**:
- BIN codes are typically 6-digit integers representing the card's bank identification prefix (e.g., 411111 = Visa USA)
- `TOP 1` protects against any duplicate BIN entries - always returns one country even if multiple rows match
- If no BIN record exists, `@CountryBinID` remains NULL (DECLARE default), so `@CountryID` output will be NULL
- NULL output = unknown BIN - caller must handle this case (unknown issuing country)
- Routing and validation logic downstream uses CountryID to apply country-specific payment rules

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CountryID | int | YES | - | VERIFIED | OUTPUT parameter. Receives the CountryID from Dictionary.CountryBin for the given BinCode. NULL if no BIN record found (unknown issuing country). References Dictionary.Country.CountryID. |
| 2 | @BinCode | int | NO | - | VERIFIED | INPUT parameter. The Bank Identification Number - typically the first 6 digits of a credit card number as an integer. Looked up in Dictionary.CountryBin.BinCode. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BinCode | Dictionary.CountryBin | Lookup | Queries Dictionary.CountryBin WHERE BinCode = @BinCode to resolve card issuing country. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| FundingUser (role) | EXECUTE permission | Permission | Funding service uses BIN-to-country resolution during deposit processing. |
| CashoutTool (role) | EXECUTE permission | Permission | Cashout tool uses BIN-to-country resolution during withdrawal processing. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetBinCountryID (procedure)
└── Dictionary.CountryBin (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CountryBin | Table | SELECT TOP 1 CountryID WHERE BinCode = @BinCode. The BIN-to-country mapping table. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| FundingUser (role) | Permission | Deposit funding flow |
| CashoutTool (role) | Permission | Cashout processing flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Resolve a BIN code to country (OUTPUT parameter pattern)
```sql
DECLARE @OutCountryID INT
EXEC Billing.GetBinCountryID @CountryID = @OutCountryID OUTPUT, @BinCode = 411111
SELECT @OutCountryID AS ResolvedCountryID
-- Returns the CountryID for Visa BIN 411111
```

### 8.2 Direct BIN lookup
```sql
SELECT TOP 1 BinCode, CountryID
FROM Dictionary.CountryBin WITH (NOLOCK)
WHERE BinCode = 411111
```

### 8.3 Resolve BIN to country name
```sql
DECLARE @OutCountryID INT
EXEC Billing.GetBinCountryID @CountryID = @OutCountryID OUTPUT, @BinCode = 411111
SELECT @OutCountryID AS CountryID, c.Name AS CountryName
FROM Dictionary.Country c WITH (NOLOCK)
WHERE c.CountryID = @OutCountryID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Credit card deposit flow](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/8626503698/Credit+card+deposit+flow) | Confluence | Describes the credit card deposit flow where BIN-to-country resolution is used for routing decisions. MEDIUM confidence - not directly describing this SP. |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetBinCountryID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetBinCountryID.sql*
