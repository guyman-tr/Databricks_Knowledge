# Customer.GetRafConfiguration_NogaJunk210725

> Returns the currently active Refer-A-Friend (RAF) compensation configuration for all eligible countries, joining country/regulation settings with model-specific overrides for Popular Investor and Club tiers.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No required parameters (@ExculdeCountry unused); returns one row per eligible country/regulation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetRafConfiguration_NogaJunk210725 retrieves the full Refer-A-Friend (RAF) program configuration, providing the compensation amounts and eligibility rules for each country/regulation combination where RAF is active. This data drives the RAF feature that rewards customers for referring new depositors.

The procedure returns only currently valid configurations (ValidFrom <= now < ValidTo) for countries marked IsEligibleForRAFBonusCountry=1. Each row represents the RAF terms for one country within one regulatory jurisdiction.

The `_NogaJunk210725` suffix indicates this is a working/experimental SP in the RAF subsystem (author: Noga, created July 2025). The `@ExculdeCountry` parameter (with typo) was originally intended to filter specific countries but is not referenced in the WHERE clause - it is a dead parameter.

**Change history (from DDL comments)**:
- 05/2023: Created, switched to Billing.RafConfigurationModels source
- 16/05/23: Removed support for CountryID=0 and RegulationID=0 rows
- 11/06/23: Remarked exclusion of Romania
- 17/03/24 (PART-2828): Added ReferredMinDepositInCents and ReferringMinDepositInCents fields

---

## 2. Business Logic

### 2.1 Time-Valid Configuration Selection

**What**: Only configurations valid at the current UTC timestamp are returned.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo`

**Rules**:
- WHERE ValidFrom <= GETUTCDATE() AND ValidTo > GETUTCDATE()
- Configurations in the future (ValidFrom > now) are excluded
- Expired configurations (ValidTo <= now) are excluded
- This allows pre-configuring future RAF campaigns by inserting rows with future ValidFrom dates

### 2.2 Model-Based Compensation Override (PI and Club)

**What**: Standard RAF compensation can be overridden by tier-specific models for Popular Investors and Club members.

**Columns/Parameters Involved**: `RafModelTypeID`, `RafModelID`, `ModelReferringCompensationInCents`, `ModelMaxNumberOfCompensations`

**Rules**:
- LEFT JOIN to RafConfigurationModels - rows without model overrides return NULL model columns
- RafModelTypeID: distinguishes PI models from Club models
- When model columns are NULL: standard configuration columns (ReferringCompensationInCents, MaxNumberOfCompensations) apply
- When model columns are present: model-specific values override for matching customer tiers

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExculdeCountry | INT | NO | 1 | CODE-BACKED | DEAD PARAMETER. Name has typo ("Exculde" instead of "Exclude"). The parameter is declared but not used in any WHERE, JOIN, or logic clause. Originally likely intended to filter out specific country IDs. |
| 2 | RegulationID | int (output) | NO | - | CODE-BACKED | Regulatory jurisdiction ID from Dictionary.Regulation. Identifies the regulatory framework under which these RAF terms apply (e.g., EU, ASIC, FCA). |
| 3 | CountryID | int (output) | NO | - | VERIFIED | Country identifier from Dictionary.Country. Only countries where IsEligibleForRAFBonusCountry=1 are included. |
| 4 | ReferringCompensationInCents | int (output) | YES | - | CODE-BACKED | Standard compensation for the referring customer (the one who invited a friend), in cents (USD). E.g., 5000 = $50. |
| 5 | ReferredCompensationInCents | int (output) | YES | - | CODE-BACKED | Standard compensation for the referred customer (the new registrant who was invited), in cents. |
| 6 | MaxNumberOfCompensations | int (output) | YES | - | CODE-BACKED | Maximum number of times the referring customer can receive compensation under standard terms. NULL = unlimited. |
| 7 | DaysToWaitFromFTD | int (output) | YES | - | CODE-BACKED | Number of days to wait after the referred customer's First-Time Deposit (FTD) before compensation is paid. Enforced by the RAFCompensationProcess job. |
| 8 | ReferringMinPositionsAmountInCents | int (output) | YES | - | CODE-BACKED | Minimum open positions amount (in cents) required from the referring customer to qualify for compensation. |
| 9 | ReferredMinPositionsAmountInCents | int (output) | YES | - | CODE-BACKED | Minimum open positions amount (in cents) required from the referred customer to trigger compensation. |
| 10 | ReferredMinDepositInCents | int (output) | YES | - | CODE-BACKED | Minimum deposit amount (in cents) required from the referred customer. Added PART-2828 (17/3/24). |
| 11 | ReferringMinDepositInCents | int (output) | YES | - | CODE-BACKED | Minimum deposit amount (in cents) required from the referring customer. Added PART-2828 (17/3/24). |
| 12 | TnC_URL | varchar (output) | YES | - | CODE-BACKED | URL to the Terms and Conditions page for this country's RAF program. Displayed to customers in the RAF UI. |
| 13 | RafModelTypeID | int (output) | YES | - | CODE-BACKED | Type of model override: NULL=no model, 1=Club model, 2=PI (Popular Investor) model. From Customer.RafConfigurationModels. |
| 14 | RafModelID | int (output) | YES | - | CODE-BACKED | Specific model variant ID within the RafModelTypeID. Used to match the appropriate PI guru tier or Club membership level. |
| 15 | ModelReferringCompensationInCents | int (output) | YES | - | CODE-BACKED | Model-specific compensation for referring customer (overrides ReferringCompensationInCents for matching tier). NULL if no model applies. |
| 16 | ModelMaxNumberOfCompensations | int (output) | YES | - | CODE-BACKED | Model-specific max compensations (overrides MaxNumberOfCompensations for matching tier). NULL if no model applies. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RegulationID | Customer.CountryRafConfiguration | FROM (base table) | Core RAF configuration by country/regulation |
| RafModelTypeID / RafModelID | Customer.RafConfigurationModels | LEFT JOIN on RafConfigurationID | Tier-specific model overrides |
| RegulationID | Dictionary.Regulation | INNER JOIN | Validates regulation IDs (excludes ID=0) |
| CountryID | Dictionary.Country | INNER JOIN | Validates country IDs (IsEligibleForRAFBonusCountry=1) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRafConfiguration_NogaJunk210725 (procedure)
├── Customer.CountryRafConfiguration (table)
├── Customer.RafConfigurationModels (table)
├── Dictionary.Regulation (table - cross-schema)
└── Dictionary.Country (table - cross-schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CountryRafConfiguration | Table | FROM (base) - RAF configuration per country/regulation |
| Customer.RafConfigurationModels | Table | LEFT JOIN on RafConfigurationID - tier model overrides |
| Dictionary.Regulation | Table | INNER JOIN on RegulationID (excludes ID=0) |
| Dictionary.Country | Table | INNER JOIN on CountryID (only IsEligibleForRAFBonusCountry=1) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @ExculdeCountry dead parameter | Code quality | Parameter declared but never used in body - typo in name ("Exculde"). Safe to ignore. |

---

## 8. Sample Queries

### 8.1 Get all active RAF configurations
```sql
EXEC Customer.GetRafConfiguration_NogaJunk210725;
```

### 8.2 Direct query equivalent for current valid configurations
```sql
SELECT dr.[ID] AS RegulationID, dc.[CountryID], bcrc.[ReferringCompensationInCents],
       bcrc.[ReferredCompensationInCents], bcrc.[MaxNumberOfCompensations],
       bcrc.[DaysToWaitFromFTD], bcrc.[TnC_URL], models.[RafModelTypeID]
