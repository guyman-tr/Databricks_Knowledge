# eMoney_dbo.eMoney_Dictionary_AccountSubProgram

> 10-row lookup table (Synapse; 16 rows in FiatDwhDB source) defining regional and tier-specific fiat sub-programs for eToro Money; sourced from FiatDwhDB.dbo.SubPrograms via Generic Pipeline Bronze export. IDs 11-16 (AUS and DK sub-programs) not yet loaded to Synapse.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Dictionary) |
| **Production Source** | FiatDwhDB.dbo.SubPrograms (Generic Pipeline Bronze export — note: dbo schema, NOT Dictionary schema) |
| **Refresh** | Generic Pipeline (scheduled; matches FiatDwhDB update cadence) |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| **Row Count** | 10 (IDs 1-10 confirmed live 2026-04-20; FiatDwhDB has 16 rows including AUS and DK sub-programs) |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountsubprogram` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Dictionary_AccountSubProgram` defines the complete set of fiat product offerings available on the eToro Money platform at sub-program granularity. Each sub-program represents a specific product variant combining an account type (card or IBAN), a tier level (Standard/Green, Premium/Black, Limited), and a geographic region (UK, EU, UAE, AUS, DK). Sub-programs determine the features, limits, and pricing a customer receives.

This lookup is sourced from `FiatDwhDB.dbo.SubPrograms` — note the dbo schema, not the Dictionary schema. It expands on `eMoney_Dictionary_AccountProgram` (which only distinguishes card vs IBAN at program level) by providing the full regional and tier breakdown.

As of 2026-04-20, the Synapse table has 10 of 16 source rows. The missing 6 sub-programs (IDs 11-16) correspond to Card Green EU, Card Black EU, IBAN Green AUS, IBAN Black AUS, IBAN Green DKK, and IBAN Black DKK — the AUS and European/DK expansions added after the initial Synapse load. Accounts with these sub-programs will have unresolved `AccountSubProgramID` values in eMoney analytics tables.

---

## 2. Business Logic

### 2.1 Sub-Program Hierarchy

**What**: Two-level hierarchy — Account Programs (card/iban) contain Sub-Programs (regional + tier variants).

**Columns Involved**: `AccountSubProgramID`, `AccountSubProgram`, `AccountProgramID`

**Rules**:
- `AccountProgramID=1` (card): `Card Premium UK (1)`, `Card Standard UK (2)`, `Card Premium UAE (10)`
- `AccountProgramID=2` (iban): `IBAN Premium UK (3)`, `IBAN Standard UK (4)`, `IBAN Standard EU Test (5)`, `IBAN EU Green (6)`, `IBAN EU Black (7)`, `IBAN LIMITED UK (8)`, `IBAN LIMITED EU (9)`
- IDs 11-16 (in FiatDwhDB but absent from Synapse): Card Green EU, Card Black EU, IBAN Green AUS, IBAN Black AUS, IBAN Green DKK, IBAN Black DKK

### 2.2 CUG Program Mapping

**What**: Each sub-program maps to a Tribe Closed User Group (CUG) program identifier.

**Columns Involved**: `CUGAccountSubProgram`

**Rules**:
- CUG names follow the pattern `{Type}_{Tier}_{Region}` (e.g., `Card_Premium_UK`, `IBAN_EU_Green`)
- Used in Tribe API calls, provider configuration, and eligibility rule lookups
- Changes to CUGAccountSubProgram require coordinated updates with Tribe

### 2.3 Tier Hierarchy

**What**: Implicit tier ordering within each region.

