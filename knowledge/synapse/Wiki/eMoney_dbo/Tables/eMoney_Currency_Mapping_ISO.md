# eMoney_dbo.eMoney_Currency_Mapping_ISO

> 168-row static reference table mapping ISO 4217 currency codes (alpha-3, numeric) to currency names; bridges FiatTransactions numeric currency codes to alpha-3 codes for DWH instrument and price lookups. Manually bulk-loaded 2024-06-24; no automated refresh.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Static Reference) |
| **Production Source** | ISO 4217 (manually maintained) |
| **Refresh** | Manual bulk load; no automated pipeline |
| **Synapse Distribution** | HASH(CurrencyNumericCode_ISO) |
| **Synapse Index** | HEAP |
| **Row Count** | 168 |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_currency_mapping_iso` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Currency_Mapping_ISO` is a manually maintained cross-reference table that maps the ISO 4217 currency standard (168 active currencies) to both alpha-3 and numeric codes. It serves as the bridge between the fiat platform's use of ISO numeric currency codes in transaction data and the analytical data warehouse's use of alpha-3 currency codes for instrument and price lookups.

In the fiat transaction pipeline (`FiatTransactions`), currency of transaction is stored as a 3-digit ISO numeric code. `SP_eMoney_DimFact_Transaction` uses this table (steps 05a, 05b, 06) to resolve those numeric codes to `CurrencyAlphaThreeCode`, which then joins to `DWH_dbo.Dim_Instrument.BuyCurrency` / `SellCurrency` for instrument resolution and to `Fact_CurrencyPriceWithSplit` for USD conversion rates.

HASH distribution on `CurrencyNumericCode_ISO` optimizes joins from `FiatTransactions` on the numeric currency code. All rows carry UpdateDate 2024-06-24 (single bulk load from ISO 4217 standard).

---

## 2. Business Logic

### 2.1 Transaction Currency Resolution

**What**: Resolves ISO numeric currency codes from FiatTransactions to alpha-3 codes for DWH joins.

**Columns Involved**: `CurrencyNumericCode_ISO`, `CurrencyAlphaThreeCode`

**Rules**:
- `FiatTransactions` stores currency as a 3-digit ISO 4217 numeric code (e.g., 826 = GBP, 978 = EUR, 840 = USD)
- `SP_eMoney_DimFact_Transaction` joins on `CurrencyNumericCode_ISO` to retrieve `CurrencyAlphaThreeCode`
- `CurrencyAlphaThreeCode` joins to `DWH_dbo.Dim_Instrument.BuyCurrency` / `SellCurrency` to resolve `InstrumentID`
- Used in steps 05a (billing currency), 05b (transaction currency), and 06 (settlement currency) of the SP

### 2.2 USD Price Conversion

**What**: Resolves currency alpha-3 code for USD FX rate lookup.

**Columns Involved**: `CurrencyAlphaThreeCode`

**Rules**:
- After resolving `CurrencyAlphaThreeCode`, `SP_eMoney_DimFact_Transaction` joins to `Fact_CurrencyPriceWithSplit` using the alpha-3 code to retrieve the USD conversion rate for the transaction date
- Currencies not present in `Fact_CurrencyPriceWithSplit` will result in null USD amounts in the fact table

### 2.3 Numeric Code as Distribution Key

**What**: HASH(CurrencyNumericCode_ISO) is the Synapse distribution strategy.

**Columns Involved**: `CurrencyNumericCode_ISO`

**Rules**:
- `CurrencyNumericCode_ISO` is stored as `varchar(20)` — not int; join from FiatTransactions must use the same string representation
- HASH distribution on numeric code co-locates rows with the joining transaction data for efficient lookup

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CurrencyNumericCode_ISO) distributes rows by ISO numeric currency code — optimized for joins from `FiatTransactions` on `TransactionCurrencyIso`. HEAP is optimal for 168 rows.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve ISO numeric to currency name | `SELECT CurrencyName FROM eMoney_Currency_Mapping_ISO WHERE CurrencyNumericCode_ISO = '826'` |
| Resolve ISO numeric to alpha-3 | `SELECT CurrencyAlphaThreeCode FROM eMoney_Currency_Mapping_ISO WHERE CurrencyNumericCode_ISO = @iso_numeric` |
| Look up currency by alpha-3 | `WHERE CurrencyAlphaThreeCode = 'GBP'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| FiatTransactions (eMoney_dbo mirror) | CurrencyNumericCode_ISO = TransactionCurrencyIso | Resolve transaction currency code to alpha-3 |
| DWH_dbo.Dim_Instrument | CurrencyAlphaThreeCode = BuyCurrency or SellCurrency | Resolve InstrumentID from currency pair |
| Fact_CurrencyPriceWithSplit | CurrencyAlphaThreeCode = CurrencyCode | Retrieve USD conversion rate |

### 3.4 Gotchas

- `CurrencyNumericCode_ISO` is `varchar(20)` — not int; ensure string join from FiatTransactions numeric currency field; leading zeros matter (e.g., '008' = ALL, not '8')
- No automated refresh: if ISO 4217 is updated (new currencies, retired codes), this table must be manually reloaded
- UpdateDate is uniform (2024-06-24) — do not use as a change indicator
- Currencies present in FiatTransactions but absent from this table will produce null `CurrencyAlphaThreeCode` and cascading nulls in instrument and price lookups — monitor for unmapped currencies when new currency types are added to the fiat platform

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
| 1 | CurrencyName | varchar(200) | YES | Full ISO 4217 currency name (e.g., "Pound Sterling", "Euro", "US Dollar"). (Tier 2 — Manual load context) |
| 2 | CurrencyAlphaThreeCode | varchar(20) | YES | ISO 4217 alpha-3 currency code (e.g., GBP, EUR, USD). Joins to DWH_dbo.Dim_Instrument.BuyCurrency/SellCurrency and Fact_CurrencyPriceWithSplit. (Tier 2 — SP_eMoney_DimFact_Transaction steps 05a/05b/06) |
| 3 | CurrencyNumericCode_ISO | varchar(20) | YES | ISO 4217 numeric code (3-digit string; e.g., '826', '978', '840'). Primary FK from FiatTransactions numeric currency fields. HASH distribution key. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 4 | UpdateDate | datetime | YES | Bulk-load timestamp. Static; all rows = 2024-06-24. (Tier 2 — Manual load metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CurrencyName | ISO 4217 | currency_name | Manual entry; full currency name |
| CurrencyAlphaThreeCode | ISO 4217 | alpha-3 | Manual entry; 3-letter ISO currency code |
| CurrencyNumericCode_ISO | ISO 4217 | numeric | Manual entry; 3-digit ISO numeric code; HASH distribution key |
| UpdateDate | Manual load | — | Bulk-load timestamp; all rows 2024-06-24 |

### 5.2 ETL Pipeline

```
ISO 4217 reference data (external standard)
  |-- Manual bulk load (2024-06-24) ---|
  v
