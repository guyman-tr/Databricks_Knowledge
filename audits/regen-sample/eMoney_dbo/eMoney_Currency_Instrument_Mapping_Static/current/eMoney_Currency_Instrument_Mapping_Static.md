# eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static

**Schema**: eMoney_dbo | **Batch**: 13 | **Generated**: 2026-04-21 | **Quality**: 8.5/10

## Overview

Static reference table mapping each eToro Money-supported currency (ISO alpha-3 code) to its corresponding FX instrument pair(s) in the DWH dimension model. Each row represents a single tradeable instrument pair (e.g., AUD/EUR, GBP/USD) for a given currency, linking the ISO currency code to its internal DWH instrument and currency IDs. The table was manually populated once (2022-11-21, 145 rows covering 21 currencies and their FX pairs) and has not been refreshed since; it serves as a lookup for SP-driven balance and account calculations.

**Row count**: 145 (static as of 2022-11-21)
**Grain**: One row per currency × FX instrument pair (a single currency can map to multiple instrument pairs; e.g., USD appears in 52 pairs)
**Distribution**: ROUND_ROBIN, HEAP — consistent with other small static reference tables in eMoney_dbo

## Source System

No upstream system or ETL stored procedure writes to this table. Data was inserted manually on 2022-11-21 as a one-time population of FX instrument pair mappings. Currency and instrument IDs reference `DWH_dbo.Dim_Instrument` (via `InstrumentID` = `DWHInstrumentID`) and an internal DWH currency dimension (via `BuyCurrencyID`, `SellCurrencyID`).

## ETL / Load Pattern

| Property | Value |
|----------|-------|
| Writer SP | None — manual insert (one-time load, 2022-11-21) |
| Load strategy | Manual INSERT; no Generic Pipeline export confirmed |
| UC target | TBD — no active export pipeline detected |
| Refresh cadence | Static; never refreshed after initial population |
| Row count | 145 (21 currencies, 145 FX instrument pairs) |

No truncation, deletion, or refresh mechanism exists. Any update requires a manual DBA intervention.

## Column Inventory

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Currency | varchar(50) | NOT NULL | ISO 4217 alpha-3 currency code for the base currency of this row (e.g., 'AUD', 'USD', 'GBP'). One currency can appear in multiple rows — one per instrument pair. (Tier 2 — manual static load) |
| 2 | CurrencyISO | int | NOT NULL | ISO 4217 numeric code for the currency in the Currency column (e.g., 36=AUD, 840=USD, 826=GBP). (Tier 2 — manual static load) |
| 3 | InstrumentID | int | NOT NULL | Internal DWH instrument identifier for the FX pair. Matches DWHInstrumentID and foreign-keys to DWH_dbo.Dim_Instrument.InstrumentID. (Tier 2 — manual static load) |
| 4 | InstrumentName | varchar(50) | NOT NULL | Human-readable FX pair name in base/quote format (e.g., 'AUD/EUR', 'GBP/AUD'). Describes which two currencies form this tradeable pair. (Tier 2 — manual static load) |
| 5 | DWHInstrumentID | int | NOT NULL | DWH dimension instrument ID — confirmed identical to InstrumentID from live data. Retained as a separate column for compatibility with consuming SPs. (Tier 2 — manual static load) |
| 6 | BuyCurrencyID | int | NOT NULL | Internal DWH currency ID for the base (buy) currency of this instrument pair (e.g., BuyCurrencyID=5 for AUD). References an internal DWH currency dimension. (Tier 2 — manual static load) |
| 7 | SellCurrencyID | int | NOT NULL | Internal DWH currency ID for the quote (sell) currency of this instrument pair (e.g., SellCurrencyID=2 for EUR). References an internal DWH currency dimension. (Tier 2 — manual static load) |
| 8 | BuyCurrency | varchar(50) | NOT NULL | ISO 4217 alpha-3 code for the base (buy) currency of the instrument pair (e.g., 'AUD', 'GBP'). Denormalized from BuyCurrencyID for readability. (Tier 2 — manual static load) |
| 9 | SellCurrency | varchar(50) | NOT NULL | ISO 4217 alpha-3 code for the quote (sell) currency of the instrument pair (e.g., 'EUR', 'USD'). Denormalized from SellCurrencyID for readability. (Tier 2 — manual static load) |
| 10 | UpdateDate | datetime | NOT NULL | Timestamp of the manual data load. All 145 rows carry 2022-11-21; treated as a static audit field, not a refresh indicator. (Tier 2 — manual static load) |

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — (no upstream wiki source; manual static load) |
| Tier 2 | 10 | All columns |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |

