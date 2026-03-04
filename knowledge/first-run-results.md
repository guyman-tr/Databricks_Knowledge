# First Run Results — Dim_Position POC Debriefing

> Post-generation review of `DWH_dbo.Dim_Position.md` wiki and `.alter.sql` outputs.
> Date: 2026-03-01

## Findings Table

| # | Column / Area | What Went Wrong | Root Cause | Recommendation |
|---|--------------|-----------------|------------|----------------|
| 1 | **Confluence scan skipped** | Phase 10 (Atlassian Knowledge Scan) was skipped entirely. No Jira/Confluence context gathered for a table referenced by ~240 SPs across BI, compliance, dealing, and finance. | Misjudged POC scope — prioritized speed over completeness. | **Mandate**: Phase 10 is not optional. The constitution must list it as a required phase, not deferrable. |
| 2 | **Amount** | Described as "in cents" — it's in dollars. | Confused `Amount` (dollars) with `InitialAmountCents` (cents). Upstream wiki clearly says "Customer's invested amount in account currency (USD-equivalent)." Live data also showed dollar-scale values. | **Use upstream wiki verbatim** for any column that exists in production. Don't paraphrase. |
| 3 | **FullCommission** | Described as "before any splits" — splits are irrelevant. | Invented context. Upstream wiki says "Total commission at position open, including all components." No mention of splits anywhere. | **Never add context not found in a source.** If the upstream wiki description is complete, use it as-is. |
| 4 | **IsSettled** | Described as "Whether settlement is complete" — wrong meaning. It's a legacy real-ownership indicator (1=owns asset, 0=CFD/synthetic). Also included a runtime statistic ("~79%") violating Phase 11 rule #3. | Paraphrased from column name instead of reading upstream wiki, which has a detailed code-traced description. | **Use upstream wiki verbatim.** Also: enforce Phase 11 rule #3 (no environment-specific statistics) in constitution. |
| 5 | **SettlementTypeID** | Listed only 4 values (0,1,4,5), dropping TRS=2 and CMT=3. | Sampled only 2025 data (`WHERE OpenDateID > 20250101`). Rare values in older data were missed. Upstream wiki documents all 6. | **Sampling must ADD to upstream wiki, never SUBTRACT.** Start with upstream enum, then note any additional values found in DWH. |
| 6 | **IsDiscounted** | Labeled as "DWH-specific flag" — it's a production column from `Trade.PositionTreeInfo`. Description ("commission discount") is wrong; it controls discounted spread pricing (VIP/partner). | Only searched `Trade.PositionTbl.md`. Column lives on `Trade.PositionTreeInfo` and related tables. Also had the correct info in captured SP output (Guy M's own comment about IsDiscounted). | **Before labeling anything DWH-specific, grep the entire upstream wiki + repo for the column name.** Also: read all captured Phase 8 SP output, not just skim. |
| 7 | **CommissionByUnits** | Described as "alternative to percentage-based" — fabricated. | No upstream wiki entry found in table-level wiki. Column exists in production views (`Trade.Position`, `Trade.PositionForExternalUse`) with their own wiki files — never checked. | **Expand upstream wiki search to views and related objects**, not just the source table wiki. The DWH staging sources are views, not tables. |
| 8 | **PnLVersion** | Not incorrect (0=CFD, 1=REAL) but stripped of all useful context about what the formulas actually mean and how they differ. | Paraphrased instead of using upstream wiki verbatim. Lost the function reference (`Trade.FnCalculatePnL`), the source reference (`Defs.PnlVersion` enum), and the settlement-type relationship. | **Use upstream wiki verbatim**, append DWH-specific notes only if needed. |
| 9 | **CloseMarkupOnOpen, OpenMarkup, CloseMarkup** | Descriptions are just column-name-to-English translations. Upstream wiki has richer context (currency units, relationship to other cost columns, which SP sets them). | Paraphrased instead of inheriting upstream descriptions. | **Use upstream wiki verbatim.** |
| 10 | **DLTOpen / DLTClose** | Described as "Distributed Ledger Technology — crypto on-chain." DLT is actually a German company (Tangany) used for real crypto execution routing. Also incorrectly labeled as DWH-specific. | Guessed acronym meaning from general tech knowledge. Column exists in production views (`Trade.PositionForExternalUse`). Never verified. | **Never expand acronyms or infer domain meaning from general knowledge.** If no source explains it, flag as "unresolved" rather than guess. |
| 11 | **IsAirDrop** | Described as "crypto airdrop event" — guessed from column name. Could mean something more specific in eToro context. | No upstream wiki entry. Assumed crypto-industry meaning. Production has `Trade.PositionAirdrop` SP and `Trade.PayCashAirdropByPayDateAndTerminalID` suggesting broader scope. | **Same as #10**: don't guess, flag as unresolved. Read related production objects when they exist. |
| 12 | **Close_PnLInDollars** | Described as "P&L in dollars at close" — just restating column name. No explanation of how it differs from `PnLInDollars` or `NetProfit`. | Column comes from `Trade.OpenPositionEndOfDay` view (which has its own wiki). Never read that wiki. | **Read the staging source view wikis** — `Trade.OpenPositionEndOfDay.md` and `History.ClosePositionEndOfDay.md` are direct upstream sources for the DWH ETL. |
| 13 | **Downstream SP analysis missing** | Never scanned reader SPs for `CASE WHEN` patterns that reveal column semantics (e.g., `CASE WHEN IsSettled = 1 THEN 'Real' ELSE 'CFD'`). | Phase 9 was marked complete but only ETL writer SPs were read. Downstream consumer analysis was skipped. | **Phase 9 must include top 10 reader SPs**, scanning for CASE/IF patterns on each column. This is independent validation. |

