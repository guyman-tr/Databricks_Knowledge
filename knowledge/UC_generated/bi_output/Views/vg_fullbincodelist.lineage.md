# Column Lineage: main.bi_output.vg_fullbincodelist

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_fullbincodelist` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_fullbincodelist.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_fullbincodelist.json` (rows: 7, mismatches: 1) |
| **Primary upstream** | `main.general.bronze_etoro_dictionary_countrybin` |
| **Generated** | 2026-06-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.general.bronze_etoro_dictionary_countrybin` | Primary (FROM) | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Views/Dictionary.CountryBin.md` |
| `main.general.bronze_etoro_dictionary_country` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` |
| `main.general.bronze_etoro_dictionary_cardtype` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CardType.md` |
| `main.billing.bronze_etoro_billing_badbin` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.BadBin.md` |

## Lineage Chain

```
main.general.bronze_etoro_dictionary_countrybin   ←── primary upstream
  + main.general.bronze_etoro_dictionary_country   (JOIN)
  + main.general.bronze_etoro_dictionary_cardtype   (JOIN)
  + main.billing.bronze_etoro_billing_badbin   (JOIN)
        │
        ▼
main.bi_output.vg_fullbincodelist   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `bin_code` | `main.general.bronze_etoro_dictionary_countrybin` | `BinCode` | `rename` | — | b.BinCode AS bin_code |
| 2 | `issuing_country` | `main.general.bronze_etoro_dictionary_country` | `Name` | `join_enriched` | — | c.Name AS issuing_country |
| 3 | `issuer_name` | `main.general.bronze_etoro_dictionary_countrybin` | `IssuingBank` | `rename` | — | b.IssuingBank AS issuer_name |
| 4 | `card_type` | `main.general.bronze_etoro_dictionary_cardtype` | `Name` | `join_enriched` | — | ct.Name AS card_type |
| 5 | `card_subtype` | `main.general.bronze_etoro_dictionary_countrybin` | `CardSubType` | `rename` | — | b.CardSubType AS card_subtype |
| 6 | `aft_support` | `main.general.bronze_etoro_dictionary_countrybin` | `SupportsAFT` | `rename` | — | b.SupportsAFT AS aft_support |
| 7 | `is_bad_bin` | `main.billing.bronze_etoro_billing_badbin` | `—` | `case` | — | CASE WHEN NOT x.BinFrom IS NULL THEN TRUE ELSE FALSE END AS is_bad_bin |

## Cross-check vs system.access.column_lineage

- Total target columns: **7**
- OK: **6**, WARN: **0**, ERROR: **1**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `is_bad_bin` | — | `main.billing.bronze_etoro_billing_badbin.binfrom` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **3**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN main.general.bronze_etoro_dictionary_country AS c ON b.CountryID = c.CountryID
- `INNER INNER` — INNER JOIN main.general.bronze_etoro_dictionary_cardtype AS ct ON b.CardTypeID = ct.CardTypeID
- `LEFT JOIN` — LEFT JOIN main.billing.bronze_etoro_billing_badbin AS x ON b.BinCode = x.BinFrom
