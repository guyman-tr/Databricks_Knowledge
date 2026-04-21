# eMoney_dbo.eMoney_EntityByCurrencyISO_MappingStatic

**Schema**: eMoney_dbo | **Batch**: 13 | **Generated**: 2026-04-21 | **Quality**: 8.7/10

## Overview

Micro-reference table (4 rows) that maps each eToro Money-supported base currency to its responsible eToro Money legal entity, its primary DWH instrument ID, and the entity's reporting currency. Acts as the authoritative lookup for which eToro Money subsidiary (UK, Malta, AUS) operates a given currency, and how balance calculations should be reported (e.g., DKK customers are under eToro Money Malta and their balances are reported in EUR, not DKK).

**Row count**: 4 (AUD, DKK, GBP, EUR)
**Grain**: One row per eToro Money-supported base currency
**Distribution**: ROUND_ROBIN, HEAP — appropriate for a 4-row lookup table

| CurrencyISO | CurrencyName | Entity | InstrumentID | ReportingCurrency | ReportingInstrumentID |
|-------------|-------------|--------|-------------|------------------|----------------------|
| 36 | AUD | eToro Money AUS | 7 | AUD | 7 |
| 208 | DKK | eToro Money Malta | 75 | EUR | 1 |
| 826 | GBP | eToro Money UK | 2 | GBP | 2 |
| 978 | EUR | eToro Money Malta | 1 | EUR | 1 |

## Source System

No upstream system or ETL stored procedure writes to this table. Data was manually inserted starting 2025-09-29 (AUD, GBP, EUR) with DKK added on 2025-11-26. The table is maintained by direct DBA INSERT/UPDATE as new eToro Money jurisdictions are launched.

A commented-out UPDATE block exists in `SP_eMoney_ClientBalance` (lines 56–63 of that SP) showing the original instrument ID assignment logic — this is a development artifact and is NOT executed at runtime.

## ETL / Load Pattern

| Property | Value |
|----------|-------|
| Writer SP | None — manual DBA maintenance |
| Load strategy | Manual INSERT/UPDATE per jurisdiction launch |
| UC target | TBD — no active export pipeline detected |
| Refresh cadence | Ad-hoc; updated when a new eToro Money entity/currency is onboarded |
| Row count | 4 (as of 2025-11-26) |

## Column Inventory

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | CurrencyISO | int | NULL | ISO 4217 numeric code for the eToro Money base currency (36=AUD, 208=DKK, 826=GBP, 978=EUR). The primary JOIN key used by consuming SPs (JOIN ON CurrencyISO = d.CurrencyISON). (Tier 2 — manual static load) |
| 2 | CurrencyName | varchar(250) | NULL | ISO 4217 alpha-3 currency code as a string label (e.g., 'AUD', 'DKK', 'GBP', 'EUR'). Used for display/reporting; not used as a JOIN key. (Tier 2 — manual static load) |
| 3 | Entity | varchar(250) | NULL | eToro Money legal entity responsible for customers holding this currency (e.g., 'eToro Money UK', 'eToro Money Malta', 'eToro Money AUS'). Denormalized into eMoney_Dim_Account via SP_eMoney_Dim_Account (as ISNULL(ee.Entity,'N/A')). (Tier 2 — manual static load) |
| 4 | InstrumentID | int | NULL | DWH instrument ID for the primary FX instrument associated with this currency. Foreign-keys to DWH_dbo.Dim_Instrument.InstrumentID. Used by consuming SPs as di2.InstrumentID (e.g., to derive IsToUSD flag: CASE WHEN di2.SellCurrencyID=1 THEN 1 ELSE 0 END). (Tier 2 — manual static load) |
| 5 | UpdateDate | datetime | NULL | Timestamp of the most recent manual row insert or update. Reflects the date each jurisdiction row was populated (2025-09-29 for AUD/GBP/EUR; 2025-11-26 for DKK). Not a refresh indicator — changes only on manual DBA action. (Tier 2 — manual static load) |
| 6 | ReportingCurrency | varchar(255) | NULL | ISO alpha-3 code for the eToro Money entity's reporting currency. For eToro Money Malta (which covers both EUR and DKK accounts), the reporting currency is EUR — so DKK balances are FX-converted to EUR for reporting. AUS and UK report in their native currencies (AUD and GBP respectively). (Tier 2 — manual static load) |
| 7 | ReportingInstrumentID | int | NULL | DWH instrument ID for the reporting currency. Foreign-keys to DWH_dbo.Dim_Instrument.InstrumentID. Used by consuming SPs as di.InstrumentID (the reporting-side instrument join). Example: DKK → ReportingInstrumentID=1 (EUR instrument). (Tier 2 — manual static load) |

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — (no upstream wiki; manual static load) |
| Tier 2 | 7 | All columns |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |

