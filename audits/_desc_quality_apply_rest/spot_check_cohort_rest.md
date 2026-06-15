# G3 Stratified Review Sheet

Source: `audits\_desc_quality_apply_rest\proposed_fixes.csv`

Sample size: **10**  (sql=3, v_liabilities=1, other=6)

Random seed: 51

Mark each item as `APPROVE / REJECT / EDIT(<your note>)` in the `VERDICT` line.

---

## [1/10] [SQL-derived] `ClosedOnDate` — `Function_PnL_Single_Day.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_PnL_Single_Day.md`
- **column**: `ClosedOnDate`
- **old**: Direct
- **new**: ISNULL(dp.ClosedOnDate, 0) (sql-derived [coalesce, DIVERGENT] from Function_PnL_Single_Day); branches: 1 when (dp.CloseDateID = @dateID) OR 0 (fallback); where dp = DWH_dbo.Dim_Position
- **trace**:
```
  hop[0] Function_PnL_Single_Day.ClosedOnDate [HAS_TRANSFORMATION]
```
- **VERDICT**: _________________________________

---

## [2/10] [SQL-derived] `IsCopyFund` — `Function_PnL_Single_Day.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_PnL_Single_Day.md`
- **column**: `IsCopyFund`
- **old**: Direct
- **new**: CASE WHEN NOT cpt.PositionID IS NULL THEN 1 ELSE 0 END (sql-derived [case] from Function_PnL_Single_Day); where cpt = BI_DB_dbo.BI_DB_CopyFund_Positions
- **trace**:
```
  hop[0] Function_PnL_Single_Day.IsCopyFund [HAS_TRANSFORMATION]
```
- **VERDICT**: _________________________________

---

## [3/10] [SQL-derived] `IsMarginTrade` — `Function_PnL_Single_Day.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_PnL_Single_Day.md`
- **column**: `IsMarginTrade`
- **old**: Direct
- **new**: COALESCE(dp.IsMarginTrade, upl.IsMarginTrade) (sql-derived [coalesce, DIVERGENT] from Function_PnL_Single_Day); branches: CASE WHEN dp.SettlementTypeID = 5 THEN 1 ELSE 0 END OR CASE WHEN bdppl.SettlementTypeID = 5 THEN 1 ELSE 0 END; where dp = DWH_dbo.Dim_Position, bdppl = BI_DB_dbo.BI_DB_PositionPnL
- **trace**:
```
  hop[0] Function_PnL_Single_Day.IsMarginTrade [HAS_TRANSFORMATION]
```
- **VERDICT**: _________________________________

---

## [4/10] [V_Liabilities] `CopyFundAUM` — `V_Liabilities.md`

- **wiki**: `knowledge/synapse/Wiki/DWH_dbo/Views/V_Liabilities.md`
- **column**: `CopyFundAUM`
- **old**: Direct
- **new**: Passthrough — no upstream semantic (chain: V_Liabilities.CopyFundAUM -> Fact_SnapshotEquity.CopyFundAUM, column_not_found)
- **trace**:
```
  hop[0] V_Liabilities.CopyFundAUM [TRIVIAL] src='Fact_SnapshotEquity.CopyFundAUM'
  hop[1] Fact_SnapshotEquity.CopyFundAUM [COLUMN_NOT_FOUND] note='column_not_in_upstream'
  EXHAUSTED reason=column_not_found
```
- **VERDICT**: _________________________________

---

## [5/10] [other] `SellCurrency` — `Function_Instrument_Conversion_Rates.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Instrument_Conversion_Rates.md`
- **column**: `SellCurrency`
- **old**: Direct
- **new**: Trading symbol / ticker for the sell-side currency. "USD", "EUR", "GBX". UNIQUE constraint in production. Passthrough from Dictionary.Currency.Abbreviation via sell-side join. (Tier 1 — Dictionary.Currency) (via Dim_Instrument)
- **trace**:
```
  hop[0] Function_Instrument_Conversion_Rates.SellCurrency [HAS_TRANSFORMATION] src='Dim_Instrument.SellCurrency'
```
- **VERDICT**: _________________________________

---

## [6/10] [other] `BuyCurrency` — `Function_Instrument_Snapshot_Enriched.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Instrument_Snapshot_Enriched.md`
- **column**: `BuyCurrency`
- **old**: Direct
- **new**: Trading symbol / ticker for the buy-side currency. "USD", "EUR", "AAPL.US". UNIQUE constraint in production. The primary identifier used in UIs and APIs. Passthrough from Dictionary.Currency.Abbreviation via buy-side join. (Tier 1 — Dictionary.Currency) (via Dim_Instrument)
- **trace**:
```
  hop[0] Function_Instrument_Snapshot_Enriched.BuyCurrency [HAS_TRANSFORMATION] src='isn.BuyCurrency'
```
- **VERDICT**: _________________________________

---

## [7/10] [other] `IsAirDrop` — `Function_Trading_Volume_PositionLevel.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Trading_Volume_PositionLevel.md`
- **column**: `IsAirDrop`
- **old**: Direct
- **new**: 1=position was created via an airdrop event (crypto). ETL-computed: JOIN to etoro_Trade_PositionAirdropLog. NULL=not an airdrop. (Tier 2 - SP_Dim_Position_DL_To_Synapse) (via Dim_Position)
- **trace**:
```
  hop[0] Function_Trading_Volume_PositionLevel.IsAirDrop [HAS_TRANSFORMATION] src='DWH_dbo.Dim_Position.IsAirDrop'
```
- **VERDICT**: _________________________________

---

## [8/10] [other] `LanguageID` — `Function_MIMO_First_Deposit_All_Platforms.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_MIMO_First_Deposit_All_Platforms.md`
- **column**: `LanguageID`
- **old**: Direct
- **new**: Customer's preferred interface language. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer)
- **trace**:
```
  hop[0] Function_MIMO_First_Deposit_All_Platforms.LanguageID [HAS_TRANSFORMATION] src='Fact_SnapshotCustomer.LanguageID'
```
- **VERDICT**: _________________________________

---

## [9/10] [other] `IsPhoneVerified` — `Function_MIMO_First_Deposit_All_Platforms.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_MIMO_First_Deposit_All_Platforms.md`
- **column**: `IsPhoneVerified`
- **old**: Direct
- **new**: 1 if the customer's phone number has been verified (PhoneVerifiedID IN (1,2) in source). Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer)
- **trace**:
```
  hop[0] Function_MIMO_First_Deposit_All_Platforms.IsPhoneVerified [HAS_TRANSFORMATION] src='Fact_SnapshotCustomer.IsPhoneVerified'
```
- **VERDICT**: _________________________________

---

## [10/10] [other] `ReceivedOnPriceServer` — `Function_Instrument_Snapshot_Enriched.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Instrument_Snapshot_Enriched.md`
- **column**: `ReceivedOnPriceServer`
- **old**: Direct
- **new**: Earliest price-server timestamp from PriceLog_History_CurrencyPrice_Active for the prior day, persisted via Ext_Dim_Instrument_ReceivedOnPriceServerStatic. (Tier 2 — SP_Dim_Instrument) (via Dim_Instrument)
- **trace**:
```
  hop[0] Function_Instrument_Snapshot_Enriched.ReceivedOnPriceServer [HAS_SEMANTIC] src='isn.ReceivedOnPriceServer'
```
- **VERDICT**: _________________________________

---
