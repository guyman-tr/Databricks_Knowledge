# Billing.GetRafConfiguration_NogaJunk210725

> Returns the full Refer-a-Friend (RAF) program configuration for all eligible countries and regulations - compensation amounts, minimum position thresholds, waiting periods, and T&C URLs - expanding global (CountryID=0, RegulationID=0) rules into per-country/regulation rows.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all Billing.CountryRafConfiguration rows where IsEligibleForRAFBonusCountry=1, excluding Romania (168), expanded via cross-join pattern for global rules |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetRafConfiguration_NogaJunk210725` retrieves the complete Refer-a-Friend (RAF) program configuration - compensation amounts, minimum position requirements, waiting periods, and Terms & Conditions URLs - for all eligible countries and regulations. It is consumed by the RAF service (`SQL_RAF` user) to determine program rules before processing referral compensations.

The procedure exists as the Billing-schema accessor for RAF configuration. It reads from `Billing.CountryRafConfiguration` (the original Billing-schema RAF configuration table, which is NOT present in the current SSDT - it appears to have been created dynamically or migrated to `Customer.CountryRafConfiguration_NogaJunk210725`). The `_NogaJunk210725` suffix indicates this procedure was tagged by team member Noga in July 2025 as a candidate for deprecation/cleanup, but it has an active `SQL_RAF` user permission and multiple configuration modifications through 2023.

Data flows: `SQL_RAF` user calls this to load the full RAF configuration set at the start of compensation processing. The result is used to determine: which countries/regulations are eligible for RAF bonuses, what amounts to pay, how many compensations are allowed, and whether a customer's positions meet minimum thresholds.

Change history:
- Ran Ovadia, 20/05/2019: Added MaxNumberOfCompensations column
- Ran Ovadia, 06/05/2020: Added support for minimum positions threshold
- Ran Ovadia, 10/06/2020: Fixed duplicate values
- Ran Ovadia, 23/03/2022: Added hardcoded US regulation override (IDs 6, 7, 8) - $30 compensation for a limited date window (2022-03-23 to 2022-04-24)
- Noga Rozen, 13/10/2022: Added TnC_URL column fetch
- Moshe Ozer, 12/10/2022: Exposed TnC_URL column
- Ran Ovadia, 10/05/2023: Excluded Romania (CountryID=168) from results

---

## 2. Business Logic

### 2.1 Global Rule Expansion (Cross-Join Pattern)

**What**: RAF configuration rows with RegulationID=0 or CountryID=0 represent global defaults that apply to all regulations or all countries respectively. The JOIN logic expands these into per-regulation/per-country rows.

**Columns/Parameters Involved**: `bcrc.RegulationID`, `bcrc.CountryID`, JOIN conditions

**Rules**:
- **RegulationID expansion**: `bcrc.RegulationID = dr.ID OR bcrc.RegulationID = 0` - rows with RegulationID=0 are joined to ALL regulation rows in Dictionary.Regulation
- **CountryID expansion**: `dc.CountryID = bcrc.CountryID OR (bcrc.CountryID = 0 AND dc.CountryID <> bcrc.CountryID)` - rows with CountryID=0 are joined to ALL countries (with the `<> bcrc.CountryID` guard preventing double-joining CountryID=0 row with CountryID=0 country)
- This creates a full cartesian expansion for global defaults while preserving specific per-country/per-regulation rules

### 2.2 Eligibility Filter - Romania Exclusion

**What**: Only countries eligible for RAF bonus are returned, with Romania explicitly excluded.

**Filter**: `WHERE dc.IsEligibleForRAFBonusCountry = 1 AND dc.CountryID NOT IN (168)`

**Rules**:
- `IsEligibleForRAFBonusCountry = 1`: The country's flag in Dictionary.Country must permit RAF bonuses
- Romania (CountryID=168): Hardcoded exclusion added 2023-05-10 (Ran Ovadia) - likely due to regulatory restriction or RAF program suspension in Romania

### 2.3 Hardcoded US Regulation Override (Expired Date Window)

**What**: A temporary IIF override for US-related regulations during March-April 2022.

**Columns Involved**: `dr.ID` (RegulationID), `ReferringCompensationInCents`, `ReferredCompensationInCents`

**Logic**:
```sql
IIF(GETUTCDATE() BETWEEN '20220323' AND '20220424' AND dr.ID IN (6, 7, 8),
    3000,
    bcrc.ReferringCompensationInCents) AS ReferringCompensationInCents
