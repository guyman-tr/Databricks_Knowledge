# Column Lineage: Dealing_dbo.Dealing_ApexRecon_Hedging

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_ApexRecon_Hedging` |
| **UC Target** | N/A — Dealing_dbo not yet in Unity Catalog |
| **Primary Source** | `Dealing_dbo.Dealing_ApexRecon_Holdings` (same-day + previous-day reads) |
| **ETL SP** | `Dealing_dbo.SP_Apex_Recon` |
| **Secondary Sources** | `Dealing_staging.External_Fivetran_dealing_active_hs_mappings` (via #Fivetran) |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
Dealing_dbo.Dealing_ApexRecon_Holdings (@Date)   ← (same SP run, inserted earlier this run)
    ↓
Dealing_dbo.Dealing_ApexRecon_Holdings (@PreviousDay)  ← (prior day's run)
    ↓
SP_Apex_Recon(@Date) — Hedging section
  → #Over_Under (today: compute DiffFromToday + Over/Under thresholds)
  → #PreviousDay (previous day's Apex_Units - Client_NOP_Units)
  → INSERT: LEFT JOIN #Over_Under to #PreviousDay on Symbol×HedgeServerID
    ↓
Dealing_dbo.Dealing_ApexRecon_Hedging
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| Date | — | — | ETL-computed | `@Date` parameter | |
| Symbol | Dealing_ApexRecon_Holdings | Symbol | passthrough | Direct from #Over_Under | |
| InstrumentID | Dealing_ApexRecon_Holdings | InstrumentID | passthrough | Direct | |
| InstrumentDisplayName | Dealing_ApexRecon_Holdings | InstrumentDisplayName | passthrough | Direct | |
| ISINCode | Dealing_ApexRecon_Holdings | ISINCode | passthrough | Direct | |
| HedgeServerID | Dealing_ApexRecon_Holdings | HedgeServerID | passthrough | Direct | |
| Over_Under | Dealing_ApexRecon_Holdings | Apex_Units, Client_NOP_Units, Etoro_Amount, Etoro_Units | ETL-computed | `CASE WHEN diff≥1 AND value≥50K THEN 'Over'; WHEN diff≤-1 AND value≤-5K AND portfolio<-100K THEN 'Under' END` | Computed in #Over_Under |
| DiffFromPreviousDay | Dealing_ApexRecon_Holdings (@PreviousDay) | Apex_Units, Client_NOP_Units | ETL-computed | `ISNULL(Apex_Units,0) - ISNULL(Client_NOP_Units,0)` for @PreviousDay | From #PreviousDay |
| HedgingDiff | Dealing_ApexRecon_Holdings (both days) | Apex_Units, Client_NOP_Units | ETL-computed | `CASE WHEN Over_Under IS NOT NULL AND PreviousDay.diff - Today.diff = 0 THEN 'Yes' ELSE 'No' END` | NULL when not flagged |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL metadata |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 5 |
| **ETL-computed** | 5 |
| **Total** | 10 |
