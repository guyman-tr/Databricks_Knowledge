---
object_fqn: main.etoro_kpi.vg_dealing_clicks_openclose_breakdown
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.vg_dealing_clicks_openclose_breakdown
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 47
row_count: null
generated_at: '2026-05-19T15:20:44Z'
upstreams:
- main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_dealing_clicks_openclose_breakdown.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_dealing_clicks_openclose_breakdown.sql
concept_count: 2
formula_count: 47
tier_breakdown:
  tier1_columns: 7
  tier2_columns: 36
  tier3_columns: 4
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# vg_dealing_clicks_openclose_breakdown

> View in `main.etoro_kpi`. 2 business concept(s) in §2; 43 of 47 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.vg_dealing_clicks_openclose_breakdown` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | adifa@etoro.com |
| **Row count** | n/a |
| **Column count** | 47 |
| **Concepts** | 2 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Wed Mar 25 07:46:45 UTC 2026 |

---

## 1. Business Meaning

`vg_dealing_clicks_openclose_breakdown` is a view in `main.etoro_kpi` that composes a UNION ALL with sign-flipped amount legs (deposit/withdraw composition), 1 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Clicks_OpenClose_Breakdown.md`. Additional upstreams: 2 object(s), listed in §5 Lineage.

Of its 47 columns: 7 inherit byte-for-byte from upstream wikis (Tier 1), 36 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Sign-flip leg `main` (multiplies `TicketFee` by -1)
**What**: This subselect contributes the negative-sign leg of a UNION ALL composition — amount columns are multiplied by -1 so the downstream rollup nets to (deposit - withdraw).
**Columns Involved**: `TicketFee`
**Rules**:
- `-1 * cbd.TicketFee` (sign-flip on amount)
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_dealing_clicks_openclose_breakdown.sql` L43
**Source(s)**: `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`

### 2.2 Dim lookup via alias `di` → `gold_sql_dp_prod_we_dwh_dbo_dim_instrument`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_instrument` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `cbd.InstrumentID = di.InstrumentID`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_dealing_clicks_openclose_breakdown.sql` L57
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`

---

## 3. Query Advisory

### 3.1 UC Storage Layout

