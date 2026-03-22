# Review Notes — Dealing_dbo.V_Dealing_DealingDashboard_Clients

**Status**: Active ✅ (view over active base table)

## Items Requiring Human Review

1. **Static 2021 cutoff**: DateID > 20211231 excludes all pre-2022 data. Confirm this is still the correct cutoff — if the program expanded to include 2021 historical analysis, this view would be too restrictive.

2. **SELECT * risk**: The view uses `SELECT *` — schema changes to the base table will silently change this view's output. Confirm consumers are aware.

3. **NOLOCK semantics**: The view uses WITH(NOLOCK). Confirm all consumers understand they may see uncommitted data and this is acceptable.

4. **Regime_Flags reads base table**: `SP_Regime_Flags` reads from the base table (`Dealing_DealingDashboard_Clients` from 2019-01-01), not this view. Confirm this is intentional and that no other SP should be updated to use this view instead.
