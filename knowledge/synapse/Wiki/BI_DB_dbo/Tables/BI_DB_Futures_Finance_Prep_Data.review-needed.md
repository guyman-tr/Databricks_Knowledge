# Review Sidecar: BI_DB_dbo.BI_DB_Futures_Finance_Prep_Data

## Verification Status

| Item | Status | Notes |
|------|--------|-------|
| Business meaning | Verified via SP comment + code | Author comment confirms Marex & custodian transfers purpose |
| ActionType values | Verified from SP code | 7 distinct values from CASE logic in SP |
| ChangeTypeID = 99 | Verified synthetic | Injected by SP for Hold rows — not from source |
| LotCount null-fill | Verified from SP code | CROSS APPLY + LAG pattern |
| IsSettled COALESCE | Verified from SP code | Fallback to Dim_Position |
| Settlement window logic | Verified from SP code | SettlementTimePrev to SettlementTime |

## Unverified Items

| Column | Tier | Issue |
|--------|------|-------|
| (none) | -- | All columns traced to SP code or upstream wikis |

## Quality Notes

- All 27 columns are Tier 2 (SP code evidence)
- Upstream wikis available for all 4 source tables (Dim_PositionChangeLog, Fact_Position_Futures_Snapshot, Dim_Instrument_Snapshot, Dim_Position)
- Synapse MCP was unavailable — no live data sampling or distribution analysis performed
- Phases 2-3 skipped; all other phases completed
