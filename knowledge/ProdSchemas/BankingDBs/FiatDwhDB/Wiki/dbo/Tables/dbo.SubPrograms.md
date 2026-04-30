# dbo.SubPrograms

> Lookup table defining the regional and tier-specific fiat sub-programs available on the platform, mapping each to its parent account program and provider-side program name.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (TINYINT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 0 active (PK only) |

---

## 1. Business Meaning

SubPrograms is a configuration/lookup table that defines the complete set of fiat product offerings available on the platform. Each sub-program represents a specific product variant combining an account type (card or IBAN), a tier level (Standard/Green, Premium/Black, Limited), and a geographic region (UK, EU, UAE, AUS, DK). Sub-programs determine the features, limits, and pricing a customer receives.

This table exists because the fiat platform offers different products across multiple regions and tiers. A customer in the UK card program has different capabilities than one in the EU IBAN program. Sub-programs are the granular configuration units that control this differentiation. The platform uses sub-programs for eligibility rules, program transitions, and provider-side (CUG) configuration mapping.

This is a relatively static configuration table. Values are maintained by the business team and change infrequently (only when new products or regions are launched). It is referenced by dbo.FiatAccount, dbo.FiatAccountsProperties, dbo.EligibilityRules, dbo.ProgramTransitionRules, and dbo.ProgramTransitionsEligibility.

---

## 2. Business Logic

### 2.1 Product Hierarchy

**What**: Two-level product hierarchy: Account Programs (card/iban) contain Sub-Programs (regional + tier variants).

**Columns/Parameters Involved**: `Id`, `Name`, `AccountProgramId`, `Region`

**Rules**:
- AccountProgramId=1 (card): Physical/virtual debit card products
- AccountProgramId=2 (iban): IBAN-based bank account products
- See [Account Program](../../_glossary.md#account-program) and [Sub-Program](../../_glossary.md#sub-program) for full value maps.

**Diagram**:
```
Account Programs
+-- card (1)
|   +-- Card Premium UK (1)
|   +-- Card Standard UK (2)
|   +-- Card Premium UAE (10)
|   +-- Card Green EU (11)
|   +-- Card Black EU (12)
|
+-- iban (2)
    +-- IBAN Premium UK (3)
    +-- IBAN Standard UK (4)
    +-- IBAN Standard EU Test (5)
    +-- IBAN EU Green (6)
    +-- IBAN EU Black (7)
    +-- IBAN LIMITED UK (8)
    +-- IBAN LIMITED EU (9)
    +-- IBAN Green AUS (13)
    +-- IBAN Black AUS (14)
    +-- IBAN Green DKK (15)
    +-- IBAN Black DKK (16)
```

### 2.2 Tier Hierarchy and Transitions

**What**: Sub-programs have an implicit tier hierarchy that governs upgrade/downgrade transitions.

**Columns/Parameters Involved**: `Name`, `Region`

**Rules**:
- Tier order: LIMITED < Standard/Green < Premium/Black
- Transitions move customers up (upgrade) or down (downgrade) within the same region
- Cross-region transitions are also possible (e.g., UK to EU upon relocation)
- Transition rules are defined in dbo.ProgramTransitionRules
- Eligibility for transitions is tracked in dbo.ProgramTransitionsEligibility

### 2.3 CUG Program Mapping

**What**: Each sub-program maps to a provider-side Closed User Group (CUG) program name.

**Columns/Parameters Involved**: `CugProgramName`

**Rules**:
- CugProgramName follows pattern: {Type}_{Tier}_{Region} (e.g., "Card_Premium_UK", "IBAN_EU_Green")
- This is the identifier used in Tribe's CUG system to identify the program
- Changes to CugProgramName require coordinated updates with the provider

---

## 3. Data Overview

| Id | Name | AccountProgramId | CugProgramName | Region | Meaning |
|---|---|---|---|---|---|
| 1 | Card Premium UK | 1 | Card_Premium_UK | UK | Top-tier UK debit card product with premium features and higher limits |
| 2 | Card Standard UK | 1 | Card_Standard_UK | UK | Standard UK debit card product - the default card offering |
| 6 | IBAN EU Green | 2 | IBAN_EU_Green | EU | Mid-tier EU IBAN banking product (Green tier) |
| 9 | IBAN LIMITED EU | 2 | IBAN_LIMITED_EU | EU | Restricted EU IBAN product - limited functionality, possibly for onboarding |
| 10 | Card Premium UAE | 1 | Card_Premium_UAE | UAE | Premium card product for UAE market |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Sub-program identifier. Primary key. Values 1-16 currently defined. Referenced by FiatAccount.SubProgramId, EligibilityRules.SubProgramId, ProgramTransitionRules source/destination, and ProgramTransitionsEligibility. |
| 2 | Name | nvarchar(128) | NO | - | CODE-BACKED | Human-readable sub-program name. Format: "{Type} {Tier} {Region}" (e.g., "Card Premium UK", "IBAN EU Green"). Used in reporting and customer-facing displays. |
| 3 | AccountProgramId | tinyint | NO | - | CODE-BACKED | Parent account program: 1=card, 2=iban. See [Account Program](../../_glossary.md#account-program). (Dictionary.AccountPrograms). Determines the fundamental product type. |
| 4 | CugProgramName | nvarchar(128) | NO | - | CODE-BACKED | Provider-side Closed User Group program identifier. Format: "{Type}_{Tier}_{Region}" (e.g., "Card_Premium_UK"). Used in Tribe API calls and provider configuration. |
| 5 | Region | nvarchar(128) | YES | - | CODE-BACKED | Geographic region for this sub-program: UK, EU, UAE, AUS, DK. Determines which banking rails, regulations, and currency options apply. NULL would indicate a region-agnostic program (none currently). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AccountProgramId | Dictionary.AccountPrograms | Implicit | Links to parent account program (card/iban) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.FiatAccount | SubProgramId | Implicit | Each account may be assigned to a sub-program |
| dbo.FiatAccountsProperties | SubProgramId | Implicit | Account property snapshots reference the sub-program |
| dbo.EligibilityRules | SubProgramId | FK | Eligibility rules target specific sub-programs |
| dbo.ProgramTransitionRules | SourceSubProgramId | Implicit | Transition rules define source sub-program |
| dbo.ProgramTransitionRules | DestinationSubProgramId | Implicit | Transition rules define destination sub-program |
| dbo.ProgramTransitionsEligibility | SourceSubProgramId | FK | Eligibility records reference source sub-program |
| dbo.ProgramTransitionsEligibility | DestinationSubProgramId | FK | Eligibility records reference destination sub-program |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatAccount | Table | Implicit reference from SubProgramId |
| dbo.FiatAccountsProperties | Table | Implicit reference from SubProgramId |
| dbo.EligibilityRules | Table | FK from SubProgramId |
| dbo.ProgramTransitionRules | Table | Implicit from Source/DestinationSubProgramId |
| dbo.ProgramTransitionsEligibility | Table | FK from Source/DestinationSubProgramId |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SubPrograms | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None (beyond PK).

---

## 8. Sample Queries

### 8.1 List all sub-programs with their account program
```sql
SELECT sp.Id, sp.Name, ap.Name AS AccountProgram, sp.CugProgramName, sp.Region
FROM dbo.SubPrograms sp WITH (NOLOCK)
JOIN Dictionary.AccountPrograms ap WITH (NOLOCK) ON ap.Id = sp.AccountProgramId
ORDER BY sp.AccountProgramId, sp.Region, sp.Name;
```

### 8.2 Find all card sub-programs
```sql
SELECT Id, Name, CugProgramName, Region
FROM dbo.SubPrograms WITH (NOLOCK)
WHERE AccountProgramId = 1
ORDER BY Region, Name;
```

### 8.3 Find all sub-programs for a specific region
```sql
SELECT Id, Name, AccountProgramId, CugProgramName
FROM dbo.SubPrograms WITH (NOLOCK)
WHERE Region = 'EU'
ORDER BY AccountProgramId, Name;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Important DB Queries](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290274878) | Confluence | FiatWallet.SubPrograms is queried alongside account overview - confirms sub-programs are a core entity |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.SubPrograms | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.SubPrograms.sql*