## Key Relationships

| This Column | References | Note |
|-------------|-----------|------|
| InstrumentID | DWH_dbo.Dim_Instrument.InstrumentID | FK to DWH instrument dimension; confirmed: InstrumentID = DWHInstrumentID in all 145 rows |
| DWHInstrumentID | DWH_dbo.Dim_Instrument.InstrumentID | Redundant with InstrumentID — kept for SP compatibility |
| BuyCurrencyID / SellCurrencyID | DWH internal currency dimension | Not mapped to a named table in DDL; resolved at query time by consuming SPs |
| Currency / CurrencyISO | eMoney_dbo.eMoney_Currency_Mapping_ISO | Overlapping coverage; eMoney_Currency_Mapping_ISO maps ISO codes to entity/regulatory info |

**No physical FK constraints** defined in DDL (HEAP table). All relationships are enforced by application/SP logic.

## Currency Coverage

| Currency | ISO Code | Instrument Pairs |
|----------|----------|-----------------|
| USD | 840 | 52 |
| EUR | 978 | 15 |
| GBP | 826 | 11 |
| AUD | 36 | 9 |
| CHF | 756 | 9 |
| JPY | 392 | 8 |
| NZD | 554 | 8 |
| CAD | 124 | 7 |
| HUF | 348 | 4 |
| NOK | 578 | 3 |
| SEK | 752 | 3 |
| DKK | 208 | 2 |
| HKD | 344 | 2 |
| PLN | 985 | 2 |
| RUB | 643 | 2 |
| SAR | 682 | 2 |
| ZAR | 710 | 2 |
| CZK | 203 | 1 |
| MXN | 484 | 1 |
| SGD | 702 | 1 |
| TRY | 949 | 1 |

## Business Rules & Data Quality

- **Static data**: All 145 rows carry UpdateDate = 2022-11-21. This is not a runtime field — it reflects the date of the single manual load. Any currency or instrument additions after that date are NOT reflected here.
- **All columns NOT NULL**: DDL enforces NOT NULL on all 10 columns. No nullability risk.
- **InstrumentID = DWHInstrumentID**: Verified from live data — both columns carry the same value for all 145 rows. The duplication is a legacy artifact.
- **One currency → many pairs**: A single currency (e.g., USD with 52 pairs) maps to every instrument pair in which it participates. Consumers must JOIN on both Currency and the target instrument/currency ID to avoid fan-out.
- **No ROUND_ROBIN concern at this scale**: 145 rows across ROUND_ROBIN distribution is negligible — broadcast or replicate would be more appropriate for a static table of this size, but no performance impact is expected.
- **RUB included**: Russian Ruble (RUB, ISO 643) is present in the mapping. Consuming SPs should handle any regulatory or business-rule filtering upstream if RUB trades are restricted.

## Downstream Consumers

This table is read (not written) by the following stored procedures:

| SP | Usage |
|----|-------|
| SP_eMoney_Dim_Account | Resolves FX instrument IDs for account dimension enrichment |
| SP_eMoney_Snapshot_Settled_Balance | Maps currency balances to their DWH instrument for settlement calculations |
| SP_eMoney_Calculated_Balance | Resolves instrument pairs for currency balance calculations |

No confirmed Generic Pipeline (Gold) export for this table — it is consumed exclusively via SP JOIN logic within the eMoney_dbo processing layer.

## Open Questions / Review Notes

- **UC target**: No Generic Pipeline export detected. If downstream Unity Catalog consumers need this mapping, a UC export pipeline should be created. UC target would follow naming convention: `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_currency_instrument_mapping_static`.
- **Staleness**: Data is 3+ years old (2022-11-21). Confirm whether all 21 currencies and 145 instrument pairs are still valid and complete for current eToro Money operations.
- **RUB presence**: Russian Ruble mappings (2 pairs) exist — confirm whether these are intentionally retained or should be flagged for review following 2022 regulatory changes.
- **InstrumentID = DWHInstrumentID**: If confirmed permanently identical, one column could be removed in a future cleanup. Assess SP dependencies before removing.
- See `.review-needed.md` for reviewer checklist.
