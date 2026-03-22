# Review Notes — Dealing_dbo.V_Dealing_CEPDailyAudit_Rules_Last180Days

**Status**: Active ✅ (view over active base table)

## Items Requiring Human Review

1. **Rolling window vs fixed**: The 180-day cutoff uses GETDATE()-180 (rolling). Confirm this is intentional for the intended use cases.

2. **SELECT * risk**: The view uses `SELECT *` — schema changes to the base table will silently change this view's output. Confirm consumers are aware.

3. **No NOLOCK hint**: Confirm whether NOLOCK is needed for high-frequency reads.
