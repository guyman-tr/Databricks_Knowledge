# Lineage: BI_DB_Compliance_Surveillance_Snapshot

## Writer
`BI_DB_dbo.SP_D_Compliance_Surveillance_Snapshot` — runs daily, TRUNCATE + INSERT (full refresh).  
Author: Bradley Roberts (created 2023-11-21); last modified 2024-07-28 (EitanLi).

## ETL Flow

```
External_Fivetran_compliance_snapshot_report_instrumentids (daily instrument list from Google Sheets via Fivetran)
    └─► instrument_id filter (≥100; MIN(instrument_id) < 100 → used as @lookbackdays parameter)
                │
DWH_dbo.Dim_Position (open at @snapshot, opened ≤ @lookbackdays ago, OpenDateID ≥ 30d ago)
    + DWH_dbo.Dim_Instrument (JOIN on instrument_id in Fivetran list)
    + DWH_dbo.Dim_Customer (IsValidCustomer=1 for non-eToro; or IsValidCustomer=0 for eToro employees)
    + DWH_dbo.Dim_Country (CountryID → CountryOfResidence)
    + DWH_dbo.Dim_Regulation (DesignatedRegulationID → Regulation)
    + DWH_dbo.Dim_Mirror (MirrorID → ParentCID)
    + BI_DB_dbo.BI_DB_CIDFirstDates (VerificationLevel3Date for client + parent)
    + BI_DB_dbo.BI_DB_PositionPnL (DateID=@snapshotid → UnrealisedPositionPnL_Snapshot)
    + BI_DB_dbo.BI_DB_PositionPnL (DateID=@yesterdayid → UnrealisedPositionPnL_ReportDate)
        └─► #Snapshot ──► #SnapshotCIDs
                                │
DWH_dbo.Fact_CustomerAction (ActionTypeID=14, last 365d, latest per CID) → #LastIP
                                │
                    TRUNCATE + INSERT ◄────────────────────────────────────────
                            │
            BI_DB_Compliance_Surveillance_Snapshot
```

## Snapshot Time Logic
| Run Day | `@snapshot` = |
|---------|--------------|
| Monday | Friday 23:59:59 (DATEADD(-3)) |
| Tuesday | Friday 23:59:59 (DATEADD(-3) from Tuesday = Saturday, -1 second = Friday 23:59:59) |
| Wednesday–Sunday | Yesterday 23:59:59 (DATEADD(-1)) |

## Source Tables

| Tier | Source | Columns Derived |
|------|--------|----------------|
| Tier 1 | `DWH_dbo.Dim_Position` | PositionID, IsReal (IsSettled), IsBuy, CID, Leverage, UnleveragedTradeSize (Amount), FullNotionalTradeSize (Amount×Leverage), RealisedNetProfit (NetProfit), OpenOccurred, CloseOccurred, MirrorID→IsCopy |
| Tier 1 | `DWH_dbo.Dim_Instrument` | InstrumentDisplayName, Instrument (Name), InstrumentID, InstrumentType, ISINCode, CUSIP |
| Tier 1 | `DWH_dbo.Dim_Customer` | CID (RealCID), LastName, Postcode (Zip), CountryID, DesignatedRegulationID, Region, IsValidCustomer |
| Tier 1 | `DWH_dbo.Dim_Country` | CountryOfResidence (Name) |
| Tier 1 | `DWH_dbo.Dim_Regulation` | Regulation (Name via DesignatedRegulationID) |
| Tier 1 | `DWH_dbo.Dim_Mirror` | ParentCID |
| Tier 2 | `BI_DB_dbo.BI_DB_CIDFirstDates` | ClientVerificationLevel3Date, ParentVerificationLevel3Date |
| Tier 2 | `BI_DB_dbo.BI_DB_PositionPnL` | UnrealisedPositionPnL_Snapshot (DateID=@snapshotid), UnrealisedPositionPnL_ReportDate (DateID=@yesterdayid) |
| Tier 2 | `DWH_dbo.Fact_CustomerAction` | LastIPAddress (ActionTypeID=14, DWH_dbo.IPNumToIPAddress(), last 365d) |
| Tier 2 | `External_Fivetran_compliance_snapshot_report_instrumentids` | Instrument ID filter list (+ @lookbackdays parameter) |

## Key Transformations
- **Instrument list**: Dynamic daily list from Fivetran-synced Google Sheets (`External_Fivetran_compliance_snapshot_report_instrumentids`). Only positions in instruments on that day's list are included.
- **Lookback days**: `@lookbackdays` extracted from the same Fivetran sheet as the minimum `instrument_id` value (when < 100). Default = 13 days. Controls how far back from @snapshot to search for position open dates.
- **Open positions filter**: `OpenOccurred <= @snapshot AND (CloseOccurred > @snapshot OR CloseDateID = 0)` — captures positions that were open at the snapshot moment.
- **Customer validity**: Non-employees require IsValidCustomer=1; eToro employees (Region='eToro') included even if IsValidCustomer=0 (changed 2024-05-10 for UK Compliance).
- **Regulation**: Uses `DesignatedRegulationID` (secondary/override), not primary RegulationID. eToro employees show 'Internal'.
- **CloseOccurred sentinel**: Open positions store '1900-01-01 00:00:00' as CloseOccurred (from Dim_Position.CloseDateID=0).
- **PnL search window**: Both UnrealisedPositionPnL columns filter DateID >= 30 days ago in BI_DB_PositionPnL for performance before the exact DateID match.
- **Blank string sentinels**: ClientVerificationLevel3Date, ParentVerificationLevel3Date, ParentCID use empty string '' when not applicable.

## Downstream (Known)
No known downstream BI_DB tables. Used directly by Compliance Surveillance reporting.
