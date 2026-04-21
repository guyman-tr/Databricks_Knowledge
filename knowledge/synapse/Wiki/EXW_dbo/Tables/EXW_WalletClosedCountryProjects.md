# EXW_dbo.EXW_WalletClosedCountryProjects

> 89-row manually maintained reference table listing countries where the eToro Wallet service was shut down, organized by closure campaign (Project). Each row maps a country to a compensation date and optional regulation scope, and is used across multiple Wallet ETL procedures to identify affected users.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | Manual — maintained by Wallet operations team; no automated ETL writer |
| **Refresh** | Ad-hoc — rows are inserted when a new country-closure compensation project is initiated |
| **Row Count** | 89 rows (77 distinct countries) |
| **Date Range** | CompensationDate: 2021-03-02 to 2024-12-16; UpdateDate: 2021-03-08 to 2024-12-22 |
| **Synapse Distribution** | HASH(CountryID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — manual reference table, not exported to data lake |

---

## 1. Business Meaning

This table is a manually maintained registry of countries where eToro's Wallet service was closed and users received compensation. Each row represents a single country-project combination — that is, a country that was included in a specific closure campaign (Project), optionally scoped to a particular regulatory jurisdiction (RegulationID). The 89 rows span 77 distinct countries and 8 named Projects, covering closure waves from 2021 through 2024.

The table serves as a JOIN reference in key Wallet ETL procedures:
- **SP_DimUser** LEFT JOINs on CountryID + RegulationID to determine whether a user's country of residence has been closed under a Wallet compensation project
- **SP_EXW_CompensationClosingCountries** JOINs to scope compensation reports
- **SP_EXW_UserSettingsWalletAllowance** LEFT JOINs to evaluate ongoing wallet eligibility restrictions

There is no automated ETL pipeline populating this table — it is directly inserted by the Wallet operations or analytics team when a new country closure project is executed. The data has not been normalised (CountryName is denormalised; Regulation is sometimes NULL and sometimes a text label for the same information as RegulationID).

---

## 2. Business Logic

### 2.1 Project-Based Closure Campaigns

**What**: Each distinct value of the `Project` column represents a named country-closure initiative. Countries in the same Project were compensated simultaneously.

**Columns Involved**: Project, CountryID, CompensationDate

**Rules**:
- `A` — 31 countries; first major wave (CompensationDate 2021-03-02)
- `B` — 35 countries; second wave (CompensationDate 2021-03-02)
- `French` — 7 French-jurisdiction countries
- `RussiaCySEC` — 7 Russia / CySEC-regulated users
- `Angola,Eritrea,Rwanda,Senegal` — 4 specific African countries grouped together
- `RussiaAll` — 2 entries for Russia across all regulations
- `RussiaASIC` — 2 entries for Russia under ASIC regulation
- `Philippines` — 1 entry for the Philippines

### 2.2 Regulation Scoping

**What**: The `RegulationID` and `Regulation` columns scope a row to a specific regulatory entity. A NULL value means the closure applies to all users in that country regardless of their regulation.

**Columns Involved**: RegulationID, Regulation

**Rules**:
- 78/89 rows have RegulationID = NULL → global closure for that country
- 11 rows have specific RegulationID values: 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC & GAML, 11=FSRA
- SP_DimUser join logic: `ON CountryID = cp.CountryID AND (RegulationID = cp.RegulationID OR cp.RegulationID IS NULL)` — this means regulation-specific rows take precedence, and NULL rows catch all remaining users in the country

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CountryID) with HEAP. The table is small (89 rows), so distribution has minimal performance impact. All queries against this table are extremely fast. HEAP is appropriate for a rarely-updated reference table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Which countries were closed in Project "B"? | `SELECT CountryID, CountryName, CompensationDate FROM EXW_dbo.EXW_WalletClosedCountryProjects WHERE Project = 'B'` |
| Is a specific country in any closure project? | `SELECT * FROM EXW_dbo.EXW_WalletClosedCountryProjects WHERE CountryID = @id` |
| Which closures are regulation-specific? | `WHERE RegulationID IS NOT NULL` |
| All countries with wallet closed regardless of reg? | `WHERE RegulationID IS NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Country | `CountryID = Dim_Country.CountryID` | Resolve to country name, ISO code |
| DWH_dbo.Dim_Regulation | `RegulationID = Dim_Regulation.ID` | Resolve to regulation name |
| EXW_dbo.EXW_DimUser | Via SP_DimUser join: `EXW_DimUser.CountryID = cp.CountryID AND (EXW_DimUser.RegulationID = cp.RegulationID OR cp.RegulationID IS NULL)` | Determine if user is in a closed country |

### 3.4 Gotchas

- **No SP writer**: This table is manually maintained. There is no SP to re-run if data is incorrect. Changes require direct INSERT/UPDATE.
- **Duplicate CountryID possible**: A country can appear multiple times with different RegulationID values (NULL = all regs, plus specific regulation rows). The SP join uses `OR cp.RegulationID IS NULL` to handle overlapping rows.
- **Regulation column vs RegulationID**: Both exist; `Regulation` (text) is mostly NULL (78/89 rows) even when `RegulationID` has a value. Do not rely on the `Regulation` text column for lookups — use `RegulationID`.
- **CountryName is denormalised**: Whitespace padding (nchar 50) — use RTRIM() when comparing.
- **Project is free text**: Not a FK. Values like `Angola,Eritrea,Rwanda,Senegal` are comma-separated country names packed into one Project identifier.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production DB wiki |
| Tier 2 | Derived from SP code (source-to-target mapping confirmed in code) |
| Tier 3 | Inferred from column name, type, and surrounding context |
| Tier 4 | Best available — manually maintained table with no automated lineage |
| Tier 5 | Glossary or domain knowledge only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Project | nchar(50) | YES | Closure campaign identifier grouping countries by compensation wave. Free-text label; not a FK. Known values: A (31 countries, 2021), B (35 countries, 2021), French (7), RussiaCySEC (7), Angola,Eritrea,Rwanda,Senegal (4), RussiaAll (2), RussiaASIC (2), Philippines (1). (Tier 4 — manually maintained) |
| 2 | CountryID | int | YES | FK to DWH_dbo.Dim_Country. Identifies the country whose Wallet service was closed under this Project. HASH distribution key. (Tier 4 — manually maintained) |
| 3 | CountryName | nchar(50) | YES | Denormalised country name for readability. nchar(50) with whitespace padding — use RTRIM() for comparisons. Not guaranteed to match Dim_Country.CountryName exactly. (Tier 4 — manually maintained) |
| 4 | UpdateDate | datetime | NO | Timestamp of the last modification to this row. Not auto-maintained — manually set at insert time. Range: 2021-03-08 to 2024-12-22. (Tier 4 — manually maintained) |
| 5 | CompensationDate | date | YES | Date on which users in this country received compensation for the Wallet service closure. Range: 2021-03-02 to 2024-12-16. (Tier 4 — manually maintained) |
| 6 | Regulation | varchar(100) | YES | Regulation name text label (e.g., CySEC). Mostly NULL (78/89 rows). When non-NULL, corresponds to the RegulationID value. Unreliable — prefer RegulationID for programmatic use. (Tier 4 — manually maintained) |
| 7 | RegulationID | int | YES | FK to DWH_dbo.Dim_Regulation.ID. NULL = closure applies to all users in this country regardless of their regulatory entity. Non-NULL scopes the row to a specific regulation: 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC & GAML, 11=FSRA. (Tier 4 — manually maintained) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| All columns | None — manually maintained | — | Direct manual insert by Wallet operations team |

### 5.2 ETL Pipeline

```
[Wallet Operations Team — manual data entry]
  |-- Direct INSERT into Synapse --|
  v
