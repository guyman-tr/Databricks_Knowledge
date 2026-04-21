# eMoney_dbo.eMoney_Dictionary_Provider

> 1-row lookup table mapping external payment provider identifiers to names for the eToro Money fiat platform; currently contains only Tribe (ID=1). Sourced from FiatDwhDB.Dictionary.Providers via Generic Pipeline Bronze export.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Dictionary) |
| **Production Source** | FiatDwhDB.Dictionary.Providers (Generic Pipeline Bronze export) |
| **Refresh** | Generic Pipeline (scheduled; matches FiatDwhDB update cadence) |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| **Row Count** | 1 (1=Tribe) |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_provider` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Dictionary_Provider` is a lookup/reference table that defines the valid values for external payment provider in the eToro Money fiat platform. Currently it contains a single row: `1=Tribe`, identifying Tribe Payments Ltd as the sole payment provider that powers eToro Money's card and IBAN infrastructure.

Tribe is the white-label fintech provider behind eToro Money — they supply the Mastercard card issuing, IBAN banking rails, and Closed User Group (CUG) program management. All eToro Money fiat accounts, currency balances, transactions, and card operations flow through Tribe's platform, making this effectively a constant lookup in current production. Future providers would be added as new rows.

This dictionary is sourced from `FiatDwhDB.Dictionary.Providers` via Generic Pipeline Bronze export. It is referenced by `FiatDwhDB` provider mapping tables but currently its `ProviderID` is not widely used as a join key in the Synapse eMoney layer (most provider attribution is implicit). Last loaded 2023-06-12.

---

## 2. Business Logic

### 2.1 Provider Enumeration

**What**: Single-provider registry for eToro Money fiat platform.

**Columns Involved**: `ProviderID`, `Provider`

**Rules**:
- `1=Tribe` — Tribe Payments Ltd, the sole external provider for eToro Money infrastructure
- `ProviderID=0` does not exist in this table (no Unknown sentinel, unlike other eMoney dictionaries)
- If eToro Money onboards a second provider, a new row would be added here

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE — 1-row table broadcast to all distributions. Joins are essentially free.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Confirm provider for a mapping | `SELECT Provider FROM eMoney_Dictionary_Provider WHERE ProviderID = 1` |
| Join to provider-keyed tables | `JOIN eMoney_Dictionary_Provider p ON m.ProviderID = p.ProviderID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| FiatDwhDB provider mapping tables | ProviderID = ProviderID | Provider attribution (mainly in FiatDwhDB layer) |

### 3.4 Gotchas

- Currently only 1 row — any analytics grouping by provider will produce a single group
- `ProviderID` is not a common join key in current eMoney_dbo analytical tables; most Synapse consumers join on account/transaction-level keys
- No `0=Unknown` sentinel in this table — contrast with `AccountProgram` and `AccountStatus`

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
| 1 | ProviderID | int | YES | Lookup identifier. Primary key. 1=Tribe. (Tier 1 — Dictionary.Providers) |
| 2 | Provider | varchar(50) | YES | Human-readable name for this value. 1=Tribe. (Tier 1 — Dictionary.Providers) |
| 3 | UpdateDate | datetime | YES | Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| ProviderID | FiatDwhDB.Dictionary.Providers | Id | Rename; tinyint→int widen |
| Provider | FiatDwhDB.Dictionary.Providers | Name | Rename; nvarchar→varchar(50) narrow |
| UpdateDate | ETL metadata | — | Populated by Generic Pipeline |

### 5.2 ETL Pipeline

```
FiatDwhDB.Dictionary.Providers (source — 1 row: 1=Tribe)
  |-- Generic Pipeline (Bronze export) ---|
  v
Bronze parquet (ADLS Gen2 Data Lake)
  |-- External Table: External_FiatDwhDB_Dictionary_Providers ---|
  v
eMoney_dbo.eMoney_Dictionary_Provider (1 row, REPLICATE, HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_provider
```

---

## 6. Relationships

### 6.1 References To

This object has no outgoing foreign key references.

### 6.2 Referenced By

| Object | Column | Description |
|--------|--------|-------------|
| FiatDwhDB provider mapping tables | ProviderID | Provider attribution for accounts, cards, transactions |
| eMoney_dbo analytics (indirect) | — | Referenced through FiatDwhDB layer; no direct FK in current Synapse eMoney analytical tables |

---

## 7. Sample Queries

### 7.1 View all provider values
```sql
SELECT ProviderID, Provider, UpdateDate
FROM [eMoney_dbo].[eMoney_Dictionary_Provider]
ORDER BY ProviderID;
```

### 7.2 Confirm Tribe is the active provider
```sql
SELECT Provider
FROM [eMoney_dbo].[eMoney_Dictionary_Provider]
WHERE ProviderID = 1;
-- Returns: 'Tribe'
```

### 7.3 Future provider expansion check
```sql
-- Useful to run periodically to detect if a second provider has been added
SELECT COUNT(*) AS ProviderCount, MAX(UpdateDate) AS LastLoaded
FROM [eMoney_dbo].[eMoney_Dictionary_Provider];
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Provider information is documented in the FiatDwhDB upstream wiki.

---

T1 COPY VERIFICATION:
  ProviderID: upstream "Lookup identifier. Primary key." → wiki "Lookup identifier. Primary key. 1=Tribe." — IDENTICAL (value added from live data)
  Provider: upstream "Human-readable name for this value." → wiki "Human-readable name for this value. 1=Tribe." — IDENTICAL (value added from live data)

*Generated: 2026-04-20 | Quality: 9.1/10 | Phases: 7/14 (SIMPLE-DICT fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4, 0 T5 | Elements: 3/3, Logic: 8/10, Sources: 8/10*
*Object: eMoney_dbo.eMoney_Dictionary_Provider | Type: Table (Dictionary) | Production Source: FiatDwhDB.Dictionary.Providers*
