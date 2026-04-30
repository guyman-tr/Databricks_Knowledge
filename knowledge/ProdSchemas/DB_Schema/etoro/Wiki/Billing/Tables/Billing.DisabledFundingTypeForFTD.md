# Billing.DisabledFundingTypeForFTD

> Configuration table defining which payment methods are blocked for First Time Deposits (FTD) per country and regulation - prevents certain funding types from being offered to customers making their first deposit.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (CountryID, RegulationID, FundingTypeID) - composite clustered PK |
| **Partition** | No (PRIMARY filegroup, FILLFACTOR 95) |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

`Billing.DisabledFundingTypeForFTD` is a regulatory/business rule configuration table that lists which payment methods (FundingTypes) are NOT available for a customer's First Time Deposit (FTD) based on the customer's country and regulatory jurisdiction.

FTDs receive special treatment in financial regulation: some payment methods carry elevated fraud or money laundering risk for unverified new depositors, and regulations may prohibit them until a customer's identity is established. This table captures those restrictions. When a customer initiates their first deposit, the application calls `Billing.GetDisabledFundingsFTD` with the customer's country and regulation to get the list of excluded payment methods, then removes those from the deposit options presented to the user.

The dominant restriction is PayPal (FundingTypeID=3), which is disabled for FTD in 333 of 467 rows (71%), covering 60 countries under CySEC regulation. E-wallets (Neteller, MoneyBookers) and UnionPay are also restricted in many jurisdictions. `GetCustomerDepositInfo` (result set #24) calls this procedure as part of building the complete deposit UI configuration for a customer.

---

## 2. Business Logic

### 2.1 FTD Payment Method Exclusion

**What**: For each (CountryID, RegulationID) pair, lists the FundingTypeIDs that cannot be used for a First Time Deposit.

**Columns/Parameters Involved**: `CountryID`, `RegulationID`, `FundingTypeID`

**Rules**:
- `Billing.GetDisabledFundingsFTD(@CountryID, @RegulationID)` queries: `SELECT FundingTypeID FROM Billing.DisabledFundingTypeForFTD WHERE CountryID = @CountryID AND RegulationID = @RegulationID`
- Returns a result set of FundingTypeIDs; the caller filters these from the available deposit methods.
- A row in this table = "this funding type is BLOCKED for FTD in this country+regulation".
- Absence of a row = "this funding type is ALLOWED for FTD in this country+regulation".
- No time-based logic - once a customer has made their first deposit, subsequent deposits use a different set of rules.
- Called by `Billing.GetCustomerDepositInfo` (result set #24: DisabledFundings) which explicitly passes `@IsFTD` context.

### 2.2 Regulatory Scope

**What**: Different regulations restrict different payment methods for different country sets.

**Rules**:
| RegulationID | Regulation | Disabled Rows | Unique Countries |
|-------------|-----------|--------------|-----------------|
| 1 | CySEC | 173 | 60 |
| 2 | FCA | 39 | 39 |
| 3 | NFA | 39 | 39 |
| 4 | ASIC | 39 | 39 |
| 5 | BVI | 39 | 39 |
| 9 | FSA Seychelles | 39 | 39 |
| 10 | ASIC & GAML | 39 | 39 |
| 6 | eToroUS | 20 | 20 |
| 7 | FinCEN | 20 | 20 |
| 8 | FinCEN+FINRA | 20 | 20 |

---

## 3. Data Overview

| FundingTypeID | Name | Disabled Rows | % of Total | Notes |
|--------------|------|--------------|------------|-------|
| 3 | PayPal | 333 | 71% | Blocked for FTD in most countries - e-wallet fraud risk |
| 6 | Neteller | 44 | 9% | E-wallet, restricted in some jurisdictions |
| 8 | MoneyBookers | 43 | 9% | E-wallet (Skrill), restricted in some jurisdictions |
| 22 | UnionPay | 42 | 9% | China-specific payment method, regulated carefully |
| 35 | Trustly | 5 | 1% | Open banking, restricted in select jurisdictions |

Total: 467 rows | 60 unique countries | 10 regulations

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | CODE-BACKED | Country of the customer. Part of composite PK. Implicit FK to Dictionary.Country. 60 distinct countries configured. Used in GetDisabledFundingsFTD: `WHERE CountryID = @CountryID`. |
| 2 | RegulationID | int | NO | - | CODE-BACKED | Regulatory jurisdiction governing the customer's account. Part of composite PK. Implicit FK to Dictionary.Regulation. Values: 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC & GAML. 10 distinct regulations configured. |
| 3 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method disabled for FTD in this country+regulation. Part of composite PK. Implicit FK to Dictionary.FundingType. Values: 3=PayPal (333 rows, 71%), 6=Neteller (44), 8=MoneyBookers (43), 22=UnionPay (42), 35=Trustly (5). Only these 5 payment methods have FTD restrictions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Implicit FK | Customer's country for this FTD restriction. |
| RegulationID | Dictionary.Regulation | Implicit FK | Regulatory jurisdiction for this FTD restriction. |
| FundingTypeID | Dictionary.FundingType | Implicit FK | Payment method blocked for FTD in this country+regulation. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetDisabledFundingsFTD | CountryID, RegulationID | READER | Returns list of FundingTypeIDs disabled for FTD in a given country+regulation. Only read path. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies (no FK constraints).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetDisabledFundingsFTD | Stored Procedure | READER - returns disabled FTD funding types for country+regulation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BillingCountryRegulationDisabledFunding | CLUSTERED PK | CountryID ASC, RegulationID ASC, FundingTypeID ASC | - | - | Active |

FILLFACTOR=95. Clustered PK on the three-column composite key ensures fast point lookups by (CountryID, RegulationID).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingCountryRegulationDisabledFunding | PRIMARY KEY | (CountryID, RegulationID, FundingTypeID) - unique restriction per country/regulation/funding-type |

---

## 8. Sample Queries

### 8.1 Get all FTD-disabled funding types for a country+regulation

```sql
SELECT d.FundingTypeID, ft.Name AS FundingTypeName
FROM [Billing].[DisabledFundingTypeForFTD] d WITH (NOLOCK)
JOIN [Dictionary].[FundingType] ft WITH (NOLOCK) ON d.FundingTypeID = ft.FundingTypeID
WHERE d.CountryID = @CountryID AND d.RegulationID = @RegulationID
ORDER BY ft.Name;
```

### 8.2 Countries where PayPal is disabled for FTD

```sql
SELECT d.CountryID, c.Name AS CountryName, d.RegulationID, r.Name AS RegulationName
FROM [Billing].[DisabledFundingTypeForFTD] d WITH (NOLOCK)
JOIN [Dictionary].[Country] c WITH (NOLOCK) ON d.CountryID = c.CountryID
JOIN [Dictionary].[Regulation] r WITH (NOLOCK) ON d.RegulationID = r.ID
WHERE d.FundingTypeID = 3  -- PayPal
ORDER BY r.Name, c.Name;
```

### 8.3 Summary of restrictions by funding type and regulation

```sql
SELECT ft.Name AS FundingType, r.Name AS Regulation, COUNT(*) AS DisabledCountries
FROM [Billing].[DisabledFundingTypeForFTD] d WITH (NOLOCK)
JOIN [Dictionary].[FundingType] ft WITH (NOLOCK) ON d.FundingTypeID = ft.FundingTypeID
JOIN [Dictionary].[Regulation] r WITH (NOLOCK) ON d.RegulationID = r.ID
GROUP BY ft.Name, r.Name
ORDER BY DisabledCountries DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DisabledFundingTypeForFTD | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.DisabledFundingTypeForFTD.sql*