## Key Relationships

| This Column | References | Note |
|-------------|-----------|------|
| InstrumentID | DWH_dbo.Dim_Instrument.InstrumentID | Primary currency instrument; used for IsToUSD flag derivation |
| ReportingInstrumentID | DWH_dbo.Dim_Instrument.InstrumentID | Reporting currency instrument; used to JOIN to reporting FX rates |
| CurrencyISO | eMoney_dbo.eMoney_Currency_Mapping_ISO | Overlapping currency coverage; different scope — this table adds Entity and reporting currency |
| CurrencyISO | eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static | Related static mapping; that table covers 21 currencies × all FX pairs; this table covers 4 currencies × entity/reporting |

**No physical FK constraints** defined in DDL (HEAP table, all NULL). Relationships enforced by SP logic.

## Business Rules & Data Quality

- **One row per eToro Money entity-currency**: AUD/GBP/EUR each have exactly one entity. DKK is also mapped to eToro Money Malta (the EU/EEA umbrella entity).
- **Reporting currency ≠ native currency for DKK**: DKK accounts are operated by eToro Money Malta and reported in EUR. Consumers of this table must account for this when aggregating balances — DKK balances are FX-converted to EUR before reporting.
- **All columns nullable in DDL**: Although the current 4 rows have no NULLs, DDL declares all columns NULL. An inadvertent NULL in Entity or InstrumentID would silently propagate as NULL/N/A in downstream tables (SP_eMoney_Dim_Account uses ISNULL(ee.Entity,'N/A') as a safeguard).
- **Growth tied to jurisdictional expansion**: New rows are added only when eToro Money launches in a new jurisdiction. The current 4 rows represent the active operating currencies as of 2025-11-26.
- **No automatic refresh**: Unlike SP-driven tables, this table has no scheduled refresh. Any stale or missing row requires a manual DBA action.

## Downstream Consumers

| SP | Usage |
|----|-------|
| SP_eMoney_Dim_Account | LEFT JOIN on CurrencyISO → derives Entity field for eMoney_Dim_Account (ISNULL(ee.Entity,'N/A')) |
| SP_eMoney_ClientBalance | JOIN on CurrencyISO → derives ReportingInstrumentID and InstrumentID for FX rate lookups; used for reporting-currency balance calculations |
| SP_eMoney_Aggregated_Tribe_Balance | JOIN on ReportingInstrumentID and InstrumentID → same dual-Dim_Instrument join pattern for aggregated balance reporting |
| SP_eMoney_Reconciliation_ETLs | Referenced for entity resolution in reconciliation context |

No confirmed Generic Pipeline (Gold) export — consumed exclusively via SP JOIN logic within the eMoney_dbo processing layer.

## Open Questions / Review Notes

- **UC target**: No export pipeline detected. If UC consumers need this mapping, target would be: `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_entitybycurrencyiso_mappingstatic`.
- **Completeness**: Confirms only 4 active eToro Money currencies. If new jurisdictions (e.g., additional EEA markets) are launched, this table must be manually updated or downstream Entity values will appear as 'N/A'.
- **ReportingCurrency for new entities**: The pattern for future jurisdictions (whether to use a local or hub reporting currency) should be documented in a data contract to avoid ambiguity.
- See `.review-needed.md` for reviewer checklist.