## Systemic Issues

### 1. Paraphrasing vs. Verbatim Inheritance
**Pattern**: For columns that exist in both production and DWH, the upstream wiki already has code-validated, source-traced descriptions. The agent paraphrased these from scratch, introducing errors, losing context, and fabricating details.

**Fix**: Hardline constitution rule — for any column matching an upstream wiki column, copy the description verbatim. Only append DWH-specific notes (e.g., "DWH-derived from X" or "renamed from Y"). Never rewrite.

### 2. Narrow Upstream Search Scope
**Pattern**: Only `Trade.PositionTbl.md` was searched. The DWH actually sources from views (`Trade.OpenPositionEndOfDay`, `History.ClosePositionEndOfDay`) and columns come from related tables (`Trade.PositionTreeInfo`, `Trade.Orders`). These all have wiki files that were never read.

**Fix**: Constitution must require reading the staging source view wikis (not just the base table wiki) and grepping the full upstream wiki folder before labeling any column as unresolved or DWH-specific. This is a simple `grep` — no vectorization needed. The wiki folder structure is predictable (`{schema}/Tables/`, `{schema}/Views/`).

### 3. Fabrication from Column Names
**Pattern**: When no source was found, the agent generated plausible-sounding descriptions from column names. These read confidently but are unreliable (DLT, IsAirDrop, CommissionByUnits, FullCommission "splits").

**Fix**: Constitution must require a **confidence tier** on every description:
- **Tier 1**: Upstream wiki verbatim (highest confidence)
- **Tier 2**: Synapse SP code / downstream CASE patterns (high confidence)
- **Tier 3**: Live data distribution analysis (medium confidence)
- **Tier 4**: Column name inference (low confidence — must be flagged as "unverified")

Any Tier 4 description must be visually flagged in the output (e.g., `[UNVERIFIED]` prefix) so human reviewers can prioritize corrections.

### 4. Expert Review Loop
**Need**: Some knowledge cannot be derived from code or data alone (e.g., DLT = Tangany, PnLVersion formula differences, business context for airdrops). The pipeline needs a mechanism to surface unresolved or low-confidence items for expert review.

**Recommendation**: Generate a `review-needed.md` sidecar file alongside each wiki, listing all Tier 4 items and specific questions for domain experts. This is not interactive during generation — it's a post-generation review artifact.

### 5. Vectorization Assessment
**Not needed for the primary issues.** The upstream wiki files are in a predictable folder structure with predictable naming. A broader `grep` across the wiki folder solves the search scope problem. Vectorization would help for discovery of *unknown* relationships (e.g., "which SP explains this column?") but the current failures are all cases where a simple text search would have found the answer. Recommend revisiting vectorization only if the wiki corpus grows beyond what grep can efficiently handle, or if cross-object semantic discovery becomes a bottleneck.

---

*This document feeds back into the constitution (Phase 11 rules + pipeline phases) for the second run.*
