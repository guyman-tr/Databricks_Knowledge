# eMoney_dbo.eMoney_Dictionary_AccountProgram

> 3-row replicated lookup table defining Account Program types (card/iban) for the eMoney/fiat platform. Sourced from FiatDwhDB.Dictionary.AccountPrograms via Generic Pipeline (Override, daily). Last refreshed 2023-06-12.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table |
| **Production Source** | FiatDwhDB.Dictionary.AccountPrograms via Generic Pipeline |
| **Refresh** | Daily (Override, 1440 min) — static since 2023-06-12 |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountprogram` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (eMoney schema) |

---

## 1. Business Meaning

eMoney_Dictionary_AccountProgram is a static lookup table with 3 rows that defines the valid Account Program types for the fiat/eMoney platform. Each row maps an integer identifier to a human-readable program name. The values are: 0=Unknown, 1=card, 2=iban.

The table is sourced from FiatDwhDB.Dictionary.AccountPrograms on the prod-banking-fiat server via the Generic Pipeline (Bronze export, Override strategy, daily frequency). Data flows through the Data Lake (Parquet), an external table, and the CopyFromLake staging layer before landing in eMoney_dbo.

This dictionary is referenced by eMoney_dbo.eMoney_Dim_Account (via SP_eMoney_Dim_Account) and eMoney_dbo account mapping objects (via SP_eMoney_Account_Mappings) to resolve Account Program IDs to human-readable names.

---

## 2. Business Logic

### 2.1 Static Lookup Values

**What**: Fixed mapping of Account Program IDs to names.
**Columns Involved**: AccountProgramID, AccountProgram
**Rules**:
- 0 = Unknown (default/fallback)
- 1 = card (card-based account program)
- 2 = iban (IBAN-based account program)

### 2.2 No Complex Logic

**What**: Pure reference table with no computed columns, no CASE logic, no aggregations.
**Rules**:
- All values are static and sourced directly from production
- No transforms applied during ETL beyond column rename and type cast

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE distribution — the full 3-row table is copied to every compute node. No distribution key concerns. HEAP storage (no clustered index) is appropriate for this tiny table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What are all valid Account Programs? | `SELECT * FROM eMoney_dbo.eMoney_Dictionary_AccountProgram` |
| Resolve an AccountProgramID to name | JOIN to this table on AccountProgramID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_Dim_Account | `ON a.AccountProgramID = d.AccountProgramID` | Resolve account program type for eMoney accounts |

### 3.4 Gotchas

- **0 = Unknown**: Not null-safe — some upstream tables may use NULL instead of 0 for unknown program types. Use `ISNULL(AccountProgramID, 0)` when joining.
- **Static data**: All rows share the same UpdateDate (2023-06-12). The table has not changed since initial load despite daily refresh schedule.
- **Column renames from source**: Production uses `Id`/`Name`; Synapse uses `AccountProgramID`/`AccountProgram`.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (FiatDwhDB.Dictionary.AccountPrograms) |
| Tier 2 | Derived from ETL pipeline / SP code analysis |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AccountProgramID | int | YES | Lookup identifier. Primary key. 0=Unknown, 1=card, 2=iban. (Tier 1 — Dictionary.AccountPrograms) |
| 2 | AccountProgram | varchar(50) | YES | Human-readable name for this value. 0=Unknown, 1=card, 2=iban. (Tier 1 — Dictionary.AccountPrograms) |
| 3 | UpdateDate | datetime | YES | Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|--------------|-----------|
| AccountProgramID | FiatDwhDB.Dictionary.AccountPrograms | Id | Rename (Id → AccountProgramID), type widened tinyint → int |
| AccountProgram | FiatDwhDB.Dictionary.AccountPrograms | Name | Rename (Name → AccountProgram), type narrowed nvarchar → varchar(50) |
| UpdateDate | CopyFromLake staging | SynapseUpdateDate | ETL-managed timestamp (SynapseUpdateDate → UpdateDate) |

### 5.2 ETL Pipeline

```
FiatDwhDB.Dictionary.AccountPrograms (prod-banking-fiat)
  |-- Generic Pipeline (Bronze export, Override, daily) ---|
  v
Bronze/FiatDwhDB/Dictionary/AccountPrograms (Parquet, Data Lake)
  |-- External Table bridge ---|
  v
eMoney_dbo.External_FiatDwhDB_Dictionary_AccountPrograms
  |-- CopyFromLake load ---|
  v
CopyFromLake.FiatDwhDB_Dictionary_AccountPrograms
  |-- Migration / load ---|
  v
eMoney_dbo.eMoney_Dictionary_AccountProgram (3 rows, REPLICATE)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountprogram
```

---

## 6. Relationships

### 6.1 References To (this object points to)

This object has no outgoing references (leaf lookup table).

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Relationship |
|-------------------|-------------|
| SP_eMoney_Dim_Account | Reads AccountProgramID/AccountProgram for account dimension enrichment |
| SP_eMoney_Account_Mappings | Reads AccountProgramID/AccountProgram for account mapping resolution |

---

## 7. Sample Queries

### 7.1 View all Account Program values
```sql
SELECT AccountProgramID, AccountProgram, UpdateDate
FROM eMoney_dbo.eMoney_Dictionary_AccountProgram;
```

### 7.2 Resolve Account Program for eMoney accounts
```sql
SELECT a.*, d.AccountProgram
FROM eMoney_dbo.eMoney_Dim_Account a
JOIN eMoney_dbo.eMoney_Dictionary_AccountProgram d
  ON a.AccountProgramID = d.AccountProgramID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-27 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 10/10)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4, 0 T5 | Elements: 3/3, Logic: 8/10, Lineage: 10/10, Queries: 8/10*
*Object: eMoney_dbo.eMoney_Dictionary_AccountProgram | Type: Table | Production Source: FiatDwhDB.Dictionary.AccountPrograms*
