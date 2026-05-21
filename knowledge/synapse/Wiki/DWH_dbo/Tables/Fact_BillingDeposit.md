# DWH_dbo.Fact_BillingDeposit

> ~75.4M-row Synapse deposit fact (`sp_spaceused` rows≈75387676 as of sampling). Each row is one Billing deposit attempt with Funding-XML fields, Deposit PaymentData XML echoes, FX metadata, PSP routing identifiers, AFT flags from PaymentData, BIN-enriched bank/card labels, rolling daily DELETE+INSERT from Generic Pipeline staging, PlatformID stitched from Fact_CustomerAction, and recurring-deposit applicability.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | `etoro.Billing.Deposit` + `etoro.Billing.Funding` + `etoro.Billing.RecurringDeposit` → `SP_Fact_BillingDeposit_DL_To_Synapse` + post `SP_Fact_BillingDeposit` |
| **Refresh** | Daily slice on `ModificationDate`; `DELETE Fact_BillingDeposit WHERE ModificationDateID` in `[@Yesterday,@CurrentDate)` then rebuild from `Ext_FBD_Fact_BillingDeposit`; `EXEC SP_Fact_BillingDeposit @Yesterday` enriches BIN + MOP country |
| **Synapse Distribution** | `HASH(DepositID)` |
| **Synapse Index** | `CLUSTERED INDEX (DepositID)` + `NC (PaymentStatusID, ExpirationDateID)` |
| **UC Target** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` |
| **UC Format** | delta |
| **UC Partitioned By** | _Pipeline metadata — confirm in Unity Catalog_ |
| **UC Table Type** | Gold export from Synapse `DWH_dbo` |

---

## 1. Business Meaning

`DWH_dbo.Fact_BillingDeposit` is the Synapse analytics projection of `Billing.Deposit`, joined to the customer's `Billing.Funding` row for instrument metadata and XML (`FundingData`), plus an `OUTER APPLY` against `Billing.RecurringDeposit` for the `IsRecurring` flag. `PaymentData` attributes are shredded with `[DWH_dbo].[ExtractXMLValue]` per attribute name in `SP_Fact_BillingDeposit_DL_To_Synapse`. Amount outliers are clamped in ETL (`CASE` thresholds ±1,000,000,000). `AmountUSD` is recomputed in the warehouse as `Amount * ExchangeRate`. `PlatformID` is **not** present in the XML extracts: after the load, the SP updates it from `Fact_CustomerAction` rows with `ActionTypeID = 14` matching on `CID` (= `RealCID`) and `SessionID`. A second stored procedure, `SP_Fact_BillingDeposit`, enriches `MOPCountry` by interpreting `CountryIDAsString` through `Dim_Country`, and enriches `BankName` / `CardCategory` by joining `Dim_CountryBin` on `CAST(BinCodeAsString AS INT)`.

**PHASE 1 CHECKPOINT: PASS** (SSDT `DWH_dbo.Fact_BillingDeposit.sql`, 136 columns).  
**PHASE 2 CHECKPOINT: PASS** (`SELECT TOP 10`, `sp_spaceused` row count; `sys.dm_pdw_nodes_db_partition_stats` denied — used `sp_spaceused` instead).  
**PHASE 3 CHECKPOINT: PASS** (PaymentStatusID distribution on `TOP 100000` latest DepositIDs).

---

## 2. Business Logic

### 2.1 Status, chargebacks, refunds

**What**: Deposit lifecycle mirrors `Dictionary.PaymentStatusStateMachine`; terminal success is Approved (`PaymentStatusID=2`) triggering `Billing.AmountAdd`.

**Columns Involved**: `PaymentStatusID`, `RiskManagementStatusID`, `RefundVerificationCode`

**Rules**:
- See upstream `Billing.Deposit` wiki §2.1 for enumerated `PaymentStatusID` meanings (Approved, declines, Pending, Chargeback `11`, Refund `12`, etc.).
- `RiskManagementStatusID` originates from staging `Billing.Deposit` unchanged.

### 2.2 FTD semantics

**What**: Warehouse stores `IsFTD` as `int` after `CAST`/`ISNULL`; production uses `bit`.

**Columns Involved**: `IsFTD`

**Rules**:
- Derived with `ISNULL(CAST(d.IsFTD AS int),0)` in `SP_Fact_BillingDeposit_DL_To_Synapse`.

### 2.3 FX, gross amount, fees

**What**: `Amount` is deposit-currency money after ETL cap; `AmountUSD` is `Amount * ExchangeRate` from the capped row snapshot.

**Columns Involved**: `Amount`, `CurrencyID`, `ExchangeRate`, `BaseExchangeRate`, `ExchangeFee`, `AmountUSD`

**Rules**:
- `Amount` CASE cap documented inline in Elements.
- `BaseExchangeRate` / `ExchangeFee` are passthrough columns from `Billing.Deposit` (upstream §2.3 for business narrative).

### 2.4 XML shredding & IBAN / wallet / PSP context

**What**: Most `*AsString`/`*AsDecimal`/`*AsInteger` columns are single-attribute extractions; several are `COALESCE` across `PaymentData` and `FundingData`.

**Columns Involved**: all `ExtractXMLValue` columns (see §4)

**Rules**:
- Attribute names match the second parameter literal in `SP_Fact_BillingDeposit_DL_To_Synapse` (verbatim).
- `IBANCodeAsString`, `PurseAsString`, `PSPCodeAsString`, wallet payer fields (`Payer*`): treat as PSP-specific payloads (`[UNVERIFIED]` nuances called out per column).

### 2.5 Platform attribution (warehouse)

**What**: Trading platform/device id enriched from `Fact_CustomerAction` (not from Billing cashier payloads).

**Columns Involved**: `PlatformID`, `SessionID`

**Rules**:
- `UPDATE Fact_BillingDeposit SET PlatformID = source.PlatformID JOIN #Fact_BillingDepositAction … ON CID=RealCID AND SessionID`; temp table seeded from `Fact_CustomerAction` where `ActionTypeID=14` and rolling `DateID` window (-14 days from `@Yesterday`).

