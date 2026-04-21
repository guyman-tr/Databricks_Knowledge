# eMoney_dbo.eMoney_Country_Codes_Mapping_ISO

> 248-row static reference table mapping ISO 3166-1 country codes (alpha-2, alpha-3, numeric) to eToro DWH country dimension IDs; bridges FiatTransactions.TransactionCountryIso (numeric code) to DWH_dbo.Dim_Country. Manually bulk-loaded 2024-06-24; no automated refresh.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Static Reference) |
| **Production Source** | ISO 3166-1 (manually maintained) |
| **Refresh** | Manual bulk load; no automated pipeline |
| **Synapse Distribution** | HASH(eToroDWHCountryID) |
| **Synapse Index** | HEAP |
| **Row Count** | 248 |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_country_codes_mapping_iso` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Country_Codes_Mapping_ISO` is a manually maintained cross-reference table that maps the full ISO 3166-1 country code standard (248 countries) to eToro DWH dimension IDs. It serves as the bridge between the fiat platform's use of ISO numeric country codes and the analytical data warehouse country dimension.

In the fiat transaction pipeline (`FiatTransactions`), country of transaction is stored as a 3-digit ISO numeric code (`TransactionCountryIso`). This table resolves that numeric code to a 2-letter alpha code (for display), a 3-letter alpha code (for instrument joins), and the DWH internal `eToroDWHCountryID` (for joining to `DWH_dbo.Dim_Country` and applying country-level risk scores).

This table is used by two key SPs: `SP_eMoney_DimFact_Transaction` (transaction country resolution for fact table population) and `SP_eMoney_Customer_Risk_Assessment` (High-Risk Country lookups for customer risk scoring).

There is no automated refresh — the table was bulk-loaded from the ISO 3166-1 standard on 2024-06-24. All rows carry this same UpdateDate. Updates require a manual reload if new country codes are added to ISO 3166-1.

---

## 2. Business Logic

### 2.1 Transaction Country Resolution

**What**: Resolves the ISO numeric country code in FiatTransactions to the DWH country dimension.

**Columns Involved**: `CountryNumericCode_ISO`, `eToroDWHCountryID`

**Rules**:
- `FiatTransactions.TransactionCountryIso` stores a 3-digit ISO 3166-1 numeric code (e.g., 826 = United Kingdom)
- Join `CountryNumericCode_ISO` to resolve → `eToroDWHCountryID` → `DWH_dbo.Dim_Country.CountryID`
- Used in `SP_eMoney_DimFact_Transaction` steps to populate the transaction fact table with the DWH country dimension key

### 2.2 High-Risk Country (HRC) Scoring

**What**: Supports country-level risk classification in the customer risk assessment pipeline.

**Columns Involved**: `CountryNumericCode_ISO`, `eToroDWHCountryID`

**Rules**:
- `SP_eMoney_Customer_Risk_Assessment` uses this table to resolve ISO numeric country codes to `eToroDWHCountryID` for HRC lookup
- Country risk scores are applied at the DWH country dimension level, not at the ISO numeric level
- Any country not present in this mapping table will fail to resolve and could result in a null or unscored risk record

### 2.3 Multi-Code Coverage

**What**: Provides all three ISO 3166-1 code formats for cross-system compatibility.

**Columns Involved**: `CountryAlphaTwoCode`, `CountryAlphaThreeCode`, `CountryNumericCode_ISO`

**Rules**:
- Alpha-2 (2-letter): used for display and UI rendering (e.g., GB, US, DE)
- Alpha-3 (3-letter): used for joins to `DWH_dbo.Dim_Instrument.BuyCurrency/SellCurrency` and instrument lookups
- Numeric (3-digit): primary FK from FiatTransactions; used as the HASH distribution key for join efficiency

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(eToroDWHCountryID) distributes rows by DWH country ID — optimized for joins to `DWH_dbo.Dim_Country` on `CountryID`. Transaction fact joins via `CountryNumericCode_ISO` will involve a broadcast or shuffle depending on joining table distribution. HEAP is optimal for 248 rows.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve ISO numeric to country name | `SELECT CountryName FROM eMoney_Country_Codes_Mapping_ISO WHERE CountryNumericCode_ISO = '826'` |
| Resolve ISO numeric to DWH country ID | `SELECT eToroDWHCountryID FROM eMoney_Country_Codes_Mapping_ISO WHERE CountryNumericCode_ISO = @iso_numeric` |
| Look up country by alpha-2 code | `WHERE CountryAlphaTwoCode = 'GB'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| FiatTransactions (eMoney_dbo mirror) | CountryNumericCode_ISO = TransactionCountryIso | Resolve transaction country code |
| DWH_dbo.Dim_Country | eToroDWHCountryID = CountryID | Enrich with DWH country dimension attributes |

### 3.4 Gotchas

- `CountryNumericCode_ISO` is stored as `varchar(20)` — not int; cast to string when joining from systems that store it as integer
- Some ISO 3166-1 numeric codes have leading zeros (e.g., 004 = Afghanistan) — ensure string padding is consistent
- Rows with null `eToroDWHCountryID` indicate countries not yet mapped to the DWH dimension; transactions with these codes will produce null in downstream fact tables
- No automated refresh: if ISO 3166-1 is updated (new country codes, retired codes), this table must be manually reloaded
- UpdateDate is uniform (2024-06-24) across all 248 rows — do not use as a change indicator

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
| 1 | CountryName | varchar(200) | YES | Full ISO 3166-1 country name (e.g., "United Kingdom of Great Britain and Northern Ireland"). (Tier 2 — SP and manual load context) |
| 2 | CountryAlphaTwoCode | varchar(20) | YES | ISO 3166-1 alpha-2 code (2-letter; e.g., GB, US, DE). Used for display and UI rendering. (Tier 2 — SP and manual load context) |
| 3 | CountryAlphaThreeCode | varchar(20) | YES | ISO 3166-1 alpha-3 code (3-letter; e.g., GBR, USA, DEU). Used for instrument joins to DWH_dbo.Dim_Instrument. (Tier 2 — SP and manual load context) |
| 4 | CountryNumericCode_ISO | varchar(20) | YES | ISO 3166-1 numeric code (3-digit string; e.g., '826', '840', '276'). Primary FK from FiatTransactions.TransactionCountryIso. HASH distribution key. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 5 | eToroDWHCountryID | int | YES | eToro DWH internal country dimension ID from DWH_dbo.Dim_Country. Manual mapping bridging ISO numeric to DWH country key. (Tier 2 — SP_eMoney_DimFact_Transaction, SP_eMoney_Customer_Risk_Assessment) |
| 6 | UpdateDate | datetime | YES | Bulk-load timestamp. Static; all rows = 2024-06-24. (Tier 2 — Manual load metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CountryName | ISO 3166-1 | country_name | Manual entry; full country name |
| CountryAlphaTwoCode | ISO 3166-1 | alpha-2 | Manual entry; 2-letter ISO code |
| CountryAlphaThreeCode | ISO 3166-1 | alpha-3 | Manual entry; 3-letter ISO code |
| CountryNumericCode_ISO | ISO 3166-1 | numeric | Manual entry; 3-digit ISO numeric code |
| eToroDWHCountryID | DWH_dbo.Dim_Country | CountryID | Manual mapping; ISO numeric → DWH country key |
| UpdateDate | Manual load | — | Bulk-load timestamp; all rows 2024-06-24 |

### 5.2 ETL Pipeline

```
ISO 3166-1 reference data (external standard)
  |-- Manual bulk load (2024-06-24) ---|
  v
