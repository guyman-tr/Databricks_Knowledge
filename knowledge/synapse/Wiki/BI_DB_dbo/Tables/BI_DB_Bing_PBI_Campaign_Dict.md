# BI_DB_dbo.BI_DB_Bing_PBI_Campaign_Dict

> 4,068-row Bing Ads campaign history dictionary sourced via Fivetran from the Bing Ads API. Each row represents one version of a campaign's state at a point in time (history-feed pattern — campaigns appear multiple times as their status, budget, or bid strategy changes). Covers 622 distinct campaigns across 12 Bing Ads accounts. Fully refreshed daily via SP_Bing_PBI (TRUNCATE+INSERT from the Fivetran external table). Used in Power BI reports for Bing Ads marketing performance analysis.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.External_Fivetran_bingads_campaign_history via SP_Bing_PBI |
| **Refresh** | Daily (SB_Daily, Priority 20). Full TRUNCATE+INSERT — entire table replaced on each run. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **Row Count** | 4,068 rows (622 distinct campaigns × ~6.5 state versions; 12 accounts; latest update 2026-04-13) |

---

## 1. Business Meaning

`BI_DB_Bing_PBI_Campaign_Dict` is a Bing Ads campaign reference table used to enrich Microsoft Advertising (Bing Ads) performance reports in Power BI. It maps campaign IDs to their names, budget allocations, account affiliations, statuses, and bidding strategies.

The table follows a **history-feed pattern**: the Fivetran source (`External_Fivetran_bingads_campaign_history`) appends a new row each time a campaign is modified in Bing Ads (status change, budget update, bid strategy change). The SP deduplicates exact duplicates via GROUP BY but retains all unique historical states, so a single campaign ID can appear multiple times at different `_fivetran_synced` timestamps.

**Campaign naming convention** (from sample data) follows: `{Country}_{Brand/NB}_{CampaignType}__{Targeting}__{Language}_{CampaignID}`. Example: `AU_NB_DSA_______EN_70279` = Australia, Non-Brand, Dynamic Search Ads, English.

**Current distribution (as of 2026-04-13)**:
- **Status**: Active (2,153 rows), Paused (1,074), BudgetPaused (722), Deleted (104), BudgetAndManualPaused (15)
- **Bid Strategy**: EnhancedCpc (2,564), TargetCpa (1,126), ManualCpc (212), TargetRoas (35), MaxConversions (15), MaxClicks (6), MaxConversionValue (6)
- **Accounts**: 12 distinct Bing Ads account IDs
- **Fivetran history spans**: 2021-09-22 to present

---

## 2. Business Logic

### 2.1 Full Snapshot Replace Pattern

**What**: SP_Bing_PBI truncates and reloads the entire Campaign_Dict table daily.
**Columns Involved**: All
**Rules**:
- `TRUNCATE TABLE BI_DB_Bing_PBI_Campaign_Dict` before each INSERT — no incremental merge
- Source: `External_Fivetran_bingads_campaign_history` — all rows, no date filter
- GROUP BY all columns deduplicates exact-duplicate rows only; all unique state versions are retained
- Result: every execution replaces the table with the full history from Fivetran

### 2.2 History-Feed Row Semantics

**What**: Each row represents one point-in-time state of a campaign (not the latest state only).
**Columns Involved**: id, status, budget, bid_strategy_type, _fivetran_synced
**Rules**:
- Source table is `*_history` — Fivetran history tables capture each API response that differs from the prior
- `_fivetran_synced` is when Fivetran captured that state from Bing Ads API
- Same campaign `id` can appear N times with different status/budget/bid strategy values
- To get the latest state per campaign: `WHERE _fivetran_synced = (SELECT MAX(_fivetran_synced) FROM ... WHERE id = outer.id)`

### 2.3 Numeric Precision Truncation