### 2.6 BIN post-processing

**What**: Issuing bank and card scheme category come from BIN dimension, not Billing deposit row.

**Columns Involved**: `BinCodeAsString`, `BankName`, `CardCategory`

**Rules**:
- `CAST(BinCodeAsString AS INT) = Dim_CountryBin.BinCode` inside `SP_Fact_BillingDeposit`.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

`HASH(DepositID)` plus clustered `DepositID` supports point lookups; NC `(PaymentStatusID, ExpirationDateID)` supports status/expiry reporting. Always filter `ModificationDateID` for large scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| Approved inflow USD | `WHERE PaymentStatusID=2` sum `AmountUSD` by `ModificationDateID` |
| FTD cohort | `WHERE IsFTD=1 AND PaymentStatusID=2` |
| PSP string signals | Filter `PSPCodeAsString` / `PaymentProviderTransactionStatusAsString` (mind NULLs) |
| 3DS outcomes | `TRY_CAST(ThreeDsResponseType AS INT)` join `Dim_ThreeDsResponseTypes` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `DWH_dbo.Dim_Customer` | `CID` | Customer attributes |
| `DWH_dbo.Dim_Date` | `ModificationDateID` | Activity date |
| `DWH_dbo.Dim_Currency` | `CurrencyID` | Currency labels |
| `DWH_dbo.Dim_FundingType` | `FundingTypeID` | Method-of-payment type |
| `DWH_dbo.Dim_Platform` | `PlatformID` | Device after enrichment |
| `DWH_dbo.Dim_CountryBin` | `CAST(BinCodeAsString AS INT) = BinCode` | Validate BIN enrichments |
| `DWH_dbo.Dim_ThreeDsResponseTypes` | `TRY_CAST(ThreeDsResponseType AS INT)` | 3DS outcome |

### 3.4 Gotchas