FROM [Customer].[CountryRafConfiguration] bcrc WITH (NOLOCK)
LEFT JOIN [Customer].[RafConfigurationModels] models WITH (NOLOCK)
    ON models.RafConfigurationID = bcrc.RafConfigurationID
INNER JOIN [Dictionary].[Regulation] dr WITH (NOLOCK) ON bcrc.[RegulationID] = dr.ID AND dr.ID <> 0
INNER JOIN [Dictionary].[Country] dc WITH (NOLOCK) ON dc.[CountryID] = bcrc.[CountryID] AND dc.[CountryID] <> 0
WHERE dc.IsEligibleForRAFBonusCountry = 1
  AND bcrc.ValidFrom <= GETUTCDATE() AND bcrc.ValidTo > GETUTCDATE();
```

### 8.3 See RAF configuration for a specific country
```sql
SELECT bcrc.CountryID, bcrc.ReferringCompensationInCents, bcrc.MaxNumberOfCompensations,
       bcrc.ValidFrom, bcrc.ValidTo
FROM Customer.CountryRafConfiguration bcrc WITH (NOLOCK)
INNER JOIN Dictionary.Country dc WITH (NOLOCK) ON dc.CountryID = bcrc.CountryID
WHERE dc.CountryID = 63  -- example country
ORDER BY bcrc.ValidFrom DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-2828 | Jira | Added ReferredMinDepositInCents and ReferringMinDepositInCents fields (17/3/24) |
| PART-1488 | Jira | Added support for RAF Model PI and Club (27/4/23) |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 2 Jira (from DDL comments) | Procedures: 0 SQL callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetRafConfiguration_NogaJunk210725 | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetRafConfiguration_NogaJunk210725.sql*