eMoney_dbo.eMoney_Currency_Mapping_ISO (168 rows, HASH(CurrencyNumericCode_ISO), HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_currency_mapping_iso

Consumed by:
  SP_eMoney_DimFact_Transaction (steps 05a/05b/06):
    FiatTransactions numeric currency codes → CurrencyAlphaThreeCode
    → DWH_dbo.Dim_Instrument.BuyCurrency/SellCurrency (InstrumentID lookup)
    → Fact_CurrencyPriceWithSplit (USD conversion rate)
```

---

## 6. Relationships

### 6.1 References To

| Object | Column | Description |
|--------|--------|-------------|
| DWH_dbo.Dim_Instrument | BuyCurrency / SellCurrency | CurrencyAlphaThreeCode resolves instrument dimension |
| Fact_CurrencyPriceWithSplit | CurrencyCode | CurrencyAlphaThreeCode retrieves USD FX rate |

### 6.2 Referenced By

| Object | Column | Description |
|--------|--------|-------------|
| SP_eMoney_DimFact_Transaction | CurrencyNumericCode_ISO | Resolves FiatTransactions numeric currency codes to alpha-3 |

---

## 7. Sample Queries

### 7.1 View sample currency mappings
```sql
SELECT TOP 20 CurrencyName, CurrencyAlphaThreeCode, CurrencyNumericCode_ISO
FROM [eMoney_dbo].[eMoney_Currency_Mapping_ISO]
ORDER BY CurrencyAlphaThreeCode;
```

### 7.2 Resolve a transaction's currency code
```sql
SELECT t.TransactionID, c.CurrencyName, c.CurrencyAlphaThreeCode
FROM [eMoney_dbo].[eMoney_Fact_Transaction_Status] t
JOIN [eMoney_dbo].[eMoney_Currency_Mapping_ISO] c
    ON t.TransactionCurrencyIso = c.CurrencyNumericCode_ISO
WHERE t.TransactionCurrencyIso IS NOT NULL;
```

### 7.3 Find unmapped currency codes in transactions
```sql
SELECT DISTINCT t.TransactionCurrencyIso
FROM [eMoney_dbo].[eMoney_Fact_Transaction_Status] t
LEFT JOIN [eMoney_dbo].[eMoney_Currency_Mapping_ISO] c
    ON t.TransactionCurrencyIso = c.CurrencyNumericCode_ISO
WHERE t.TransactionCurrencyIso IS NOT NULL
  AND c.CurrencyNumericCode_ISO IS NULL;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. This is a manually maintained ISO 4217 reference table with no FiatDwhDB upstream wiki.

---

PHASE GATE CHECK — eMoney_Currency_Mapping_ISO [STATIC-REF]:
  [x] P1 DDL   [x] P2 Sample   [x] P3 Dist   [-] P4 Lookup
  [x] P5 JOIN  [x] P6 BizLogic [-] P7 Views  [x] P8 SP-scan
  [-] P9 SP-logic [-] P9B ETL  [-] P10 Jira  [-] P10A Upstream  [x] P10B Lineage
  → Ready for P11
OUTPUT CHECK — eMoney_Currency_Mapping_ISO [STATIC-REF]:
  [x] .lineage.md exists   [x] .md exists   [x] .review-needed.md (writing next)
  [-] .alter.sql — deferred to /generate-alter-dwh

*Generated: 2026-04-21 | Quality: 8.8/10 | Phases: 8/14 (STATIC-REF path)*
*Tiers: 0 T1, 4 T2, 0 T3, 0 T4, 0 T5 | Elements: 4/4, Logic: 9/10, Sources: 7/10*
*Object: eMoney_dbo.eMoney_Currency_Mapping_ISO | Type: Table (Static Reference) | Production Source: ISO 4217 (manual)*