**What**: budget, bid_strategy_max_cpc, and bid_strategy_target_cpa are stored as numeric(18,0) — no decimal places.
**Columns Involved**: budget, bid_strategy_max_cpc, bid_strategy_target_cpa
**Rules**:
- numeric(18,0) truncates any fractional amount at INSERT
- Bing Ads bids (CPC, CPA) may have sub-unit precision in the source — that precision is lost here
- budget values represent daily budget in the account's currency (USD, EUR, etc.)
- bid_strategy_max_cpc / bid_strategy_target_cpa are NULL when the bid strategy type does not use those parameters (e.g., EnhancedCpc campaigns do not use a target CPA)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP. At 4,068 rows this is a micro reference table. No distribution or index tuning is needed. HEAP is intentional for small frequently-truncated tables.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| "Latest state for each campaign?" | `SELECT * FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY id ORDER BY _fivetran_synced DESC) AS rn FROM BI_DB_Bing_PBI_Campaign_Dict) t WHERE rn = 1` |
| "All campaigns for an account?" | `WHERE account_id = <id>` |
| "All active campaigns?" | `WHERE status = 'Active'` (beware: multiple rows per campaign — consider latest-state filter) |
| "Campaigns using TargetCpa strategy?" | `WHERE bid_strategy_type = 'TargetCpa'` |
| "Join to performance table by campaign?" | JOIN to BI_DB_Bing_PBI_Daily_Perf on `id = campaign_id` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Bing_PBI_Daily_Perf | `Campaign_Dict.id = Daily_Perf.campaign_id` | Attach campaign name/budget/strategy to daily performance metrics |
| BI_DB_Bing_PBI_Group_Dict | `Group_Dict.campaign_id = Campaign_Dict.id` | Attach ad group definitions to campaigns |

### 3.4 Gotchas

- **History-feed: id is NOT unique** — 622 distinct campaign IDs across 4,068 rows. If you join to a performance table on campaign ID without filtering to latest state, you will get fan-out duplicates. Always apply a latest-state filter or `ROW_NUMBER()` before joining.
- **TRUNCATE+INSERT daily** — the table is fully replaced every day. Any query depending on "was this campaign present yesterday?" cannot rely on this table for historical existence. Use `_fivetran_synced` to reason about when a campaign state was active.
- **numeric(18,0) precision loss** — bid values and budgets may have been fractional in Bing Ads; they are truncated to integers here. Do not use these fields for precise bid reconstruction.
- **bid_strategy_max_cpc NULL** — this field is NULL for campaigns that don't use a max CPC cap (TargetCpa, MaxConversions, etc.). Null does not mean "no bid cap" in all cases.
- **status 'Deleted' rows** — campaigns with status='Deleted' (104 rows) still appear in the table. If you want active-only, filter `WHERE status = 'Active'`.
- **Account currency is not stored** — the table does not include account currency; budget and bid amounts must be interpreted in the context of the account's configured currency (not necessarily USD).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| **Tier 1** | Description copied verbatim from upstream wiki |
| **Tier 2** | Derived from SP code analysis or DWH ETL logic |
| **Tier 3** | Inferred from data patterns; no SP confirmation |
| **Tier 4** | Best available knowledge; limited evidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | id | int | YES | Bing Ads campaign ID. Unique identifier in the Bing Ads platform. NOT unique in this table — same campaign appears multiple times as its state changes (history-feed pattern). (Tier 2 — SP_Bing_PBI) |
| 2 | budget | numeric(18,0) | YES | Daily campaign budget in the account's configured currency. Stored as integer (numeric(18,0) — decimal truncated). Reflects the budget as of the Fivetran sync captured in `_fivetran_synced`. (Tier 2 — SP_Bing_PBI) |
| 3 | account_id | bigint | YES | Bing Ads account ID this campaign belongs to. 12 distinct accounts present. Maps to a Bing Ads account (advertiser account), not a customer ID in eToro systems. (Tier 2 — SP_Bing_PBI) |
| 4 | status | varchar(max) | YES | Campaign status at the time of Fivetran sync. Five values: Active, Paused, BudgetPaused, Deleted, BudgetAndManualPaused. BudgetPaused = system-paused due to budget exhaustion; BudgetAndManualPaused = both conditions apply. (Tier 2 — SP_Bing_PBI) |
| 5 | name | varchar(max) | YES | Campaign name as configured in Bing Ads. Follows naming convention: `{Country}_{Brand/NB}_{Type}__{Targeting}__{Language}_{ID}`. Example: `AU_NB_DSA_______EN_70279`. (Tier 2 — SP_Bing_PBI) |
| 6 | bid_strategy_max_cpc | numeric(18,0) | YES | Maximum cost-per-click bid cap for the campaign's bid strategy. NULL for strategies that do not use a max CPC cap (TargetCpa, MaxConversions, MaxClicks, MaxConversionValue). Stored as integer (decimal truncated). (Tier 2 — SP_Bing_PBI) |
| 7 | bid_strategy_target_cpa | numeric(18,0) | YES | Target cost-per-acquisition for TargetCpa bid strategies. NULL for campaigns using other strategy types. Stored as integer (decimal truncated). Units: account currency. (Tier 2 — SP_Bing_PBI) |
| 8 | bid_strategy_type | varchar(max) | YES | Bidding strategy type. Seven values observed: EnhancedCpc (2,564 rows), TargetCpa (1,126), ManualCpc (212), TargetRoas (35), MaxConversions (15), MaxClicks (6), MaxConversionValue (6). NULL for Deleted campaigns. (Tier 2 — SP_Bing_PBI) |
| 9 | _fivetran_synced | datetime | YES | Fivetran metadata: timestamp when this campaign state was synced from the Bing Ads API by Fivetran. Used to determine the chronological order of campaign state changes. Earliest value: 2021-09-22. (Tier 2 — SP_Bing_PBI) |
| 10 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_Bing_PBI. All rows in the table share the same UpdateDate from the most recent daily TRUNCATE+INSERT run (2026-04-13). (Tier 2 — SP_Bing_PBI) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| id | External_Fivetran_bingads_campaign_history | id | Pass-through |
| budget | External_Fivetran_bingads_campaign_history | budget | Pass-through (numeric(18,0) truncates decimal) |
| account_id | External_Fivetran_bingads_campaign_history | account_id | Pass-through |
| status | External_Fivetran_bingads_campaign_history | status | Pass-through |
| name | External_Fivetran_bingads_campaign_history | name | Pass-through |
| bid_strategy_max_cpc | External_Fivetran_bingads_campaign_history | bid_strategy_max_cpc | Pass-through (numeric(18,0) truncates decimal) |
| bid_strategy_target_cpa | External_Fivetran_bingads_campaign_history | bid_strategy_target_cpa | Pass-through (numeric(18,0) truncates decimal) |
| bid_strategy_type | External_Fivetran_bingads_campaign_history | bid_strategy_type | Pass-through |
| _fivetran_synced | External_Fivetran_bingads_campaign_history | _fivetran_synced | Pass-through (Fivetran metadata) |
| UpdateDate | ETL system | GETDATE() | Insert timestamp |

