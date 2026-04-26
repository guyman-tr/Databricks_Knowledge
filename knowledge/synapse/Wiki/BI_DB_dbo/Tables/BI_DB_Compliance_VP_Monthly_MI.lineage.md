# Lineage: BI_DB_Compliance_VP_Monthly_MI

## Writer
`BI_DB_dbo.SP_Compliance_VP_Monthly_MI` — runs daily, TRUNCATE + INSERT (full refresh).  
Author: Lior Ben Dor (created 2025-01-14); performance improvement by Oskar Harhalakis (2025-12-11).

## ETL Flow

```
External_Fivetran_google_sheets_vp_monthly_mi (CID list from Google Sheets via Fivetran)
    └─► DWH_dbo.Dim_Customer (filter to listed CIDs + demographics)
        + DWH_dbo.Dim_PlayerStatus (PlayerStatus name)
        + DWH_dbo.Dim_Regulation (Regulation name via primary RegulationID)
            └─► #pop (56 VP clients with status/regulation)
                    │
DWH_dbo.Fact_CustomerAction (ALL historical, ActionTypeID 1-6, per #pop CID)
    + DWH_dbo.Dim_Instrument (InstrumentTypeID for asset class classification)
        └─► UNION ALL:
            ├─ Opens (ActionTypeID 1,2,3): NEGATIVE notional → #Notional
            └─ Closes (ActionTypeID 4,5,6): POSITIVE notional → #Notional
                    │ GROUP BY CID
                    │ SUM across opens+closes → net notional per asset class
                    ▼
DWH_dbo.Dim_Position (CloseDateID=0, per #pop CID) ──► #OpenPositions (count only, not in output)
                    │
                    ▼ LEFT JOINs to Dim_Customer, Dim_Country, Dim_Language, BI_DB_CIDFirstDates
                      (most joined columns are COMMENTED OUT and not in final output)
                    │
            TRUNCATE + INSERT ◄─────────────────────────────────────
                    │
        BI_DB_Compliance_VP_Monthly_MI
```

## Source Tables

| Tier | Source | Columns Derived |
|------|--------|----------------|
| Tier 1 | `DWH_dbo.Dim_Customer` | CID (RealCID), IsDepositor, IsValidCustomer, VerificationLevelID, RegulationID, PlayerStatusID |
| Tier 1 | `DWH_dbo.Dim_PlayerStatus` | PlayerStatus (Name) |
| Tier 1 | `DWH_dbo.Dim_Regulation` | Regulation (Name via DWHRegulationID = RegulationID) |
| Tier 1 | `DWH_dbo.Fact_CustomerAction` | TradesExecuted, TradesExecuted_CFD/RealStocksETF/RealCrypto, NotionalAmount_* (Amount × Leverage, all historical) |
| Tier 1 | `DWH_dbo.Dim_Instrument` | InstrumentTypeID (for asset class split: CFD=IsSettled=0, Stocks/ETF=TypeID 5/6, Crypto=TypeID 10) |
| Tier 2 | `External_Fivetran_google_sheets_vp_monthly_mi` | Input CID filter list (VP client list managed by Compliance via Google Sheets) |

## Key Transformations
- **CID filter**: Only customers in the Fivetran-synced Google Sheets VP list are processed. Current list has 56 CIDs.
- **All-time scope**: No date filter applied — all historical Fact_CustomerAction records are included.
- **UNION ALL opens + closes**: TradesExecuted sums both open AND close actions (ActionTypeID 1-3 and 4-6). A complete round-trip trade contributes 2 to TradesExecuted.
- **Net notional calculation**: Opens arm applies a **NEGATIVE sign** to notional amounts; closes arm applies a **POSITIVE sign**. Final SUM = `Σ(close_notional) − Σ(open_notional)`. Positive = more close notional than open notional (net closed flow); negative = more open notional (net open exposure).
- **Asset class split**:
  - CFD: `IsSettled = 0` (leveraged or CFD position)
  - Real Stocks/ETF: `IsSettled = 1 AND InstrumentTypeID IN (5, 6)`
  - Real Crypto: `IsSettled = 1 AND InstrumentTypeID = 10`
- **Regulation**: Uses primary RegulationID via `DWHRegulationID` join (unlike Surveillance tables that use DesignatedRegulationID).
- **Commented-out columns**: SP had Email, GCID, CountryOfCitizenship, CountryOfResidence, Language, Manager, Club, HasOpenPositions — all commented out. Only core metrics remain in output.

## Downstream (Known)
No known downstream BI_DB tables. Used directly by Compliance VP Monthly MI reporting.
