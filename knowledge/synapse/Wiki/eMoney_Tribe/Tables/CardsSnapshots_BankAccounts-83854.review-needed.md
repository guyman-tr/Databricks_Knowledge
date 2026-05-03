# Review Needed: eMoney_Tribe.CardsSnapshots_BankAccounts-83854

## 1. Tier 3 Columns Requiring Upstream Clarification

| # | Column | Current Tier | Question |
|---|--------|-------------|----------|
| 1 | @CardsSnapshots_Account@Id-513255 | Tier 3 | Production schema has `@CardsSnapshots@Id-890718` (FK to root CardsSnapshots-890718) but Synapse has `@CardsSnapshots_Account@Id-513255` (FK to intermediate Account-513255). These are structurally different FKs. Confirm whether this is an intentional Synapse-specific hierarchy difference or a schema divergence. |
| 2 | etr_y | Tier 3 | ETL partition year marker populated for 2023-12 data only; empty string for 2024+ records. Was the Generic Pipeline configuration changed to stop populating these fields? |
| 3 | etr_ym | Tier 3 | Same as etr_y — empty for 2024+ data. |
| 4 | etr_ymd | Tier 3 | Same as etr_y — empty for 2024+ data. |

## 2. Data Quality Observations

- **1:1 relationship anomaly**: Despite being named as a "collection" table (plural "BankAccounts"), `@Id` equals `@CardsSnapshots_Account@Id-513255` in 100% of sampled rows. This suggests every parent account has exactly one bank accounts collection — effectively a 1:1 bridge. Confirm whether this is expected business behavior or a data artifact.
- **etr_* population gap**: The etr_y, etr_ym, etr_ymd columns are populated for early data (2023-12-20) but are empty strings (not NULL) for all 2024+ data. The pipeline appears to have stopped populating these after the initial load. These columns add no value for recent data.
- **Production schema mismatch**: Production wiki documents 4 columns (@Created, @Id, @CardsSnapshots@Id-890718, Created) while Synapse DDL has 8 columns with different FK references and additional Generic Pipeline columns. The structural divergence should be validated.

## 3. Upstream Wiki Coverage

- **Production wiki found**: `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.CardsSnapshots_BankAccounts-83854.md`
- **Matchable columns**: 2 of 8 Synapse columns matched production wiki (25% coverage)
- **Unmatched**: 6 columns — 1 Synapse-specific FK, 3 Generic Pipeline markers, 1 ingestion timestamp, 1 partition date
- **Note**: The `_no_upstream_found.txt` marker was set by the harness, but a production wiki WAS found independently at BankingDBs/FiatDwhDB. The harness resolver may not have searched BankingDBs upstream repos.

## 5. Freshservice Reference

- SP header references Freshservice change request #20353 (https://etoro.freshservice.com/a/changes/20353) for the eToro Money Reconciliation Tables migration to Synapse. Consider checking this for additional business context.
