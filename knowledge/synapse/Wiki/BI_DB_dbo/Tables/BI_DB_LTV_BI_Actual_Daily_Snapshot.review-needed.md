# BI_DB_LTV_BI_Actual_Daily_Snapshot — Review Needed

## Tier 4 / Uncertain Items

1. **70 inactive columns — intended or oversight?**: SP_D_LTV_BI_Actual_Snapshot has 70 of 86 columns commented out. This appears intentional (the LTV pipeline was simplified in 2023), but these columns remain in the DDL. Confirm with Jan Iablunovskey or BI team whether the DDL should be cleaned up (DROP COLUMN for unused cols) or if they are retained for potential future reactivation.

2. **BI_DB_LTV_BI_Actual undocumented**: The primary source table is not yet in the wiki. LTV column semantics (Revenue8Y_LTV_New, LTV_8Y_GroupLevel, WO_Group_LTV variants) are inferred from column names and SP comments only. When BI_DB_LTV_BI_Actual is documented, verify that column descriptions here are consistent.

3. **Revenue8Y_LTV_New_WO_Group_LTV = 0 for group-assigned customers**: Confirmed from SP structure, but the exact condition under which LTV_8Y_GroupLevel is applied vs. individual LTV is not spelled out in SP_D_LTV_BI_Actual_Snapshot (it's inherited from SP_LTV_BI_Actual). Verify zero-vs-NULL behavior from the upstream SP logic.

4. **Currency field semantics**: Values are 'USD', 'Non_USD', and empty string. The binary classification (not the actual currency code) is unusual for a column named Currency. Confirm whether this is a flag sourced from BI_DB_LTV_BI_Actual or whether it was once a richer field that got simplified.

5. **Snapshot retention policy**: The table has 865 snapshots back to 2023-10-22. At ~5.24M rows/snapshot, this is ~4.54B rows. Confirm whether there is any snapshot archival or purge policy, or whether this table grows unboundedly.

6. **First_Month_Equity_Tier = 1 for nearly all customers**: Sample data shows value = 1 for all 5 sampled rows. If this is nearly universal, the column may have limited analytical value. Confirm distribution across the full population.

## No Review Needed
- Table name, distribution, index: confirmed from DDL (HASH(CID), HEAP)
- Active vs inactive column split (16 active, 70 NULL): confirmed via MCP sampling
- Row count, snapshot range: confirmed via MCP (4.54B rows, 865 snapshots, 2023-10-22 to 2026-04-11)
- Channel distribution, First_Month_Cluster values, Currency values: confirmed via MCP
- SnapshotDate = yesterday logic: confirmed from SP code (DATEADD(dd,-1,GETDATE()))
- Channel = 'NULL' string (not SQL NULL): confirmed from SP ISNULL(bdfa.Channel,'NULL')
- CID T1 description: verbatim from canonical source