- `v` duplicates `ClientBankNameAsString` XML attribute but lands in misnamed column `v`.
- `PlatformIDAsInteger` (XML) ≠ `PlatformID` (Fact_CustomerAction update).
- `LanguageIDAsInteger` / `ACHBankAccountIDAsInteger` are `nvarchar(max)` despite names.
- `SessionID` zeroed with `ISNULL`; join logic must allow `0` vs NULL semantics.
- `ExpirationDateID` CASE returns sentinel `190001` when XML missing/short.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Upstream `Billing.Deposit` wiki / passthrough staging column with same semantics |
| Tier 2 | Expression documented from `SP_Fact_BillingDeposit_DL_To_Synapse` or `SP_Fact_BillingDeposit` with explicit source object |
| Tier 3 | Expression known; business label incomplete — marked `[UNVERIFIED]` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Passthrough `d.CID` from `DWH_staging.etoro_Billing_Deposit`. Production `Billing.Deposit.CID` (same semantics as upstream wiki §4). (Tier 1 — Billing.Deposit) |
| 2 | CurrencyID | int | YES | Passthrough `d.CurrencyID` from staging. Production `Billing.Deposit.CurrencyID`. (Tier 1 — Billing.Deposit) |
| 3 | Commission | money | YES | Passthrough `d.Commission`. Production defaults 0. (Tier 1 — Billing.Deposit) |
| 4 | Approved | bit | YES | Passthrough `d.Approved`. Legacy flag; `PaymentStatusID` is authoritative. (Tier 1 — Billing.Deposit) |
| 5 | ModificationDate | datetime | YES | Passthrough `d.ModificationDate`. ETL incremental watermark. (Tier 1 — Billing.Deposit) |
| 6 | ModificationDateID | int | YES | ETL `convert(int,convert(varchar,dateadd(day,datediff(day,0,d.ModificationDate),0),112))` (`SP_Fact_BillingDeposit_DL_To_Synapse` Ext_FBD SELECT). (Tier 2 — Billing.Deposit.ModificationDate) |
| 7 | FundingID | int | YES | Passthrough `d.FundingID`; JOIN to `etoro_Billing_Funding` `f`. (Tier 1 — Billing.Deposit) |
| 8 | ExchangeRate | numeric(16,8) | YES | Passthrough `d.ExchangeRate`; also used in `Amount * ExchangeRate` for `AmountUSD`. (Tier 1 — Billing.Deposit) |
| 9 | DepositID | int | YES | Passthrough `d.DepositID`. `HASH(DepositID)` distribution + clustered index. (Tier 1 — Billing.Deposit) |
| 10 | ProcessorValueDate | datetime | YES | Passthrough `d.ProcessorValueDate`. (Tier 1 — Billing.Deposit) |
| 11 | DepotID | int | YES | Passthrough `d.DepotID`. (Tier 1 — Billing.Deposit) |
| 12 | SecuredCardDataAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('SecuredCardDataAsString',f.FundingData)`. Token / secured card reference; PSP semantics `[UNVERIFIED]`. (Tier 3 — Billing.Funding.FundingData) |
| 13 | BinCodeAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('BinCodeAsString',f.FundingData)`. Downstream `SP_Fact_BillingDeposit`: `CAST(BinCodeAsString AS INT) = Dim_CountryBin.BinCode`. (Tier 2 — Billing.Funding.FundingData) |
| 14 | BinCountryIDAsInteger | int | YES | `[DWH_dbo].[ExtractXMLValue]('BinCountryIDAsInteger',f.FundingData)` assigned to `int` (implicit cast from string). Prefer `TRY_CAST` for analytics. (Tier 2 — Billing.Funding.FundingData) |
| 15 | CardTypeIDAsInteger | int | YES | `[DWH_dbo].[ExtractXMLValue]('CardTypeIDAsInteger',f.FundingData)` assigned to `int`. Dictionary meaning beyond SQL `[UNVERIFIED]`. (Tier 3 — Billing.Funding.FundingData) |
| 16 | PaymentStatusID | int | YES | Passthrough `d.PaymentStatusID`. Enum per upstream wiki §4 (1=New, 2=Approved, …, 35=DeclineByRRE). (Tier 1 — Billing.Deposit) |
| 17 | ManagerID | int | YES | Passthrough `d.ManagerID`. `0` = automated. (Tier 1 — Billing.Deposit) |
| 18 | RiskManagementStatusID | int | YES | Passthrough `d.RiskManagementStatusID`. Upstream risk reason catalogue. (Tier 1 — Billing.Deposit) |
| 19 | Amount | money | YES | ETL `CASE WHEN d.Amount >= 1000000000 THEN 99999999 WHEN d.Amount <= -1000000000 THEN -99999999 ELSE d.Amount END` (2025-04-17 cap). (Tier 2 — Billing.Deposit.Amount) |
| 20 | PaymentDate | datetime | YES | Passthrough `d.PaymentDate` (submission UTC). (Tier 1 — Billing.Deposit) |
| 21 | IPAddress | numeric(18,0) | YES | Passthrough `d.IPAddress` as `numeric(18,0)` (prod IPv4 encoding). (Tier 1 — Billing.Deposit) |
| 22 | ClearingHouseEffectiveDate | datetime | YES | Passthrough `d.ClearingHouseEffectiveDate`. (Tier 1 — Billing.Deposit) |
| 23 | IsFTD | int | YES | ETL `ISNULL(CAST(d.IsFTD AS int),0)` (bit→int). FTD rules upstream wiki §2.2. (Tier 1 — Billing.Deposit) |
| 24 | RefundVerificationCode | varchar(50) | YES | Passthrough `d.RefundVerificationCode`. (Tier 1 — Billing.Deposit) |
| 25 | MatchStatusID | tinyint | YES | Passthrough `d.MatchStatusID`. PSP reconciliation match. (Tier 1 — Billing.Deposit) |
| 26 | BonusStatusID | int | YES | Status of promotional bonus for this deposit (Tier 1 - Billing.Deposit) |
| 27 | BonusAmount | money | YES | Passthrough `d.BonusAmount`. (Tier 1 — Billing.Deposit) |
| 28 | BonusErrorCode | int | YES | Passthrough `d.BonusErrorCode`. (Tier 1 — Billing.Deposit) |
| 29 | ExTransactionID | varchar(50) | YES | Passthrough `ExTransactionID` from `d` (SELECT list). External provider txn id. (Tier 1 — Billing.Deposit) |
| 30 | FundingTypeID | int | YES | JOIN `f.FundingTypeID` where `d.FundingID = f.FundingID`. (Tier 2 — Billing.Funding.FundingTypeID) |
| 31 | IsRefundExcluded | int | YES | ETL `CAST(f.IsRefundExcluded AS int)`. (Tier 2 — Billing.Funding.IsRefundExcluded) |
| 32 | DocumentRequired | int | YES | ETL `CAST(f.DocumentRequired AS int)`. (Tier 2 — Billing.Funding.DocumentRequired) |
| 33 | UpdateDate | datetime | YES | ETL `GETDATE()` at Ext_FBD build. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 34 | ExpirationDateID | int | YES | Integer date ID derived from ExpirationDateAsString XML attribute (MMYY format). Represents card expiration as YYYYMM (e.g., 202501 = Jan 2025), not YYYYMMDD. Default 190001 when NULL or too short. |
| 35 | CountryIDAsInteger | int | YES | `[DWH_dbo].[ExtractXMLValue]('CountryIDAsInteger',f.FundingData)` (Funding XML, despite column name). (Tier 2 — Billing.Funding.FundingData) |
| 36 | StateIDAsInteger | int | YES | `[DWH_dbo].[ExtractXMLValue]('StateIDAsInteger',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 37 | BankIDAsInteger | int | YES | COALESCE(`[DWH_dbo].[ExtractXMLValue]('BankIDAsInteger',d.PaymentData)`, `[DWH_dbo].[ExtractXMLValue]('BankIDAsInteger',f.FundingData)`). (Tier 2 — Billing.Deposit.PaymentData / Billing.Funding.FundingData) |
| 38 | AccountNameAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('AccountNameAsString',f.FundingData)`. (Tier 2 — Billing.Funding.FundingData) |
| 39 | AccountTypeAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('AccountTypeAsString',f.FundingData)`. (Tier 2 — Billing.Funding.FundingData) |
| 40 | BankAccountAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('BankAccountAsString',f.FundingData)`. (Tier 2 — Billing.Funding.FundingData) |
| 41 | BankAddressAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('BankAddressAsString',f.FundingData)`. (Tier 2 — Billing.Funding.FundingData) |
| 42 | BankCodeAsDecimal | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('BankCodeAsDecimal',f.FundingData)` stored as nvarchar(max). (Tier 2 — Billing.Funding.FundingData) |
| 43 | BankDetailsAccountIDAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('BankDetailsAccountIDAsString',f.FundingData)`. (Tier 2 — Billing.Funding.FundingData) |
| 44 | BankIDAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('BankIDAsString',f.FundingData)`. (Tier 2 — Billing.Funding.FundingData) |
| 45 | BankNameAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('BankNameAsString',f.FundingData)` (XML). Distinct from `BankName` column enriched from `Dim_CountryBin`. (Tier 2 — Billing.Funding.FundingData) |
| 46 | BICCodeAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('BICCodeAsString',f.FundingData)`. (Tier 2 — Billing.Funding.FundingData) |
| 47 | CIDAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('CIDAsString',f.FundingData)`. (Tier 2 — Billing.Funding.FundingData) |
| 48 | v | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('ClientBankNameAsString',f.FundingData)` **aliased** `AS v` — duplicate payload versus `ClientBankNameAsString` column (same XML key loaded twice). (Tier 3 — Billing.Funding.FundingData) |
| 49 | CustomerAddressAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('CustomerAddressAsString',f.FundingData)`. (Tier 2 — Billing.Funding.FundingData) |
| 50 | CustomerNameAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('CustomerNameAsString',f.FundingData)`. (Tier 2 — Billing.Funding.FundingData) |
| 51 | FundingType | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('FundingType',f.FundingData)` textual label alongside typed `FundingTypeID`. (Tier 2 — Billing.Funding.FundingData) |
| 52 | MaskedAccountIDAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('MaskedAccountIDAsString',f.FundingData)`. (Tier 2 — Billing.Funding.FundingData) |
| 53 | PurseAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('PurseAsString',f.FundingData)`. (Tier 2 — Billing.Funding.FundingData) |
| 54 | RoutingNumberAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('RoutingNumberAsString',f.FundingData)`. (Tier 2 — Billing.Funding.FundingData) |
| 55 | SecureIDAsDecimal | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('SecureIDAsDecimal',f.FundingData)` (nvarchar storage). (Tier 2 — Billing.Funding.FundingData) |
| 56 | SortCodeAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('SortCodeAsString',f.FundingData)`. (Tier 2 — Billing.Funding.FundingData) |
| 57 | AccountBalanceAsDecimal | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('AccountBalanceAsDecimal',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 58 | AccountHolderAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('AccountHolderAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 59 | AccountIDAsDecimal | nvarchar(max) | YES | COALESCE(`[DWH_dbo].[ExtractXMLValue]('AccountIDAsDecimal',d.PaymentData)`, `[DWH_dbo].[ExtractXMLValue]('AccountIDAsDecimal',f.FundingData)`). (Tier 2 — Billing.Deposit.PaymentData / Billing.Funding.FundingData) |
| 60 | ACHBankAccountIDAsInteger | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('ACHBankAccountIDAsInteger',d.PaymentData)` (DDL `nvarchar(max)`). (Tier 2 — Billing.Deposit.PaymentData) |
| 61 | Address1AsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('Address1AsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 62 | Address2AsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('Address2AsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 63 | AdviseAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('AdviseAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 64 | AvailableBalanceAsDecimal | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('AvailableBalanceAsDecimal',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 65 | BankCodeAsString | nvarchar(max) | YES | COALESCE(`[DWH_dbo].[ExtractXMLValue]('BankCodeAsString',d.PaymentData)`, `[DWH_dbo].[ExtractXMLValue]('BankCodeAsString',f.FundingData)`). (Tier 2 — Billing.Deposit.PaymentData / Billing.Funding.FundingData) |
| 66 | BillNumberAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('BillNumberAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 67 | BuildingNumberAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('BuildingNumberAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 68 | CardHolderPhoneNumberBodyAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('CardHolderPhoneNumberBodyAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 69 | CardHolderPhoneNumberPrefixAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('CardHolderPhoneNumberPrefixAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 70 | CardNumberAsString | nvarchar(max) | YES | COALESCE(`[DWH_dbo].[ExtractXMLValue]('CardNumberAsString',d.PaymentData)`, `[DWH_dbo].[ExtractXMLValue]('CardNumberAsString',f.FundingData)`). (Tier 2 — Billing.Deposit.PaymentData / Billing.Funding.FundingData) |
| 71 | CityAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('CityAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 72 | CountryIDAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('CountryIDAsString',d.PaymentData)`. Feeds `MOPCountry` resolution in `SP_Fact_BillingDeposit` via `Dim_Country` joins. (Tier 2 — Billing.Deposit.PaymentData) |
| 73 | CountryNameAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('CountryNameAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 74 | CreatedAtAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('CreatedAtAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 75 | CurrentBalanceAsDecimal | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('CurrentBalanceAsDecimal',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 76 | CustomerIDAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('CustomerIDAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 77 | EmailAsString | nvarchar(max) | YES | COALESCE(`[DWH_dbo].[ExtractXMLValue]('EmailAsString',d.PaymentData)`, `[DWH_dbo].[ExtractXMLValue]('EmailAsString',f.FundingData)`). (Tier 2 — Billing.Deposit.PaymentData / Billing.Funding.FundingData) |
| 78 | EndPointIDAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('EndPointIDAsString',d.PaymentData)`. PSP endpoint id; business label `[UNVERIFIED]`. (Tier 3 — Billing.Deposit.PaymentData) |
| 79 | ErrorCodeAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('ErrorCodeAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 80 | ErrorTypeAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('ErrorTypeAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 81 | FirstNameAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('FirstNameAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 82 | IBANCodeAsString | nvarchar(max) | YES | COALESCE(`[DWH_dbo].[ExtractXMLValue]('IBANCodeAsString',d.PaymentData)`, `[DWH_dbo].[ExtractXMLValue]('IBANCodeAsString',f.FundingData)`). (Tier 2 — Billing.Deposit.PaymentData / Billing.Funding.FundingData) |
| 83 | InitialTransactionIDAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('InitialTransactionIDAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 84 | IPAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('IPAsString',d.PaymentData)`. Parallel to numeric `IPAddress`. (Tier 2 — Billing.Deposit.PaymentData) |
| 85 | LanguageIDAsInteger | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('LanguageIDAsInteger',d.PaymentData)` (nvarchar(max) column). (Tier 2 — Billing.Deposit.PaymentData) |
| 86 | LastNameAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('LastNameAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 87 | MD5AsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('MD5AsString',d.PaymentData)` provider hash / fingerprint `[UNVERIFIED]`. (Tier 3 — Billing.Deposit.PaymentData) |
| 88 | PayerAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('PayerAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 89 | PayerBusiness | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('PayerBusiness',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 90 | PayerIDAsString | nvarchar(max) | YES | COALESCE(`[DWH_dbo].[ExtractXMLValue]('PayerIDAsString',d.PaymentData)`, `[DWH_dbo].[ExtractXMLValue]('PayerIDAsString',f.FundingData)`). (Tier 2 — Billing.Deposit.PaymentData / Billing.Funding.FundingData) |
| 91 | PayerPurseAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('PayerPurseAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 92 | PayerStatus | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('PayerStatus',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 93 | PaymentAmountAsDecimal | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('PaymentAmountAsDecimal',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 94 | PaymentDateAsDateTime | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('PaymentDateAsDateTime',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 95 | PaymentGuaranteeAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('PaymentGuaranteeAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 96 | PaymentModeAsInteger | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('PaymentModeAsInteger',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 97 | PaymentProviderTransactionStatusAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('PaymentProviderTransactionStatusAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 98 | PaymentStatusAsInteger | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('PaymentStatusAsInteger',d.PaymentData)`. Provider status integer echo; not identical to `PaymentStatusID` semantics. (Tier 2 — Billing.Deposit.PaymentData) |
| 99 | PaymentTypeAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('PaymentTypeAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 100 | PlaidItemIDAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('PlaidItemIDAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 101 | PlaidNamesAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('PlaidNamesAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 102 | PlatformIDAsInteger | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('PlatformIDAsInteger',d.PaymentData)`. Separate from fact `PlatformID` (session join). (Tier 2 — Billing.Deposit.PaymentData) |
| 103 | PromotionCodeAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('PromotionCodeAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 104 | PSPCodeAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('PSPCodeAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 105 | RapidFirstNameAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('RapidFirstNameAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 106 | RapidLastNameAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('RapidLastNameAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 107 | ResponseMessageAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('ResponseMessageAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 108 | ResponseTimeAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('ResponseTimeAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 109 | SecretKeyAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('SecretKeyAsString',d.PaymentData)`. Masked / reference only; treat as sensitive. (Tier 2 — Billing.Deposit.PaymentData) |
| 110 | ThreeDsAsJson | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('ThreeDsAsJson',d.PaymentData)`. Raw 3DS payload JSON string. (Tier 2 — Billing.Deposit.PaymentData) |
| 111 | ThreeDsResponseType | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('ThreeDsResponseType',d.PaymentData)`. Outcome id as string; analysts `TRY_CAST` → `Dim_ThreeDsResponseTypes`. (Tier 2 — Billing.Deposit.PaymentData) |
| 112 | TokenAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('TokenAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 113 | TransactionIDAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('TransactionIDAsString',d.PaymentData)`. Distinct from `Billing.Deposit.TransactionID` (internal 6-char) — this is provider string from XML. (Tier 2 — Billing.Deposit.PaymentData) |
| 114 | ZipCodeAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('ZipCodeAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 115 | BaseExchangeRate | numeric(16,8) | YES | Passthrough `d.BaseExchangeRate`. Upstream: reference rate before fee markup. (Tier 1 — Billing.Deposit) |
| 116 | ExchangeFee | int | YES | Passthrough `d.ExchangeFee`. (Tier 1 — Billing.Deposit) |
| 117 | ProtocolMIDSettingsID | int | YES | Passthrough `d.ProtocolMIDSettingsID`. (Tier 1 — Billing.Deposit) |
| 118 | FunnelID | int | YES | Passthrough `d.FunnelID`. (Tier 1 — Billing.Deposit) |
| 119 | AmountUSD | decimal(11,2) | YES | Second INSERT: `Amount * ExchangeRate AS AmountUSD` from `Ext_FBD_Fact_BillingDeposit` snapshot (post-cap `Amount`). (Tier 2 — Billing.Deposit.Amount/ExchangeRate) |
| 120 | SessionID | bigint | YES | ETL `ISNULL(d.SessionID,0)` (Ext_FBD). Platform enrichment JOIN uses `CID`+`SessionID`. (Tier 2 — Billing.Deposit.SessionID) |
| 121 | PlatformID | int | YES | Pass-1 INSERT leaves NULL; then `UPDATE a SET PlatformID=b.PlatformID FROM Fact_BillingDeposit a JOIN #Fact_BillingDepositAction b ON `a.CID=b.RealCID AND a.SessionID=b.SessionID` where `#Fact_BillingDepositAction` is built from `Fact_CustomerAction` `ActionTypeID=14` (`SP_Fact_BillingDeposit_DL_To_Synapse`). (Tier 5 — Fact_CustomerAction.PlatformID) |
| 122 | MOPCountry | varchar(50) | YES | `UPDATE … SET MOPCountry=m.MOPCountry` from `#MOPCountryFinal` built off `CountryIDAsString` with nested `LEFT JOIN Dim_Country` on numeric id vs `LongAbbreviation` vs `Abbreviation` (`SP_Fact_BillingDeposit`, `@dateID` slice). (Tier 2 — Dim_Country.Name via CountryIDAsString) |
| 123 | SwiftCodeAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('SwiftCodeAsString',f.FundingData)`. (Tier 2 — Billing.Funding.FundingData) |
| 124 | ClientBankNameAsString | nvarchar(max) | YES | `[DWH_dbo].[ExtractXMLValue]('ClientBankNameAsString',f.FundingData)` **AS ClientBankNameAsString** (same XML key also loaded into `v`). (Tier 2 — Billing.Funding.FundingData) |
| 125 | BankName | varchar(100) | YES | `UPDATE fbw SET BankName = cb.IssuingBank` JOIN `Dim_CountryBin cb` ON `CAST(fbw.BinCodeAsString AS INT) = cb.BinCode` (`SP_Fact_BillingDeposit`). (Tier 2 — Dim_CountryBin.IssuingBank) |
| 126 | CardCategory | varchar(50) | YES | `UPDATE fbw SET CardCategory = cb.CardCategory` same JOIN as `BankName` (`SP_Fact_BillingDeposit`). (Tier 2 — Dim_CountryBin.CardCategory) |
| 127 | PaymentGeneration | int | YES | Passthrough `d.PaymentGeneration`. (Tier 1 — Billing.Deposit) |
| 128 | ProcessRegulationID | int | YES | Passthrough `d.ProcessRegulationID`. (Tier 1 — Billing.Deposit) |
| 129 | MerchantAccountID | int | YES | Passthrough `d.MerchantAccountID`. (Tier 1 — Billing.Deposit) |
| 130 | IsSetBalanceCompleted | int | YES | Whether the balance-credit operation (Billing.AmountAdd) for this deposit has completed; 1 = account crediting succeeded, 0 = pending retry. Cast from bit to INT by ETL. (Tier 1 - Billing.Deposit.md) |
| 131 | RoutingReasonID | int | YES | Passthrough `d.RoutingReasonID`. (Tier 1 — Billing.Deposit) |
| 132 | IsRecurring | int | YES | ETL `ISNULL(Recurring.IsRecurring,0)` from `OUTER APPLY (SELECT 1 AS IsRecurring FROM etoro_Billing_RecurringDeposit WHERE DepositID=d.DepositID) Recurring`. (Tier 2 — Billing.RecurringDeposit) |
| 133 | FlowID | int | YES | Passthrough `d.FlowID` (SELECT list uses bare `FlowID`). (Tier 1 — Billing.Deposit) |
| 134 | IsAftSupportedAsBool | bit | YES | Whether Account Funding Transaction (AFT) is supported. Extracted from Billing.Deposit PaymentData XML (not Billing.Funding). Defaults to 0 when NULL. |
| 135 | IsAftEligibleAsBool | bit | YES | Whether this deposit was eligible for AFT processing. Extracted from Billing.Deposit PaymentData XML (not Billing.Funding). Defaults to 0 when NULL. |
| 136 | IsAftProcessedAsBool | bit | YES | ETL `ISNULL([DWH_dbo].[ExtractXMLValue]('IsAftProcessedAsBool',d.PaymentData),0)`. (Tier 2 — Billing.Deposit.PaymentData) |


---

## 5. Lineage

### 5.1 Production Sources

| Synapse column group | Production / warehouse source | Transform |
|---------------------|------------------------------|-----------|
| Core deposit keys & amounts | `Billing.Deposit` via `DWH_staging.etoro_Billing_Deposit` | Passthrough + `Amount` CASE + `IsFTD` cast + `SessionID` ISNULL |
| Instrument type & refund/doc flags | `Billing.Funding` via `etoro_Billing_Funding` | JOIN on `FundingID` |
| Recurring flag | `Billing.RecurringDeposit` | `OUTER APPLY` existence → `IsRecurring` |
| XML attributes | `PaymentData` / `FundingData` blobs | `ExtractXMLValue` per attribute |
| USD reporting column | Derived | `Amount * ExchangeRate` |
| Platform | `Fact_CustomerAction` | `UPDATE` join on `CID`+`SessionID`, `ActionTypeID=14` |
| MOP country string | `Dim_Country` | Interpret `CountryIDAsString` (`SP_Fact_BillingDeposit`) |
| Bank / card category | `Dim_CountryBin` | `CAST(BinCodeAsString AS INT)` |

### 5.2 ETL Pipeline

```
etoro.Billing.Deposit ─┐
                        ├─► Lake / Generic Pipeline ► DWH_staging.etoro_Billing_Deposit (d)
etoro.Billing.Funding ─┘       │
                               JOIN etoro_Billing_Funding (f)
                               OUTER APPLY etoro_Billing_RecurringDeposit
                               ► INSERT Ext_FBD_Fact_BillingDeposit
                               ► DELETE+INSERT DWH_dbo.Fact_BillingDeposit
                               ► UPDATE PlatformID (Fact_CustomerAction #temp)
                               ► EXEC SP_Fact_BillingDeposit (@date)
                                      ├► UPDATE MOPCountry (Dim_Country)
                                      └► UPDATE BankName / CardCategory (Dim_CountryBin)
Unity Catalog Gold: main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
```

---

## 6. Relationships

### 6.1 References To (this fact points outward)

| Element | Related object | Notes |
|---------|---------------|------|
| `CID` | `DWH_dbo.Dim_Customer` | Customer key |
| `CurrencyID` | `DWH_dbo.Dim_Currency` | |
| `FundingTypeID` | `DWH_dbo.Dim_FundingType` | |
| `PaymentStatusID` | `DWH_dbo.Dim_PaymentStatus` | |
| `ModificationDateID` | `DWH_dbo.Dim_Date` | |
| `RiskManagementStatusID` | `DWH_dbo.Dim_RiskManagementStatus` | |
| `FunnelID` | `DWH_dbo.Dim_Funnel` | |
| `PlatformID` | `DWH_dbo.Dim_Platform` | After UPDATE |
| `TRY_CAST(ThreeDsResponseType AS INT)` | `DWH_dbo.Dim_ThreeDsResponseTypes` | |

### 6.2 Referenced By

| Consumer | Relationship |
|----------|--------------|
| `DWH_dbo.VU_FactBilling_ForBigQuery` | View over this table |
| Multiple `BI_DB_dbo` AML / revenue / operations SPs | JOIN by `CID` / `DepositID` |
| `SP_Fact_BillingDeposit` | Same-table UPDATE enrichments |

---

## 7. Sample Queries

### 7.1 Recent approved USD volume

```sql
SELECT ModificationDateID,
       SUM(AmountUSD) AS usd
FROM [DWH_dbo].[Fact_BillingDeposit]
WHERE PaymentStatusID = 2
  AND ModificationDateID >= CONVERT(int, CONVERT(varchar(8), DATEADD(day, -7, SYSUTCDATETIME()), 112))
GROUP BY ModificationDateID
ORDER BY ModificationDateID DESC;
```

### 7.2 BIN enrichment coverage

```sql
SELECT CASE WHEN BankName IS NULL THEN 0 ELSE 1 END AS has_bankname,
       COUNT(*) AS deposits
FROM [DWH_dbo].[Fact_BillingDeposit]
WHERE ModificationDateID >= CONVERT(int, CONVERT(varchar(8), DATEADD(day, -1, SYSUTCDATETIME()), 112))
GROUP BY CASE WHEN BankName IS NULL THEN 0 ELSE 1 END;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Notes |
|--------|------|-------|
| Upstream `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` | Wiki | Tier-1 business semantics for core deposit columns |
| Confluence links embedded in `Billing.Deposit` wiki | Confluence | PSP / funding-type operational context (follow upstream doc) |

---

*Generated: 2026-05-14 | Quality: 8.5/10 | Phases: Speckit 1–16 pass (MCP sample + SSDT + SP trace)*  
*Tiers: 33 T1, 97 T2, 6 T3, 0 T4 | Elements: 136/136 | Row estimate: ~75.4M (`sp_spaceused`)*  
*Object: DWH_dbo.Fact_BillingDeposit | Type: Table | Sources: Billing.Deposit + Billing.Funding + RecurringDeposit + Fact_CustomerAction + Dim_Country + Dim_CountryBin*
