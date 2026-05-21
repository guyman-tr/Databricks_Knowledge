# Tier 1 Claim Audit — knowledge/synapse/Wiki/DWH_dbo

_Generated: 2026-05-21T06:44:41Z → 2026-05-21T09:22:01Z_  
_Wall-clock: 9439.7s_  
_Wikis scanned: 134 | Tier 1 tags: 1050_  
_LLM judge: default | calls=589 cache_hits=16 failed=0_

## Headline

- **PASS**: 576
- **FAIL**: 474
  - HIGH: 348
  - MEDIUM: 9
  - LOW: 117

By layer:
- `L2-semantic`: 605
- `L1-structural`: 341
- `L0-unresolved`: 104

## Wikis with the most FAILs

| Rank | Wiki | FAIL count |
|------|------|------------|
| 1 | `knowledge/synapse/Wiki/DWH_dbo/Views/VU_FactBilling_ForBigQuery.md` | 98 |
| 2 | `…napse/Wiki/DWH_dbo/Views/V_Fact_CustomerUnrealized_PnL_For_DWH_Rep.md` | 48 |
| 3 | `…wledge/synapse/Wiki/DWH_dbo/Views/V_Fact_SnapshotEquity_FromDateID.md` | 30 |
| 4 | `knowledge/synapse/Wiki/DWH_dbo/Views/V_Fact_SnapshotEquity.md` | 28 |
| 5 | `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Date.md` | 27 |
| 6 | `knowledge/synapse/Wiki/DWH_dbo/Views/V_Dim_Customer.md` | 27 |
| 7 | `…owledge/synapse/Wiki/DWH_dbo/Views/V_Fact_SnapshotEquity_ForDWHRep.md` | 26 |
| 8 | `…dge/synapse/Wiki/DWH_dbo/Views/Vw_STS_User_Operations_Data_History.md` | 21 |
| 9 | `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_CustomerAction.md` | 20 |
| 10 | `knowledge/synapse/Wiki/DWH_dbo/Views/V_Customers.md` | 15 |
| 11 | `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_BillingWithdraw.md` | 10 |
| 12 | `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_Cashout_Rollback.md` | 10 |
| 13 | `knowledge/synapse/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation.md` | 10 |
| 14 | `knowledge/synapse/Wiki/DWH_dbo/Views/V_Dim_Instrument_Correlation.md` | 10 |
| 15 | `…/synapse/Wiki/DWH_dbo/Views/V_Dim_Instrument_Correlation_Test_Full.md` | 10 |
| 16 | `…edge/synapse/Wiki/DWH_dbo/Views/V_Fact_SnapshotCustomer_FromDateID.md` | 10 |
| 17 | `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Position.md` | 9 |
| 18 | `knowledge/synapse/Wiki/DWH_dbo/Views/V_Fact_SnapshotCustomer.md` | 8 |
| 19 | `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Instrument.md` | 6 |
| 20 | `knowledge/synapse/Wiki/DWH_dbo/Tables/History_CurrencyPrice.md` | 6 |

## Top 25 corrupted columns — downstream blast radius

For each DWH object with FAILs, the count of *.md files in each search root that mention the object by name. A high downstream count means many BI_DB_dbo / UC_generated wikis inherited the corrupted text.

| DWH object | FAILs | knowledge/synapse/Wiki/BI_DB_dbo | knowledge/synapse/Wiki/DWH_dbo | knowledge/UC_generated |
|---|---|---|---|---|
| `VU_FactBilling_ForBigQuery` | 98 | 0 | 7 | 0 |
| `V_Fact_CustomerUnrealized_PnL_For_DWH_Rep` | 48 | 0 | 7 | 0 |
| `V_Fact_SnapshotEquity_FromDateID` | 30 | 1 | 10 | 0 |
| `V_Fact_SnapshotEquity` | 28 | 0 | 11 | 0 |
| `V_Dim_Customer` | 27 | 42 | 14 | 1 |
| `V_Fact_SnapshotEquity_ForDWHRep` | 26 | 0 | 7 | 0 |
| `Vw_STS_User_Operations_Data_History` | 21 | 0 | 7 | 0 |
| `V_Customers` | 15 | 0 | 8 | 0 |
| `Dim_Instrument_Correlation` | 10 | 8 | 13 | 0 |
| `V_Dim_Instrument_Correlation` | 10 | 0 | 7 | 0 |
| `V_Dim_Instrument_Correlation_Test_Full` | 10 | 0 | 6 | 0 |
| `V_Fact_SnapshotCustomer_FromDateID` | 10 | 0 | 12 | 89 |
| `V_Fact_SnapshotCustomer` | 8 | 0 | 10 | 0 |
| `v_Dim_Mirror` | 5 | 0 | 6 | 0 |
| `Dim_CountryBin` | 2 | 9 | 13 | 9 |
| `Dim_PlayerStatus` | 2 | 246 | 17 | 39 |
| `Fact_BillingDeposit` | 2 | 126 | 23 | 23 |
| `Fact_BillingWithdraw` | 2 | 84 | 15 | 12 |
| `Dim_BillingProtocolMIDSettingsID` | 1 | 8 | 10 | 2 |
| `Dim_BonusType` | 1 | 0 | 9 | 2 |
| `Dim_Campaign` | 1 | 1 | 10 | 2 |
| `Dim_CashoutStatus` | 1 | 34 | 10 | 3 |
| `Dim_Country` | 1 | 555 | 28 | 60 |
| `Dim_CreditType` | 1 | 6 | 6 | 0 |
| `Dim_DocumentStatus` | 1 | 4 | 11 | 0 |

## FAIL detail (first 200 of 474)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_BillingProtocolMIDSettingsID.md` — 2 FAIL(s)

- **line 147** `ProtocolMIDSettingsID` — L0-unresolved / LOW
  - claim source: `upstream wiki, Billing.ProtocolMIDSettings`
  - source wiki: `…as/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ProtocolMIDSettings.md` (matched col `` via n/a, source tier `n/a`)
  - current: Surrogate primary key. Renamed from `ID` in the production Billing.ProtocolMIDSettings table. Referenced by fact deposit and withdrawal tables to record which routing configuration was used per transaction
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Billing.ProtocolMIDSettings.md: no column matching 'ProtocolMIDSettingsID' (checked 10 rows)

