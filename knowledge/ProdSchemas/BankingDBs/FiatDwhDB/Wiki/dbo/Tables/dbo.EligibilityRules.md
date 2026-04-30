# dbo.EligibilityRules

> Configuration table defining which customer segments (by regulation, country, and club tier) are eligible for each fiat sub-program, with rollout percentages for gradual feature launches.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (INT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 0 active (PK only) |

---

## 1. Business Meaning

EligibilityRules is a configuration table that defines the targeting matrix for fiat sub-program assignment. Each rule specifies a combination of regulation, country, and club tier, along with the target sub-program and a rollout percentage. When a customer's attributes match a rule, they become eligible for the specified sub-program (subject to the rollout percentage).

This table exists because the fiat platform operates across multiple regulatory jurisdictions (designated regulations), countries, and customer tiers (clubs). Each combination may or may not have access to specific sub-programs. For example, UK customers under regulation 5 in club tier 1 might be eligible for IBAN Green DKK (SubProgramId=15) at 100% rollout. Without this configuration table, the platform would need hardcoded eligibility logic per sub-program.

Data is created and updated by the dbo.AddEligibilityRules stored procedure, which accepts batches via the EligibilityRulesType TVP. Rules are maintained by the business/product team and deployed via configuration updates. The LastTimeOverride field shows rules are periodically refreshed.

---

## 2. Business Logic

### 2.1 Eligibility Targeting Matrix

**What**: Multi-dimensional targeting that matches customers to sub-programs based on regulation, country, and club attributes.

**Columns/Parameters Involved**: `DesignatedRegulationId`, `CountryId`, `ClubId`, `SubProgramId`, `RolloutPercentage`, `RegulationId`, `Priority`

**Rules**:
- A customer matches a rule when their RegulationId, CountryId, and ClubId all match
- DesignatedRegulationId determines which regulatory framework the sub-program operates under
- When multiple rules match, Priority determines which wins (lower number = higher priority)
- RolloutPercentage (0-100) enables gradual rollout - only that percentage of matching customers get the sub-program
- FiatId groups rules by fiat platform instance

**Diagram**:
```
Customer Attributes           Rule Match           Sub-Program Assignment
+-------------------+       +------------+       +--------------------+
| RegulationId: 5   |------>|            |       | SubProgramId: 15   |
| CountryId: 57     |------>| Rule Match |------>| IBAN Green DKK     |
| ClubId: 1         |------>|            |       | Rollout: 100%      |
+-------------------+       +------------+       +--------------------+

Priority Resolution (when multiple rules match):
  Rule A (Priority 0) -> wins
  Rule B (Priority 1) -> loses (higher number = lower priority)
```

---

## 3. Data Overview

| Id | FiatId | DesignatedRegulationId | CountryId | ClubId | SubProgramId | RolloutPercentage | Priority | Meaning |
|---|---|---|---|---|---|---|---|---|
| 3152850 | 2657 | 5 | 57 | 1 | 15 | 100 | 0 | Customers in country 57, regulation 5, club 1 are 100% eligible for IBAN Green DKK |
| 3152849 | 2656 | 10 | 57 | 7 | 16 | 100 | 0 | Customers in country 57, regulation 10, club 7 are 100% eligible for IBAN Black DKK |
| 3152848 | 2655 | 10 | 57 | 6 | 16 | 100 | 0 | Customers in country 57, regulation 10, club 6 are also eligible for IBAN Black DKK |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | FiatId | int | NO | - | NAME-INFERRED | Fiat platform instance identifier. Groups rules by deployment context. |
| 3 | DesignatedRegulationId | tinyint | NO | - | NAME-INFERRED | Target regulatory jurisdiction. Determines which regulatory framework governs the sub-program for this rule. |
| 4 | CountryId | tinyint | NO | - | NAME-INFERRED | Country filter for the rule. Only customers in this country match. References an external country ID system. |
| 5 | ClubId | tinyint | NO | - | NAME-INFERRED | eToro club tier filter. Restricts eligibility to customers at a specific club/loyalty level. |
| 6 | SubProgramId | tinyint | NO | - | CODE-BACKED | Target sub-program that eligible customers can access. FK to dbo.SubPrograms: 1=Card Premium UK, 2=Card Standard UK, ..., 16=IBAN Black DKK. See [Sub-Program](../../_glossary.md#sub-program). |
| 7 | RolloutPercentage | decimal(18,1) | NO | - | CODE-BACKED | Percentage of matching customers to enroll (0.0-100.0). Enables gradual rollout of new sub-programs. 100.0 = fully available. |
| 8 | RegulationId | tinyint | NO | - | NAME-INFERRED | Source regulatory jurisdiction of the customer. Used to match customers by their current regulation. |
| 9 | UpdateTime | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this rule was last configured/deployed. |
| 10 | LastTimeOverride | datetime2(7) | NO | - | CODE-BACKED | Timestamp of the most recent bulk refresh/override of this rule. Updated when AddEligibilityRules runs. |
| 11 | Priority | smallint | NO | 0 | CODE-BACKED | Priority rank for rule evaluation. When multiple rules match, lowest number wins. Default 0 (highest priority). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SubProgramId | dbo.SubPrograms | FK | Target sub-program for eligible customers |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AddEligibilityRules | INSERT/MERGE | Writer | Bulk inserts/updates eligibility rules via EligibilityRulesType TVP |
| dbo.GetCountEligibilityRules | SELECT | Reader | Returns count of eligibility rules |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.EligibilityRules (table)
└── dbo.SubPrograms (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.SubPrograms | Table | FK from SubProgramId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AddEligibilityRules | Stored Procedure | Writes eligibility rules |
| dbo.GetCountEligibilityRules | Stored Procedure | Reads rule count |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_dbo_EligibilityRules_SubProgramId_dbo_SubPrograms_Id | FK | SubProgramId -> dbo.SubPrograms.Id |
| (default) | DEFAULT | Priority defaults to 0 |

---

## 8. Sample Queries

### 8.1 Find all rules for a specific sub-program
```sql
SELECT er.*, sp.Name AS SubProgramName
FROM dbo.EligibilityRules er WITH (NOLOCK)
JOIN dbo.SubPrograms sp WITH (NOLOCK) ON sp.Id = er.SubProgramId
WHERE er.SubProgramId = 15
ORDER BY er.Priority, er.CountryId;
```

### 8.2 Find rules with partial rollout (gradual launch)
```sql
SELECT er.Id, er.SubProgramId, sp.Name, er.RolloutPercentage, er.CountryId, er.ClubId
FROM dbo.EligibilityRules er WITH (NOLOCK)
JOIN dbo.SubPrograms sp WITH (NOLOCK) ON sp.Id = er.SubProgramId
WHERE er.RolloutPercentage < 100.0
ORDER BY er.RolloutPercentage;
```

### 8.3 Count rules per sub-program
```sql
SELECT sp.Name, COUNT(*) AS RuleCount
FROM dbo.EligibilityRules er WITH (NOLOCK)
JOIN dbo.SubPrograms sp WITH (NOLOCK) ON sp.Id = er.SubProgramId
GROUP BY sp.Name ORDER BY RuleCount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Banking Database](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290242096) | Confluence | FiatDwhDB stores reporting data including program eligibility information |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.6/10 (Elements: 8.2/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 5 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.EligibilityRules | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.EligibilityRules.sql*