```
- RegulationIDs 6, 7, 8 = US-related regulations
- During 2022-03-23 to 2022-04-24: both referring and referred compensations = 3000 cents ($30)
- **CURRENTLY INACTIVE**: This date range has long expired. The IIF always returns the standard `bcrc.ReferringCompensationInCents` value now. This is effectively dead code that remains for historical traceability.

### 2.4 RAF Configuration Columns Returned

| Column | Business Meaning |
|--------|-----------------|
| RegulationID | Regulatory jurisdiction this config applies to |
| CountryID | Country this config applies to |
| ReferringCompensationInCents | Amount in cents paid to the person who made the referral (e.g., 5000 = $50) |
| ReferredCompensationInCents | Amount in cents paid to the newly referred customer |
| MaxNumberOfCompensations | Maximum number of referral bonuses a single referrer can claim |
| DaysToWaitFromFTD | Days after the referred customer's First Time Deposit before compensation is paid |
| ReferringMinPositionsAmountInCents | Minimum total position amount the referrer must have (in cents) |
| ReferredMinPositionsAmountInCents | Minimum total position amount the referred customer must reach to trigger payout |
| TnC_URL | URL to the country-specific Terms & Conditions PDF for the RAF program |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters. The procedure returns all eligible RAF configuration data.

**Return columns:**

| # | Column | Source | Confidence | Description |
|---|--------|--------|------------|-------------|
| 1 | RegulationID | Dictionary.Regulation.ID | CODE-BACKED | Regulatory jurisdiction ID. Expanded from global (0) or specific regulation entries. |
| 2 | CountryID | Dictionary.Country.CountryID | CODE-BACKED | Country ID for this RAF rule. Expanded from global (0) or specific country entries. |
| 3 | ReferringCompensationInCents | Billing.CountryRafConfiguration (with IIF override) | CODE-BACKED | Compensation for the referring customer in US cents (e.g., 5000 = $50). |
| 4 | ReferredCompensationInCents | Billing.CountryRafConfiguration (with IIF override) | CODE-BACKED | Compensation for the newly referred customer in US cents. |
| 5 | MaxNumberOfCompensations | Billing.CountryRafConfiguration | CODE-BACKED | Maximum number of referral bonuses this referrer can earn. |
| 6 | DaysToWaitFromFTD | Billing.CountryRafConfiguration | CODE-BACKED | Days to wait after the referred customer's First Time Deposit before paying compensation. |
| 7 | ReferringMinPositionsAmountInCents | Billing.CountryRafConfiguration | CODE-BACKED | Minimum position amount (cents) the referring customer must maintain. |
| 8 | ReferredMinPositionsAmountInCents | Billing.CountryRafConfiguration | CODE-BACKED | Minimum position amount (cents) the referred customer must reach to trigger payout. |
| 9 | TnC_URL | Billing.CountryRafConfiguration | CODE-BACKED | URL to the country-specific RAF Terms & Conditions document. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (FROM) | Billing.CountryRafConfiguration | Primary source | RAF configuration rows (note: NOT in current SSDT - likely migrated or created via migration script) |
| (JOIN) | Dictionary.Regulation | INNER JOIN | Expands RegulationID to regulation rows; enables global (ID=0) rule expansion |
| (JOIN) | Dictionary.Country | INNER JOIN | Expands CountryID to country rows; enables global (ID=0) rule expansion; provides IsEligibleForRAFBonusCountry flag |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_RAF | GRANT EXECUTE | Permission | RAF service loads full configuration at the start of compensation processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetRafConfiguration_NogaJunk210725 (procedure)
├── Billing.CountryRafConfiguration (table - NOT in SSDT repo)
├── Dictionary.Regulation (table - cross-schema)
└── Dictionary.Country (table - cross-schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CountryRafConfiguration | Table | Primary source of RAF config rows; NOT present in SSDT - may be a pre-existing table or migration artifact |
| Dictionary.Regulation | Table | INNER JOINed to expand RegulationID=0 global rules to per-regulation rows |
| Dictionary.Country | Table | INNER JOINed to expand CountryID=0 global rules to per-country rows; source of IsEligibleForRAFBonusCountry flag and exclusion of Romania (168) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_RAF | DB Security Principal | EXECUTE permission - RAF compensation service loads configuration |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**IMPORTANT - Naming Convention**: The `_NogaJunk210725` suffix is a deprecation/cleanup tag applied by team member Noga in July 2025. Despite the suffix, this procedure has an active `SQL_RAF` GRANT EXECUTE permission and was last modified in May 2023, suggesting it remains in production use. The Customer schema counterpart (`Customer.GetRafConfiguration_NogaJunk210725`) has a similar suffix.

**IMPORTANT - Table Not in SSDT**: `Billing.CountryRafConfiguration` is not present in the SSDT repository. The current production RAF configuration table appears to be `Customer.CountryRafConfiguration_NogaJunk210725` (temporal table with full history). The Billing version of this table may be a legacy pre-migration artifact or was never included in the SSDT project.

**Expired override**: The US regulation (IDs 6, 7, 8) hardcoded $30 override for 2022-03-23 to 2022-04-24 is now permanently inactive (the date range has passed). It functions as documentation of a past T&C change.

---

## 8. Sample Queries

### 8.1 Execute the procedure to get RAF configuration
```sql
EXEC [Billing].[GetRafConfiguration_NogaJunk210725]
```

### 8.2 Check RAF configuration for a specific country/regulation
```sql
-- From the underlying table (if accessible)
SELECT *
FROM Billing.CountryRafConfiguration WITH (NOLOCK)
WHERE CountryID IN (0, 1)   -- 0 = global, 1 = specific country
  AND RegulationID IN (0, 1) -- 0 = global, 1 = specific regulation
```

### 8.3 Find max compensation limits per regulation
```sql
-- From procedure results: join back to names
SELECT
    RegulationID,
    MAX(ReferringCompensationInCents) / 100.0 AS MaxReferringUSD,
    MAX(ReferredCompensationInCents) / 100.0 AS MaxReferredUSD,
    MAX(MaxNumberOfCompensations) AS MaxCompensations
FROM (EXEC [Billing].[GetRafConfiguration_NogaJunk210725]) config
GROUP BY RegulationID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetRafConfiguration_NogaJunk210725 | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetRafConfiguration_NogaJunk210725.sql*