| Property | Value |
|----------|-------|
| **Type** | VIEW |
| **Format** | n/a |
| **Partitioned by** | (not partitioned) |
| **Materialization** | view_definition (re-runs on every query) |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_instrument`). |
| Sum amounts directly for net flow | Amount columns are already sign-flipped per leg — summing them yields net flow (deposits - withdraws). No need to subset by MIMOAction unless you want gross flow. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `cbd.InstrumentID = di.InstrumentID` | Lookup via alias `di` |

### 3.4 Gotchas

- Sign flip in scope(s) `main` means summing amount columns nets to (deposit - withdraw). Multiply by -1 again if you want gross withdraw amounts.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | TIMESTAMP | YES | Report date. Set to `@Date` SP parameter (typically yesterday). One day's worth of clicks per load. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 1 | DateID | INT | YES | Date as YYYYMMDD integer. `CAST(CONVERT(VARCHAR(8), @Date, 112) AS INT)`. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 2 | SellCurrency | STRING | YES | Text abbreviation of the instrument's sell-side (denomination) currency. Example: USD, EUR, GBX (GBP pence). DWH-added for query convenience. (Tier 2 — SP_Dim_Instrument) |
| 3 | Club | STRING | YES | Player tier name from Dim_PlayerLevel (e.g., Bronze, Silver, Gold, Platinum). Customer's loyalty/tier level at the snapshot date. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 4 | CID | INT | YES | Customer ID. References Customer.Customer. (Tier 1 — Trade.PositionTbl) |
| 5 | IsBuy | BOOLEAN | YES | Trade direction. 1=Long (buy), 0=Short (sell). (Tier 1 — Trade.PositionTbl) |
| 6 | HeldOnReportDate | BOOLEAN | YES | Whether position was still open at end of report date. `CASE WHEN CloseDateID > @DateID OR CloseDateID = 0 THEN 1 ELSE 0 END`. Renamed from IsOpen (SR-325240). Always 0 for close clicks. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 7 | HedgeServerID | INT | YES | Liquidity provider server ID. Identifies which hedge server executed the position. Key servers: 2=JP Morgan legacy, 101=Goldman Sachs, 81=Real Stocks LP. HedgeServerID=35 allows invalid customer inclusion. (Tier 1 — Trade.PositionTbl) |
| 8 | InstrumentID | INT | YES | Instrument identifier. FK to DWH_dbo.Dim_Instrument. (Tier 1 — Trade.PositionTbl) |
| 9 | InstrumentDisplayName | STRING | YES | User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than InstrumentName (e.g., 'Apple Inc.' vs 'Apple'). (Tier 2 — SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 10 | InstrumentName | STRING | YES | Internal instrument name from Trade.Instrument. Renamed from Dim_Instrument.Name. For forex: pair notation (e.g., EUR/USD). For stocks: company name. (Tier 3 — live data, etoro.Trade.GetInstrument) |
| 11 | InstrumentTypeID | INT | YES | Asset class: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. (Tier 2 — SP_Dim_Instrument) |
| 12 | InstrumentType | STRING | YES | Text label for InstrumentTypeID. DWH-computed via CASE: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. Use InstrumentTypeID for filtering; InstrumentType for display. (Tier 2 — SP_Dim_Instrument) |
| 13 | IsCopy | BOOLEAN | YES | Copy-trade flag. `CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END`. 1=position opened via CopyTrader, 0=direct trade. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 14 | IsCFD | BOOLEAN | YES | CFD vs Real asset flag. `CASE WHEN IsSettled = 1 THEN 0 ELSE 1 END`. 1=CFD (contract for difference), 0=Real stock/crypto ownership. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 15 | Symbol | STRING | YES | Ticker symbol for the instrument (e.g., AAPL, EURUSD, BTCUSD). Used for display, search, and price feed identification. (Tier 3 — live data, etoro.Trade.GetInstrument) |
| 16 | Leverage | INT | YES | Position leverage multiplier. 1=unleveraged (real stocks), 2-30=leveraged (CFDs). From Dim_Position.Leverage. (Tier 1 — Trade.PositionTbl) |
| 17 | Exchange | STRING | YES | Stock exchange name from Trade.InstrumentMetaData (e.g., Nasdaq, NYSE, LSE). NULL for non-stock instruments. (Tier 3 — live data, etoro_Trade_InstrumentMetaData) |
| 18 | CountryID | INT | YES | Customer's registered country at snapshot date. FK to Dim_Country. From Fact_SnapshotCustomer via Dim_Country. (Tier 1 — Dictionary.Country upstream wiki) |
| 19 | Country | STRING | YES | Country name from Dim_Country.Name. (Tier 1 — Dictionary.Country upstream wiki) |
| 20 | Region | STRING | YES | Marketing region manual override. From Dim_Country.MarketingRegionManualName. Examples: Latam, UK, German, CEE, SEA. (Tier 3 — Ext_Dim_Country live data) |
| 21 | RegulationID | INT | YES | Customer's regulatory jurisdiction at snapshot date. FK to Dim_Regulation. 1=CySEC, 2=FCA, etc. (Tier 2 — SP_Fact_SnapshotCustomer) |
| 22 | Regulation | STRING | YES | Regulation name from Dim_Regulation.Name. Examples: CySEC, FCA, ASIC. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 23 | IsIslamic | BOOLEAN | YES | Islamic (swap-free) account flag. `CASE WHEN WeekendFeePrecentage = 0 THEN 1 ELSE 0 END`. Source: Dim_Customer.WeekendFeePrecentage. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 24 | Size_of_Tickets | STRING | YES | Direct passthrough from upstream. Formula: `Size_of_Tickets`. (Tier 2 — from `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown`) |
| 25 | OpenOrClose | STRING | YES | Row type: `'Open Click'` or `'Close Click'`. Literal string set by SP. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 26 | OpenOrCloseID | INT | YES | Row type numeric: 1=Open Click, 0=Close Click. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 27 | Click | LONG | YES | Trade event count. `SUM(NumberofPositionsOpened)` for opens (1 per non-partial-close position opened on @Date), `SUM(NumberofPositionsClosed)` for closes. Aggregated in GROUP BY. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 28 | Volume | DECIMAL | YES | USD trade volume. For opens: `SUM(CAST(VolumeOpened AS BIGINT))` where VolumeOpened = SUM(Dim_Position.Volume) over OriginalPositionID partition. For closes: `SUM(VolumeClosed)` where VolumeClosed = VolumeOnClose. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 29 | Units | DECIMAL | YES | Instrument units traded. For opens: `SUM(InitialUnits)` WHERE OpenDateID=@DateID. For closes: `SUM(AmountInUnitsDecimal)` WHERE CloseDateID=@DateID. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 30 | FullCommission | DECIMAL | YES | Commission amount. Opens: `SUM(FullCommissionOnOpenInit)` — accumulated FullCommissionByUnits including partial close children. Closes: `SUM(FullCommissionOnClose)` for same-day opens, `SUM(FullCommissionOnClose - FullCommissionByUnits)` for older positions. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 31 | InitialAmountUSDOnOpen | DECIMAL | YES | Initial investment in USD for open clicks only. `SUM(InitialAmountCents/100) WHERE NumberofPositionsOpened=1`. Always 0 for close clicks. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 32 | UpdateDate | TIMESTAMP | YES | ETL load timestamp. Set to `GETDATE()` on each daily reload. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 33 | IsPI | BOOLEAN | YES | Popular Investor flag. `CASE WHEN GuruStatusID >= 2 THEN 1 ELSE 0 END`. Source: Fact_SnapshotCustomer.GuruStatusID. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 34 | IsTicketFee | BOOLEAN | YES | Has ticket fee flag. `CASE WHEN Fact_CustomerAction.Amount IS NOT NULL THEN 1 ELSE 0 END`. Ticket fee = ActionTypeID=35 AND IsFeeDividend=4. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 35 | TicketFee | DECIMAL | YES | Arithmetic combination of upstream columns. Formula: `-1 * TicketFee`. (Tier 2 — from `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown`) |
| 36 | IsAirDrop | BOOLEAN | YES | AirDrop position flag. `CASE WHEN Dim_Position.IsAirDrop = 1 THEN 1 ELSE 0 END`. AirDrop opens are treated separately: zero ticket fees, IsFTDClick always 0. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 37 | IsFuture | BOOLEAN | YES | Futures instrument flag. Direct from Dim_Instrument.IsFuture. Added SR-308870 (2025-04-07). (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 38 | etr_y | STRING | YES | Direct passthrough from upstream. Formula: `etr_y`. (Tier 2 — from `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown`) |
| 39 | etr_ym | STRING | YES | Direct passthrough from upstream. Formula: `etr_ym`. (Tier 2 — from `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown`) |
| 40 | etr_ymd | STRING | YES | Direct passthrough from upstream. Formula: `etr_ymd`. (Tier 2 — from `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown`) |
| 41 | HaseMoneyAccount | BOOLEAN | YES | Has eMoney account flag (note: intentional typo in column name). `CASE WHEN eMoney_Dim_Account.CID IS NOT NULL THEN 1 ELSE 0 END` WHERE GCID_Unique_Count=1 AND IsValidETM=1. Added SR-346605 (2025-12-07). (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 42 | IsIBANClick | BOOLEAN | YES | IBAN-originated trade flag. Opens: `CASE WHEN BI_DB_Positions_Opened_From_IBAN.PositionID IS NOT NULL THEN 1 ELSE 0 END`. Closes: same with BI_DB_Positions_Closed_To_IBAN. Added SR-346605 (2025-12-07). (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 43 | IsFTDClick | BOOLEAN | YES | First Trade after Deposit flag. `CASE WHEN dp.PositionID = dc.PositionID THEN 1 ELSE 0 END`. dc.PositionID = first non-airdrop position opened after customer's first deposit date (ROW_NUMBER=1). Always 0 for close clicks and AirDrop opens. Added SR-346605. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 44 | IsLowTouch | BOOLEAN | YES | Low-touch instrument flag. From Dim_Instrument.OperationMode. Indicates instruments with simplified execution flow. Added SR-346605 (2025-12-07). (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 45 | Multiplier | DECIMAL | YES | Direct passthrough from upstream. Formula: `Multiplier`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 46 | Manager | STRING | YES | Direct passthrough from upstream. Formula: `Manager`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | Primary | `knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Clicks_OpenClose_Breakdown.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
        │
        ▼
