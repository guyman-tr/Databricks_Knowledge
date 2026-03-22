# Review Notes — Dealing_dbo.V_Dealing_Duco_EODRecon

**Status**: Active ✅ (view over active base table)

## Items Requiring Human Review

1. **Duplicate column**: `SELECT *` plus explicit `[Buy/Sell] AS BuyOrSell` means the `[Buy/Sell]` column appears twice in the result set — once from `*` expansion and once aliased. Downstream tools that reference by position rather than name may pick the wrong column. Confirm this is not causing issues.

2. **Static 2023-01-01 cutoff**: Hardcoded, not rolling. Confirm this is still appropriate and whether the cutoff should be moved forward as the table grows.

3. **DISTINCT overhead**: DISTINCT on the full result set adds a sort/dedup operation. Confirm whether duplicates actually exist in the base table — if not, DISTINCT is unnecessary overhead.

4. **NOLOCK semantics**: Confirm all downstream broker recon SPs that reference this view are aware of and accept NOLOCK dirty read risk.
