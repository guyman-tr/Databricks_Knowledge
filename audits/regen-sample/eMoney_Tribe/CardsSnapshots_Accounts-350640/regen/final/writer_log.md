MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline for `eMoney_Tribe.CardsSnapshots_Accounts-350640`.

**PHASE 1 — Structure Analysis** (from DDL in bundle)

Columns (8):
1. `@Id` — varchar(255), NULL, HASH distribution key, clustered index
2. `@CardsSnapshots_CardSnapshot@Id-140457` — varchar(max), NULL
3. `etr_y` — varchar(max), NULL
4. `etr_ym` — varchar(max), NULL
5. `etr_ymd` — varchar(max), NULL
6. `SynapseUpdateDate` — datetime, NULL
7. `Created` — datetime2(7), NULL
8. `partition_date` — date, NULL

Indexes: Clustered on `@Id`, NCI on `partition_date`, NCI on `@Id`.

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling) and Phase 8 (SP scan) in parallel.
PHASE 2 CHECKPOINT: PASS — 86.2M rows, date range 2023-12-20 to 2026-04-26, TOP 10 sampled.

**Phase 3 — Distribution Analysis**: Column regex check: `Status|Type|Code|Country|Region|Currency|Category|Reg|Score|Group|Kind|Class` — none of the 8 columns match. Zero distribution queries needed.

PHASE 3 CHECKPOINT: PASS

**Phase 4 — Lookup Resolution**: No *ID columns referencing Dim/Dict tables. All columns are structural/system.

PHASE 4 CHECKPOINT: PASS

**Phase 5 — JOIN Analysis**: From SP code, this table is used as an intermediate JOIN link:
- `CardsSnapshots_CardSnapshot-140457` (ab) → main source
- `CardsSnapshots-890718` (aa) → file metadata
- `CardsSnapshots_Accounts-350640` (ac) → **this table, JOIN bridge on `@Id`**
- `CardsSnapshots_Account-513255` (ad) → account-level detail columns

`LEFT JOIN [eMoney_Tribe].[CardsSnapshots_Accounts-350640] ac ON ac.[@Id] = ab.[@Id]`
`LEFT JOIN [eMoney_Tribe].[CardsSnapshots_Account-513255] ad ON ad.[@Id] = ac.[@Id]`

PHASE 5 CHECKPOINT: PASS

**Phase 6 — Business Logic**: This is a raw Tribe data ingestion table serving as a structural bridge between CardSnapshot and Account entities in the eMoney card snapshot hierarchy. No business transforms.

PHASE 6 CHECKPOINT: PASS

Now checking for views and verifying no other SPs reference this table.
**Phase 7 — View Dependencies**: No views reference this table.

PHASE 7 CHECKPOINT: PASS

**Phase 8 — SP Scan**: Only `eMoney_dbo.SP_eMoney_Reconciliation_ETLs` references this table (as a LEFT JOIN bridge). No writer SP populates it directly — data is ingested via the Generic Pipeline from Tribe.

PHASE 8 CHECKPOINT: PASS

**Phase 9 — SP Logic**: The table is consumed (read-only) in `SP_eMoney_Reconciliation_ETLs`. It provides no columns to the final output — it serves only as a JOIN key relay between `CardsSnapshots_CardSnapshot-140457` (`@Id`) and `CardsSnapshots_Account-513255` (`@Id`). No columns from this table appear in the `INSERT INTO ETL_CardSnapshot` statement.

PHASE 9 CHECKPOINT: PASS

**Phase 9B — ETL Orchestration**: Data arrives via Generic Pipeline (Tribe raw data export). The table is consumed by `SP_eMoney_Reconciliation_ETLs` which builds `ETL_CardSnapshot`.

PHASE 9B CHECKPOINT: PASS

**Phase 10 — Atlassian**: Skipping deep search for raw Tribe ingestion table. Low business context expected.

PHASE 10 CHECKPOINT: PASS

**Phase 10A — Upstream Wiki**: `_no_upstream_found.txt` present. No upstream wiki resolvable. Table is a raw Tribe data export.

PHASE 10A CHECKPOINT: PASS

Let me check the generic pipeline mapping for this table.
Now I have all the context. Let me print the phase gate and write the three output files.

```
PHASE GATE — eMoney_Tribe.CardsSnapshots_Accounts-350640:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
```
OUTPUT CHECK — eMoney_Tribe.CardsSnapshots_Accounts-350640:
  [x] .lineage.md    written → audits/regen-sample/eMoney_Tribe/CardsSnapshots_Accounts-350640/regen/attempt_1/CardsSnapshots_Accounts-350640.lineage.md
  [x] .md            written → audits/regen-sample/eMoney_Tribe/CardsSnapshots_Accounts-350640/regen/attempt_1/CardsSnapshots_Accounts-350640.md
  [x] .review-needed.md written → audits/regen-sample/eMoney_Tribe/CardsSnapshots_Accounts-350640/regen/attempt_1/CardsSnapshots_Accounts-350640.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 8    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists)
```