**Rules**:
- Tier order: `LIMITED < Standard/Green < Premium/Black`
- Within card programs: `Standard UK < Premium UK`
- Within IBAN programs: `LIMITED < Standard/Green < Black`
- Cross-region transitions (UK ↔ EU, EU ↔ AUS) are also supported

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE — 10-row table broadcast to all distributions. Joins are data-local and free.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode sub-program for account | `JOIN eMoney_Dictionary_AccountSubProgram sp ON a.AccountSubProgramID = sp.AccountSubProgramID` |
| Filter UK card accounts | `WHERE sp.AccountProgramID = 1 AND sp.AccountSubProgram LIKE '%UK%'` |
| Get CUG name for Tribe API | `SELECT CUGAccountSubProgram FROM eMoney_Dictionary_AccountSubProgram WHERE AccountSubProgramID = @id` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_Dim_Account | AccountSubProgramID = AccountSubProgramID | Decode sub-program on account records |
| eMoney_Dictionary_AccountProgram | AccountProgramID = AccountProgramID | Navigate up to program level |

### 3.4 Gotchas

- **10 of 16 rows loaded**: Accounts with AUS/DK sub-programs (IDs 11-16) will have `NULL` sub-program names on join — always use LEFT JOIN and handle NULL to avoid excluding these accounts
- DWH `AccountSubProgram` is `varchar(50)` vs source `nvarchar(128)` — names longer than 50 chars would truncate (none of the current 10 values exceed this limit, but verify for new AUS/DK sub-programs)
- Source is `FiatDwhDB.dbo.SubPrograms` not `FiatDwhDB.Dictionary.*` — the object naming in eMoney_Dictionary_* is a DWH convention, not a source schema convention

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (FiatDwhDB) |
| Tier 2 | Derived from ETL SP code or DWH logic |
| Tier 3 | Inferred from column name and context |
| Tier 4 | Best available — limited confidence |
| Tier 5 | Glossary-sourced |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AccountSubProgramID | int | YES | Sub-program identifier. Primary key. Referenced by FiatAccount.SubProgramId, EligibilityRules.SubProgramId, ProgramTransitionRules source/destination, and ProgramTransitionsEligibility. DWH note: Synapse currently contains 10 of 16 source values; IDs 11-16 (AUS and DK sub-programs) are in FiatDwhDB source but not yet reflected. (Tier 1 — dbo.SubPrograms) |
| 2 | AccountSubProgram | varchar(50) | YES | Human-readable sub-program name. Format: "{Type} {Tier} {Region}" (e.g., "Card Premium UK", "IBAN EU Green"). Used in reporting and customer-facing displays. (Tier 1 — dbo.SubPrograms) |
| 3 | AccountProgramID | int | YES | Parent account program: 1=card, 2=iban. See Account Program. (Dictionary.AccountPrograms). Determines the fundamental product type. (Tier 1 — dbo.SubPrograms) |
| 4 | CUGAccountSubProgram | varchar(50) | YES | Provider-side Closed User Group program identifier. Format: "{Type}_{Tier}_{Region}" (e.g., "Card_Premium_UK"). Used in Tribe API calls and provider configuration. (Tier 1 — dbo.SubPrograms) |
| 5 | UpdateDate | datetime | YES | Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| AccountSubProgramID | FiatDwhDB.dbo.SubPrograms | Id | Rename; tinyint→int widen |
| AccountSubProgram | FiatDwhDB.dbo.SubPrograms | Name | Rename; nvarchar(128)→varchar(50) narrow |
| AccountProgramID | FiatDwhDB.dbo.SubPrograms | AccountProgramId | Rename; tinyint→int widen |
| CUGAccountSubProgram | FiatDwhDB.dbo.SubPrograms | CugProgramName | Rename; nvarchar(128)→varchar(50) narrow |
| UpdateDate | ETL metadata | — | Populated by Generic Pipeline |

Note: `Region` column from `dbo.SubPrograms` is NOT present in the DWH table — omitted during Bronze export mapping.

### 5.2 ETL Pipeline

