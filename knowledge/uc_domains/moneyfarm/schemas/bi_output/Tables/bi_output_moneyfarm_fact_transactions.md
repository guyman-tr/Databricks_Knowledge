---
object: main.bi_output.bi_output_moneyfarm_fact_transactions
domain: moneyfarm
table_type: EXTERNAL
format: PARQUET
column_count: 7
row_count: null
generated_at: "2026-05-04T12:52:00Z"
tier_breakdown:
  tier1_columns: 3
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 4
  tier5_columns: 0
  unverified_columns: 0
sources:
  confluence: ["XP/13551468545", "XP/12216961926", "MG/13600227427", "CS/13209534657"]
  tableau:    ["main__etoro_kpi"]
  databricks: ["genie:01f14394002815a288421fd85f36d595"]
  uc_comment: false
---

# bi_output_moneyfarm_fact_transactions

## 1. What it is

eToro-side fact of MoneyFarm portfolio-level deposits and withdrawals.
Granularity: one row per `event_correlation_ID` — i.e. one row per source
event in the sub-accounts event-hub stream. Each row records the GCID,
PortfolioID, transaction direction (Deposit / Withdrawal / Full Withdrawal),
the source event timestamp, and the GBP amount (signed: negative for
withdrawals). The `event_correlation_ID` format `<UUID>_<EventType>` is the
same `EventPayloadRowData.EventMetadata.EventId + EventType` concatenation that
the V2 deposit-event HLD (Confluence XP/13551468545) describes.

## 2. Identity & Lineage

| Attribute | Value | Source |
|-----------|-------|--------|
| Full name | `main.bi_output.bi_output_moneyfarm_fact_transactions` | UC inventory |
| Type | EXTERNAL TABLE | UC inventory |
| Format | PARQUET (BI output) | UC inventory |
| Owner | BI / data-platform | inferred |
| Row count | ~29k events (sum of enum_hints: 26,712 Deposit + 1,815 Withdrawal + 844 Full Withdrawal) | enum_hints |
| Upstream | `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` filtered for `EventPayloadRowData.ProviderName = 'Moneyfarm'` and `EventMetadata.EventType IN ('PORTFOLIO_DEPOSIT', 'PORTFOLIO_WITHDRAW')`. The same source feed used by `etoro_kpi_prep.v_moneyfarm_mimo` (which aggregates to daily grain) and `bi_output_moneyfarm_fact_portfolio_snapshot.Source_Type='Live Event'` (which uses it for state). | XP/13551468545 + sample format correlation |
| Downstream | eToro KPI MIMO panels (Tableau `main__etoro_kpi`); Investment Portfolio Analytics Genie space `01f14394002815a288421fd85f36d595` | Tableau index + Databricks assets |

## 3. Columns

