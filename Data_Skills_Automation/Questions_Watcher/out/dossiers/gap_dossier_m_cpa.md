# Gap Dossier: `m:cpa`

**Signature:** `m:cpa`  
**Intent:** cpa by country, month, region, quarter  
**Coverage status:** underserved  
**Frequency:** low | **Distinct users:** few  
**Current top routed skill:** none (MCP gateway scores 0.31–0.33, below floor; Genie has no skill router match)

---

## 1. Intent summary

Users ask for **cost per acquisition (CPA)** rolled up by geographic and temporal classifiers — country, region, month, and quarter — often in diagnostic mode: explain a CPA decline, identify which regions drove inflation, compare quarter-over-quarter, or locate the tables that hold marketing budget / spend data supporting CPA. Some questions extend into **driver decomposition** (CPC inflation vs weaker conversion quality).

The denoised cluster examples:

- i see a decline in cpa can you explain why by country and quarter
- what tables contain marketing budget or cost data for latam monthly marketing spend by country or region cpa
- which regions contributed most to cpa inflation did cpa pressure come from cpc inflation or weaker conversion quality compare reg by region

---

## 2. Why current skills fall short

### 2.1 Nearest hub exists but does not answer CPA rollup questions

`domain-marketing-and-acquisition` (sub-skill `affiliate-and-paid-media.md`) is the closest hub. Gateway logs show it is occasionally returned for CPA prompts but with **scores below the routing floor** (0.31–0.33 in fixtures; `skills_all_below_floor: true`), so users effectively get **no skill**.

### 2.2 Canonical CPA data is not anchored in skills

The production CPA metric is computed and consumed from the **marketing performance cube**, not from objects currently listed as `required_tables` in the marketing skill:

| Lens | Canonical object | CPA definition in production |
|------|------------------|------------------------------|
| **Marketing cube (primary)** | `BI_DB_MarketingDailyRawData` / `BI_DB_MarketingMonthlyRawData` | Tableau **Marketing Hierarchy Report**: `CPA = SUM(TotalCost) / SUM(FTD)`; also `eCPA = SUM(eCost) / SUM(EFTD)` |
| **Paid-media channel view** | `v_marketing_campaigns_social` / `v_marketing_campaigns_google` | `cost_per_ftd = SUM(Cost) / SUM(FTD_Count)` at Region × Channel × Date (no country grain) |
| **Finance / OPS** | `BI_DB_CIDFirstDates` + LTV joins | Workbook *CPA and LTV per region - for cost of OPS* |

The marketing skill documents `cost-per-FTD` on `v_marketing_campaigns_*` and affiliate lifecycle counters on `dim_affiliate_masked`, but **does not document**:

- UC FQNs for the marketing cube tables
- The `TotalCost`, `CPA_Comm`, `FTD`, `EFTD`, `Registration` column semantics
- The canonical CPA formula (`TotalCost / FTD`) vs `CPA_Comm` (commission subtype only)
- `Region` vs `NewMarketingRegion` (geographic vs marketing-curated taxonomy)
- Monthly (`YearMonth` / `YearMonthID`) vs daily (`Date` / `DateID`) vs quarterly rollups
- **Scope warning:** cube `FTD` is **affiliate-attributed FTDs only** (Fiktivo Tier-1 credits), not all platform FTDs

### 2.3 Trigger vocabulary gap

Skill triggers emphasize affiliate platform, paid campaigns, live acquisition dashboard, and `dim_affiliate_masked`. They lack high-signal CPA triggers: `cpa`, `cost per acquisition`, `marketing spend`, `marketing budget`, `marketing hierarchy`, `marketing cube`, `total cost`, `cpa_comm`, `ecpa`.

### 2.4 Diagnostic / decomposition questions unaddressed

Example questions ask whether CPA pressure came from **CPC inflation** or **weaker conversion quality**. The cube supports decomposition via:

- Cost side: `TotalCost`, `CPA_Comm`, `eCost`, `RevShare_Comm`, `CPL_Comm`
- Conversion side: `Registration`, `FTD`, `EFTD`, `SameDayFTD`, `VerificationLevelID2/3`, `IsRev`, `Redeposits`

No skill documents these decomposition patterns or the double-counting risk between cube FTDs and `v_marketing_campaigns_*` FTDs.

### 2.5 Related partial clusters

`m:cpa+ftd` and `m:active_traders+cpa+deposits+ftd+net_deposits+revenue` are marked **partial** — users bundle CPA with other KPIs in regional scorecards. A focused CPA sub-skill would still benefit those clusters via shared anchors.

---

## 3. Investigation evidence

### 3.1 Unity Catalog / Synapse wikis

