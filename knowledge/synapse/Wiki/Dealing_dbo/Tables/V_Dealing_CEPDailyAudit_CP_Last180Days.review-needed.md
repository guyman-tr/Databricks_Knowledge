# Review Notes — Dealing_dbo.V_Dealing_CEPDailyAudit_CP_Last180Days

**Status**: Active ✅ (view over active base table)

## Items Requiring Human Review

1. **Rolling window vs fixed**: The 180-day cutoff uses GETDATE()-180 (rolling). Confirm this is intentional — if reports need a consistent date range, the fixed-cutoff approach may be preferable.

2. **SELECT * risk**: The view uses `SELECT *` — if the base table schema changes (column added/dropped), this view will silently change its output. Confirm consumers are aware of this risk.

3. **No NOLOCK hint**: Unlike V_Dealing_DealingDashboard_Clients, this view does not use NOLOCK. Confirm whether NOLOCK is needed for high-frequency dashboard reads.
