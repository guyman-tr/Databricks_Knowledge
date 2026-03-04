# Handoff: Dim_Position Wiki — Second Run

> Written by the first-run agent after a detailed debriefing with the user.
> Read this BEFORE doing anything.

## Your Task

Re-generate the semantic wiki for `DWH_dbo.Dim_Position` and its Databricks ALTER script. The first run produced output with significant quality issues. You are doing a **corrected second run**.

## Files to Read First (in order)

1. **`knowledge/first-run-results.md`** — The debriefing findings. Contains 13 specific errors and 5 systemic issues. Read the full thing. This is your primary guide for what NOT to do.
2. **`knowledge/canonical-schema.md`** — The canonical metadata schema.
3. **`.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc`** — The Phase 11 template (the "constitution"). Pay special attention to rule #9 (CODE IS KING hierarchy) and rule #3 (no runtime statistics).
4. **`.cursor/rules/dwh-semantic-doc/04-lookup-resolution.mdc`** — Phase 4 rules. Start from upstream wiki.
5. **`dwh-semantic-doc-config.json`** in `.specify/Configs/` — upstream wiki paths.

## What the First Run Got Right

- **Synapse connectivity**: `synapse_connect.py` works. Use it for any Synapse queries. Read `C:\Users\guyman\.cursor\skills\synapse-connection\SKILL.md` for auth details.
- **Phase 1-3 raw data**: Structure, sampling, and distribution queries were run successfully. Results are in `phase3_output.txt`, `phase3_output2.txt`, `phase3_output_p4_8.txt`, `phase3_output_p5_8.txt` in the repo root. You can reuse this data.
- **Phase 4 lookup tables**: `Dim_ClosePositionReason` (27 values), `Dim_RedeemStatus` (13 values), `OpenPositionActionType` (20 values) were all queried and captured in the output files.
- **Phase 5/7/8 metadata**: ~240 SPs and 2 views referencing Dim_Position were identified. SP list and view definitions are in `phase3_output_p5_8.txt`. The ETL SP `SP_Dim_Position_DL_To_Synapse` definition (first 9000 chars) is in the quick output.
- **ETL lineage**: Fully traced — `Trade.PositionTbl` → Generic Pipeline → `DWH_staging.etoro_Trade_OpenPositionEndOfDay` + `DWH_staging.etoro_History_ClosePositionEndOfDay` → `SP_Dim_Position_DL_To_Synapse` → `DWH_dbo.Dim_Position`, plus post-load SPs (ReOpen, IsPartialCloseParent, HedgeType).

## What the First Run Got Wrong — Critical Rules for You

### Rule 1: UPSTREAM WIKI VERBATIM
For any column that exists in the upstream production wiki, **copy the description verbatim**. Do not paraphrase, summarize, or rewrite. Only APPEND DWH-specific notes if the DWH transforms that column differently.

The upstream wiki is at: `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\`

### Rule 2: SEARCH THE FULL UPSTREAM WIKI, NOT JUST THE TABLE FILE
The first run only read `Trade/Tables/Trade.PositionTbl.md`. Many columns come from:
- **Views**: `Trade/Views/Trade.Position.md`, `Trade/Views/Trade.OpenPositionEndOfDay.md`, `Trade/Views/Trade.PositionForExternalUse.md`, `Trade/Views/Trade.GetPositionDataForExternalUse.md`
- **Related tables**: `Trade/Tables/Trade.PositionTreeInfo.md` (has IsDiscounted, IsNoStopLoss, IsNoTakeProfit, IsTslEnabled)
- **History views**: `History/Views/History.Position.md`

**Before writing any column description**: grep the entire `DB_Schema\etoro\Wiki\` folder for the column name. If found anywhere, read that file and use the description.

### Rule 3: NEVER FABRICATE FROM COLUMN NAMES
If no source documents a column, do NOT invent a description. Instead:
- Flag it as `[UNVERIFIED]` in the wiki
- Add it to a `review-needed.md` sidecar file with the question for domain experts
- Write only what can be mechanically inferred (data type, nullability, observed values)

Specific columns the first run got wrong by guessing:
- `DLTOpen`/`DLTClose` — DLT is a German company (Tangany), NOT "Distributed Ledger Technology"
- `IsAirDrop` — don't assume "crypto airdrop"; could be broader
- `CommissionByUnits` — don't say "alternative to percentage-based"; it's in production views, read those
- `FullCommission` — don't add "before any splits"; upstream wiki doesn't mention splits
- `IsDiscounted` — it's NOT a commission discount, it's discounted spread pricing (VIP/partner). Lives on `Trade.PositionTreeInfo`

### Rule 4: SAMPLING ADDS, NEVER SUBTRACTS
When querying Synapse for enum values, start from the upstream wiki's documented values. Sampling only ADDS newly discovered values — never drop documented values because they didn't appear in a filtered sample. The first run dropped SettlementTypeID 2 (TRS) and 3 (CMT) because they filtered to 2025 data only.

### Rule 5: PHASE 9 MEANS READER SPs TOO
Read at least 10 downstream reader SPs for CASE/IF patterns on columns. These reveal business semantics independently (e.g., `CASE WHEN IsSettled = 1 THEN 'Real' ELSE 'CFD'`). The first run only read ETL writer SPs.

### Rule 6: PHASE 10 IS NOT OPTIONAL
Run the Atlassian Knowledge Scan. The tools are available. Search Confluence and Jira for "Dim_Position", "position", "settlement type", "copy trade", etc.

### Rule 7: NO RUNTIME STATISTICS IN DESCRIPTIONS
Phase 11 rule #3: "No environment-specific statistics." Don't write "~85% Buy", "~69% leverage=1", "~79% settled", "2.64B rows" in the Elements table. These belong in query advisory or working notes, not in column descriptions.

### Rule 8: CONFIDENCE TIERS
Tag each description's source:
- **Tier 1**: Upstream wiki verbatim
- **Tier 2**: Synapse SP code / downstream CASE patterns  
- **Tier 3**: Live data distribution
- **Tier 4**: Column name inference → must be flagged `[UNVERIFIED]`

### Rule 9: GENERATE A REVIEW SIDECAR
Produce `DWH_dbo.Dim_Position.review-needed.md` alongside the wiki, listing all Tier 4 / unresolved items with specific questions for domain experts.

## Output Files to Produce

1. `knowledge/synapse/Wiki/DWH_dbo/Tables/DWH_dbo.Dim_Position.md` — Corrected wiki (overwrite existing)
2. `knowledge/synapse/Wiki/DWH_dbo/Tables/DWH_dbo.Dim_Position.alter.sql` — Corrected Databricks ALTER script (overwrite existing)
3. `knowledge/synapse/Wiki/DWH_dbo/Tables/DWH_dbo.Dim_Position.review-needed.md` — New: unresolved items for expert review

## Spec 006 Note

The user confirmed that compressed 1024-char descriptions combining meaning + lineage (Spec 006, tasks T046-T052) are a later phase, NOT part of this run. Don't attempt it. The `.alter.sql` should use the best description available, but the 1024-char compression is separate work.

## Previous Conversation Reference

Full transcript of the first run + debriefing: `C:\Users\guyman\.cursor\projects\c-Users-guyman-Documents-github-Databricks-Knowledge\agent-transcripts\56e3708b-4b48-42b0-9b32-c9ba80530331.txt`

Search for "first-run-results" or specific column names if you need to understand the debriefing context.
