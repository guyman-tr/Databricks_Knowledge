# G3 Stratified Review Sheet

Source: `audits\_desc_quality_apply_revenue\proposed_fixes.csv`

Sample size: **5**  (sql=0, v_liabilities=0, other=0)

Random seed: 27

Mark each item as `APPROVE / REJECT / EDIT(<your note>)` in the `VERDICT` line.

---

## [1/5] [other] `PhoneVerificationDateID` — `Function_Revenue_TransferCoinFee.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_TransferCoinFee.md`
- **column**: `PhoneVerificationDateID`
- **old**: Direct
- **new**: Date the phone was verified, as YYYYMMDD string. Rows where PhoneVerificationDateID='19000101' are excluded from source. Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer)
- **trace**:
```
  hop[0] Function_Revenue_TransferCoinFee.PhoneVerificationDateID [HAS_TRANSFORMATION] src='Fact_SnapshotCustomer.PhoneVerificationDateID'
```
- **VERDICT**: _________________________________

---

## [2/5] [other] `InstrumentID` — `Function_Revenue_SDRT.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_SDRT.md`
- **column**: `InstrumentID`
- **old**: Direct
- **new**: Tradeable instrument pair identifier. FK to Dim_Instrument. COALESCE from Dim_Position over Fact_CustomerAction. (Tier 1 — Trade.Instrument) (via BI_DB_Fact_Customer_Action_Position_Distribution)
- **trace**:
```
  hop[0] Function_Revenue_SDRT.InstrumentID [HAS_SEMANTIC] src='BI_DB_Fact_Customer_Action_Position_Distribution.InstrumentID'
```
- **VERDICT**: _________________________________

---

## [3/5] [other] `RealCID` — `Function_Revenue_CryptoToFiat_C2F.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_CryptoToFiat_C2F.md`
- **column**: `RealCID`
- **old**: Direct
- **new**: Internal CID after deduplication mapping. Sourced from EXW_dbo.EXW_DimUser.RealCID; maps GCID to the canonical customer record. (Tier 2 — SP_EXW_C2F_E2E) (via EXW_C2F_E2E)
- **trace**:
```
  hop[0] Function_Revenue_CryptoToFiat_C2F.RealCID [HAS_SEMANTIC] src='EXW_C2F_E2E.RealCID'
```
- **VERDICT**: _________________________________

---

## [4/5] [other] `PlayerStatusReasonID` — `Function_Revenue_CashoutFee_IncRedeem.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_CashoutFee_IncRedeem.md`
- **column**: `PlayerStatusReasonID`
- **old**: Direct
- **new**: Reason code for the current PlayerStatusID (e.g., why account was blocked). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusReasonID (CC). FK to Dim_PlayerStatusReasons. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer)
- **trace**:
```
  hop[0] Function_Revenue_CashoutFee_IncRedeem.PlayerStatusReasonID [HAS_TRANSFORMATION] src='Fact_SnapshotCustomer.PlayerStatusReasonID'
```
- **VERDICT**: _________________________________

---

## [5/5] [other] `PhoneNumber` — `Function_Revenue_ConversionFee_WithPositionData.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_ConversionFee_WithPositionData.md`
- **column**: `PhoneNumber`
- **old**: Direct
- **new**: Customer phone number. PII: not DDL-masked but GDPR-erased to 'DelPhoneNumber_XXXXXXX' for deleted users. Source: Ext_FSC_PhoneCustomer.PhoneNumber. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer)
- **trace**:
```
  hop[0] Function_Revenue_ConversionFee_WithPositionData.PhoneNumber [HAS_TRANSFORMATION] src='Fact_SnapshotCustomer.PhoneNumber'
```
- **VERDICT**: _________________________________

---
