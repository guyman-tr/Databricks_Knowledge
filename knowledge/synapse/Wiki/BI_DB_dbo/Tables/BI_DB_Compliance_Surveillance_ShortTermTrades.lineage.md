# Lineage: BI_DB_Compliance_Surveillance_ShortTermTrades

## Writer
`BI_DB_dbo.SP_D_Compliance_Surveillance_ShortTermTrades` — runs daily, TRUNCATE + INSERT (full refresh).  
Author: Bradley Roberts (created 2023-12-14).

## ETL Flow

```
DWH_dbo.Dim_Position (CloseDateID = last working day, InstrumentTypeID IN (5,6), ≤300 min round trip)
    + DWH_dbo.Dim_Instrument (filter + attributes)
    + DWH_dbo.Dim_Customer (IsValidCustomer=1)
        └─► #RoundTripTrades ──► #AllCriteria (≥1 position per CID+Instrument) ──► #CIDs, #Instruments
                                                                                        │
DWH_dbo.Dim_Position (all history, MirrorID=0) ──────────────────────────────────────► #LifetimePositionsManual
DWH_dbo.Dim_Position (all history, MirrorID≠0) ──────────────────────────────────────► #LifetimePositionsCopy
                                                                                        │
DWH_dbo.Fact_CustomerAction (ActionTypeID=14, last 365d, latest IP per CID) ──────────► #LastIP
                                                                                        │
DWH_dbo.Dim_Position ─────────────────────────────────────────────────────────────────┐│
DWH_dbo.Dim_Instrument ────────────────────────────────────────────────────────────────┤│
DWH_dbo.Dim_Customer (LastName, Zip, CountryID, IsValidCustomer) ──────────────────────┤│
DWH_dbo.Dim_Country ────────────────────────────────────────────────────────────────────┤│
DWH_dbo.Dim_Regulation (via DesignatedRegulationID) ────────────────────────────────────┤├► #Final
DWH_dbo.Dim_Mirror (ParentCID) ────────────────────────────────────────────────────────┤│
BI_DB_dbo.BI_DB_CIDFirstDates (fd = client L3 date, fd2 = parent L3 date) ─────────────┤│
#LastIP, #LifetimePositionsManual, #LifetimePositionsCopy ──────────────────────────────┘│
                                                                                         │
                                        TRUNCATE + INSERT ◄──────────────────────────────┘
                                                │
                        BI_DB_Compliance_Surveillance_ShortTermTrades
```

## Source Tables

| Tier | Source | Columns Derived |
|------|--------|----------------|
| Tier 1 | `DWH_dbo.Dim_Position` | PositionID, IsReal (IsSettled), IsBuy, CID, Leverage, UnleveragedTradeSize (Amount), RealisedNetProfit (NetProfit), InitForexRate, EndForexRate, Units_Closed (AmountInUnitsDecimal), IsPartialCloseChild, OpenOccurred, CloseOccurred, MirrorID→IsCopy, ParentPositionID |
| Tier 1 | `DWH_dbo.Dim_Instrument` | InstrumentDisplayName, Instrument (Name), InstrumentID, InstrumentType, ISINCode, CUSIP |
| Tier 1 | `DWH_dbo.Dim_Customer` | CID (RealCID), LastName, Postcode (Zip), CountryID, DesignatedRegulationID, IsValidCustomer |
| Tier 1 | `DWH_dbo.Dim_Country` | CountryOfResidence (Name) |
| Tier 1 | `DWH_dbo.Dim_Regulation` | Regulation (Name via DesignatedRegulationID) |
| Tier 1 | `DWH_dbo.Dim_Mirror` | ParentCID |
| Tier 2 | `BI_DB_dbo.BI_DB_CIDFirstDates` | ClientVerificationLevel3Date, ParentVerificationLevel3Date |
| Tier 2 | `DWH_dbo.Fact_CustomerAction` | LastIPAddress (IPNumToIPAddress(IPNumber), ActionTypeID=14, latest per CID, last 365 days) |
| Tier 2 | SP-computed | FullNotionalTradeSize (Amount × Leverage), RoundTripDurationMins (DATEDIFF(MINUTE, Open, Close)), PositionsMeetingCriteria (COUNT per CID+Instrument), Lifetime_RealisedPnL (COALESCE manual/copy PnL from Dim_Position history) |

## Key Transformations
- **Instrument scope**: Only `InstrumentTypeID IN (5, 6)` — Stocks and ETFs
- **Close date filter**: `CloseDateID = last working day` — Friday if run on Monday, else yesterday
- **Short-term criteria**: `DATEDIFF(MINUTE, OpenOccurred, CloseOccurred) <= 300` (5 hours)
- **Client gate**: `COUNT(DISTINCT PositionID) >= @min_num_trades (=1)` per CID+InstrumentID; effectively captures all short-term positions with at least 1 occurrence
- **Regulation**: Uses `DesignatedRegulationID` (not primary RegulationID); eToro employees show 'Internal' (Region='eToro')
- **PnL split**: Manual (MirrorID=0) vs Copy (MirrorID≠0); `Lifetime_RealisedPnL = COALESCE(manual_pnl, copy_pnl)` for the specific CID+Instrument combination
- **IP lookup**: Most recent login action (ActionTypeID=14) within last 365 days, converted from integer to dotted-quad format via `DWH_dbo.IPNumToIPAddress()`
- **Blank vs NULL**: ClientVerificationLevel3Date and ParentVerificationLevel3Date use empty string `''` instead of NULL when unavailable; ParentCID also uses ISNULL→'' for non-copy positions

## Downstream (Known)
No known downstream BI_DB tables. Used directly by Compliance Surveillance reporting.
