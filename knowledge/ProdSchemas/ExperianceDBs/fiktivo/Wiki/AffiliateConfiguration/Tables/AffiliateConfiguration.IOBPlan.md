# AffiliateConfiguration.IOBPlan

> Configuration table defining IOB (Interest on Balance) commission amounts per affiliate type and country - when a referred customer activates the IOB feature, this plan determines the affiliate's commission instead of the standard CPA.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateConfiguration |
| **Object Type** | Table |
| **Key Identifier** | AffiliateTypeID + CountryID (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (clustered composite PK) |

---

## 1. Business Meaning

AffiliateConfiguration.IOBPlan defines per-country commission amounts for the IOB (Interest on Balance) affiliate commission model. IOB is an eToro feature where customers earn interest on their uninvested cash balance. When a referred customer activates IOB, the affiliate earns a commission configured in this table instead of the standard CPA first-position commission. The key business rule is: **IOB commission takes priority over CPA** - if both IOB and CPA are configured, IOB wins.

Without this table, affiliates would only earn commissions through the CPA first-position model. IOBPlan provides an alternative commission trigger based on product adoption (IOB activation) rather than trading activity (first position). This is particularly valuable for affiliates who refer customers who may not trade immediately but do activate IOB for passive income.

Plan entries are managed atomically by [AffiliateAdmin.UpdateInsertAffiliateType](../../AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateInsertAffiliateType.md) using the [RegistrationCountryRateType TVP](../User Defined Types/AffiliateConfiguration.RegistrationCountryRateType.md) (reused as `@IOBPerCountry`). The procedure compares old vs new plan states via STRING_AGG and only writes if changed. The commission pipeline reads this table via GetAffiliateTypeDataByAffiliateTypeId and GetCreditTriggeredEvents to determine IOB eligibility. Created as part of PART-4763 (Sep 2025).

---

## 2. Business Logic

### 2.1 IOB vs CPA Priority

**What**: When both IOB and CPA commission models are configured for an affiliate type, IOB takes priority over CPA.

**Columns/Parameters Involved**: `AffiliateTypeID`, `Commission` (this table) vs FirstPositionAssetPlan.CPAAmount

**Rules**:
- The CreditEligibility service checks via API whether the trader has consented to IOB
- If the trader has IOB active AND the affiliate type has an IOBPlan entry: IOB commission is used
- If the trader does NOT have IOB active: standard CPA commission from FirstPositionAssetPlan is used
- CreditEligibility adds an indication to the message about which model to use before sending to CreditCommission service
- CreditCommission calculates the commission based on this flag
- The existence of an IOBPlan entry for the AffiliateTypeID is itself a signal in GetCreditTriggeredEvents (LEFT JOIN produces non-null if configured)

**Diagram**:
```
Customer activates IOB?
  |
  +-- YES --> IOBPlan configured for affiliate type?
  |             |
  |             +-- YES --> Use IOBPlan.Commission (IOB wins)
  |             +-- NO  --> Use CPA from FirstPositionAssetPlan
  |
  +-- NO  --> Use CPA from FirstPositionAssetPlan
```

### 2.2 Country-Tiered IOB Commission

**What**: IOB commissions can be configured per country, with a global default for unlisted countries.

**Columns/Parameters Involved**: `CountryID`, `Commission`

**Rules**:
- CountryID=0 means default (global rate for all countries not explicitly listed)
- Country-specific entries (CountryID>0) override the default
- Commission is a flat amount paid to the affiliate when the referred customer activates IOB
- Some plans cover 100+ countries with per-country rates (live data shows plans with up to 101 distinct countries)

---

## 3. Data Overview

| AffiliateTypeID | CountryID | Commission | DateModified | Meaning |
|---|---|---|---|---|
| 18 | 0 (All) | 77 | 2025-12-04 | Global default IOB rate for affiliate type 18: $77 commission for any country not explicitly listed |
| 20 | 0 (All) | 0 | 2025-12-02 | IOB plan exists but with $0 commission - effectively disables IOB payout while keeping the IOB model active for eligibility routing |
| 745 | 0 (All) | 60 | 2025-11-16 | Global default: $60 IOB commission |
| 4765 | 1 (Afghanistan) | 300 | 2026-02-17 | Country-specific entry from a plan with per-country rates: $300 for Afghanistan |
| 4765 | 79 (Germany) | 300 | 2026-02-17 | Same plan, Germany-specific: $300. This plan applies the same rate across many individual countries |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateTypeID | int | NO | - | VERIFIED | Commission plan template this IOB entry belongs to. Part of composite PK. Implicit FK to [dbo.tblaff_AffiliateTypes](../../dbo/Tables/dbo.tblaff_AffiliateTypes.md). Each affiliate type can have multiple IOBPlan entries (one per country). The mere existence of IOBPlan rows for an AffiliateTypeID signals that IOB commission model is available (used as LEFT JOIN non-null check in GetCreditTriggeredEvents). |
| 2 | CountryID | bigint | NO | - | VERIFIED | Target country for this IOB commission rate. Part of composite PK. Implicit FK to [dbo.tblaff_Country](../../dbo/Tables/dbo.tblaff_Country.md). 0 = global default for all countries not explicitly listed. Country-specific entries override the default. Validated by UpdateInsertAffiliateType against tblaff_Country before insertion. |
| 3 | Commission | float | NO | - | CODE-BACKED | Flat IOB commission amount paid to the affiliate when a referred customer from this country activates the Interest on Balance feature. Expressed in platform base currency (USD). Live range: $0-$300. $0 effectively disables payout while keeping the IOB model active. |
| 4 | DateModified | datetime | NO | GETUTCDATE() | CODE-BACKED | Timestamp of the last update to this entry (UTC). Default: GETUTCDATE(). Set on insert by UpdateInsertAffiliateType. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateTypeID | dbo.tblaff_AffiliateTypes | Implicit FK | Commission plan template this IOB entry belongs to |
| CountryID | dbo.tblaff_Country | Implicit FK | Target country for geo-segmented IOB rates. 0=all countries |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateAdmin.UpdateInsertAffiliateType | Direct INSERT/DELETE | WRITER | Creates and replaces IOB plan entries using RegistrationCountryRateType TVP as @IOBPerCountry |
| AffiliateAdmin.GetAffiliateTypeData | Direct SELECT | READER | Reads IOB plan for admin UI display |
| AffiliateCommission.GetAffiliateTypeDataByAffiliateTypeId | Direct SELECT | READER | Reads IOB plan for commission pipeline |
| AffiliateCommission.GetAffiliateTypeDataByAffiliateId | Direct SELECT | READER | Reads IOB plan for commission pipeline by affiliate |
| AffiliateCommission.GetCreditTriggeredEvents | LEFT JOIN | READER | Checks IOB plan existence as eligibility signal in credit-triggered commission evaluation |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies. Tables are always leaf nodes.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateAdmin.UpdateInsertAffiliateType | Stored Procedure | WRITER - INSERT/DELETE IOB plan entries |
| AffiliateAdmin.GetAffiliateTypeData | Stored Procedure | READER - admin UI display |
| AffiliateCommission.GetAffiliateTypeDataByAffiliateTypeId | Stored Procedure | READER - commission pipeline |
| AffiliateCommission.GetAffiliateTypeDataByAffiliateId | Stored Procedure | READER - commission pipeline |
| AffiliateCommission.GetCreditTriggeredEvents | Stored Procedure | READER - IOB eligibility check |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_IOBPlan_AffiliateTypeID | CLUSTERED | AffiliateTypeID ASC, CountryID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_IOBPlan_AffiliateTypeID | PRIMARY KEY | Composite clustered PK. Ensures one IOB rate per affiliate type per country |
| DF_IOBPlan_DateModified | DEFAULT | GETUTCDATE() for DateModified. Automatically timestamps on insert |

---

## 8. Sample Queries

### 8.1 View IOB plan with resolved country names

```sql
SELECT iob.AffiliateTypeID, at.Description AS PlanName,
       iob.CountryID, CASE WHEN iob.CountryID = 0 THEN 'All Countries' ELSE c.Name END AS Country,
       iob.Commission, iob.DateModified
FROM AffiliateConfiguration.IOBPlan iob WITH (NOLOCK)
LEFT JOIN dbo.tblaff_AffiliateTypes at WITH (NOLOCK) ON iob.AffiliateTypeID = at.AffiliateTypeID
LEFT JOIN dbo.tblaff_Country c WITH (NOLOCK) ON iob.CountryID = c.CountryID
WHERE iob.AffiliateTypeID = 18
ORDER BY iob.CountryID;
```

### 8.2 Find affiliate types with IOB plans configured

```sql
SELECT iob.AffiliateTypeID, at.Description, COUNT(*) AS CountryEntries,
       MAX(CASE WHEN iob.CountryID = 0 THEN iob.Commission END) AS DefaultCommission
FROM AffiliateConfiguration.IOBPlan iob WITH (NOLOCK)
INNER JOIN dbo.tblaff_AffiliateTypes at WITH (NOLOCK) ON iob.AffiliateTypeID = at.AffiliateTypeID
GROUP BY iob.AffiliateTypeID, at.Description
ORDER BY CountryEntries DESC;
```

### 8.3 Compare IOB vs CPA commission for an affiliate type

```sql
SELECT 'IOB' AS Model, iob.CountryID, c.Name AS Country, iob.Commission
FROM AffiliateConfiguration.IOBPlan iob WITH (NOLOCK)
LEFT JOIN dbo.tblaff_Country c WITH (NOLOCK) ON iob.CountryID = c.CountryID
WHERE iob.AffiliateTypeID = 18
UNION ALL
SELECT 'CPA' AS Model, fp.CountryID, c2.Name AS Country, fp.CPAAmount
FROM AffiliateConfiguration.FirstPositionAssetPlan fp WITH (NOLOCK)
LEFT JOIN dbo.tblaff_Country c2 WITH (NOLOCK) ON fp.CountryID = c2.CountryID
WHERE fp.AffiliateTypeID = 18
ORDER BY Model, CountryID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [IOB](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13304168449/IOB) | Confluence | IOB = Interest on Balance. Key rule: if having IOB & CPA, IOB wins. CreditEligibility service checks IOB consent via API. Table originally designed as "AffiliateTypeIOB", CountryID=0 means default. Commission pipeline reads IOB model alongside CPA model. |
| [CPA New Compensation Plan - DB design](https://etoro-jira.atlassian.net/wiki/x/PLACEHOLDER) | Confluence | IOBPlan is an extension of the CPA compensation plan architecture, added under AffiliateConfiguration schema |

PART-4763 (Jira): IOB feature - original creation ticket for IOBPlan table (Sep 2025, referenced in procedure header comments).

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateConfiguration.IOBPlan | Type: Table | Source: fiktivo/AffiliateConfiguration/Tables/AffiliateConfiguration.IOBPlan.sql*