```
FiatDwhDB.dbo.SubPrograms (source — 16 rows; product sub-program config)
  |-- Generic Pipeline (Bronze export) ---|
  v
Bronze parquet (ADLS Gen2 Data Lake)
  |-- External Table: External_FiatDwhDB_dbo_SubPrograms ---|
  v
eMoney_dbo.eMoney_Dictionary_AccountSubProgram (10 rows live, REPLICATE, HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountsubprogram
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| AccountProgramID | eMoney_Dictionary_AccountProgram | Links sub-program to parent program type (card/iban) |

### 6.2 Referenced By

| Object | Column | Description |
|--------|--------|-------------|
| eMoney_Dim_Account | AccountSubProgramID | Account dimension carries sub-program |
| eMoney_Account_Mappings | (via FiatCurrencyBalances/FiatAccount) | Mapping tables reference sub-program |

---

## 7. Sample Queries

### 7.1 View all sub-programs with parent program
```sql
SELECT sp.AccountSubProgramID, sp.AccountSubProgram,
       p.AccountProgram, sp.CUGAccountSubProgram
FROM [eMoney_dbo].[eMoney_Dictionary_AccountSubProgram] sp
JOIN [eMoney_dbo].[eMoney_Dictionary_AccountProgram] p
    ON sp.AccountProgramID = p.AccountProgramID
ORDER BY sp.AccountProgramID, sp.AccountSubProgramID;
```

### 7.2 Account distribution by sub-program
```sql
SELECT sp.AccountSubProgram, p.AccountProgram, COUNT(*) AS AccountCount
FROM [eMoney_dbo].[eMoney_Dim_Account] a
LEFT JOIN [eMoney_dbo].[eMoney_Dictionary_AccountSubProgram] sp
    ON a.AccountSubProgramID = sp.AccountSubProgramID
LEFT JOIN [eMoney_dbo].[eMoney_Dictionary_AccountProgram] p
    ON a.AccountProgramID = p.AccountProgramID
GROUP BY sp.AccountSubProgram, p.AccountProgram
ORDER BY AccountCount DESC;
```

### 7.3 Identify accounts with missing sub-program mapping (AUS/DK gap)
```sql
SELECT DISTINCT a.AccountSubProgramID, COUNT(*) AS AffectedAccounts
FROM [eMoney_dbo].[eMoney_Dim_Account] a
LEFT JOIN [eMoney_dbo].[eMoney_Dictionary_AccountSubProgram] sp
    ON a.AccountSubProgramID = sp.AccountSubProgramID
WHERE sp.AccountSubProgramID IS NULL
  AND a.AccountSubProgramID IS NOT NULL
GROUP BY a.AccountSubProgramID
ORDER BY AffectedAccounts DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Sub-program business rules and transition logic are documented in the FiatDwhDB upstream wiki (dbo.SubPrograms, 9.4/10 quality).

---

T1 COPY VERIFICATION:
  AccountSubProgramID: upstream "Sub-program identifier. Primary key. Values 1-16 currently defined. Referenced by FiatAccount.SubProgramId, EligibilityRules.SubProgramId, ProgramTransitionRules source/destination, and ProgramTransitionsEligibility." → wiki same text; stripped snapshot stat "Values 1-16 currently defined"; added DWH note about the 10/16 lag — PASS
  AccountSubProgram: upstream "Human-readable sub-program name. Format: \"{Type} {Tier} {Region}\" (e.g., \"Card Premium UK\", \"IBAN EU Green\"). Used in reporting and customer-facing displays." → wiki identical — PASS
  AccountProgramID: upstream "Parent account program: 1=card, 2=iban. See Account Program. (Dictionary.AccountPrograms). Determines the fundamental product type." → wiki identical — PASS
  CUGAccountSubProgram: upstream "Provider-side Closed User Group program identifier. Format: \"{Type}_{Tier}_{Region}\" (e.g., \"Card_Premium_UK\"). Used in Tribe API calls and provider configuration." → wiki identical — PASS

*Generated: 2026-04-20 | Quality: 9.1/10 | Phases: 7/14 (SIMPLE-DICT fast-path)*
*Tiers: 4 T1, 1 T2, 0 T3, 0 T4, 0 T5 | Elements: 5/5, Logic: 9/10, Sources: 8/10*
*Object: eMoney_dbo.eMoney_Dictionary_AccountSubProgram | Type: Table (Dictionary) | Production Source: FiatDwhDB.dbo.SubPrograms*
