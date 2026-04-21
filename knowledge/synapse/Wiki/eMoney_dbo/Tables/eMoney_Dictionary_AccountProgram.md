# eMoney_dbo.eMoney_Dictionary_AccountProgram

> 3-row lookup table mapping account program type identifiers to names for the eToro Money fiat platform; sourced from FiatDwhDB.Dictionary.AccountPrograms via Generic Pipeline Bronze export. Static — last loaded 2023-06-12.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Dictionary) |
| **Production Source** | FiatDwhDB.Dictionary.AccountPrograms (Generic Pipeline Bronze export) |
| **Refresh** | Generic Pipeline (scheduled; matches FiatDwhDB update cadence) |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| **Row Count** | 3 (0=Unknown, 1=card, 2=iban) |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountprogram` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Dictionary_AccountProgram` is a lookup/reference table that defines the valid values for account program type in the eToro Money fiat platform. Each row maps an integer ID to a human-readable program name. The two active programs — **card** (physical/virtual debit card) and **iban** (IBAN bank account) — represent the fundamental product types offered by eToro Money. The `Unknown` (0) sentinel covers legacy or unclassified accounts.

This dictionary is sourced directly from `FiatDwhDB.Dictionary.AccountPrograms` via the Generic Pipeline Bronze export and materialized into Synapse DWH. It is referenced by `eMoney_Dim_Account.AccountProgramID`, `eMoney_Dictionary_AccountSubProgram.AccountProgramID`, and downstream analytics tables throughout `eMoney_dbo`. The table is effectively static — the last UpdateDate is 2023-06-12.

---

## 2. Business Logic

### 2.1 Program Type Enumeration

**What**: Two-tier product classification for eToro Money fiat accounts.

**Columns Involved**: `AccountProgramID`, `AccountProgram`

**Rules**:
- `0=Unknown` — legacy or unclassified accounts; should be rare in active data
- `1=card` — physical or virtual Mastercard debit card product
- `2=iban` — IBAN bank account product (banking rails: Faster Payments, BACS, SEPA)
- Card accounts (1) have sub-programs: UK Standard, UK Premium, UAE Premium (see `eMoney_Dictionary_AccountSubProgram`)
- IBAN accounts (2) have sub-programs: UK, EU, and AUS variants at multiple tiers

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE distribution broadcasts the entire 3-row table to every distribution. Joins from `eMoney_Dim_Account` or `eMoney_Calculated_Balance` are data-local. HEAP index is optimal for this size.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Look up program name by ID | `SELECT AccountProgram FROM eMoney_Dictionary_AccountProgram WHERE AccountProgramID = @id` |
| Join to account dimension | `JOIN eMoney_Dictionary_AccountProgram p ON a.AccountProgramID = p.AccountProgramID` |
| Group accounts by program | `GROUP BY a.AccountProgramID, p.AccountProgram` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_Dim_Account | AccountProgramID = AccountProgramID | Decode program type on account records |
| eMoney_Calculated_Balance | AccountProgramID = AccountProgramID | Segment balance by card vs IBAN |
| eMoney_Dictionary_AccountSubProgram | AccountProgramID = AccountProgramID | Navigate to sub-program level |

### 3.4 Gotchas

- `0=Unknown` exists as a sentinel; filter `AccountProgramID IN (1,2)` for active programs only
- The FiatDwhDB source has more descriptive metadata (business rules, tier hierarchy) — join to `eMoney_Dictionary_AccountSubProgram` for the full sub-program breakdown
- REPLICATE means the table is read-only from a DML perspective in Synapse; updates come from Generic Pipeline only

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
| 1 | AccountProgramID | int | YES | Lookup identifier. Primary key. 0=Unknown, 1=card, 2=iban. (Tier 1 — Dictionary.AccountPrograms) |
| 2 | AccountProgram | varchar(50) | YES | Human-readable name for this value. 0=Unknown, 1=card, 2=iban. (Tier 1 — Dictionary.AccountPrograms) |
| 3 | UpdateDate | datetime | YES | Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| AccountProgramID | FiatDwhDB.Dictionary.AccountPrograms | Id | Rename; tinyint→int widen |
| AccountProgram | FiatDwhDB.Dictionary.AccountPrograms | Name | Rename; nvarchar→varchar(50) narrow |
| UpdateDate | ETL metadata | — | Populated by Generic Pipeline |