main.etoro_kpi.vg_dealing_clicks_openclose_breakdown   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=47 runtime=47 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` (wiki: `knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Clicks_OpenClose_Breakdown.md`)
- **JOIN/UNION upstreams**: 2 additional object(s)
- **Wiki coverage**: 2/2 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- _(no downstream consumers tracked in `_dag.json`)_

---

## 7. Sample Queries

> Sample queries are not auto-generated. Refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage patterns against this object.

---

## 8. Atlassian Knowledge Sources

> No Atlassian sources discovered for this object in the current pipeline. When Confluence pages or Jira tickets are linked to this UC object, they will appear here (run `tools/uc_pipelines/cache_atlassian_for_object.py` if/when that tool exists).

---

## Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough/rename/cast).
- **Tier 2** — column described from a formula in `formulas.json` + an optional named concept from `concepts.json`. The formula is the predicate-explicit, alias-resolved SQL transformation; the concept gives the business name.
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides every other tier including Tier 1 (per DWH semantic-doc framework).
- **Tier N** — null-with-provenance: column points at an upstream that is either terminal-with-no-wiki, or in-scope-but-not-yet-authored. Explicit gap disclosure.
- **Tier U** — unclassifiable: no upstream wiki match, no formula, no source-code snippet. Mechanical disclosure of unclassifiability — see `.review-needed.md`.

*Generated: 2026-05-19 | Concepts: 2 | Formulas: 47 | Tiers: 7 T1, 36 T2, 4 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 47/47 | Source: view_definition*