| FQN | Role | Key classifiers |
|-----|------|-----------------|
| `main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db__marketing_daily_raw_data` | Daily marketing cube (~12M rows, ~2yr window) | `CountryName`, `Region`, `NewMarketingRegion`, `Date`, `DateID`, `Channel`, `SubChannel` |
| `main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db__marketing_monthly_raw_data` | Monthly rollup (~2.4M rows, ~5yr window) | `CountryName`, `Region`, `NewMarketingRegion`, `YearMonth`, `YearMonthID` |
| `main.etoro_kpi_stg.v_marketing_campaigns_social` | Paid social spend + FTDs (Region × Channel × Date) | `Region`, `Channel`, `Cost`, `FTD_Count` |
| `main.etoro_kpi_stg.v_marketing_campaigns_google` | Paid Google spend + FTDs (Region × Channel × Date) | `Region`, `Channel`, `Cost`, `FTD_Count` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked` | Affiliate dimension; `ContractType` encodes CPA vs RevShare vs Hybrid | `Region`, `Channel`, `SubChannel`, pre-aggregated lifecycle counters (not for time-series CPA) |

Synapse wiki (`knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_MarketingDailyRawData.md`) confirms ETL via `SP_Marketing_Cube`, grain `AffiliateID × CountryID × Date × Funnel`, and cost columns `TotalCost` (all commission types) vs `CPA_Comm` (CPA credits only).

### 3.2 Tableau (via `knowledge/tableau/` metadata)

| Workbook | Anchor table | CPA logic |
|----------|--------------|-----------|
| **Marketing Hierarchy Report** (Acquisition, active) | `BI_DB_MarketingDailyRawData` | Calc field `CPA`: `SUM([Total Cost]) / SUM(FTD)` |
| **Marketing Hierarchy Report** | same | Calc field `eCPA`: eCost / EFTD variant |
| **CPA and LTV per region - for cost of OPS** | `BI_DB_CIDFirstDates`, `BI_DB_LTV_Predictions` | Region-level CPA for finance planning |

Tableau metadata (`knowledge/tableau/unknown_db__unknown_schema/BI_DB_MarketingDailyRawData.md`) confirms 4 downstream workbooks; the active canonical report is **Marketing Hierarchy Report**.

### 3.3 Confluence / Jira

Atlassian MCP was unavailable in this run. Offline wiki cross-refs found:

- `Dim_ContractType` Confluence: CPA = Cost Per Acquisition (flat fee per qualifying deposit)
- `dim_affiliate_masked` upstream wiki: ContractType 2 = CPA payment model
- Fiktivo affiliate system docs (ExperianceDBs): `tblaff_CPA`, CPA commission tiers

These clarify **affiliate-contract CPA** vs **marketing-efficiency CPA** (spend / FTD) — a common source of user confusion the skill must disambiguate.

---

## 4. Proposed placement

**Recommendation: new sub-skill under existing hub `domain-marketing-and-acquisition`**

Proposed file: `knowledge/skills/domain-marketing-and-acquisition/marketing-performance-cube-and-cpa.md`

Rationale:

| Option | Verdict |
|--------|---------|
| New super-domain | **Reject** — data, ETL, and Tableau consumers already live inside marketing & acquisition |
| Extend `affiliate-and-paid-media.md` | **Partial** — file is already long; CPA cube is a distinct analytical layer (country × time rollup) vs affiliate platform / paid-media vendor detail |
| Cross-domain skill | **Reject** — no second domain owns the cube; finance OPS workbook is a downstream consumer, not the source of truth |

**Cross-links:** `affiliate-and-paid-media.md` (channel/vendor lens), `registration-to-ftd-funnel.md` (full-platform FTD counts when cube scope is too narrow), future `domain-finance-and-treasury` (P&L marketing spend allocation).

---

## 5. Candidate anchor UC tables (FQNs)

**Primary (must-have):**

1. `main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db__marketing_monthly_raw_data` — default for quarter/month CPA by country/region (`YearMonthID` → quarter)
2. `main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db__marketing_daily_raw_data` — when user asks by month/week or needs finer drill-down

**Secondary (paid-media lens, region-level only):**

3. `main.etoro_kpi_stg.v_marketing_campaigns_social`
4. `main.etoro_kpi_stg.v_marketing_campaigns_google`

**Reference / disambiguation:**

5. `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked` — affiliate contract type (CPA vs RevShare), not for time-series CPA ratios
6. `main.bi_output.bi_output_marketing_liveacquisitiondashboard` — per-CID funnel when user needs conversion-quality drill-down beyond cube aggregates

---

## 6. Proposed triggers

```
cpa
cost per acquisition
marketing spend
marketing budget
marketing cost
marketing hierarchy
marketing cube
marketing daily raw
marketing monthly raw
bi_db_marketingdailyrawdata
bi_db_marketingmonthlyrawdata
total cost
cpa_comm
ecpa
cost per ftd
cpc inflation
conversion quality
marketing performance
```

---

## 7. Sample questions (denoised)

1. cpa by country per quarter
2. what tables contain marketing budget or cost data for monthly marketing spend by country or region cpa
3. i see a decline in cpa can you explain why by country and quarter
4. which regions contributed most to cpa inflation — did cpa pressure come from cpc inflation or weaker conversion quality compare by region
5. cpa cost per acquisition by country per month for marketing

---

## 8. Skill content outline (for future authoring — not in scope here)

1. **Disambiguation tier:** marketing-efficiency CPA (`TotalCost / FTD`) vs `CPA_Comm` column vs affiliate `ContractType = CPA`
2. **Grain selection:** monthly cube for quarter rollups; daily for intra-month; prefer `NewMarketingRegion` when user says "marketing region"
3. **Canonical SQL pattern:** `SUM(TotalCost) / NULLIF(SUM(FTD), 0)` grouped by country/region and time bucket
4. **Scope footer:** cube FTDs are affiliate-attributed only; cite Marketing Hierarchy Report as production reference
5. **Decomposition pattern:** cost components vs conversion funnel metrics for "why did CPA rise" questions
6. **Anti-pattern:** do not sum `dim_affiliate_masked.FTDThisQuarter` for time-series CPA; do not double-count with `v_marketing_campaigns_*`

---

*Generated by Questions Interest Tracker. Proposal only — no skill files authored.*