EXW_dbo.EXW_WalletClosedCountryProjects (89 rows, manual)
  |-- Read by SP_DimUser (LEFT JOIN) --|
  |-- Read by SP_EXW_CompensationClosingCountries (JOIN) --|
  |-- Read by SP_EXW_UserSettingsWalletAllowance (LEFT JOIN) --|
  v
[Downstream: EXW_DimUser, EXW_CompensationClosingCountries, EXW_UserSettingsWalletAllowance]

Note: No UC export (UC Target: _Not_Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CountryID | DWH_dbo.Dim_Country | FK to country dimension; resolves to country name, ISO code |
| RegulationID | DWH_dbo.Dim_Regulation | FK to regulation dimension (ID column); NULL = all regulations |

### 6.2 Referenced By (other objects point to this)

| Object | Usage |
|--------|-------|
| EXW_dbo.EXW_DimUser | LEFT JOIN on CountryID + RegulationID to mark closed-wallet countries |
| EXW_dbo.EXW_CompensationClosingCountries | JOIN to scope compensation reporting |
| EXW_dbo.EXW_UserSettingsWalletAllowance | LEFT JOIN for wallet eligibility restriction checks |

---

## 7. Sample Queries

### Countries in Project B

```sql
SELECT CountryID, RTRIM(CountryName) AS CountryName, CompensationDate
FROM [EXW_dbo].[EXW_WalletClosedCountryProjects]
WHERE RTRIM(Project) = 'B'
ORDER BY CountryName;
```

### Check whether a specific country has been closed (any project)

```sql
SELECT RTRIM(Project) AS Project, RTRIM(CountryName) AS CountryName,
       CompensationDate, RegulationID
FROM [EXW_dbo].[EXW_WalletClosedCountryProjects]
WHERE CountryID = 75  -- France
ORDER BY CompensationDate;
```

### All regulation-specific closures (not global)

```sql
SELECT RTRIM(Project) AS Project, RTRIM(CountryName) AS CountryName,
       RegulationID, RTRIM(Regulation) AS Regulation, CompensationDate
FROM [EXW_dbo].[EXW_WalletClosedCountryProjects]
WHERE RegulationID IS NOT NULL
ORDER BY RegulationID, CountryName;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. It is a manually maintained operational reference table with no formal documentation in Atlassian.

---

*Generated: 2026-04-20 | Quality: 7.5/10 | Phases: 10/14*
*Tiers: 0 T1, 0 T2, 0 T3, 7 T4, 0 T5 | Elements: 7/7, Logic: 7/10, Source: Manual*
*Object: EXW_dbo.EXW_WalletClosedCountryProjects | Type: Table | Production Source: Manual*