- **line 151** `Value` — L2-semantic / LOW
  - claim source: `upstream wiki, Billing.ProtocolMIDSettings`
  - source wiki: `…as/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ProtocolMIDSettings.md` (matched col `**Value**` via normalised (alphanumeric only), source tier `OLTP-truth`)
  - current: The protocol identifier string (MID, merchant ID, API key, etc.) passed to the payment processor for routing. SENSITIVE -- contains payment gateway credentials. Examples: merchant ID numbers, API endpoint identifiers
  - source:  [CODE-BACKED] The protocol identifier string (MID, merchant ID, API key, etc.). This is the actual routing value passed to the payment processor. Examples: "18989693", "18986763"
  - reason:  The downstream description adds an unsupported claim that the field contains 'payment gateway credentials' and 'API endpoint identifiers', whereas the source describes it as a routing identifier (MID/merchant ID/API key…
  - **proposed**: The protocol identifier string (MID, merchant ID, API key, etc.). This is the actual routing value passed to the payment processor. Examples: "18989693", "18986763" (Tier 1 - Billing.ProtocolMIDSettings.md)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_BonusType.md` — 1 FAIL(s)

- **line 126** `IsActive` — L2-semantic / LOW
  - claim source: `upstream wiki, BackOffice.BonusType`
  - source wiki: `…chemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.BonusType.md` (matched col `IsActive` via exact (case-insensitive), source tier `OLTP-truth`)
  - current: Whether this bonus type is still in active use. False for IDs 0 (N/A placeholder), 17 (Refill-Negative Balance), and 23 (Championship Winner Demo). True for all other 63 types
  - source:  Whether this bonus type is still in active use. 0=deprecated (should not be assigned to new bonuses). Active=0 types: 17=Refill-Negative Balance, 23=Championship Winner Demo. All other 68 types are IsActive=1
  - reason:  Downstream adds ID 0 as inactive and counts 63 active types instead of 68, contradicting the source which only lists IDs 17 and 23 as inactive with 68 active types.
  - **proposed**: Whether this bonus type is still in active use. 0=deprecated (should not be assigned to new bonuses). Active=0 types: 17=Refill-Negative Balance, 23=Championship Winner Demo. All other 68 types are IsActive=1 (Tier 1 - BackOffice.BonusType)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Campaign.md` — 1 FAIL(s)

- **line 94** `Code` — L2-semantic / LOW
  - claim source: `upstream wiki, BackOffice.Campaign`
  - source wiki: `…Schemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Campaign.md` (matched col `Code` via exact (case-insensitive), source tier `OLTP-truth`)
  - current: Unique public-facing campaign code (e.g., "20coupon", "freecopyref"). The identifier customers enter at registration. UNIQUE in production. Currently only 'N/A' (ID=0 placeholder)
  - source:  Unique public-facing campaign code. UNIQUE index. The identifier customers enter at registration (e.g., "20coupon", "freecopyref"). Auto-generated if not supplied to CampaignAdd: 6-char random string. CampaignBunchAdd g…
  - reason:  The downstream description adds a claim that the column currently contains only 'N/A' (ID=0 placeholder), which is an unverified data-quality assertion not present in the source and could mislead analysts into thinking…
  - **proposed**: Unique public-facing campaign code (e.g., "20coupon", "freecopyref"). The identifier customers enter at registration. UNIQUE index. Auto-generated 6-char random string if not supplied. (Tier 1 - BackOffice.Campaign)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_CardType.md` — 1 FAIL(s)

- **line 100** `CarTypeName` — L0-unresolved / LOW
  - claim source: `Dictionary.CardType`
  - source wiki: `…Schemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CardType.md` (matched col `` via n/a, source tier `n/a`)
  - current: Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from `Name` in production. 0=None, 1=Visa, 2=Master Card, 3=Diners, 4=Amex, 5=F…
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Dictionary.CardType.md: no column matching 'CarTypeName' (checked 4 rows)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_CashoutFeeGroup.md` — 1 FAIL(s)

- **line 103** `CashoutFeeGroupName` — L0-unresolved / LOW
  - claim source: `upstream wiki, Dictionary.CashoutFeeGroup`
  - source wiki: `…/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutFeeGroup.md` (matched col `` via n/a, source tier `n/a`)
  - current: Human-readable fee group name: 'Default', 'Exempt', 'Discount'. Renamed from production `Name` column. Used in reporting to display fee group
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Dictionary.CashoutFeeGroup.md: no column matching 'CashoutFeeGroupName' (checked 2 rows)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_CashoutReason.md` — 2 FAIL(s)

- **line 101** `CashoutReasonID` — L0-unresolved / LOW
  - claim source: `- Dictionary.CashoutReason`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Primary key identifying the withdrawal reason. Range 1-19. Stored in Billing.Withdraw, History.WithdrawAction. Default 16 (user request) in WithdrawRequestAdd. Special processing for IN (12, 14, 15) in WithdrawToFunding…
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='- Dictionary.CashoutReason': bare name '- Dictionary.CashoutReason' not found in sibling synapse wikis

- **line 102** `Name` — L0-unresolved / LOW
  - claim source: `- Dictionary.CashoutReason`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Human-readable reason label. No unique constraint. Displayed in BackOffice withdrawal screens via LEFT JOIN. Used in reports, audit trails, and customer-facing credit history
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='- Dictionary.CashoutReason': bare name '- Dictionary.CashoutReason' not found in sibling synapse wikis

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_CashoutStatus.md` — 1 FAIL(s)

- **line 123** `CashoutStatusID` — L2-semantic / MEDIUM
  - claim source: `upstream wiki, Dictionary.CashoutStatus`
  - source wiki: `…as/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutStatus.md` (matched col `CashoutStatusID` via exact (case-insensitive), source tier `OLTP-truth`)
  - current: Primary key. DWH values: 0=N/A (placeholder), 1=Pending, 2=InProcess, 3=Processed, 4=Canceled. Note: production has 17 states (IDs 5-17 missing from DWH). Stored in withdrawal request records and updated as requests pro…
  - source:  Primary key identifying the withdrawal lifecycle state. 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Partially Processed, 6=Payment Sent, 7=Rejected, 8=RejectedByProvider, 9=PendingByProvider, 10=SentToProvider, 1…
  - reason:  Downstream claims only 4 DWH values (0-4) and flags IDs 5-17 as missing, but the source defines all 17 states as valid; this misrepresents the column's population as a subset.
  - **proposed**: Primary key identifying withdrawal lifecycle state (17 values: 1=Pending through 17=Partially Reversed; 0=N/A is a DWH placeholder). See glossary for full mapping. (Tier 1 - Dictionary.CashoutStatus)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_ClientWithdrawReason.md` — 1 FAIL(s)

- **line 106** `ClientWithdrawReasonName` — L0-unresolved / LOW
  - claim source: `upstream wiki, Dictionary.ClientWithdrawReason`
  - source wiki: `…chema/etoro/Wiki/Dictionary/Tables/Dictionary.ClientWithdrawReason.md` (matched col `` via n/a, source tier `n/a`)
  - current: Human-readable reason label shown in the withdrawal form. DWH note: column renamed from production `Name` to `ClientWithdrawReasonName` by SP_Dictionaries_DL_To_Synapse. E.g., "Withdrawing profits", "Moving to a competi…
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Dictionary.ClientWithdrawReason.md: no column matching 'ClientWithdrawReasonName' (checked 4 rows)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_ClosePositionReason.md` — 2 FAIL(s)

- **line 121** `ClosePositionReasonID` — L0-unresolved / LOW
  - claim source: `upstream wiki, Dictionary.ClosePositionActionType`
  - source wiki: `…ma/etoro/Wiki/Dictionary/Tables/Dictionary.ClosePositionActionType.md` (matched col `` via n/a, source tier `n/a`)
  - current: Primary key. DWH rename of production `ID`. Values 0-26. 0=Customer (manual), 1=Stop Loss, 2=End of Week, 3=SL via trade server, 4=Return to Market, 5=Take Profit, 6=TP via trade server, 7=Contact Rollover, 8=BackOffice…
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Dictionary.ClosePositionActionType.md: no column matching 'ClosePositionReasonID' (checked 2 rows)

- **line 122** `Name` — L0-unresolved / LOW
  - claim source: `upstream wiki, Dictionary.ClosePositionActionType`
  - source wiki: `…ma/etoro/Wiki/Dictionary/Tables/Dictionary.ClosePositionActionType.md` (matched col `` via n/a, source tier `n/a`)
  - current: DWH rename of production `ClosePositionActionName`. Human-readable closure trigger label. E.g., "Customer", "Stop Loss", "Hierarchical Close", "BSL". Used in account statements, trading reports, and position analytics
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Dictionary.ClosePositionActionType.md: no column matching 'Name' (checked 2 rows)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Country.md` — 1 FAIL(s)

- **line 169** `MarketingRegionID` — L2-semantic / LOW
  - claim source: `Dictionary.Country upstream wiki`
  - source wiki: `…dSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` (matched col `MarketingRegionID` via exact (case-insensitive), source tier `OLTP-truth`)
  - current: FK to etoro.Dictionary.MarketingRegion. Marketing segment ID grouping countries by marketing strategy. Distinct from geographic RegionID (which is dropped in DWH). 22 distinct values matching the 22 Region labels
  - source:  FK to Dictionary.MarketingRegion. Segments countries for marketing campaigns. Distinct from geographic Region — MarketingRegion groups by marketing strategy (e.g., "Arabic" cuts across Asia/Africa regions)
  - reason:  Downstream conflates MarketingRegion with Region by saying '22 distinct values matching the 22 Region labels', implying they are the same set, and incorrectly states geographic RegionID is dropped in DWH — neither claim…
  - **proposed**: FK to Dictionary.MarketingRegion. Segments countries by marketing strategy (e.g. 'Arabic' cuts across Asia/Africa regions). Distinct from geographic RegionID. (Tier 1 - Dictionary.Country)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_CountryBin.md` — 2 FAIL(s)

- **line 115** `BinCode` — L2-semantic / MEDIUM
  - claim source: `Dictionary.CountryBin6 upstream wiki`
  - source wiki: `…emas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CountryBin6.md` (matched col `BinCode` via exact (case-insensitive), source tier `OLTP-truth`)
  - current: Bank Identification Number. First 6 or 8 digits of the card number identifying the issuing bank and card product. Values < 10,000,000 are 6-digit BINs; >= 10,000,000 are 8-digit BINs. Clustered index key for fast lookups
  - source:  6-digit BIN (must be < 10,000,000 per CHK_CountryBin6). Part of composite PK. Indexed by IX_DCNB_Bincode
  - reason:  Source constrains BinCode strictly to 6-digit BINs (< 10,000,000), but the claimed description expands scope to include 8-digit BINs (>= 10,000,000), which is not supported by the source.
  - **proposed**: 6-digit Bank Identification Number (BIN) identifying the issuing bank; constrained to values < 10,000,000 per CHK_CountryBin6. Part of composite PK and indexed by IX_DCNB_Bincode (Tier 1 - Dictionary.CountryBin6)

- **line 123** `MinAmountFor3ds` — L2-semantic / LOW
  - claim source: `Dictionary.CountryBin6 upstream wiki`
  - source wiki: `…emas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CountryBin6.md` (matched col `MinAmountFor3ds` via exact (case-insensitive), source tier `OLTP-truth`)
  - current: Minimum deposit amount (in account currency units) that triggers 3DS verification for this BIN. 0 = all amounts require 3DS when ShouldCheck3ds=1. Only meaningful when ShouldCheck3ds=1
  - source:  Minimum amount that triggers 3DS check. NULL = no minimum
  - reason:  Downstream adds specific semantics (0 = all amounts, only meaningful when ShouldCheck3ds=1, account currency units) not stated in the source, and replaces NULL=no minimum with different logic.
  - **proposed**: Minimum amount that triggers 3DS check. NULL = no minimum. (Tier 1 - Dictionary.CountryBin6)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_CreditType.md` — 2 FAIL(s)

- **line 119** `CreditTypeID` — L2-semantic / LOW
  - claim source: `Dictionary.CreditType`
  - source wiki: `…hemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CreditType.md` (matched col `CreditTypeID` via exact (case-insensitive), source tier `OLTP-truth`)
  - current: Financial operation type identifier (1-33). Classifies every balance change: 1=Deposit, 2=Cashout, 3=Open Position, 4=Close Position, 5=Champ Winner, 6=Compensation, 7=Bonus, 8=Reverse Cashout, 9=Cashout Request, 10=IB…
  - source:  Financial operation type identifier (1-33). Classifies every balance change: 1=Deposit, 2=Cashout, 3=Open Position, 4=Close Position, 5=Champ Winner, 6=Compensation, 7=Bonus, 8=Reverse Cashout, 9=Cashout Request, 10=IB…
  - reason:  Source says 29-30=Stock Orders while downstream says 29-30=Close Stock Order, narrowing the scope from general stock orders to only closing ones.
  - **proposed**: Financial operation type identifier (1-33). Classifies every balance change: ...29-30=Stock Orders... (Tier 1 - Dictionary.CreditType)

- **line 120** `CreditTypeName` — L0-unresolved / LOW
  - claim source: `Dictionary.CreditType`
  - source wiki: `…hemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CreditType.md` (matched col `` via n/a, source tier `n/a`)
  - current: Human-readable operation name. Unique constraint ensures no duplicate names. Used in financial reports, transaction history, and reconciliation tools. Note: char(50) with trailing spaces — always RTRIM when displaying.…
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Dictionary.CreditType.md: no column matching 'CreditTypeName' (checked 2 rows) | Dictionary.CreditType.md: no column matching 'CreditTypeName' (checked 2 rows)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` — 4 FAIL(s)

- **line 157** `AffiliateID` — L0-unresolved / LOW
  - claim source: `Customer.CustomerStatic`
  - source wiki: `…hemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.CustomerStatic.md` (matched col `` via n/a, source tier `n/a`)
  - current: Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Customer.CustomerStatic.md: no column matching 'AffiliateID' (checked 106 rows)

- **line 172** `RegisteredReal` — L0-unresolved / LOW
  - claim source: `Customer.CustomerStatic`
  - source wiki: `…hemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.CustomerStatic.md` (matched col `` via n/a, source tier `n/a`)
  - current: Account registration date (renamed from Registered). Default=getdate()
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Customer.CustomerStatic.md: no column matching 'RegisteredReal' (checked 106 rows)

- **line 222** `EmployeeAccount` — L0-unresolved / LOW
  - claim source: `BackOffice.Customer`
  - source wiki: `…Schemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Customer.md` (matched col `` via n/a, source tier `n/a`)
  - current: 1 if this is an eToro employee personal trading account (renamed from isEmployeeAccount). Flags employee accounts for special monitoring and compliance checks
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  BackOffice.Customer.md: no column matching 'EmployeeAccount' (checked 67 rows)

- **line 248** `AccountManagerID` — L0-unresolved / LOW
  - claim source: `BackOffice.Customer`
  - source wiki: `…Schemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Customer.md` (matched col `` via n/a, source tier `n/a`)
  - current: Currently assigned BackOffice sales/service agent (renamed from ManagerID). FK to BackOffice.Manager. NULL = unassigned
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  BackOffice.Customer.md: no column matching 'AccountManagerID' (checked 67 rows)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Date.md` — 27 FAIL(s)

- **line 133** `DateKey` — L0-unresolved / LOW
  - claim source: `DDL + SP_PopulateDimDate`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Primary key. Date encoded as integer YYYYMMDD (e.g. 20260101 for 2026-01-01). The join target for every date-keyed fact in the warehouse
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='DDL + SP_PopulateDimDate': bare name 'DDL + SP_PopulateDimDate' not found in sibling synapse wikis

- **line 134** `FullDate` — L0-unresolved / LOW
  - claim source: `DDL`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Native SQL date (e.g. 2026-01-01). 1:1 with DateKey. Use this when a date-typed comparison is needed; use DateKey for integer joins
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='DDL': sentinel 'DDL': explicitly declares no upstream wiki

- **line 135** `MonthNumberOfYear` — L0-unresolved / LOW
  - claim source: `DDL`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Month number 1-12 (1=January)
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='DDL': sentinel 'DDL': explicitly declares no upstream wiki

- **line 138** `ISOWeekNumberOfYear` — L0-unresolved / LOW
  - claim source: `DDL`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: ISO-8601 week number of year (1-53). Week starts Monday
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='DDL': sentinel 'DDL': explicitly declares no upstream wiki

- **line 139** `SSWeekNumberOfYear` — L0-unresolved / LOW
  - claim source: `DDL`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Sunday-Start week number of year (1-53). Week starts Sunday — US retail convention
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='DDL': sentinel 'DDL': explicitly declares no upstream wiki

- **line 143** `DayNumberOfYear` — L0-unresolved / LOW
  - claim source: `DDL`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Day-of-year 1-366. Jan 1 = 1, Dec 31 = 365 (or 366 in leap year)
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='DDL': sentinel 'DDL': explicitly declares no upstream wiki

- **line 144** `DaysSince1900` — L0-unresolved / LOW
  - claim source: `DDL`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Numeric days elapsed since 1900-01-01 — useful for delta/age calculations and for compatibility with legacy serial-date systems
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='DDL': sentinel 'DDL': explicitly declares no upstream wiki

- **line 145** `DayNumberOfFiscalYear` — L0-unresolved / LOW
  - claim source: `SP`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Day-of-year within the fiscal year (1-366). Currently equal to DayNumberOfYear because @FiscalYearMonthsOffset=0
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='SP': bare name 'SP' not found in sibling synapse wikis

- **line 147** `DayNumberOfMonth` — L0-unresolved / LOW
  - claim source: `DDL`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Day-of-month 1-31
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='DDL': sentinel 'DDL': explicitly declares no upstream wiki

- **line 148** `DayNumberOfWeek_Sun_Start` — L0-unresolved / LOW
  - claim source: `SP`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Day-of-week with Sunday=1, Saturday=7 (US convention; SET DATEFIRST 7 in SP)
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='SP': bare name 'SP' not found in sibling synapse wikis

- **line 150** `MonthNameAbbreviation` — L0-unresolved / LOW
  - claim source: `DDL`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: 3-letter month abbreviation (`'Jan'`, `'Feb'`, ..., `'Dec'`)
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='DDL': sentinel 'DDL': explicitly declares no upstream wiki

- **line 151** `DayName` — L0-unresolved / LOW
  - claim source: `DDL`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Full English weekday name (`'Sunday'`, `'Monday'`, ..., `'Saturday'`)
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='DDL': sentinel 'DDL': explicitly declares no upstream wiki

- **line 152** `DayNameAbbreviation` — L0-unresolved / LOW
  - claim source: `DDL`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: 3-letter weekday abbreviation (`'Sun'`, `'Mon'`, ..., `'Sat'`)
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='DDL': sentinel 'DDL': explicitly declares no upstream wiki

- **line 153** `CalendarYear` — L0-unresolved / LOW
  - claim source: `DDL`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Calendar year (e.g. 2026)
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='DDL': sentinel 'DDL': explicitly declares no upstream wiki

- **line 157** `CalendarQuarter` — L0-unresolved / LOW
  - claim source: `DDL`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Calendar quarter 1-4
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='DDL': sentinel 'DDL': explicitly declares no upstream wiki

- **line 158** `FiscalYear` — L0-unresolved / LOW
  - claim source: `SP`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Fiscal year. With current `@FiscalYearMonthsOffset=0`, equals CalendarYear
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='SP': bare name 'SP' not found in sibling synapse wikis

- **line 159** `FiscalMonth` — L0-unresolved / LOW
  - claim source: `SP`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Fiscal month 1-12 (= CalendarMonth at offset=0)
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='SP': bare name 'SP' not found in sibling synapse wikis

- **line 165** `MM/DD/YYYY` — L0-unresolved / LOW
  - claim source: `DDL`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Date string in US display format `MM/DD/YYYY` (e.g. `'01/01/2026'`). Backtick the column name in UC
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='DDL': sentinel 'DDL': explicitly declares no upstream wiki

- **line 166** `YYYY/MM/DD` — L0-unresolved / LOW
  - claim source: `DDL`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Date string in slash-separated ISO order `YYYY/MM/DD`. Backtick required
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='DDL': sentinel 'DDL': explicitly declares no upstream wiki

- **line 167** `YYYY-MM-DD` — L0-unresolved / LOW
  - claim source: `DDL`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Date string in ISO-8601 dashed order `YYYY-MM-DD`. Same content as FullDate as text. Backtick required
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='DDL': sentinel 'DDL': explicitly declares no upstream wiki

- **line 171** `IsWeekend` — L0-unresolved / LOW
  - claim source: `DDL`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: `'Y'` if day is Sat-Sun, else `'N'`
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='DDL': sentinel 'DDL': explicitly declares no upstream wiki

- **line 172** `IsWorkday` — L0-unresolved / LOW
  - claim source: `SP_PopulateDimDate`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: `'Y'` if day is Mon-Fri AND NOT a US federal/bank holiday — i.e. business day under US calendar. Use this (not IsWeekday) for trading-day / business-day filters
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='SP_PopulateDimDate': bare name 'SP_PopulateDimDate' not found in sibling synapse wikis

- **line 173** `IsFederalHoliday` — L0-unresolved / LOW
  - claim source: `SP`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: `'Y'` if day is a US Federal holiday (New Year's, MLK, Presidents, Memorial, Independence, Labor, Columbus, Veterans, Thanksgiving, Christmas) per the hard-coded calendar in SP_PopulateDimDate. US-only — do not use for…
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='SP': bare name 'SP' not found in sibling synapse wikis

- **line 174** `IsBankHoliday` — L0-unresolved / LOW
  - claim source: `SP`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: `'Y'` if day is a US bank holiday (Federal holidays + day-after-Thanksgiving)
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='SP': bare name 'SP' not found in sibling synapse wikis

- **line 175** `IsCompanyHoliday` — L0-unresolved / LOW
  - claim source: `SP`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: `'Y'` if day is a US corporate holiday (Bank holidays + Christmas Eve)
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='SP': bare name 'SP' not found in sibling synapse wikis

- **line 177** `UpdateDate` — L0-unresolved / LOW
  - claim source: `DDL`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: ETL load timestamp. NULL on rows pre-existing the introduction of this column; populated with `GETDATE()` by SP_PopulateDimDate runs from 2018+
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='DDL': sentinel 'DDL': explicitly declares no upstream wiki

- **line 178** `IsFirstDayOfMonth` — L0-unresolved / LOW
  - claim source: `SP change history`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: `'Y'` if FullDate is the 1st of its calendar month, else `'N'`. Added 2020-11-16 (Boris Slutski) — older rows may have NULL until the SP is re-run
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='SP change history': bare name 'SP change history' not found in sibling synapse wikis

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_DocumentStatus.md` — 1 FAIL(s)

- **line 100** `DocumentStatusID` — L2-semantic / HIGH
  - claim source: `Dictionary.DocumentStatus`
  - source wiki: `…s/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DocumentStatus.md` (matched col `DocumentStatusID` via exact (case-insensitive), source tier `OLTP-truth`)
  - current: Primary key identifying the document review state. 1=New Upload, 2=Reviewed, 3=Accepted, 4=Rejected, 5=POIApproved
  - source:  Primary key identifying the document review state. 1=Uploaded, 2=PendingReview, 3=Approved, 4=Declined, 5=Expired. See [Document Status](_glossary.md#document-status). (Dictionary.DocumentStatus)
  - reason:  Status labels differ materially: source says 2=PendingReview but claim says 2=Reviewed (opposite meaning), 3=Approved vs 3=Accepted is minor, but 5=Expired vs 5=POIApproved are completely different statuses.
  - **proposed**: Primary key identifying the document review state. 1=Uploaded, 2=PendingReview, 3=Approved, 4=Declined, 5=Expired. See glossary Document Status. (Tier 1 - Dictionary.DocumentStatus)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_FeeOperationTypes.md` — 1 FAIL(s)

- **line 119** `FeeOperationTypeName` — L0-unresolved / LOW
  - claim source: `Dictionary.FeeOperationTypes`
  - source wiki: `…B_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FeeOperationTypes.md` (matched col `` via n/a, source tier `n/a`)
  - current: Human-readable phase label: 'Open', 'Close', 'All'. Used in trading engine configuration and admin UIs
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Dictionary.FeeOperationTypes.md: no column matching 'FeeOperationTypeName' (checked 2 rows)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_FundType.md` — 1 FAIL(s)

- **line 98** `FundTypeName` — L0-unresolved / LOW
  - claim source: `Dictionary.FundType`
  - source wiki: `…Schemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FundType.md` (matched col `` via n/a, source tier `n/a`)
  - current: Human-readable label for the fund type. Used in the platform UI, fund details pages, and management reporting. Describes the fundamental strategy approach of the fund category
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Dictionary.FundType.md: no column matching 'FundTypeName' (checked 2 rows)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_GuruStatus.md` — 1 FAIL(s)

- **line 130** `GuruStatusName` — L0-unresolved / LOW
  - claim source: `Dictionary.GuruStatus`
  - source wiki: `…hemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.GuruStatus.md` (matched col `` via n/a, source tier `n/a`)
  - current: Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Dictionary.GuruStatus.md: no column matching 'GuruStatusName' (checked 2 rows) | Dictionary.GuruStatus.md: no column matching 'GuruStatusName' (checked 2 rows)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Instrument.md` — 6 FAIL(s)

- **line 146** `DWHInstrumentID` — L0-unresolved / LOW
  - claim source: `Trade.GetInstrument`
  - source wiki: `…e/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Views/Trade.GetInstrument.md` (matched col `` via n/a, source tier `n/a`)
  - current: Alias of InstrumentID (InstrumentID AS DWHInstrumentID). Always equals InstrumentID
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Trade.GetInstrument.md: no column matching 'DWHInstrumentID' (checked 19 rows)

- **line 148** `BuyCurrencyID` — L2-semantic / MEDIUM
  - claim source: `Trade.GetInstrument`
  - source wiki: `…e/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Views/Trade.GetInstrument.md` (matched col `BuyCurrencyID` via exact (case-insensitive), source tier `OLTP-truth`)
  - current: FK to Dictionary.Currency. Buy-side asset. For forex: base currency; for stocks: asset itself (BuyCurrencyID=InstrumentID). Inherited from Trade.Instrument
  - source:  Buy-side abbreviation
  - reason:  Source says the column holds a currency abbreviation (text), while the claim says it is a foreign key ID to Dictionary.Currency; abbreviation vs FK integer changes how an analyst would join or filter.
  - **proposed**: Buy-side currency abbreviation. For forex: base currency code; for stocks: the asset code (BuyCurrencyID=InstrumentID). Inherited from Trade.Instrument (Tier 1 - Trade.GetInstrument)

- **line 150** `BuyCurrency` — L0-unresolved / LOW
  - claim source: `Dictionary.Currency`
  - source wiki: `…Schemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Currency.md` (matched col `` via n/a, source tier `n/a`)
  - current: Trading symbol / ticker for the buy-side currency. "USD", "EUR", "AAPL.US". UNIQUE constraint in production. The primary identifier used in UIs and APIs. Passthrough from Dictionary.Currency.Abbreviation via buy-side jo…
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Dictionary.Currency.md: no column matching 'BuyCurrency' (checked 12 rows) | Dictionary.Currency.md: no column matching 'BuyCurrency' (checked 2 rows)

- **line 151** `SellCurrency` — L0-unresolved / LOW
  - claim source: `Dictionary.Currency`
  - source wiki: `…Schemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Currency.md` (matched col `` via n/a, source tier `n/a`)
  - current: Trading symbol / ticker for the sell-side currency. "USD", "EUR", "GBX". UNIQUE constraint in production. Passthrough from Dictionary.Currency.Abbreviation via sell-side join
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Dictionary.Currency.md: no column matching 'SellCurrency' (checked 12 rows) | Dictionary.Currency.md: no column matching 'SellCurrency' (checked 2 rows)

- **line 185** `ProviderMarginPerLot` — L0-unresolved / LOW
  - claim source: `Trade.FuturesInstrumentsInitialMarginByProviderMapping`
  - source wiki: `…rade/Tables/Trade.FuturesInstrumentsInitialMarginByProviderMapping.md` (matched col `` via n/a, source tier `n/a`)
  - current: Cash margin required to open one unit/lot of this futures instrument with this provider. Expressed in the instrument's base currency. Renamed from InitialMargin
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Trade.FuturesInstrumentsInitialMarginByProviderMapping.md: no column matching 'ProviderMarginPerLot' (checked 9 rows)

- **line 186** `eToroMarginPerLot` — L0-unresolved / LOW
  - claim source: `Trade.ProviderToInstrument`
  - source wiki: `…hemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ProviderToInstrument.md` (matched col `` via n/a, source tier `n/a`)
  - current: Initial margin in asset currency as set by eToro. Renamed from InitialMarginInAssetCurrency. From Trade.ProviderToInstrument
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Trade.ProviderToInstrument.md: no column matching 'eToroMarginPerLot' (checked 92 rows)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Mirror.md` — 1 FAIL(s)

- **line 159** `RealziedPnL` — L0-unresolved / LOW
  - claim source: `Trade.Mirror`
  - source wiki: `…owledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Mirror.md` (matched col `` via n/a, source tier `n/a`)
  - current: Net realized profit/loss of the mirror in USD. NOTE: column name has a typo ('Realzied' not 'Realized') — use exact spelling in queries. For closed mirrors: final P&L from History.Mirror.NetProfit. For open mirrors: run…
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Trade.Mirror.md: no column matching 'RealziedPnL' (checked 30 rows)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PaymentStatus.md` — 1 FAIL(s)

- **line 113** `PaymentStatusID` — L2-semantic / HIGH
  - claim source: `Dictionary.PaymentStatus`
  - source wiki: `…as/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PaymentStatus.md` (matched col `PaymentStatusID` via exact (case-insensitive), source tier `OLTP-truth`)
  - current: Primary key identifying the payment state. 1=New, 2=Approved, 3=Decline, 4=Technical, 5=InProcess, 6=Canceled, 7=Confirmed
  - source:  Primary key identifying the payment state. 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Failed, 6=Reversed, 7=CompletedExternally. See [Payment Status](_glossary.md#payment-status). (Dictionary.PaymentStatus)
  - reason:  The downstream description maps entirely different status labels to the same IDs (e.g., 1=New vs 1=Pending, 2=Approved vs 2=InProcess), describing a different enumeration that would cause analysts to misinterpret every…
  - **proposed**: Primary key identifying the payment state. 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Failed, 6=Reversed, 7=CompletedExternally. See Payment Status glossary. (Tier 1 - Dictionary.PaymentStatus)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PlayerStatus.md` — 2 FAIL(s)

- **line 150** `CanLogin` — L2-semantic / MEDIUM
  - claim source: `upstream wiki, Dictionary.PlayerStatus`
  - source wiki: `…mas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PlayerStatus.md` (matched col `CanLogin` via exact (case-insensitive), source tier `OLTP-truth`)
  - current: Whether the user can authenticate and access the platform. False when IsBlocked=1. True for all partial-restriction statuses -- wind-down users can view their portfolio
  - source:  Whether the user can authenticate and access the platform. When false, login attempts are rejected at the gate. Checked by History.LogIn and History.LogInIB procedures
  - reason:  The downstream description adds specific implementation claims (IsBlocked=1 logic, wind-down user behavior) not present in the source, which only states it controls login gate checks.
  - **proposed**: Whether the user can authenticate and access the platform. When false, login attempts are rejected at the gate. Checked by History.LogIn and History.LogInIB procedures (Tier 1 - Dictionary.PlayerStatus)

- **line 151** `CanChatAndPost` — L2-semantic / LOW
  - claim source: `upstream wiki, Dictionary.PlayerStatus`
  - source wiki: `…mas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PlayerStatus.md` (matched col `CanChatAndPost` via exact (case-insensitive), source tier `OLTP-truth`)
  - current: Whether the user can post to the social feed or chat. False when IsBlocked=1 and for status 3 (Chat Blocked). True for all other statuses including close-only
  - source:  Whether the user can post to the social feed, comment, or chat. When false, the user can view social content but cannot contribute. Applied by status 3 (Chat Blocked) for social policy violations
  - reason:  Downstream adds that CanChatAndPost is false when IsBlocked=1, which is not stated in the source; source also mentions commenting, which the downstream omits.
  - **proposed**: Whether the user can post to the social feed, comment, or chat. When false the user can view social content but cannot contribute. Applied by status 3 (Chat Blocked) for social policy violations (Tier 1 - Dictionary.PlayerStatus)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PlayerStatusSubReasons.md` — 1 FAIL(s)

- **line 127** `PlayerStatusSubReasonName` — L0-unresolved / LOW
  - claim source: `upstream wiki, Dictionary.PlayerStatusSubReasons`
  - source wiki: `…ema/etoro/Wiki/Dictionary/Tables/Dictionary.PlayerStatusSubReasons.md` (matched col `` via n/a, source tier `n/a`)
  - current: Human-readable sub-reason label (renamed from production `Name`). Nullable. Key abbreviations: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address, FTD=First Time Deposit, MOP=Method of Payment, PWMB=eToro Mone…
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Dictionary.PlayerStatusSubReasons.md: no column matching 'PlayerStatusSubReasonName' (checked 2 rows) | Dictionary.PlayerStatusSubReasons.md: no column matching 'PlayerStatusSubReasonName' (checked 2 rows)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Position.md` — 9 FAIL(s)

- **line 238** `OpenOccurred` — L0-unresolved / LOW
  - claim source: `Trade.PositionTbl`
  - source wiki: `…ge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionTbl.md` (matched col `` via n/a, source tier `n/a`)
  - current: When position was persisted (mapped from Occurred in production). Default getutcdate()
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Trade.PositionTbl.md: no column matching 'OpenOccurred' (checked 133 rows)

- **line 242** `RequestOpenOccurred` — L0-unresolved / LOW
  - claim source: `Trade.PositionTbl`
  - source wiki: `…ge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionTbl.md` (matched col `` via n/a, source tier `n/a`)
  - current: When the open request arrived at Trading API. Distinct from OpenOccurred (DB insert time)
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Trade.PositionTbl.md: no column matching 'RequestOpenOccurred' (checked 133 rows)

- **line 278** `CloseOnEndOfWeek` — L0-unresolved / LOW
  - claim source: `Trade.PositionTbl`
  - source wiki: `…ge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionTbl.md` (matched col `` via n/a, source tier `n/a`)
  - current: Weekend-close flag. 1 = position auto-closes at end of trading week
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Trade.PositionTbl.md: no column matching 'CloseOnEndOfWeek' (checked 133 rows)

- **line 279** `LimitRate` — L0-unresolved / LOW
  - claim source: `Trade.PositionTbl`
  - source wiki: `…ge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionTbl.md` (matched col `` via n/a, source tier `n/a`)
  - current: Take-profit rate set at open (or most recent update)
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Trade.PositionTbl.md: no column matching 'LimitRate' (checked 133 rows)

- **line 280** `StopRate` — L0-unresolved / LOW
  - claim source: `Trade.PositionTbl`
  - source wiki: `…ge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionTbl.md` (matched col `` via n/a, source tier `n/a`)
  - current: Stop-loss rate set at open (or most recent update). Can be updated via PositionChangeLog
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Trade.PositionTbl.md: no column matching 'StopRate' (checked 133 rows)

- **line 370** `TreeID` — L2-semantic / HIGH
  - claim source: `Trade.PositionTbl`
  - source wiki: `…ge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionTbl.md` (matched col `TreeID` via exact (case-insensitive), source tier `OLTP-truth`)
  - current: Links to Trade.PositionTreeInfo. Root: TreeID=PositionID. Children: root PositionID. Demo: negative
  - source:  SL/TP/TSL settings
  - reason:  Source says TreeID holds SL/TP/TSL settings, while the claim describes it as a parent-child linkage key to PositionTreeInfo — different real-world meaning.
  - **proposed**: SL/TP/TSL settings for the position; also used as linkage key in Trade.PositionTreeInfo hierarchy (Tier 1 - Trade.PositionTbl wiki)

- **line 400** `ClosePositionReasonID` — L0-unresolved / LOW
  - claim source: `Trade.PositionTbl`
  - source wiki: `…ge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionTbl.md` (matched col `` via n/a, source tier `n/a`)
  - current: Close reason mapped from ActionType. 0=Customer, 1=Stop Loss, 5=Take Profit, 9=Hierarchical Close
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Trade.PositionTbl.md: no column matching 'ClosePositionReasonID' (checked 133 rows)

- **line 401** `OpenPositionReasonID` — L0-unresolved / LOW
  - claim source: `Trade.PositionTbl`
  - source wiki: `…ge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionTbl.md` (matched col `` via n/a, source tier `n/a`)
  - current: Open reason mapped from OpenActionType. 0=Customer, 1=Hierarchical Open, 2=Reopen, 3=Open Open, 13=ACATS_IN
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Trade.PositionTbl.md: no column matching 'OpenPositionReasonID' (checked 133 rows)

- **line 420** `IsDiscounted` — L0-unresolved / LOW
  - claim source: `Trade.PositionTbl`
  - source wiki: `…ge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionTbl.md` (matched col `` via n/a, source tier `n/a`)
  - current: 1=position received a discounted rate. DWH note: CAST from bit to int
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Trade.PositionTbl.md: no column matching 'IsDiscounted' (checked 133 rows)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PositionHedgeServerChangeLog_Snapshot.md` — 1 FAIL(s)

- **line 118** `HedgeServerID` — L0-unresolved / LOW
  - claim source: `Trade.PositionsHedgeServerChangeLog`
  - source wiki: `…Schema/etoro/Wiki/Trade/Tables/Trade.PositionsHedgeServerChangeLog.md` (matched col `` via n/a, source tier `n/a`)
  - current: The hedge server ID the position was moved to. After this operation, Trade.PositionTbl.HedgeServerID equals this value for the affected position
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Trade.PositionsHedgeServerChangeLog.md: no column matching 'HedgeServerID' (checked 11 rows)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_RedeemReason.md` — 1 FAIL(s)

- **line 116** `RedeemReasonName` — L0-unresolved / LOW
  - claim source: `upstream wiki, Dictionary.RedeemReason`
  - source wiki: `…mas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RedeemReason.md` (matched col `` via n/a, source tier `n/a`)
  - current: Internal reason code name. DWH note: renamed from Name in production source. Prefix convention: Rre = Redeem Rejection, ServerError = service failure, Failed = processing failure. Values: RreTradeBlocked(1), RreFundingB…
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Dictionary.RedeemReason.md: no column matching 'RedeemReasonName' (checked 4 rows)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_RedeemStatus.md` — 1 FAIL(s)

- **line 128** `DisplayName` — L2-semantic / LOW
  - claim source: `upstream wiki, Dictionary.RedeemStatus`
  - source wiki: `…mas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RedeemStatus.md` (matched col `DisplayName` via exact (case-insensitive), source tier `OLTP-truth`)
  - current: User-facing label. Currently matches Name for most rows. Shown in copy-trading UI and notifications
  - source:  User-facing display label. More readable than the internal Name. Shown in copy-trading UI and notifications
  - reason:  Source says DisplayName is 'more readable than the internal Name', while the claim says it 'currently matches Name for most rows', which contradicts the source's distinction between the two.
  - **proposed**: User-facing display label. More readable than the internal Name. Shown in copy-trading UI and notifications (Tier 1 - Dictionary.RedeemStatus)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Regulation.md` — 1 FAIL(s)

- **line 121** `ID` — L2-semantic / MEDIUM
  - claim source: `upstream wiki, Dictionary.Regulation`
  - source wiki: `…Bs/RiskClassification/Wiki/Dictionary/Tables/Dictionary.Regulation.md` (matched col `ID` via exact (case-insensitive), source tier `OLTP-truth`)
  - current: Primary key identifying the regulatory authority. 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA. Stored…
  - source:  Regulation identifier. PK. Values: 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 14=NYDFSFINRA. ID 13 is skipped
  - reason:  Downstream adds ID 13=MAS which the source says is skipped, and changes ID 14 label from NYDFSFINRA to NYDFS+FINRA.
  - **proposed**: Primary key identifying the regulation. 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 14=NYDFSFINRA. ID 13 is skipped (Tier 1 - Dictionary.Regulation)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_ThreeDsResponseTypes.md` — 1 FAIL(s)

- **line 100** `ThreeDsResponseTypesName` — L0-unresolved / LOW
  - claim source: `upstream wiki, Dictionary.ThreeDsResponseTypes`
  - source wiki: `…chema/etoro/Wiki/Dictionary/Tables/Dictionary.ThreeDsResponseTypes.md` (matched col `` via n/a, source tier `n/a`)
  - current: Human-readable label for the 3DS outcome. Source column is `Name` in Dictionary.ThreeDsResponseTypes; renamed in DWH with plural suffix. Used in deposit reporting to display authentication outcomes. All 15 rows are popu…
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Dictionary.ThreeDsResponseTypes.md: no column matching 'ThreeDsResponseTypesName' (checked 17 rows)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_BillingDeposit.md` — 2 FAIL(s)

- **line 165** `BonusStatusID` — L2-semantic / LOW
  - claim source: `Billing.Deposit`
  - source wiki: `…ge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (matched col `BonusStatusID` via exact (case-insensitive), source tier `OLTP-truth`)
  - current: Passthrough `d.BonusStatusID`
  - source:  Status of promotional bonus for this deposit
  - reason:  The downstream description is a raw lineage reference rather than a business-meaning description, so an analyst cannot understand what the column represents without chasing the source.
  - **proposed**: Status of promotional bonus for this deposit (Tier 1 - Billing.Deposit)

- **line 269** `IsSetBalanceCompleted` — L2-semantic / MEDIUM
  - claim source: `Billing.Deposit`
  - source wiki: `…ge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (matched col `IsSetBalanceCompleted` via exact (case-insensitive), source tier `OLTP-truth`)
  - current: ETL `CAST(d.IsSetBalanceCompleted AS INT)` (`SP…` Ext_FBD). Production `bit`
  - source:  Whether the balance set/credit operation (`Billing.AmountAdd`) for this deposit has been completed. Set by IsSetBalanceCompleted=1 after AmountAdd succeeds. Used in reconciliation to identify deposits where account cred…
  - reason:  The downstream description only documents the ETL cast mechanics, not the column's business meaning (whether the balance-credit operation for the deposit completed).
  - **proposed**: Whether the balance-credit operation (Billing.AmountAdd) for this deposit has completed; 1 = account crediting succeeded, 0 = pending retry. Cast from bit to INT by ETL. (Tier 1 - Billing.Deposit.md)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_BillingWithdraw.md` — 10 FAIL(s)

- **line 140** `FundingTypeID_Withdraw` — L0-unresolved / LOW
  - claim source: `Billing.Withdraw`
  - source wiki: `…e/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (matched col `` via n/a, source tier `n/a`)
  - current: Payment method type of the withdrawal request (Visa/Wire/Neteller/eToroMoney/etc.). 26 distinct values in production. Renamed from FundingTypeID to disambiguate from Billing.Funding's FundingTypeID
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Billing.Withdraw.md: no column matching 'FundingTypeID_Withdraw' (checked 35 rows)

- **line 142** `Amount_Withdraw` — L0-unresolved / LOW
  - claim source: `Billing.Withdraw`
  - source wiki: `…e/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (matched col `` via n/a, source tier `n/a`)
  - current: Gross withdrawal amount in CurrencyID denomination. Renamed from Amount to disambiguate from WithdrawToFunding Amount
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Billing.Withdraw.md: no column matching 'Amount_Withdraw' (checked 35 rows)

- **line 151** `AccountCurrencyID` — L2-semantic / MEDIUM
  - claim source: `Billing.Withdraw`
  - source wiki: `…e/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (matched col `AccountCurrencyID` via exact (case-insensitive), source tier `OLTP-truth`)
  - current: Customer eToro account currency, if different from CurrencyID. Used when account and withdrawal currencies differ. FK to Dim_Currency
  - source:  Customer account currency
  - reason:  The downstream description adds a conditional qualifier ('if different from CurrencyID') that narrows the column's meaning to a subset of cases, whereas the source simply defines it as the customer's account currency un…
  - **proposed**: Customer account currency. FK to Dim_Currency (Tier 1 - Billing.Withdraw)

- **line 152** `CashoutStatusID_Withdraw` — L0-unresolved / LOW
  - claim source: `Billing.Withdraw`
  - source wiki: `…e/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (matched col `` via n/a, source tier `n/a`)
  - current: Withdrawal request-level status. FK to Dim_CashoutStatus. 10 distinct values: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled. Renamed from CashoutStatusID
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Billing.Withdraw.md: no column matching 'CashoutStatusID_Withdraw' (checked 35 rows)

- **line 156** `CashoutStatusID_Funding` — L0-unresolved / LOW
  - claim source: `Billing.WithdrawToFunding`
  - source wiki: `…emas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawToFunding.md` (matched col `` via n/a, source tier `n/a`)
  - current: Execution-level status of the payment leg. FK to Dim_CashoutStatus. Values: 3=Processed (31.5%), 4=Canceled (67.7%), 14=Pending Review, 17=Partially Reversed. Renamed from CashoutStatusID
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Billing.WithdrawToFunding.md: no column matching 'CashoutStatusID_Funding' (checked 40 rows)

- **line 159** `Amount_WithdrawToFunding` — L0-unresolved / LOW
  - claim source: `Billing.WithdrawToFunding`
  - source wiki: `…emas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawToFunding.md` (matched col `` via n/a, source tier `n/a`)
  - current: Payout amount in ProcessCurrencyID currency. Renamed from Amount. For refunds, the amount being refunded to the instrument
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Billing.WithdrawToFunding.md: no column matching 'Amount_WithdrawToFunding' (checked 40 rows)

- **line 160** `ModificationDate_WithdrawToFunding` — L0-unresolved / LOW
  - claim source: `Billing.WithdrawToFunding`
  - source wiki: `…emas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawToFunding.md` (matched col `` via n/a, source tier `n/a`)
  - current: UTC timestamp of the most recent status change on the payment execution leg. Renamed from ModificationDate
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Billing.WithdrawToFunding.md: no column matching 'ModificationDate_WithdrawToFunding' (checked 40 rows)

- **line 167** `WithdrawPaymentID` — L0-unresolved / LOW
  - claim source: `Billing.WithdrawToFunding`
  - source wiki: `…emas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawToFunding.md` (matched col `` via n/a, source tier `n/a`)
  - current: Surrogate primary key of the WithdrawToFunding execution leg. Renamed from ID
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Billing.WithdrawToFunding.md: no column matching 'WithdrawPaymentID' (checked 40 rows)

- **line 170** `CashoutModeID` — L2-semantic / LOW
  - claim source: `Billing.WithdrawToFunding`
  - source wiki: `…emas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawToFunding.md` (matched col `CashoutModeID` via exact (case-insensitive), source tier `OLTP-truth`)
  - current: Mode of withdrawal execution: 1=Auto Create (75.2%), NULL=legacy (17%), 2=Alternate e.g. eToroMoney/ACH (4%), 0=Manual (3.8%). FK to Dim_CashoutMode
  - source:  Mode of withdrawal execution: NULL=legacy (17%), 0=unknown/fallback (3.8%), 1=Standard (75.2%), 2=Alternate mode e.g., eToroMoney/ACH (4%). Determines which processing path is used for this leg
  - reason:  The enum labels differ: source says 0=unknown/fallback and 1=Standard, while downstream says 0=Manual and 1=Auto Create, which could mislead analysts interpreting the codes.
  - **proposed**: Mode of withdrawal execution: NULL=legacy (17%), 0=unknown/fallback (3.8%), 1=Standard (75.2%), 2=Alternate e.g. eToroMoney/ACH (4%). FK to Dim_CashoutMode (Tier 1 - Billing.WithdrawToFunding)

- **line 171** `FundingTypeID_Funding` — L0-unresolved / LOW
  - claim source: `Billing.Funding`
  - source wiki: `…ge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Funding.md` (matched col `` via n/a, source tier `n/a`)
  - current: Payment method type of the funding instrument receiving the payout. Renamed from FundingTypeID on Billing.Funding. 34 distinct types (Visa/MC/Neteller/PayPal/Wire/eToroMoney/etc.). FK to Dim_FundingType
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Billing.Funding.md: no column matching 'FundingTypeID_Funding' (checked 18 rows)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_Cashout_Rollback.md` — 10 FAIL(s)

- **line 136** `WithdrawprocessingID` — L0-unresolved / LOW
  - claim source: `upstream wiki, Billing.WithdrawToFunding`
  - source wiki: `…emas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawToFunding.md` (matched col `` via n/a, source tier `n/a`)
  - current: Surrogate primary key of the payment execution leg in `Billing.WithdrawToFunding`. Identifies which specific payment leg (card/bank/wallet payout attempt) was rolled back. Implicit FK to Billing.WithdrawToFunding(ID). D…
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Billing.WithdrawToFunding.md: no column matching 'WithdrawprocessingID' (checked 40 rows)

- **line 138** `ProcessTime` — L0-unresolved / LOW
  - claim source: `upstream wiki, Billing.WithdrawToFunding`
  - source wiki: `…emas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawToFunding.md` (matched col `` via n/a, source tier `n/a`)
  - current: Value date from the payment processor — when funds are considered available on the processor side. Set for wire/ACH payouts; NULL for instant payment methods. DWH note: renamed from `WithdrawToFunding.ProcessorValueDate`
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Billing.WithdrawToFunding.md: no column matching 'ProcessTime' (checked 40 rows)

- **line 139** `NetAmount` — L0-unresolved / LOW
  - claim source: `upstream wiki, Billing.WithdrawToFunding`
  - source wiki: `…emas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawToFunding.md` (matched col `` via n/a, source tier `n/a`)
  - current: Refund amount expressed in the original deposit's currency. May differ from NetUSDAmount when exchange rates changed between deposit and refund. ISNULL(0) applied — zero when NULL in source. DWH note: renamed from `With…
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Billing.WithdrawToFunding.md: no column matching 'NetAmount' (checked 40 rows)

- **line 141** `NetUSDAmount` — L0-unresolved / LOW
  - claim source: `upstream wiki, Billing.WithdrawToFunding`
  - source wiki: `…emas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawToFunding.md` (matched col `` via n/a, source tier `n/a`)
  - current: Payout amount in the processing currency (despite the "USD" suffix, this is actually in ProcessCurrencyID currency). MONEY type in source, CAST to decimal(16,2). ISNULL(0) applied. DWH note: renamed from `WithdrawToFund…
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Billing.WithdrawToFunding.md: no column matching 'NetUSDAmount' (checked 40 rows)

- **line 143** `RollbackAmount` — L0-unresolved / LOW
  - claim source: `upstream wiki, Billing.CashoutRollbackTracking`
  - source wiki: `…B_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (matched col `` via n/a, source tier `n/a`)
  - current: The incremental amount in the original transaction currency for this rollback event. Parallel to RollbackUSDAmount. DWH note: renamed from `CashoutRollbackTracking.RollbackAmountInCurrency`
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Billing.CashoutRollbackTracking.md: no column matching 'RollbackAmount' (checked 28 rows)

- **line 145** `FeeInPIPs` — L0-unresolved / LOW
  - claim source: `upstream wiki, Billing.WithdrawToFunding`
  - source wiki: `…emas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawToFunding.md` (matched col `` via n/a, source tier `n/a`)
  - current: Exchange fee in provider-specific integer units from the original payment leg. DWH note: renamed from `WithdrawToFunding.ExchangeFee`. Not a rollback-specific fee — it reflects the fee structure of the original withdraw…
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Billing.WithdrawToFunding.md: no column matching 'FeeInPIPs' (checked 40 rows)

- **line 146** `RollbackUSDAmount` — L0-unresolved / LOW
  - claim source: `upstream wiki, Billing.CashoutRollbackTracking`
  - source wiki: `…B_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (matched col `` via n/a, source tier `n/a`)
  - current: The incremental amount (in USD) reversed in this specific rollback event. Negative values indicate a rollback correction (reversal of a previous rollback). SUM this column grouped by WithdrawID to compute net rollback t…
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Billing.CashoutRollbackTracking.md: no column matching 'RollbackUSDAmount' (checked 28 rows)

- **line 148** `RollbackReason` — L0-unresolved / LOW
  - claim source: `upstream wiki, Billing.CashoutRollbackTracking`
  - source wiki: `…B_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (matched col `` via n/a, source tier `n/a`)
  - current: Reason code for the rollback. Maps to @RollbackType parameter in AddCashoutRollbackTrackingRecord. No Dictionary lookup table exists. Observed values: 0=default/unknown, 1=standard rollback, 3=dominant reason (83% of ev…
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Billing.CashoutRollbackTracking.md: no column matching 'RollbackReason' (checked 28 rows)

- **line 149** `PaymentStatusID` — L2-semantic / LOW
  - claim source: `upstream wiki, Billing.CashoutRollbackTracking`
  - source wiki: `…B_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (matched col `PaymentStatusID` via exact (case-insensitive), source tier `OLTP-truth`)
  - current: Status of the rollback at time of recording. Always 2 (InProcess) across all production rows — set from @CashoutStatusID parameter. Uses Dictionary.PaymentStatus: 1=New, 2=Approved, 3=Decline, 4=Technical, 5=InProcess,…
  - source:  Status of the rollback at time of recording. Always 2 across all 7,349 rows (set from @CashoutStatusID parameter). Uses the same CashoutStatus lookup as Billing.Withdraw. The constant value 2 suggests rollbacks are only…
  - reason:  Downstream maps constant value 2 to 'InProcess' (status 5 in its own lookup) while also listing 2=Approved, creating an internal contradiction; source says value 2 references the CashoutStatus lookup shared with Billing…
  - **proposed**: Status of the rollback at time of recording. Always 2 across all production rows — set from @CashoutStatusID parameter. Uses the same CashoutStatus lookup as Billing.Withdraw, not Dictionary.PaymentStatus. (Tier 1 - Billing.CashoutRollbackTracking.md)

- **line 160** `StatusModificationTime` — L0-unresolved / LOW
  - claim source: `upstream wiki, Billing.CashoutRollbackTracking`
  - source wiki: `…B_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (matched col `` via n/a, source tier `n/a`)
  - current: UTC timestamp when the rollback tracking record was last modified. Set to GETUTCDATE() at INSERT in production. DWH note: renamed from `CashoutRollbackTracking.ModificationDate`; serves as the ETL watermark — `Modificat…
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Billing.CashoutRollbackTracking.md: no column matching 'StatusModificationTime' (checked 28 rows)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_CustomerAction.md` — 20 FAIL(s)

- **line 141** `Occurred` — L0-unresolved / LOW
  - claim source: `source-dependent`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='source-dependent': bare name 'source-dependent' not found in sibling synapse wikis

- **line 142** `IPNumber` — L0-unresolved / LOW
  - claim source: `STS/Billing.Login`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: IP address of the customer as a numeric value. Populated for logins and registrations
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='STS/Billing.Login': bare name 'STS/Billing.Login' not found in sibling synapse wikis

- **line 144** `ActionTypeID` — L0-unresolved / LOW
  - claim source: `History.Credit / Trade snapshots / STS / Customer payloads`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Event classifier — join `Dim_ActionType` for `Name` / `Category`. Drives sparse column population. Derived from **`CreditTypeID`** & branch router in loader + positional feeds
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='History.Credit / Trade snapshots / STS / Customer payloads': bare name 'History.Credit / Trade snapshots / STS / Customer payloads' not found in sibling synapse wikis

- **line 147** `Amount` — L0-unresolved / LOW
  - claim source: `Trade.PositionTbl / History.Credit`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Position / ledger amount discipline per branch (cash change on opens; fee/deposit sizing on ledger rows — see lineage). Must be ≥0 on trade opens historically
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='Trade.PositionTbl / History.Credit': bare name 'Trade.PositionTbl / History.Credit' not found in sibling synapse wikis

- **line 154** `FundingTypeID` — L0-unresolved / LOW
  - claim source: `History.Credit`
  - source wiki: `…edge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Credit.md` (matched col `` via n/a, source tier `n/a`)
  - current: Ledger funding / wallet channel identifier (deposits & cash-outs). Nullable upstream coerced with `ISNULL(...,0)` sentinel row **`0`** (`Dim_FundingType.md`). **Value 27 pairs with redeem flag derivation on cash-outs.**…
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  History.Credit.md: no column matching 'FundingTypeID' (checked 23 rows)

- **line 157** `WithdrawID` — L0-unresolved / LOW
  - claim source: `History.Credit`
  - source wiki: `…edge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Credit.md` (matched col `` via n/a, source tier `n/a`)
  - current: Withdrawal request identifier for cash-out credits; 0 when absent
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  History.Credit.md: no column matching 'WithdrawID' (checked 23 rows)

- **line 158** `DurationInSeconds` — L0-unresolved / LOW
  - claim source: `Billing.Login`
  - source wiki: `…edge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Login.md` (matched col `` via n/a, source tier `n/a`)
  - current: Login session dwell seconds (NULL outside login cashier events)
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Billing.Login.md: no column matching 'DurationInSeconds' (checked 7 rows)

- **line 159** `PostID` — L0-unresolved / LOW
  - claim source: `Social platform`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Social GUID for deprecated social action types (**21‑26**) — stale per historical wiki audits. NULL otherwise
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='Social platform': bare name 'Social platform' not found in sibling synapse wikis

- **line 160** `CaseID` — L0-unresolved / LOW
  - claim source: `CRM`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: CRM case (`ActionTypeID=31`). 0 default
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='CRM': bare name 'CRM' not found in sibling synapse wikis

- **line 166** `CompensationReasonID` — L0-unresolved / LOW
  - claim source: `History.Credit, updated wiki 2025-12`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: `BackOffice.CompensationReason` code on comps & some opens for airdrops
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='History.Credit, updated wiki 2025-12': bare name 'History.Credit, updated wiki 2025-12' not found in sibling synapse wikis

- **line 167** `WithdrawPaymentID` — L0-unresolved / LOW
  - claim source: `History.Credit`
  - source wiki: `…edge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Credit.md` (matched col `` via n/a, source tier `n/a`)
  - current: Payment-processing key for withdrawals; used to collapse duplicate WithdrawProcessing tuples per historical ETL memo
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  History.Credit.md: no column matching 'WithdrawPaymentID' (checked 23 rows)

- **line 170** `DepositID` — L0-unresolved / LOW
  - claim source: `History.Credit`
  - source wiki: `…edge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Credit.md` (matched col `` via n/a, source tier `n/a`)
  - current: Deposit transaction reference on inbound money rows (`NULL` off-deposit actions)
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  History.Credit.md: no column matching 'DepositID' (checked 23 rows)

- **line 171** `PostRootID` — L0-unresolved / LOW
  - claim source: `Social platform`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Deprecated social threading key. NULL off-social
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='Social platform': bare name 'Social platform' not found in sibling synapse wikis

- **line 176** `SessionID` — L0-unresolved / LOW
  - claim source: `STS`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: STS session BIGINT for opens/logins (`NULL` off those branches)
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='STS': bare name 'STS' not found in sibling synapse wikis

- **line 189** `IsDiscounted` — L0-unresolved / LOW
  - claim source: `Trade.PositionTbl`
  - source wiki: `…ge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionTbl.md` (matched col `` via n/a, source tier `n/a`)
  - current: 1=commission discount applied at open (legacy bit widening)
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Trade.PositionTbl.md: no column matching 'IsDiscounted' (checked 133 rows)

- **line 195** `IsAnonymousIP` — L0-unresolved / LOW
  - claim source: `IP geolocation service`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Anonymous / proxy heuristic flag STS path. NULL off relevant rows
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='IP geolocation service': bare name 'IP geolocation service' not found in sibling synapse wikis

- **line 196** `ProxyType` — L0-unresolved / LOW
  - claim source: `STS`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Proxy taxonomy (`DCH`, `VPN`, `TOR`, etc.) from STS classifications. NULL if direct
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='STS': bare name 'STS' not found in sibling synapse wikis

- **line 199** `DividendID` — L0-unresolved / LOW
  - claim source: `Trade.Positions/dividends lineage`
  - source wiki: `(unresolved)` (matched col `` via n/a, source tier `n/a`)
  - current: Dividend event pointer for dividend-driven fee deductions. NULL off-dividend
  - source:  _(empty)_
  - reason:  cannot locate source wiki — manual lookup required
  - notes:  primary='Trade.Positions/dividends lineage': bare name 'Trade.Positions/dividends lineage' not found in sibling synapse wikis

- **line 200** `MoveMoneyReasonID` — L2-semantic / HIGH
  - claim source: `History.Credit`
  - source wiki: `…edge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Credit.md` (matched col `MoveMoneyReasonID` via exact (case-insensitive), source tier `OLTP-truth`)
  - current: Dictionary.MoveMoneyReason code on internal sweeps (**5/6**/recurring enums per prior audits). References dictionary dimension. Some low-volume codepoints flagged `[UNVERIFIED]` historically in **`Dim_MoveMoneyReason`**…
  - source:  NULL in all archive branches. Native in History.ActiveCredit
  - reason:  Source says the column is NULL in all archive branches (not populated), while the downstream description treats it as an active foreign key to a dictionary dimension with specific enum values.
  - **proposed**: NULL in all archive branches; natively populated only in History.ActiveCredit. Do not join from this view. (Tier 1 - History.Credit.md)

- **line 205** `Description` — L0-unresolved / LOW
  - claim source: `History.Credit`
  - source wiki: `…edge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Credit.md` (matched col `` via n/a, source tier `n/a`)
  - current: Operational narrative pulled from Credits / fees ("Over night fee", ticket fee tokens, Payments deposit processor strings)
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  History.Credit.md: no column matching 'Description' (checked 23 rows)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/History_CurrencyPrice.md` — 6 FAIL(s)

- **line 152** `CurrencyPriceID` — L0-unresolved / LOW
  - claim source: `upstream wiki, Trade.CurrencyPrice`
  - source wiki: `…/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.CurrencyPrice.md` (matched col `` via n/a, source tier `n/a`)
  - current: Unique tick identifier. Bigint supports high-volume tick stream
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Trade.CurrencyPrice.md: no column matching 'CurrencyPriceID' (checked 26 rows)

- **line 156** `MarketPriceRateID` — L2-semantic / LOW
  - claim source: `upstream wiki, Trade.CurrencyPrice`
  - source wiki: `…/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.CurrencyPrice.md` (matched col `MarketPriceRateID` via exact (case-insensitive), source tier `OLTP-truth`)
  - current: Market-level rate ID for this tick. Links to the composite market price at this point. Distinct from PriceRateID when bid/ask have separate market sources
  - source:  Market rate ID. TCRP_NullMarketPriceRateID default
  - reason:  The downstream description fabricates a distinction from PriceRateID and claims linkage to a 'composite market price' not supported by the source, which only says 'Market rate ID' with a null-default constant.
  - **proposed**: Market rate ID; defaults to TCRP_NullMarketPriceRateID when not set. (Tier 1 - Trade.CurrencyPrice.md)

- **line 171** `USDConversionRate` — L0-unresolved / LOW
  - claim source: `upstream wiki, Trade.CurrencyPrice`
  - source wiki: `…/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.CurrencyPrice.md` (matched col `` via n/a, source tier `n/a`)
  - current: USD conversion rate for non-USD instruments at this tick. Used by SP_Dim_Position to convert P&L to USD. 1.0 for USD-based instruments
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Trade.CurrencyPrice.md: no column matching 'USDConversionRate' (checked 26 rows)

- **line 179** `ValidFrom` — L0-unresolved / LOW
  - claim source: `upstream wiki, Trade.CurrencyPrice`
  - source wiki: `…/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.CurrencyPrice.md` (matched col `` via n/a, source tier `n/a`)
  - current: Start of the period during which this tick was the "current" price. Used for temporal price lookups
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Trade.CurrencyPrice.md: no column matching 'ValidFrom' (checked 26 rows)

- **line 180** `ValidTo` — L0-unresolved / LOW
  - claim source: `upstream wiki, Trade.CurrencyPrice`
  - source wiki: `…/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.CurrencyPrice.md` (matched col `` via n/a, source tier `n/a`)
  - current: End of the period during which this tick was current. ValidFrom/ValidTo define a non-overlapping time series per (ProviderID, InstrumentID)
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Trade.CurrencyPrice.md: no column matching 'ValidTo' (checked 26 rows)

- **line 182** `OccurredOnProvider` — L0-unresolved / LOW
  - claim source: `upstream wiki, Trade.CurrencyPrice`
  - source wiki: `…/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.CurrencyPrice.md` (matched col `` via n/a, source tier `n/a`)
  - current: Timestamp reported by the external price provider. May differ from Occurred due to network latency
  - source:  _(empty)_
  - reason:  source wiki found but no matching column row
  - notes:  Trade.CurrencyPrice.md: no column matching 'OccurredOnProvider' (checked 26 rows)

### `knowledge/synapse/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation.md` — 10 FAIL(s)

- **line 139** `DateID` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `DateID` via exact (case-insensitive), source tier `2`)
  - current: Integer date key in YYYYMMDD format identifying the calculation date for this correlation snapshot. Matches the @auxdate parameter passed to SP_Dim_Instrument_Correlation_Half_Records. Filter by this column for performa…
  - source:  Integer date key in YYYYMMDD format identifying the calculation date for this correlation snapshot. Matches the @auxdate parameter passed to SP_Dim_Instrument_Correlation_Half_Records. Filter by this column for performa…
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Integer date key in YYYYMMDD format identifying the calculation date for this correlation snapshot. Matches the @auxdate parameter passed to SP_Dim_Instrument_Correlation_Half_Records. Filter by this column for performance (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 140** `InstrumentID_a` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `InstrumentID_a` via exact (case-insensitive), source tier `2`)
  - current: ID of the first financial instrument in the pair. In the full-symmetric view, this can be any instrument (not limited to <= InstrumentID_b). Resolves to Dim_Currency.CurrencyID for the instrument name
  - source:  ID of the first financial instrument in the pair (always <= InstrumentID_b in this half-matrix view). Resolves to Dim_Currency.CurrencyID for the instrument name
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: ID of the first financial instrument in the pair (always <= InstrumentID_b in this half-matrix view). Resolves to Dim_Currency.CurrencyID for the instrument name (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 141** `InstrumentID_b` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `InstrumentID_b` via exact (case-insensitive), source tier `2`)
  - current: ID of the second financial instrument in the pair. In the full-symmetric view, this can be any instrument (not limited to >= InstrumentID_a). Resolves to Dim_Currency.CurrencyID for the instrument name
  - source:  ID of the second financial instrument in the pair (always >= InstrumentID_a in this half-matrix view). Resolves to Dim_Currency.CurrencyID for the instrument name
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: ID of the second financial instrument in the pair (always >= InstrumentID_a in this half-matrix view). Resolves to Dim_Currency.CurrencyID for the instrument name (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 142** `SampleSize` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `SampleSize` via exact (case-insensitive), source tier `2`)
  - current: Number of hourly candle data points where both instruments had valid prices in the 3-month lookback window. Higher values = more reliable correlation estimate. Low values (< 100) indicate sparse data
  - source:  Number of hourly candle data points where both instruments had valid prices in the 3-month lookback window. Higher values = more reliable correlation estimate. Low values (< 100) indicate sparse data
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Number of hourly candle data points where both instruments had valid prices in the 3-month lookback window. Higher values = more reliable correlation estimate. Low values (< 100) indicate sparse data (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 143** `StandardDeviation_a` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `StandardDeviation_a` via exact (case-insensitive), source tier `2`)
  - current: Population standard deviation of hourly price returns for InstrumentID_a over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows). Swapped with StandardDeviation_…
  - source:  Population standard deviation of hourly price returns for InstrumentID_a over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows)
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Population standard deviation of hourly price returns for InstrumentID_a over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows) (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 144** `StandardDeviation_b` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `StandardDeviation_b` via exact (case-insensitive), source tier `2`)
  - current: Population standard deviation of hourly price returns for InstrumentID_b over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows). Swapped with StandardDeviation_…
  - source:  Population standard deviation of hourly price returns for InstrumentID_b over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows)
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Population standard deviation of hourly price returns for InstrumentID_b over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows) (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 145** `Covariance` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `Covariance` via exact (case-insensitive), source tier `2`)
  - current: Raw covariance between the hourly price returns of the two instruments. Formula: sum(a*b)/n - (sum(a)*sum(b))/n^2. Used as numerator in PearsonCorrelation formula
  - source:  Raw covariance between the hourly price returns of the two instruments. Formula: sum(a*b)/n - (sum(a)*sum(b))/n^2. Used as numerator in PearsonCorrelation formula
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Raw covariance between the hourly price returns of the two instruments. Formula: sum(a*b)/n - (sum(a)*sum(b))/n^2. Used as numerator in PearsonCorrelation formula (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 146** `PearsonCorrelation` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `PearsonCorrelation` via exact (case-insensitive), source tier `2`)
  - current: Pearson correlation coefficient between the two instruments' hourly price returns over the 3-month window. Range -1.0 (perfect negative) to +1.0 (perfect positive). 0 = no linear correlation. Formula: Covariance / (Stan…
  - source:  Pearson correlation coefficient between the two instruments' hourly price returns over the 3-month window. Range -1.0 (perfect negative) to +1.0 (perfect positive). 0 = no linear correlation. Formula: Covariance / (Stan…
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Pearson correlation coefficient between the two instruments' hourly price returns over the 3-month window. Range -1.0 (perfect negative) to +1.0 (perfect positive). 0 = no linear correlation. Formula: Covariance / (StandardDeviation_a * StandardDeviation_b) (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 147** `InsertDate` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `InsertDate` via exact (case-insensitive), source tier `2`)
  - current: Timestamp when the correlation row was first computed. Set to GETDATE() by the ETL SP
  - source:  Timestamp when the correlation row was first computed. Set to GETDATE() by the ETL SP
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Timestamp when the correlation row was first computed. Set to GETDATE() by the ETL SP (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 148** `UpdateDate` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `UpdateDate` via exact (case-insensitive), source tier `2`)
  - current: Timestamp when the correlation row was last updated. Set to GETDATE() by the ETL SP (same as InsertDate on initial load; may differ on re-computation)
  - source:  Timestamp when the correlation row was last updated. Set to GETDATE() by the ETL SP (same as InsertDate on initial load; may differ on re-computation)
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Timestamp when the correlation row was last updated. Set to GETDATE() by the ETL SP (same as InsertDate on initial load; may differ on re-computation) (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

### `knowledge/synapse/Wiki/DWH_dbo/Views/V_Customers.md` — 15 FAIL(s)

- **line 29** `GCID` — L1-structural / HIGH
  - claim source: `inherited from Fact_SnapshotCustomer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md` (matched col `GCID` via exact (case-insensitive), source tier `2`)
  - current: Global Customer ID — unique cross-platform identifier. ISNULL → 0 when NULL
  - source:  Global Customer ID — the cross-platform identifier linking RealCID to demo and external systems. Source: Ext_FSC_Real_Customer_Customer (primary), Ext_Dim_Customer_CustomerIdentification_DLT (fallback)
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Global Customer ID — the cross-platform identifier linking RealCID to demo and external systems. Source: Ext_FSC_Real_Customer_Customer (primary), Ext_Dim_Customer_CustomerIdentification_DLT (fallback) (Tier 2 — via Fact_SnapshotCustomer)

- **line 31** `RealCID` — L1-structural / HIGH
  - claim source: `inherited from Fact_SnapshotCustomer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md` (matched col `RealCID` via exact (case-insensitive), source tier `2`)
  - current: Real-money account Customer ID. ISNULL → 0
  - source:  Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values (Tier 2 — via Fact_SnapshotCustomer)

- **line 32** `DemoCID` — L1-structural / HIGH
  - claim source: `inherited from Fact_SnapshotCustomer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md` (matched col `DemoCID` via exact (case-insensitive), source tier `4`)
  - current: Demo account Customer ID. Legacy — always 0 in current ETL
  - source:  [UNVERIFIED] Demo account customer ID linked to this real customer. NOT populated by current SP_Fact_SnapshotCustomer — legacy column from original SCD2 design. Value is DEFAULT NULL/0 for all rows created post-schema-m…
  - reason:  source wiki tags this column as Tier 4 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: [UNVERIFIED] Demo account customer ID linked to this real customer. NOT populated by current SP_Fact_SnapshotCustomer — legacy column from original SCD2 design. Value is DEFAULT NULL/0 for all rows created post-schema-migration (Tier 4 — via Fact_SnapshotCustomer)

- **line 33** `CustomerChangeTypeID` — L1-structural / HIGH
  - claim source: `inherited from Fact_SnapshotCustomer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md` (matched col `CustomerChangeTypeID` via exact (case-insensitive), source tier `4`)
  - current: Change type that triggered this snapshot row. Legacy — always 0 in current ETL
  - source:  [UNVERIFIED] Legacy: type of change that created this snapshot row (e.g., 1=CountryID, 2=LabelID). NOT populated by current SP — retained for backward compatibility. FK to Dim_CustomerChangeType
  - reason:  source wiki tags this column as Tier 4 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: [UNVERIFIED] Legacy: type of change that created this snapshot row (e.g., 1=CountryID, 2=LabelID). NOT populated by current SP — retained for backward compatibility. FK to Dim_CustomerChangeType (Tier 4 — via Fact_SnapshotCustomer)

- **line 34** `CurentValue` — L1-structural / HIGH
  - claim source: `inherited from Fact_SnapshotCustomer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md` (matched col `CurentValue` via exact (case-insensitive), source tier `4`)
  - current: Current attribute value at time of change. Legacy — always 0 in current ETL. Note typo: "Curent" not "Current"
  - source:  [UNVERIFIED] Legacy: the current value of the changed attribute (used with CustomerChangeTypeID). NOT populated by current SP. Column name has a typo ("Curent")
  - reason:  source wiki tags this column as Tier 4 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: [UNVERIFIED] Legacy: the current value of the changed attribute (used with CustomerChangeTypeID). NOT populated by current SP. Column name has a typo ("Curent") (Tier 4 — via Fact_SnapshotCustomer)

- **line 35** `PreviousValue` — L1-structural / HIGH
  - claim source: `inherited from Fact_SnapshotCustomer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md` (matched col `PreviousValue` via exact (case-insensitive), source tier `4`)
  - current: Previous attribute value before change. Legacy — always 0 in current ETL
  - source:  [UNVERIFIED] Legacy: the previous value of the changed attribute. NOT populated by current SP
  - reason:  source wiki tags this column as Tier 4 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: [UNVERIFIED] Legacy: the previous value of the changed attribute. NOT populated by current SP (Tier 4 — via Fact_SnapshotCustomer)

- **line 40** `DocsOK` — L1-structural / HIGH
  - claim source: `inherited from Fact_SnapshotCustomer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md` (matched col `DocsOK` via exact (case-insensitive), source tier `4`)
  - current: Document verification status. Legacy — always 0 in current ETL
  - source:  [UNVERIFIED] Legacy: documents verified flag (1=OK). NOT populated by current SP. DEFAULT 0
  - reason:  source wiki tags this column as Tier 4 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: [UNVERIFIED] Legacy: documents verified flag (1=OK). NOT populated by current SP. DEFAULT 0 (Tier 4 — via Fact_SnapshotCustomer)

- **line 42** `Bankruptcy` — L1-structural / HIGH
  - claim source: `inherited from Fact_SnapshotCustomer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md` (matched col `Bankruptcy` via exact (case-insensitive), source tier `4`)
  - current: Bankruptcy flag. Legacy — always 0 in current ETL
  - source:  [UNVERIFIED] Legacy: bankruptcy flag. NOT populated by current SP. DEFAULT 0
  - reason:  source wiki tags this column as Tier 4 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: [UNVERIFIED] Legacy: bankruptcy flag. NOT populated by current SP. DEFAULT 0 (Tier 4 — via Fact_SnapshotCustomer)

- **line 45** `CommunicationLanguageID` — L1-structural / HIGH
  - claim source: `inherited from Fact_SnapshotCustomer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md` (matched col `CommunicationLanguageID` via exact (case-insensitive), source tier `2`)
  - current: Language used for customer communications. FK → Dim_Language
  - source:  Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language (Tier 2 — via Fact_SnapshotCustomer)

- **line 46** `PremiumAccount` — L1-structural / HIGH
  - claim source: `inherited from Fact_SnapshotCustomer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md` (matched col `PremiumAccount` via exact (case-insensitive), source tier `4`)
  - current: Premium account flag. Legacy — always 0 in current ETL
  - source:  [UNVERIFIED] Legacy: premium account flag. NOT populated by current SP. DEFAULT 0
  - reason:  source wiki tags this column as Tier 4 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: [UNVERIFIED] Legacy: premium account flag. NOT populated by current SP. DEFAULT 0 (Tier 4 — via Fact_SnapshotCustomer)

- **line 47** `Evangelist` — L1-structural / HIGH
  - claim source: `inherited from Fact_SnapshotCustomer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md` (matched col `Evangelist` via exact (case-insensitive), source tier `4`)
  - current: Evangelist program flag. Legacy — always 0 in current ETL
  - source:  [UNVERIFIED] Legacy: evangelist/ambassador status flag. NOT populated by current SP. DEFAULT 0
  - reason:  source wiki tags this column as Tier 4 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: [UNVERIFIED] Legacy: evangelist/ambassador status flag. NOT populated by current SP. DEFAULT 0 (Tier 4 — via Fact_SnapshotCustomer)

- **line 49** `RegulationID` — L1-structural / HIGH
  - claim source: `inherited from Fact_SnapshotCustomer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md` (matched col `RegulationID` via exact (case-insensitive), source tier `2`)
  - current: Regulatory jurisdiction. FK → Dim_Regulation. Sourced from RegulationChangeLog, not BO
  - source:  Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation (Tier 2 — via Fact_SnapshotCustomer)

- **line 51** `AccountManagerID` — L1-structural / HIGH
  - claim source: `inherited from Fact_SnapshotCustomer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md` (matched col `AccountManagerID` via exact (case-insensitive), source tier `2`)
  - current: Assigned account manager. FK → Dim_Manager
  - source:  Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager (Tier 2 — via Fact_SnapshotCustomer)

- **line 52** `PlayerLevelID` — L2-semantic / HIGH
  - claim source: `inherited from Fact_SnapshotCustomer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md` (matched col `PlayerLevelID` via exact (case-insensitive), source tier `n/a`)
  - current: Gamification/tier level. FK → Dim_PlayerLevel
  - source:  Real vs demo tier
  - reason:  Source says the column distinguishes real vs demo accounts, not a gamification/tier level.
  - **proposed**: Real vs demo account tier. FK → Dim_PlayerLevel (Tier 1 - Fact_SnapshotCustomer)

- **line 54** `IsDepositor` — L1-structural / HIGH
  - claim source: `inherited from Fact_SnapshotCustomer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md` (matched col `IsDepositor` via exact (case-insensitive), source tier `2`)
  - current: Whether the customer has ever deposited. Not wrapped in ISNULL — only column passed through without null coercion
  - source:  1 if the customer has made at least one real-money deposit (FTD detected). Set when CID appears in Ext_FSC_Customer_FirstTimeDeposits. Never reverted to 0 once set. DEFAULT 0
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: 1 if the customer has made at least one real-money deposit (FTD detected). Set when CID appears in Ext_FSC_Customer_FirstTimeDeposits. Never reverted to 0 once set. DEFAULT 0 (Tier 2 — via Fact_SnapshotCustomer)

### `knowledge/synapse/Wiki/DWH_dbo/Views/V_Dim_Customer.md` — 27 FAIL(s)

- **line 41** `DemoCID` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `DemoCID` via exact (case-insensitive), source tier `2`)
  - current: Demo account CID associated with this customer. From UserApiDB_Customer_CustomerIdentification
  - source:  Demo account CID associated with this customer. From `UserApiDB_Customer_CustomerIdentification`
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Demo account CID associated with this customer. From `UserApiDB_Customer_CustomerIdentification` (Tier 2 — via Dim_Customer)

- **line 52** `SubChannelID` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `SubChannelID` via exact (case-insensitive), source tier `2`)
  - current: Sub-channel ID. Populated post-load from SubChannel unify code via AffiliateID mapping. DEFAULT=0
  - source:  Sub-channel ID. Populated post-load from SubChannel unify code via AffiliateID mapping. DEFAULT=0
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Sub-channel ID. Populated post-load from SubChannel unify code via AffiliateID mapping. DEFAULT=0 (Tier 2 — via Dim_Customer)

- **line 60** `AccountExpirationDate` — L2-semantic / LOW
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `AccountExpirationDate` via exact (case-insensitive), source tier `1`)
  - current: Expiration date for demo or time-limited accounts. CONVERT to varchar(50) style 121. NULL for standard real-money accounts
  - source:  Expiration date for demo or time-limited accounts. NULL for standard real-money accounts
  - reason:  The downstream description leaks a SQL formatting directive (CONVERT to varchar(50) style 121) into the business definition, which is implementation detail, not business meaning.
  - **proposed**: Expiration date for demo or time-limited accounts. NULL for standard real-money accounts (Tier 1 - Dim_Customer.md)

- **line 61** `SocialConnectID` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `SocialConnectID` via exact (case-insensitive), source tier `2`)
  - current: Social media connection type. DEFAULT=0
  - source:  Social media connection type. DEFAULT=0
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Social media connection type. DEFAULT=0 (Tier 2 — via Dim_Customer)

- **line 63** `DocsOK` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `DocsOK` via exact (case-insensitive), source tier `2`)
  - current: Whether required documents are verified. CAST to varchar(10)
  - source:  Whether required documents are verified
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Whether required documents are verified (Tier 2 — via Dim_Customer)

- **line 65** `Bankruptcy` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `Bankruptcy` via exact (case-insensitive), source tier `2`)
  - current: Bankruptcy flag. CAST to varchar(10)
  - source:  Bankruptcy flag
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Bankruptcy flag (Tier 2 — via Dim_Customer)

- **line 69** `RegisteredDemo` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `RegisteredDemo` via exact (case-insensitive), source tier `2`)
  - current: Demo account registration date. CONVERT to varchar(50) style 121
  - source:  Demo account registration date. Source unclear — may be populated separately
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Demo account registration date. Source unclear — may be populated separately (Tier 2 — via Dim_Customer)

- **line 76** `PremiumAccount` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `PremiumAccount` via exact (case-insensitive), source tier `2`)
  - current: Whether this is a premium account. CAST to varchar(10)
  - source:  Whether this is a premium account
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Whether this is a premium account (Tier 2 — via Dim_Customer)

- **line 77** `Evangelist` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `Evangelist` via exact (case-insensitive), source tier `2`)
  - current: Whether this customer is an evangelist/ambassador. CAST to varchar(10)
  - source:  Whether this customer is an evangelist/ambassador
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Whether this customer is an evangelist/ambassador (Tier 2 — via Dim_Customer)

- **line 79** `NumOfGurus` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `NumOfGurus` via exact (case-insensitive), source tier `2`)
  - current: Number of Popular Investors this customer is copying
  - source:  Number of Popular Investors this customer is copying
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Number of Popular Investors this customer is copying (Tier 2 — via Dim_Customer)

- **line 80** `NumOfCopiers` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `NumOfCopiers` via exact (case-insensitive), source tier `2`)
  - current: Number of customers copying this customer's trades
  - source:  Number of customers copying this customer's trades
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Number of customers copying this customer's trades (Tier 2 — via Dim_Customer)

- **line 81** `NumOfRAF` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `NumOfRAF` via exact (case-insensitive), source tier `2`)
  - current: Number of successful Refer-A-Friend referrals
  - source:  Number of successful Refer-A-Friend referrals
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Number of successful Refer-A-Friend referrals (Tier 2 — via Dim_Customer)

- **line 87** `HasAvatar` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `HasAvatar` via exact (case-insensitive), source tier `2`)
  - current: Whether customer has uploaded a custom avatar. CAST to varchar(10). Updated post-load from Avatars staging
  - source:  Whether customer has uploaded a custom avatar. Updated post-load from Avatars staging (excludes default/avatoros images)
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Whether customer has uploaded a custom avatar. Updated post-load from Avatars staging (excludes default/avatoros images) (Tier 2 — via Dim_Customer)

- **line 88** `AvatarUploadDate` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `AvatarUploadDate` via exact (case-insensitive), source tier `2`)
  - current: When the avatar was uploaded. CONVERT to varchar(50) style 121
  - source:  When the avatar was uploaded
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: When the avatar was uploaded (Tier 2 — via Dim_Customer)

- **line 89** `UpdateDate` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `UpdateDate` via exact (case-insensitive), source tier `2`)
  - current: ETL load/update timestamp (GETDATE()). CONVERT to varchar(50) style 121
  - source:  ETL load/update timestamp (GETDATE())
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: ETL load/update timestamp (GETDATE()) (Tier 2 — via Dim_Customer)

- **line 90** `IsDepositor` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `IsDepositor` via exact (case-insensitive), source tier `2`)
  - current: Whether the customer has ever deposited. CAST to varchar(1). DEFAULT=0
  - source:  Whether the customer has ever deposited. DEFAULT=0. Updated post-load from FTD data
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Whether the customer has ever deposited. DEFAULT=0. Updated post-load from FTD data (Tier 2 — via Dim_Customer)

- **line 91** `FirstDepositDate` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `FirstDepositDate` via exact (case-insensitive), source tier `2`)
  - current: Date of first deposit. CONVERT to varchar(50) style 121. DEFAULT='19000101'
  - source:  Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic (Tier 2 — via Dim_Customer)

- **line 105** `FirstDepositAmount` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `FirstDepositAmount` via exact (case-insensitive), source tier `2`)
  - current: Amount of first deposit (in USD). CAST to decimal(19,4). Updated from FTDAmountInUsd
  - source:  Amount of first deposit (in USD). Updated from FTDAmountInUsd
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Amount of first deposit (in USD). Updated from FTDAmountInUsd (Tier 2 — via Dim_Customer)

- **line 107** `MifidCategorizationID` — L2-semantic / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `MifidCategorizationID` via exact (case-insensitive), source tier `1`)
  - current: MiFID II investor classification. FK to Dictionary.MifidCategorization. 1=Retail (97.3%), 4=Retail Pending, 5=Pending
  - source:  MiFID II investor classification. FK to Dictionary.MifidCategorization. Values: 1=Retail (97.3%), 4=Eligible Counterparty (2.6%), 5=Professional (0.03%). Default=1
  - reason:  Value labels 4 and 5 differ: source says 4=Eligible Counterparty and 5=Professional, but claim says 4=Retail Pending and 5=Pending, which are entirely different classification meanings.
  - **proposed**: MiFID II investor classification. FK to Dictionary.MifidCategorization. 1=Retail (97.3%), 4=Eligible Counterparty (2.6%), 5=Professional (0.03%). Default=1 (Tier 1 - Dim_Customer.md)

- **line 109** `IsValidCustomer` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `IsValidCustomer` via exact (case-insensitive), source tier `2`)
  - current: DWH-computed: 1 when PlayerLevelID≠4, LabelID NOT IN (30,26), CountryID≠250. Filters non-standard customers from reporting
  - source:  DWH-computed: 1 when not Popular Investor (PlayerLevelID≠4), not label 30/26, and not CountryID=250. Used in reporting to filter out non-standard customers
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: DWH-computed: 1 when not Popular Investor (PlayerLevelID≠4), not label 30/26, and not CountryID=250. Used in reporting to filter out non-standard customers (Tier 2 — via Dim_Customer)

- **line 112** `ScreeningStatusID` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `ScreeningStatusID` via exact (case-insensitive), source tier `2`)
  - current: Compliance screening status. Updated from ScreeningService
  - source:  Compliance screening status. Updated from ScreeningService
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Compliance screening status. Updated from ScreeningService (Tier 2 — via Dim_Customer)

- **line 114** `WorldCheckResultsUpdated` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `WorldCheckResultsUpdated` via exact (case-insensitive), source tier `2`)
  - current: When World-Check results were last updated. CONVERT to varchar(50) style 121
  - source:  When World-Check results were last updated. Preserved from previous row
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: When World-Check results were last updated. Preserved from previous row (Tier 2 — via Dim_Customer)

- **line 116** `IsAddressProof` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `IsAddressProof` via exact (case-insensitive), source tier `2`)
  - current: Whether address proof document is on file (1/0). Updated from BackOffice.CustomerDocument
  - source:  Whether address proof document is on file (1/0). Updated from BackOffice.CustomerDocument
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Whether address proof document is on file (1/0). Updated from BackOffice.CustomerDocument (Tier 2 — via Dim_Customer)

- **line 117** `IsAddressProofExpiryDate` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `IsAddressProofExpiryDate` via exact (case-insensitive), source tier `2`)
  - current: Expiry date of address proof document. CONVERT to varchar(50) style 121
  - source:  Expiry date of address proof document
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Expiry date of address proof document (Tier 2 — via Dim_Customer)

- **line 118** `IsIDProof` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `IsIDProof` via exact (case-insensitive), source tier `2`)
  - current: Whether ID proof document is on file (1/0)
  - source:  Whether ID proof document is on file (1/0)
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Whether ID proof document is on file (1/0) (Tier 2 — via Dim_Customer)

- **line 119** `IsIDProofExpiryDate` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `IsIDProofExpiryDate` via exact (case-insensitive), source tier `2`)
  - current: Expiry date of ID proof document. CONVERT to varchar(50) style 121
  - source:  Expiry date of ID proof document
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Expiry date of ID proof document (Tier 2 — via Dim_Customer)

- **line 123** `IsCreditReportValidCB` — L1-structural / HIGH
  - claim source: `inherited from Dim_Customer wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` (matched col `IsCreditReportValidCB` via exact (case-insensitive), source tier `2`)
  - current: DWH-computed: similar to IsValidCustomer but with additional AccountTypeID≠2 exclusion and specific CID exceptions for CountryID=250
  - source:  DWH-computed: similar to IsValidCustomer but with additional AccountTypeID≠2 exclusion and specific CID exceptions for CountryID=250
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: DWH-computed: similar to IsValidCustomer but with additional AccountTypeID≠2 exclusion and specific CID exceptions for CountryID=250 (Tier 2 — via Dim_Customer)

### `knowledge/synapse/Wiki/DWH_dbo/Views/V_Dim_Instrument_Correlation.md` — 10 FAIL(s)

- **line 28** `DateID` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `DateID` via exact (case-insensitive), source tier `2`)
  - current: Integer date key in YYYYMMDD format identifying the calculation date for this correlation snapshot. Matches the @auxdate parameter passed to SP_Dim_Instrument_Correlation_Half_Records. Filter by this column for performa…
  - source:  Integer date key in YYYYMMDD format identifying the calculation date for this correlation snapshot. Matches the @auxdate parameter passed to SP_Dim_Instrument_Correlation_Half_Records. Filter by this column for performa…
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Integer date key in YYYYMMDD format identifying the calculation date for this correlation snapshot. Matches the @auxdate parameter passed to SP_Dim_Instrument_Correlation_Half_Records. Filter by this column for performance (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 29** `InstrumentID_a` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `InstrumentID_a` via exact (case-insensitive), source tier `2`)
  - current: ID of the first financial instrument in the pair. In the full-symmetric output, this can be any instrument (not limited to <= InstrumentID_b). Resolves to Dim_Currency.CurrencyID for the instrument name
  - source:  ID of the first financial instrument in the pair (always <= InstrumentID_b in this half-matrix view). Resolves to Dim_Currency.CurrencyID for the instrument name
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: ID of the first financial instrument in the pair (always <= InstrumentID_b in this half-matrix view). Resolves to Dim_Currency.CurrencyID for the instrument name (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 30** `InstrumentID_b` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `InstrumentID_b` via exact (case-insensitive), source tier `2`)
  - current: ID of the second financial instrument in the pair. In the full-symmetric output, this can be any instrument (not limited to >= InstrumentID_a). Resolves to Dim_Currency.CurrencyID for the instrument name
  - source:  ID of the second financial instrument in the pair (always >= InstrumentID_a in this half-matrix view). Resolves to Dim_Currency.CurrencyID for the instrument name
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: ID of the second financial instrument in the pair (always >= InstrumentID_a in this half-matrix view). Resolves to Dim_Currency.CurrencyID for the instrument name (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 31** `SampleSize` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `SampleSize` via exact (case-insensitive), source tier `2`)
  - current: Number of hourly candle data points where both instruments had valid prices in the 3-month lookback window. Higher values = more reliable correlation estimate. Low values (< 100) indicate sparse data
  - source:  Number of hourly candle data points where both instruments had valid prices in the 3-month lookback window. Higher values = more reliable correlation estimate. Low values (< 100) indicate sparse data
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Number of hourly candle data points where both instruments had valid prices in the 3-month lookback window. Higher values = more reliable correlation estimate. Low values (< 100) indicate sparse data (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 32** `StandardDeviation_a` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `StandardDeviation_a` via exact (case-insensitive), source tier `2`)
  - current: Population standard deviation of hourly price returns for InstrumentID_a over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows). Swapped with StandardDeviation_…
  - source:  Population standard deviation of hourly price returns for InstrumentID_a over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows)
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Population standard deviation of hourly price returns for InstrumentID_a over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows) (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 33** `StandardDeviation_b` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `StandardDeviation_b` via exact (case-insensitive), source tier `2`)
  - current: Population standard deviation of hourly price returns for InstrumentID_b over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows). Swapped with StandardDeviation_…
  - source:  Population standard deviation of hourly price returns for InstrumentID_b over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows)
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Population standard deviation of hourly price returns for InstrumentID_b over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows) (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 34** `Covariance` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `Covariance` via exact (case-insensitive), source tier `2`)
  - current: Raw covariance between the hourly price returns of the two instruments. Formula: sum(a*b)/n - (sum(a)*sum(b))/n^2. Used as numerator in PearsonCorrelation formula
  - source:  Raw covariance between the hourly price returns of the two instruments. Formula: sum(a*b)/n - (sum(a)*sum(b))/n^2. Used as numerator in PearsonCorrelation formula
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Raw covariance between the hourly price returns of the two instruments. Formula: sum(a*b)/n - (sum(a)*sum(b))/n^2. Used as numerator in PearsonCorrelation formula (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 35** `PearsonCorrelation` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `PearsonCorrelation` via exact (case-insensitive), source tier `2`)
  - current: Pearson correlation coefficient between the two instruments' hourly price returns over the 3-month window. Range -1.0 (perfect negative) to +1.0 (perfect positive). 0 = no linear correlation. Formula: Covariance / (Stan…
  - source:  Pearson correlation coefficient between the two instruments' hourly price returns over the 3-month window. Range -1.0 (perfect negative) to +1.0 (perfect positive). 0 = no linear correlation. Formula: Covariance / (Stan…
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Pearson correlation coefficient between the two instruments' hourly price returns over the 3-month window. Range -1.0 (perfect negative) to +1.0 (perfect positive). 0 = no linear correlation. Formula: Covariance / (StandardDeviation_a * StandardDeviation_b) (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 36** `InsertDate` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `InsertDate` via exact (case-insensitive), source tier `2`)
  - current: Timestamp when the correlation row was first computed. Set to GETDATE() by the ETL SP
  - source:  Timestamp when the correlation row was first computed. Set to GETDATE() by the ETL SP
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Timestamp when the correlation row was first computed. Set to GETDATE() by the ETL SP (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 37** `UpdateDate` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `UpdateDate` via exact (case-insensitive), source tier `2`)
  - current: Timestamp when the correlation row was last updated. Set to GETDATE() by the ETL SP (same as InsertDate on initial load; may differ on re-computation)
  - source:  Timestamp when the correlation row was last updated. Set to GETDATE() by the ETL SP (same as InsertDate on initial load; may differ on re-computation)
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Timestamp when the correlation row was last updated. Set to GETDATE() by the ETL SP (same as InsertDate on initial load; may differ on re-computation) (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

### `knowledge/synapse/Wiki/DWH_dbo/Views/V_Dim_Instrument_Correlation_Test_Full.md` — 10 FAIL(s)

- **line 28** `DateID` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `DateID` via exact (case-insensitive), source tier `2`)
  - current: Integer date key in YYYYMMDD format identifying the calculation date for this correlation snapshot. Matches the @auxdate parameter passed to SP_Dim_Instrument_Correlation_Half_Records. Filter by this column for performa…
  - source:  Integer date key in YYYYMMDD format identifying the calculation date for this correlation snapshot. Matches the @auxdate parameter passed to SP_Dim_Instrument_Correlation_Half_Records. Filter by this column for performa…
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Integer date key in YYYYMMDD format identifying the calculation date for this correlation snapshot. Matches the @auxdate parameter passed to SP_Dim_Instrument_Correlation_Half_Records. Filter by this column for performance (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 29** `InstrumentID_a` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `InstrumentID_a` via exact (case-insensitive), source tier `2`)
  - current: ID of the first financial instrument in the pair. In the full-symmetric output, this can be any instrument (not limited to <= InstrumentID_b). Resolves to Dim_Currency.CurrencyID for the instrument name
  - source:  ID of the first financial instrument in the pair (always <= InstrumentID_b in this half-matrix view). Resolves to Dim_Currency.CurrencyID for the instrument name
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: ID of the first financial instrument in the pair (always <= InstrumentID_b in this half-matrix view). Resolves to Dim_Currency.CurrencyID for the instrument name (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 30** `InstrumentID_b` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `InstrumentID_b` via exact (case-insensitive), source tier `2`)
  - current: ID of the second financial instrument in the pair. In the full-symmetric output, this can be any instrument (not limited to >= InstrumentID_a). Resolves to Dim_Currency.CurrencyID for the instrument name
  - source:  ID of the second financial instrument in the pair (always >= InstrumentID_a in this half-matrix view). Resolves to Dim_Currency.CurrencyID for the instrument name
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: ID of the second financial instrument in the pair (always >= InstrumentID_a in this half-matrix view). Resolves to Dim_Currency.CurrencyID for the instrument name (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 31** `SampleSize` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `SampleSize` via exact (case-insensitive), source tier `2`)
  - current: Number of hourly candle data points where both instruments had valid prices in the 3-month lookback window. Higher values = more reliable correlation estimate. Low values (< 100) indicate sparse data
  - source:  Number of hourly candle data points where both instruments had valid prices in the 3-month lookback window. Higher values = more reliable correlation estimate. Low values (< 100) indicate sparse data
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Number of hourly candle data points where both instruments had valid prices in the 3-month lookback window. Higher values = more reliable correlation estimate. Low values (< 100) indicate sparse data (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 32** `StandardDeviation_a` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `StandardDeviation_a` via exact (case-insensitive), source tier `2`)
  - current: Population standard deviation of hourly price returns for InstrumentID_a over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows). Swapped with StandardDeviation_…
  - source:  Population standard deviation of hourly price returns for InstrumentID_a over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows)
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Population standard deviation of hourly price returns for InstrumentID_a over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows) (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 33** `StandardDeviation_b` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `StandardDeviation_b` via exact (case-insensitive), source tier `2`)
  - current: Population standard deviation of hourly price returns for InstrumentID_b over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows). Swapped with StandardDeviation_…
  - source:  Population standard deviation of hourly price returns for InstrumentID_b over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows)
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Population standard deviation of hourly price returns for InstrumentID_b over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows) (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 34** `Covariance` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `Covariance` via exact (case-insensitive), source tier `2`)
  - current: Raw covariance between the hourly price returns of the two instruments. Formula: sum(a*b)/n - (sum(a)*sum(b))/n^2. Used as numerator in PearsonCorrelation formula
  - source:  Raw covariance between the hourly price returns of the two instruments. Formula: sum(a*b)/n - (sum(a)*sum(b))/n^2. Used as numerator in PearsonCorrelation formula
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Raw covariance between the hourly price returns of the two instruments. Formula: sum(a*b)/n - (sum(a)*sum(b))/n^2. Used as numerator in PearsonCorrelation formula (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 35** `PearsonCorrelation` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `PearsonCorrelation` via exact (case-insensitive), source tier `2`)
  - current: Pearson correlation coefficient between the two instruments' hourly price returns over the 3-month window. Range -1.0 (perfect negative) to +1.0 (perfect positive). 0 = no linear correlation. Formula: Covariance / (Stan…
  - source:  Pearson correlation coefficient between the two instruments' hourly price returns over the 3-month window. Range -1.0 (perfect negative) to +1.0 (perfect positive). 0 = no linear correlation. Formula: Covariance / (Stan…
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Pearson correlation coefficient between the two instruments' hourly price returns over the 3-month window. Range -1.0 (perfect negative) to +1.0 (perfect positive). 0 = no linear correlation. Formula: Covariance / (StandardDeviation_a * StandardDeviation_b) (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 36** `InsertDate` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `InsertDate` via exact (case-insensitive), source tier `2`)
  - current: Timestamp when the correlation row was first computed. Set to GETDATE() by the ETL SP
  - source:  Timestamp when the correlation row was first computed. Set to GETDATE() by the ETL SP
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Timestamp when the correlation row was first computed. Set to GETDATE() by the ETL SP (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

- **line 37** `UpdateDate` — L1-structural / HIGH
  - claim source: `inherited from Dim_Instrument_Correlation_UnionedPartitions wiki`
  - source wiki: `…se/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation_UnionedPartitions.md` (matched col `UpdateDate` via exact (case-insensitive), source tier `2`)
  - current: Timestamp when the correlation row was last updated. Set to GETDATE() by the ETL SP (same as InsertDate on initial load; may differ on re-computation)
  - source:  Timestamp when the correlation row was last updated. Set to GETDATE() by the ETL SP (same as InsertDate on initial load; may differ on re-computation)
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Timestamp when the correlation row was last updated. Set to GETDATE() by the ETL SP (same as InsertDate on initial load; may differ on re-computation) (Tier 2 — via Dim_Instrument_Correlation_UnionedPartitions)

### `knowledge/synapse/Wiki/DWH_dbo/Views/v_Dim_Mirror.md` — 3 FAIL(s)

- **line 84** `OpenOccurred` — L1-structural / HIGH
  - claim source: `inherited from Dim_Mirror wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Mirror.md` (matched col `OpenOccurred` via exact (case-insensitive), source tier `2`)
  - current: Datetime the copy relationship was opened (started). From Trade.Mirror.Occurred. Covers back to 2011-06-13 (first CopyTrader launch)
  - source:  Datetime the copy relationship was opened (started). From Trade.Mirror.Occurred. Covers back to 2011-06-13 (first CopyTrader launch)
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Datetime the copy relationship was opened (started). From Trade.Mirror.Occurred. Covers back to 2011-06-13 (first CopyTrader launch) (Tier 2 — via Dim_Mirror)

- **line 86** `CloseOccurred` — L1-structural / HIGH
  - claim source: `inherited from Dim_Mirror wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Mirror.md` (matched col `CloseOccurred` via exact (case-insensitive), source tier `2`)
  - current: Datetime the copy relationship was closed. '1900-01-01 00:00:00' sentinel = still open (CloseDateID=0)
  - source:  Datetime the copy relationship was closed. '1900-01-01 00:00:00' sentinel = still open (CloseDateID=0). For closed mirrors, this is History.Mirror.ModificationDate at the close event
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: Datetime the copy relationship was closed. '1900-01-01 00:00:00' sentinel = still open (CloseDateID=0). For closed mirrors, this is History.Mirror.ModificationDate at the close event (Tier 2 — via Dim_Mirror)

- **line 102** `UpdateDate` — L1-structural / HIGH
  - claim source: `inherited from Dim_Mirror wiki`
  - source wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Mirror.md` (matched col `UpdateDate` via exact (case-insensitive), source tier `2`)
  - current: ETL run timestamp from the last SP update that touched this row. Set to GETDATE() on each UPDATE/INSERT by the SP
  - source:  ETL run timestamp from the last SP update that touched this row. Set to GETDATE() on each UPDATE/INSERT by the SP
  - reason:  source wiki tags this column as Tier 2 — the (Tier 1) claim is a tier promotion lie
  - **proposed**: ETL run timestamp from the last SP update that touched this row. Set to GETDATE() on each UPDATE/INSERT by the SP (Tier 2 — via Dim_Mirror)
