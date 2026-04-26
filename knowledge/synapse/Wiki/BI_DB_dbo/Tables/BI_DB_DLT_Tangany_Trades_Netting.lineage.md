# BI_DB_dbo.BI_DB_DLT_Tangany_Trades_Netting — Column Lineage

## Writer SP
`BI_DB_dbo.SP_BI_DB_DLT_Tangany_Trades_Netting`

## Source Objects
- `DWH_dbo.Fact_CustomerAction` — trade events (open/close actions, amounts, units)
- `DWH_dbo.Dim_Instrument` — instrument name and type classification (InstrumentTypeID=10 filter)
- `DWH_dbo.Fact_SnapshotCustomer` — customer snapshot (CountryID, DltStatusID, DltID, DateRangeID)
- `DWH_dbo.Dim_Range` — date range resolution for Fact_SnapshotCustomer
- `DWH_dbo.Dim_Customer` — customer master (TanganyID, DltID)
- `DWH_dbo.Dim_Position` — position details for bug fix calculations (InitForexRate, Leverage, UnitMargin, etc.)
- `DWH_dbo.Dim_ClosePositionReason` — close reason lookup (Name)
- `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` — Tangany/DLT status per CID per date
- `BI_DB_dbo.External_eToro_Dictionary_TanganyStatus` — Tangany status ID lookup
- `BI_DB_dbo.Function_Revenue_TicketFeeByPercent` — percentage-based ticket fee calculation

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| DateID | SP parameter | @dateID | CAST(CONVERT(VARCHAR(8), @date, 112) AS INT) |
| Date | SP parameter | @date | Direct |
| RealCID | Fact_CustomerAction | RealCID | Direct passthrough |
| CountryID | Fact_SnapshotCustomer | CountryID | Direct passthrough (date-range matched via Dim_Range) |
| IsDLTUser | Fact_SnapshotCustomer | DltStatusID | CASE WHEN DltStatusID = 4 THEN 1 ELSE 0 END |
| TanganyStatusID | External_eToro_Dictionary_TanganyStatus + BI_DB_Client_Balance_CID_Level_New | TanganyStatus → StatusID | JOIN on TanganyStatus = Status Desc, filtered to IN (2,3,5) |
| ActionType | Computed | ActionTypeID filter | 'Open' for ActionTypeID IN (1,2,3,39); 'Close' for IN (4,5,6,28,40) |
| InvestedAmount | Fact_CustomerAction | Amount | -1 * Amount (sign-flipped for netting) |
| Units | Fact_CustomerAction / Dim_Position | InitialUnits / AmountInUnitsDecimal | Open: -1 * InitialUnits; Close: -1 * AmountInUnitsDecimal |
| TanganyID | Dim_Customer | TanganyID | Direct passthrough |
| DltID | Fact_SnapshotCustomer / Dim_Customer | DltID | Open: from Fact_SnapshotCustomer; Close: from Dim_Customer |
| IsCoinsTransferedOut | Dim_Position | ClosePositionReasonID | CASE WHEN ClosePositionReasonID = 22 THEN 1 ELSE 0 END; always 0 for opens |
| Instrument | Dim_Instrument | Name | Direct passthrough (crypto names only: InstrumentTypeID=10) |
| PositionID | Fact_CustomerAction | PositionID | Direct passthrough |
| AmountBugFix | Dim_Position | InitForexRate, InitialUnits, AmountInUnitsDecimal, NetProfit, Leverage, UnitMargin, InitialAmountCents | 3 bug-fix formulas based on Leverage and UnitMargin conditions |
| UpdateDate | ETL | GETDATE() | ETL timestamp |
| CloseReason | Dim_ClosePositionReason | Name | Direct; 'NA' for opens |
| TicketFeeByPercent | Function_Revenue_TicketFeeByPercent | TicketFeeByPercent | ISNULL to 0; matched by PositionID + ActionType |
| CommissionVersion | Dim_Position | CommissionVersion | Direct passthrough (final JOIN) |
