# Lineage: BI_DB_US_Apex_Instrument_Holders

**Schema:** BI_DB_dbo  
**Writer SP:** `SP_US_Apex_Instrument_Holders`  
**ETL Pattern:** DELETE WHERE DateID=@DateID → INSERT SELECT  
**Frequency:** Daily (SB_Daily, Priority 20)

## Column Lineage

| Target Column | Source Table | Source Column | Transformation |
|---|---|---|---|
| DateID | SP input | @DateID | Direct assignment |
| GCID | External_USABroker_Apex_UserData | GCID | Joined via AccountNumber in #apex CTE |
| RealCID | DWH_dbo.Dim_Customer | RealCID | Filtered: RegulationID=8 (NYDFS), IsValidCustomer=1 |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | Filtered: InstrumentTypeID IN(5=RealStocks, 6=ETF) |
| InstrumentName | DWH_dbo.Dim_Instrument | Name | Aliased as InstrumentName; internal name format (e.g., "NVDA/USD") |
| Symbol | DWH_dbo.Dim_Instrument | Symbol | Direct; ticker symbol (e.g., "NVDA") |
| CUSIP | DWH_dbo.Dim_Instrument | CUSIP | Direct; NULL for ~0.05% of instruments without US CUSIP |
| Amount | BI_DB_dbo.BI_DB_PositionPnL | Amount | SUM() aggregated per customer/instrument; USD position value |
| Units | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal | SUM() aggregated per customer/instrument; share count |
| UpdateDate | ETL runtime | GETDATE() | Always current ETL run timestamp |

## Source Tables

| Table | Role | Filter |
|---|---|---|
| `BI_DB_dbo.BI_DB_PositionPnL` | Core position data | IsBuy=1 (long), IsSettled=1, DateID=@DateID |
| `DWH_dbo.Dim_Customer` | Customer dimension | RegulationID=8 (NYDFS), IsValidCustomer=1 |
| `DWH_dbo.Dim_Instrument` | Instrument dimension | InstrumentTypeID IN(5,6) — RealStocks and ETFs only |
| `External_USABroker_Apex_ApexData` | Apex broker account data | Joined to get AccountNumber |
| `External_USABroker_Apex_ApexStatus` | Apex account status | Used in #apex filter |
| `External_USABroker_Apex_UserData` | Apex user identity | Supplies GCID |

## ETL Notes

- **Long positions only**: IsBuy=1 filter — short positions are NOT included.
- **Settled positions only**: IsSettled=1 — open/unsettled positions excluded.
- **US stocks and ETFs only**: InstrumentTypeID IN(5,6) restricts to RealStocks and ETFs.
- **NYDFS regulation only**: RegulationID=8 — US customers under NY DFS regulation.
- **InstrumentName is internal name** (`Dim_Instrument.Name`), not display name — appears as "NVDA/USD" format, not "NVIDIA Corporation".
- **No author header** in the SP — unlike companion Apex SPs authored by Artyom Bogomolsky.
