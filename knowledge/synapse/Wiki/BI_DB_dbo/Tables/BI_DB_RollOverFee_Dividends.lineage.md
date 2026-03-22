# Column Lineage -- BI_DB_dbo.BI_DB_RollOverFee_Dividends

**Writer SP**: `BI_DB_dbo.SP_RollOverFee_Dividends` (Priority 99 -- FinanceReportSPS)
**Author**: Jenia (procedure header; change history lists Adar, Boris, Adi Ferber, Adva)
**ETL Pattern**: DELETE-INSERT by DateID
**Architecture**: `#HS` + dividend temps + `#FCA` (UNION aggregate) -> INSERT

---

## Source Tables

| Source | Alias | Role |
|--------|-------|------|
| DWH_dbo.Fact_CustomerAction | fca | Roll-over fee rows (`ActionTypeID=35`, `IsFeeDividend=1`) |
| DWH_dbo.Dim_Customer | dc | `IsValidCustomer`, player rules |
| DWH_dbo.Dim_Position | dp | Instrument, settlement, units fallback, `IsComputeForHedge` |
| DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot | cl | Hedge server as-of date |
| DWH_dbo.Dim_PositionChangeLog | pcl | Optional `IsSettled` override (future-dated change type 13) |
| BI_DB_dbo.BI_DB_PositionPnL | bdppl | Units for roll-over and dividend eligibility |
| BI_DB_dbo.BI_DB_DailyDividendsByPosition | bdddbp | Position-level dividend amounts |
| DWH_dbo.etoro_Trade_IndexDividends | b | Dividend dates, raw event type, `DividendValueInCurrency` |
| DWH_dbo.Dim_Instrument | di | `InstrumentType`, `Name` |

---

## Column-Level Lineage

Final SELECT is from `#FCA` (UNION of roll-over aggregate and dividend aggregate).

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| DateID | Fact_CustomerAction (fca) / BI_DB_DailyDividendsByPosition (bdddbp) | DateID | Direct in branches; GROUP BY key |
| Date | parameter | @Date | `CONVERT` via `@Date` in INSERT list |
| PaymentDate | etoro_Trade_IndexDividends (b) | PaymentDate | NULL in roll-over branch; direct in dividend branch |
| ExDate | etoro_Trade_IndexDividends (b) | ExDate | NULL in roll-over branch; direct in dividend branch |
| HedgeServerID | Dim_Position (dp) / Snapshot (cl) | HedgeServerID | `ISNULL(cl.HedgeServerID, dp.HedgeServerID)` |
| InstrumentType | Dim_Instrument (di) | InstrumentType | JOIN on `InstrumentID` |
| InstrumentID | Dim_Position / BI_DB_DailyDividendsByPosition | InstrumentID | GROUP BY key |
| InstrumentName | Dim_Instrument (di) | Name | GROUP BY key |
| IsSettled | Dim_Position / Dim_PositionChangeLog | IsSettled, PreviousIsSettled | `CASE WHEN settled THEN 'Real' ELSE 'CFD'` with pcl override |
| PaymentType | literal | -- | `'RollOverFee'` or `'Dividend'` |
| EventType | literal / etoro_Trade_IndexDividends | EventType | `'RollOverFee'` or classified `CASE` on `b.EventType` |
| DividendID | -- / BI_DB_DailyDividendsByPosition | DividendID | NULL roll-over; GROUP BY in dividend branch |
| Amount | Fact_CustomerAction / BI_DB_DailyDividendsByPosition | Amount | `SUM(-Amount)` |
| DividendValueInCurrency | -- / etoro_Trade_IndexDividends | DividendValueInCurrency | NULL roll-over; GROUP BY dividend branch |
| IsValidCustomer | Dim_Customer / BI_DB_DailyDividendsByPosition | IsValidCustomer | Direct |
| UpdateDate | computed | GETDATE() | INSERT timestamp |
| CountCIDs | #DistinctCIDs_RollOver / #DistinctCIDs_Div | DistinctCIDs | `AVG(CAST(DistinctCIDs AS BIGINT))` after group-by RealCID |
| AmountOfUnits | BI_DB_PositionPnL / Dim_Position | AmountInUnitsDecimal | `SUM` from `#ROF_Units` or `#Div_EligibleUnits` |
| PlayerLevel | Dim_Customer / bdddbp | RealCID, PlayerLevelID | Hard-coded BVI CIDs OR Internal OR Other |
| PlayerStatus | Dim_Customer / bdddbp | PlayerStatusID | Deposit Blocked vs Other |
| IsComputeForHedge | Dim_Position / bdddbp | IsComputeForHedge | Direct |