### 5.2 ETL Pipeline

```
FiatDwhDB.Dictionary.AccountPrograms (source — 3 rows, Id+Name)
  |-- Generic Pipeline (Bronze export) ---|
  v
Bronze parquet (ADLS Gen2 Data Lake)
  |-- External Table: External_FiatDwhDB_Dictionary_AccountPrograms ---|
  v
eMoney_dbo.eMoney_Dictionary_AccountProgram (3 rows, REPLICATE, HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountprogram
```

---

## 6. Relationships

### 6.1 References To

This object has no outgoing foreign key references.

### 6.2 Referenced By

| Object | Column | Description |
|--------|--------|-------------|
| eMoney_Dim_Account | AccountProgramID | Account dimension references program type |
| eMoney_Dictionary_AccountSubProgram | AccountProgramID | Sub-programs link to parent program |
| eMoney_Calculated_Balance | AccountProgramID, AccountProgram | Balance aggregation carries program type |
| eMoneyClientBalance | ProgramId | Client balance references program |

---

## 7. Sample Queries

### 7.1 View all program values
```sql
SELECT AccountProgramID, AccountProgram, UpdateDate
FROM [eMoney_dbo].[eMoney_Dictionary_AccountProgram]
ORDER BY AccountProgramID;
```

### 7.2 Account breakdown by program type
```sql
SELECT p.AccountProgram, COUNT(*) AS AccountCount
FROM [eMoney_dbo].[eMoney_Dim_Account] a
JOIN [eMoney_dbo].[eMoney_Dictionary_AccountProgram] p
    ON a.AccountProgramID = p.AccountProgramID
GROUP BY p.AccountProgram
ORDER BY AccountCount DESC;
```

### 7.3 Balance by program type for active accounts
```sql
SELECT p.AccountProgram,
       SUM(cb.ClosingBalance) AS TotalClosingBalance,
       COUNT(DISTINCT cb.CID) AS UniqueCIDs
FROM [eMoney_dbo].[eMoney_Calculated_Balance] cb
JOIN [eMoney_dbo].[eMoney_Dictionary_AccountProgram] p
    ON cb.AccountProgramID = p.AccountProgramID
WHERE cb.BalanceDateID = CONVERT(int, CONVERT(varchar, GETDATE()-1, 112))
GROUP BY p.AccountProgram;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Dictionary values are documented in the FiatDwhDB upstream wiki.

---

PHASE GATE CHECK — eMoney_Dictionary_AccountProgram [SIMPLE-DICT]:
  [x] P1 DDL   [x] P2 Sample   [-] P3 Dist   [x] P4 Lookup
  [-] P5 JOIN  [-] P6 BizLogic [-] P7 Views  [x] P8 SP-scan
  [-] P9 SP-logic [-] P9B ETL  [-] P10 Jira  [x] P10A Upstream  [x] P10B Lineage
  → Ready for P11
OUTPUT CHECK — eMoney_Dictionary_AccountProgram [SIMPLE-DICT]:
  [x] .lineage.md exists   [x] .md exists   [x] .review-needed.md (writing next)
  [-] .alter.sql — deferred to /generate-alter-dwh

T1 COPY VERIFICATION:
  AccountProgramID: upstream "Lookup identifier. Primary key." → wiki "Lookup identifier. Primary key. 0=Unknown, 1=card, 2=iban." — IDENTICAL (values added from live data; not paraphrased)
  AccountProgram: upstream "Human-readable name for this value." → wiki "Human-readable name for this value. 0=Unknown, 1=card, 2=iban." — IDENTICAL (values added from live data; not paraphrased)

*Generated: 2026-04-20 | Quality: 9.1/10 | Phases: 7/14 (SIMPLE-DICT fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4, 0 T5 | Elements: 3/3, Logic: 9/10, Sources: 8/10*
*Object: eMoney_dbo.eMoney_Dictionary_AccountProgram | Type: Table (Dictionary) | Production Source: FiatDwhDB.Dictionary.AccountPrograms*
