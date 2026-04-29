MCP PRE-FLIGHT: PASS

Now loading all required rule files and the DDL in parallel.
Rules loaded. DDL confirms 3 columns: `MoveMoneyReasonID`, `MoveMoneyReason`, `UpdateDate`. Simple dictionary table — using fast-path: P1→P2→P8→P4→P10A→P10B→P11.

**PHASE 1 CHECKPOINT: PASS** — 3 columns, REPLICATE distribution, clustered index on MoveMoneyReasonID.

Now running P2 (sampling) and P8 (SP scan) in parallel.
**PHASE 2 CHECKPOINT: PASS** — 4 rows total. IDs: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 4=Airdrop. All UpdateDate = 2022. Notable: upstream wiki documents IDs 1-9, DWH only has 4 rows. ID 4 is "Airdrop" here (upstream said ID 4 was missing).

**PHASE 8 CHECKPOINT: PASS** — No dedicated writer SP found in DWH_dbo Stored Procedures. No views reference this table. Checking for SP_Dictionaries.
Let me check the staging table and find the SP_Dictionaries loader.
Good. Full picture assembled:
- **Source**: `etoro.Dictionary.MoveMoneyReason` via Generic Pipeline (Override, daily)
- **Staging**: `DWH_staging.etoro_Dictionary_MoveMoneyReason` (2 cols: MoveMoneyReasonID, MoveMoneyReason)
- **No dedicated writer SP** — loaded via generic dictionary process, `UpdateDate` added during ETL
- **UC Gold**: `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason`
- **Data staleness**: DWH has only 4 rows (IDs 1-4), production has at least 9 reason codes. Last updated 2022.

**PHASE 4 CHECKPOINT: PASS** — MoveMoneyReasonID → Dictionary.MoveMoneyReason lookup resolved.
**PHASE 10 CHECKPOINT: PASS** [-] — Low value for simple dictionary, skipped per fast-path.
**PHASE 10A CHECKPOINT: PASS** — Upstream wiki: `Dictionary.MoveMoneyReason` from DB_Schema/etoro.

Now proceeding through remaining gates and writing output.

```
PHASE GATE CHECK — Dim_MoveMoneyReason [SIMPLE-DICT]:
  [x] P1 DDL   [x] P2 Sample   [-] P3 Dist (4-row dictionary, trivial)
  [x] P4 Lookup
  [-] P5 JOIN  [-] P6 BizLogic [-] P7 Views  [x] P8 SP-scan
  [-] P9 SP-logic [-] P9B ETL  [-] P10 Jira  [x] P10A Upstream  [x] P10B Lineage
  → Ready for P11
```
Good, the directory exists. Writing the three files now — lineage first, then wiki, then review-needed.
T1 COPY VERIFICATION:
- MoveMoneyReasonID: upstream 30 words → wiki 30 words — IDENTICAL (stats stripped: none)
- MoveMoneyReason: upstream 22 words → wiki 22 words — IDENTICAL (stats stripped: none)

```
OUTPUT CHECK — DWH_dbo.Dim_MoveMoneyReason:
  [x] .lineage.md    written → audits/regen-sample/DWH_dbo/Dim_MoveMoneyReason/regen/attempt_1/Dim_MoveMoneyReason.lineage.md
  [x] .md            written → audits/regen-sample/DWH_dbo/Dim_MoveMoneyReason/regen/attempt_1/Dim_MoveMoneyReason.md
  [x] .review-needed.md written → audits/regen-sample/DWH_dbo/Dim_MoveMoneyReason/regen/attempt_1/Dim_MoveMoneyReason.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 2    Tier2: 1    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
