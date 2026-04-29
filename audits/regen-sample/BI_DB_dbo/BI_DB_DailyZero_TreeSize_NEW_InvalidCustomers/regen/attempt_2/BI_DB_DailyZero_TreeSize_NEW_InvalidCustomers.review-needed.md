# Review sidecar -- BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers

## Data Quality Concerns

- **Missing 2024 data**: Year distribution shows 2021=2.51M, 2022=2.88M, 2023=766K, 2025=20K with no 2024 rows at all. Investigate whether SP was not scheduled in 2024 or table is being deprecated.
- **Sparse 2025 data**: Only ~20K rows for 2025 (dates 2025-06-28 to 2025-06-29) vs millions in prior years. Verify SP_DailyZero_TreeSize_NEW_InvalidCustomers is still scheduled and running daily.
- **Not in OpsDB**: The InvalidCustomers variant SP is not listed in opsdb-objects-status.json (only the main SP_DailyZero_TreeSize_NEW is listed at Priority 99, FinanceReportSPS). May be invoked manually or via a wrapper.

## UC Migration

- **No UC target**: Table not found in _generic_pipeline_mapping.json. Sister table BI_DB_DailyZero_TreeSize_NEW maps to `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new`. If migration is needed, expected target would follow the same pattern.

## Tier Decisions

- **MifID (Tier 1)**: Passthrough rename from Fact_SnapshotCustomer.MifidCategorizationID. Description quoted verbatim from Fact_SnapshotCustomer wiki.
- **IsValidCustomer (Tier 1)**: Passthrough from Fact_SnapshotCustomer. Always 0 in this table due to SP WHERE filter. Description from Fact_SnapshotCustomer wiki retained with table-specific note.
- **IsCreditReportValidCB (Tier 1)**: Passthrough from Fact_SnapshotCustomer. Description from Fact_SnapshotCustomer wiki.
- **Regulation, Country, PlayerLevel, GuruStatus (Tier 1)**: Dim-lookup passthroughs. Origins traced through dim wikis to production Dictionary tables.

## Columns Needing Expert Review

- **IsCFD**: Reconciliation logic between Dim_Position.IsSettled and BI_DB_PositionPnL.IsSettled has edge cases when the two disagree. Confirm business intent of the precedence logic.
- **RiskIndex / RiskGroup / DepositGroup**: Empty string placeholders. Confirm if these will ever be populated or should be deprecated.