| # | Column | Type | Tier | Description | Notes & citations | Sample values |
|---|--------|------|------|-------------|-------------------|---------------|
| 0 | `event_correlation_ID` | STRING | T1 | "Concatenated source event ID = '{EventMetadata.EventId UUID}_{EventType}'. Primary key. Same EventId space as the sub-accounts EH MoneyFarm stream. [Confluence/XP/13551468545]" | Sources: UC samples (`{UUID}_PORTFOLIO_WITHDRAW` format observed) + Confluence XP/13551468545 §"General Flow". Wiki-only enrichment: the `_PORTFOLIO_WITHDRAW` / `_PORTFOLIO_DEPOSIT` suffix lets a single physical event be replayed under different consumer logic without colliding on PK. | `aea76e71-3bf8-4e74-8b62-0b3472c70db1_PORTFOLIO_WITHDRAW` |
| 1 | `GCID` | LONG | T1 | "eToro Global Customer ID at the time of the event. FK to main.bi_db.gold_sub_accounts_accounts.gcid (providerName='Moneyfarm'). [Confluence/XP/13551468545]" | Sources: UC samples + Confluence XP/13551468545 §"EventMetadata.Gcid". Same GCID space as the customers dim and fact_portfolio_snapshot. | `24737425`, `18260286`, `45177544` |
| 2 | `PortfolioID` | STRING | T1 | "MoneyFarm portfolio UUID v4 (8-4-4-4-12 with hyphens). FK to fact_portfolio_snapshot.PortfolioID. From event payload data.portfolioId. [Confluence/XP/13551468545]" | Sources: UC samples (UUID v4 format) + Confluence XP/13551468545 §"event_data_json $.data.portfolioId". One GCID can hold multiple PortfolioIDs (one per MoneyFarm product enrolled). | `961b754e-87ed-41f8-8d21-33b68f1b1781`, `e8c00d03-4376-45b8-b6be-88fdb1b2dffd` |
| 3 | `TransactionType` | STRING | T4 | "Direction enum. Values: Deposit (26712), Withdrawal (1815), Full Withdrawal (844). 'Full Withdrawal' indicates portfolio-closing withdrawal (deplete to zero). [uc_sample]" | Sources: UC enum_hints. Wiki-only enrichment: source event types are `PORTFOLIO_DEPOSIT` and `PORTFOLIO_WITHDRAW`; the 3-value split between Withdrawal and Full Withdrawal must come from event-payload data (likely `data.amount` vs. portfolio remaining balance, or an explicit `data.isFullWithdrawal` flag). The split logic is NOT anchored in the cached Confluence pages. | `Deposit`, `Withdrawal`, `Full Withdrawal` |
| 4 | `Transaction_Date` | TIMESTAMP | T4 | "Source event timestamp (UTC, microsecond precision). From EventMetadata.CreatedAt. NOT the value date — for that, parse value_date from the event payload. [uc_sample]" | Sources: UC samples (TIMESTAMP UTC). Wiki-only enrichment: `value_date` (settlement date) is parsed in `v_moneyfarm_mimo.parsed_events.value_date` but is NOT preserved in this fact — only `Transaction_Date` (created_at) is. Use this column for time-bucketing the event itself; reconcile to settlement only when MoneyFarm side timing matters. | `2025-10-10T15:31:32.586Z` |
| 5 | `Amount_GBP` | DECIMAL | T4 | "Signed GBP amount. Negative for Withdrawal/Full Withdrawal, positive for Deposit. From event_data_json $.data.amount. [uc_sample]" | Sources: UC samples (`-1000.00`, `-200.00`, `-500.00` for Withdrawal rows). Wiki-only enrichment: the corresponding USD/EUR conversion is done in `v_moneyfarm_aum`/`v_moneyfarm_mimo` via `fact_currencypricewithsplit` InstrumentID=2 (GBP/USD). This fact preserves the source GBP only. | `-1000.00`, `-200.00`, `-500.00` |
| 6 | `UpdateDate` | TIMESTAMP | T4 | "Snapshot refresh timestamp (UTC). All rows in a refresh share the same value. [uc_sample]" | Sources: UC samples (`2026-03-13T06:27:38.232Z` shared across the 3-row sample). | `2026-03-13T06:27:38.232Z` |

## 4. Common usage / JOINs

- **Daily aggregation**: `etoro_kpi_prep.v_moneyfarm_mimo` aggregates this stream to one row per `(date, GCID)`. Use the view, not this raw fact, for daily MIMO panels.
- **Per-event drill-down**: this fact is the right grain for forensic / audit queries (which event drove the snapshot change).
- **Cross-domain bridge**: `GCID` joins to eToro DWH; `PortfolioID` joins to `bi_output_moneyfarm_fact_portfolio_snapshot.PortfolioID`.
- **Genie usage**: Investment Portfolio Analytics Genie space (`01f14394002815a288421fd85f36d595`) references this stream for portfolio-level transaction lookups.

## 5. Gotchas

- `Amount_GBP` is **signed** — `SUM(Amount_GBP)` yields net flow. For gross
  deposit / gross withdrawal: split by `TransactionType`. [uc_sample]
- `Transaction_Date` is the source event `CreatedAt`, NOT the settlement
  `value_date`. The settlement field is parsed elsewhere
  (`v_moneyfarm_mimo.parsed_events.value_date`) but is not surfaced in this
  fact. [view_def: v_moneyfarm_mimo]
- `Full Withdrawal` (844 rows) and `Withdrawal` (1815 rows) are functionally
  the same thing for SUM(Amount_GBP) — the distinction matters only when
  counting **portfolio closure events** vs partial withdrawals. The exact
  split logic is not anchored in the cached Confluence pages. [uc_sample]
- `event_correlation_ID` PK uniqueness depends on the source event-hub message
  not being replayed to the same EventType — verify upstream if you see
  duplicates.

## 6. UC ALTER provenance

7 column-level COMMENTs + 1 table-level COMMENT. The 3 PK/FK columns
(`event_correlation_ID`, `GCID`, `PortfolioID`) are Tier 1 anchored on the
V2 deposit-event HLD (Confluence XP/13551468545). The 4 measure/timestamp/
operational columns are Tier 4 sample-anchored. All 7 are deployed.