eMoney_dbo.eMoney_Country_Codes_Mapping_ISO (248 rows, HASH(eToroDWHCountryID), HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_country_codes_mapping_iso

Consumed by:
  SP_eMoney_Customer_Risk_Assessment → country HRC lookups (country risk scoring)
  SP_eMoney_DimFact_Transaction → TransactionCountryIso (numeric) → eToroDWHCountryID
```

---

## 6. Relationships

### 6.1 References To

| Object | Column | Description |
|--------|--------|-------------|
| DWH_dbo.Dim_Country | CountryID | eToroDWHCountryID bridges to DWH country dimension |

### 6.2 Referenced By

| Object | Column | Description |
|--------|--------|-------------|
| SP_eMoney_DimFact_Transaction | CountryNumericCode_ISO | Resolves FiatTransactions.TransactionCountryIso to eToroDWHCountryID |
| SP_eMoney_Customer_Risk_Assessment | CountryNumericCode_ISO | Resolves country code for HRC scoring |

---

## 7. Sample Queries

### 7.1 View sample country mappings
```sql
SELECT TOP 20 CountryName, CountryAlphaTwoCode, CountryAlphaThreeCode,
              CountryNumericCode_ISO, eToroDWHCountryID
FROM [eMoney_dbo].[eMoney_Country_Codes_Mapping_ISO]
ORDER BY CountryAlphaTwoCode;
```

### 7.2 Resolve a transaction's country code
```sql
SELECT t.TransactionID, c.CountryName, c.CountryAlphaTwoCode, c.eToroDWHCountryID
FROM [eMoney_dbo].[eMoney_Fact_Transaction_Status] t
JOIN [eMoney_dbo].[eMoney_Country_Codes_Mapping_ISO] c
    ON t.TransactionCountryIso = c.CountryNumericCode_ISO
WHERE t.TransactionCountryIso IS NOT NULL;
```

### 7.3 Find unmapped country codes in transactions
```sql
SELECT DISTINCT t.TransactionCountryIso
FROM [eMoney_dbo].[eMoney_Fact_Transaction_Status] t
LEFT JOIN [eMoney_dbo].[eMoney_Country_Codes_Mapping_ISO] c
    ON t.TransactionCountryIso = c.CountryNumericCode_ISO
WHERE t.TransactionCountryIso IS NOT NULL
  AND c.CountryNumericCode_ISO IS NULL;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. This is a manually maintained ISO 3166-1 reference table with no FiatDwhDB upstream wiki.

---

PHASE GATE CHECK — eMoney_Country_Codes_Mapping_ISO [STATIC-REF]:
  [x] P1 DDL   [x] P2 Sample   [x] P3 Dist   [-] P4 Lookup
  [x] P5 JOIN  [x] P6 BizLogic [-] P7 Views  [x] P8 SP-scan
  [-] P9 SP-logic [-] P9B ETL  [-] P10 Jira  [-] P10A Upstream  [x] P10B Lineage
  → Ready for P11
OUTPUT CHECK — eMoney_Country_Codes_Mapping_ISO [STATIC-REF]:
  [x] .lineage.md exists   [x] .md exists   [x] .review-needed.md (writing next)
  [-] .alter.sql — deferred to /generate-alter-dwh

*Generated: 2026-04-21 | Quality: 8.8/10 | Phases: 8/14 (STATIC-REF path)*
*Tiers: 0 T1, 6 T2, 0 T3, 0 T4, 0 T5 | Elements: 6/6, Logic: 9/10, Sources: 7/10*
*Object: eMoney_dbo.eMoney_Country_Codes_Mapping_ISO | Type: Table (Static Reference) | Production Source: ISO 3166-1 (manual)*