### 5.2 ETL Pipeline

```
Bing Ads API (campaign definitions via Microsoft Advertising API)
  |
  |-- Fivetran bingads connector ---|
  |   History-mode sync: appends a row per campaign state change
  v
BI_DB_dbo.External_Fivetran_bingads_campaign_history
  (all columns, full history from 2021-09-22 onward)
  |
  |-- SP_Bing_PBI(@date) — daily, SB_Daily Priority 20 ---|
  |   TRUNCATE TABLE BI_DB_Bing_PBI_Campaign_Dict
  |   INSERT SELECT id, budget, account_id, status, name,
  |     bid_strategy_max_cpc, bid_strategy_target_cpa,
  |     bid_strategy_type, _fivetran_synced, GETDATE()
  |   FROM External_Fivetran_bingads_campaign_history
  |   GROUP BY all cols (dedup exact duplicates only)
  v
BI_DB_dbo.BI_DB_Bing_PBI_Campaign_Dict
  (4068 rows, 622 distinct campaigns, 12 accounts, history from 2021-09-22)
  |
  |-- UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| (source) | BI_DB_dbo.External_Fivetran_bingads_campaign_history | Fivetran-managed external table with full Bing Ads campaign history |

### 6.2 Referenced By

No SPs or views in the SSDT repo reference this table directly (SP_Bing_PBI writes to it; no reader SPs found). Consumed directly by Power BI dashboards for Bing Ads marketing reporting.

---

## 7. Sample Queries

### Latest state for each campaign

```sql
SELECT id, budget, account_id, status, name, bid_strategy_type
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY id ORDER BY _fivetran_synced DESC) AS rn
    FROM [BI_DB_dbo].[BI_DB_Bing_PBI_Campaign_Dict]
) t
WHERE rn = 1;
```

### All active campaigns by account

```sql
SELECT account_id, id, name, budget, bid_strategy_type
FROM [BI_DB_dbo].[BI_DB_Bing_PBI_Campaign_Dict]
WHERE status = 'Active'
ORDER BY account_id, name;
```

### Campaign state history for a specific campaign

```sql
SELECT id, status, budget, bid_strategy_type, _fivetran_synced
FROM [BI_DB_dbo].[BI_DB_Bing_PBI_Campaign_Dict]
WHERE id = 614031374
ORDER BY _fivetran_synced;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources searched (Phase 10 skipped). SP header comment: authored by Jan Iablunovskey (2022-05-01), description "Data from bing for Power BI reports". No additional business context in SP code.

---

*Generated: 2026-04-21 | Quality: 8.5/10 | Phases: 12/14 (P7 Views, P10 Jira skipped)*
*Tiers: 0 T1, 10 T2, 0 T3, 0 T4 | Elements: 10/10 | Logic: 3 subsections*
*Object: BI_DB_dbo.BI_DB_Bing_PBI_Campaign_Dict | Type: Table | Production Source: External_Fivetran_bingads_campaign_history via SP_Bing_PBI*
