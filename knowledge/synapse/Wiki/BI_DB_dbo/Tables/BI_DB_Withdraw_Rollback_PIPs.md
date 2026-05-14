# BI_DB_dbo.BI_DB_Withdraw_Rollback_PIPs

> 149-row cashout rollback PIPs table recording withdrawal rollback and cancelled-rollback events with merchant ID attribution, customer snapshot attributes, and PIPs (payment processing) calculations. Populated daily by SP_Withdraw_Rollback_PIPs from Billing.CashoutRollbackTracking joined to Fact_BillingWithdraw and dimension tables. Data from 2024-01-05 to present.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Billing.CashoutRollbackTracking via External_etoro_Billing_CashoutRollbackTracking + DWH_dbo.Fact_BillingWithdraw + DWH_dbo.Fact_CustomerAction (ActionTypeID=42) |
| **Refresh** | Daily via SP_Withdraw_Rollback_PIPs @Date |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (Date ASC, CID ASC) |
| **UC Target** | _Pending_ |
| **UC Format** | _Pending_ |
| **UC Partitioned By** | _Pending_ |
| **UC Table Type** | _Pending_ |

---

## 1. Business Meaning

`BI_DB_dbo.BI_DB_Withdraw_Rollback_PIPs` captures cashout rollback events for finance reconciliation and PIPs (Payment Intermediary Processing) analysis. Each row represents a withdrawal payment that was rolled back (returned payment, rejected payment, adjust discrepancy) or a cancelled rollback, enriched with customer snapshot attributes, payment method metadata, merchant ID (MID) attribution, and PIPs calculations in USD.

The table was created as a temporary solution (authored by Guy Manova, 2023-01-30) to bring cashout rollback PIPs data into the finance reporting layer, previously only available through the BackOffice system. The SP replicates production logic from `Billing.GetRollbackedPaymentOrdersReport` and `BackOffice.GetProcessedWithdrawPCIVersion`, translating production UDF-based merchant detail lookups into table joins since Synapse does not support SELECT statements within UDFs.

As of 2026-04-30, the table contains 149 rows spanning from 2024-01-05 to 2025-08-14. Two transaction types exist: CashoutRollback (106 rows, 71%) for actual rollbacks (CashoutStatusID IN (16=Reversed, 17=Partially Reversed)) and CancelledCashoutRollback (43 rows, 29%) for processed rollbacks that were subsequently cancelled (CashoutStatusID=3=Processed).

The ETL pattern is DELETE by DateID + INSERT. The SP uses Fact_CustomerAction (ActionTypeID=42, cashout rollbacks) to identify the day's events, joins to External_etoro_Billing_CashoutRollbackTracking for rollback details, Fact_BillingWithdraw for payment execution data, and multiple merchant account tables for MID resolution.

---

## 2. Business Logic

### 2.1 Transaction Type Classification

**What**: Classifies each rollback event based on the CashoutStatus of the WithdrawToFunding action.

**Columns Involved**: `TransactionType`, CashoutStatusID (from External_Etoro_History_vWithdrawToFundingAction)

**Rules**:
- CashoutStatusID IN (16=Reversed, 17=Partially Reversed) → `CashoutRollback` (71% of rows)
- CashoutStatusID = 3 (Processed) → `CancelledCashoutRollback` (29%)
- All other statuses → `NA` (not observed in current data)

### 2.2 MID Resolution (Multi-Source Cascade)

**What**: Resolves the Merchant ID (MIDValue) and Entity name (MIDNameFinal) through a depot-specific cascade of merchant account lookups.

**Columns Involved**: `MIDValue`, `Entity`, `Depot`, DepotID

**Rules**:
- **Depot IDs 35-43** (specific acquirers): Uses BPMS2.Value (from deposit-side ProtocolMIDSettings) and DR2 regulation name
- **Depot IDs 1,24,25,26,78,79,80,4,75,86** (credit card gateways): Uses BackOffice.GetMerchantDetails via MerchantAccountRouting lookup
- **WireTransfer**: Uses BPMS1 (withdraw-side ProtocolMIDSettings) Description and Value
- **All other depots**: Falls back to COALESCE(BOGetMerchantDetails via WTF MerchantAccountID, BOGetMerchantDetails via BPMS1 MerchantAccountID, DR2 regulation name, MapMerchantCodeToMid, BPMS1 Value)

### 2.3 PIPs Calculation

**What**: Computes the PIPs (payment processing intermediary profit/loss) for the rollback amount, pro-rated from the original withdrawal PIPs.

**Columns Involved**: `PIPsCalculation`, `BaseExchangeRate`, `Amount`, `AmountUSD`

**Rules**:
- Retrieves the original withdrawal's PIPsCalculation from `BI_DB_DepositWithdrawFee` by matching CID and TransactionID (WithdrawPaymentID + 'W')
- Computes `PIPsRatioNew = RollbackAmount / Amount_WithdrawToFunding` (proportion of rollback to original withdrawal)
- `PIPsCalculationNew = PIPsRatioNew * original PIPsCalculation`
- `PIPsCalculationOld = ((-1 * AmountUSD / BaseExchangeRate) + Amount) * BaseExchangeRate` (legacy formula)
- Final: If PIPsCalculationOld differs from PIPsCalculationNew and is not NULL, uses Old; otherwise uses New
- Sign: negated when RollbackAmount > 0

### 2.4 BaseExchangeRate Inversion for Reciprocal Forex Pairs

**What**: For instruments where USD is the buy-side currency (reciprocal pairs), inverts the BaseExchangeRate.

**Columns Involved**: `BaseExchangeRate`

**Rules**:
- Builds a list of reciprocal forex pairs from Dim_Instrument (InstrumentTypeID=1, BuyCurrencyID=1)
- If the withdrawal's ProcessCurrency abbreviation matches a reciprocal pair: `1/BaseExchangeRate`
- Otherwise: passthrough from Fact_BillingWithdraw.BaseExchangeRate

### 2.5 Hardcoded / Unpopulated Columns

**What**: Several columns exist for schema compatibility with BI_DB_DepositWithdrawFee but are not populated.

**Columns Involved**: `CreditTypeID`, `CardCategory`, `BinCountry`, `MOPCountry`, `IsGermanBaFin`

**Rules**:
- CreditTypeID = 33 (hardcoded — maps to Dictionary.CreditType for cashout rollback)
- CardCategory = 'NA' (not computed for rollbacks)
- BinCountry = 'NA' (not computed for rollbacks)
- MOPCountry = 'NA' (not computed for rollbacks)
- IsGermanBaFin = NULL (not computed for rollbacks)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CID) distribution with CLUSTERED INDEX on (Date ASC, CID ASC). With only 149 rows, distribution strategy is largely irrelevant for performance. The clustered index supports date-range + customer queries efficiently.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All rollbacks for a date | `WHERE DateID = @dateID` |
| Rollback vs cancelled breakdown | `GROUP BY TransactionType` |
| Total rollback PIPs by regulation | `GROUP BY Regulation` with `SUM(PIPsCalculation)` |
| Rollbacks for a specific customer | `WHERE CID = @cid` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_DepositWithdrawFee | ON CID and TransactionID | Reconcile rollback PIPs against original withdrawal PIPs |
| DWH_dbo.Dim_Date | ON DateID | Calendar attributes |
| DWH_dbo.Dim_Customer | ON CID = RealCID | Additional customer attributes not in this table |

### 3.4 Gotchas

- **Very small table**: Only 149 rows — aggregations are trivial but beware of drawing statistical conclusions from small samples.
- **CreditTypeID is always 33**: Hardcoded in the SP, not sourced from production data. Represents cashout rollback credit type.
- **CardCategory, BinCountry, MOPCountry are always 'NA'**: These columns exist for schema compatibility with BI_DB_DepositWithdrawFee but carry no data for rollbacks.
- **IsGermanBaFin is always NULL**: Not computed for this table.
- **Amounts can be negative**: The SP does not apply ABS — negative RollbackAmountInCurrency values flow through as negative Amount/AmountUSD.
- **PIPsCalculation may be NULL**: When the BI_DB_DepositWithdrawFee JOIN fails to match (no original withdrawal PIPs record), PIPsCalculation is NULL.
- **TransactionID format**: Always ends with 'W' (WithdrawPaymentID cast to varchar + 'W'). Matches the convention in BI_DB_DepositWithdrawFee.
- **Customer is ExternalID (decimal as varchar)**: Not the CID — it is the APEX broker external identifier from Dim_Customer.
- **This SP is described as temporary**: The codebase notes this should eventually be replaced by production views from DBAs; hardcoded business rules may diverge from production over time.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki — description copied as-is |
| Tier 2 | ETL-computed in SP_Withdraw_Rollback_PIPs — transform documented from SP code |
| Tier 3 | Source identified but no upstream wiki available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Business date as YYYYMMDD for the SP run (@StartDateInt). (Tier 2 — SP_Withdraw_Rollback_PIPs) |
| 2 | CID | int | YES | Customer ID (RealCID) from the cashout rollback tracking source. HASH distribution key. (Tier 3 — Billing.CashoutRollbackTracking, no upstream wiki) |
| 3 | DepositWithdrawID | int | YES | Withdrawal request ID (WithdrawID from rollback tracking). Identifies the original cashout request that was rolled back. (Tier 3 — Billing.CashoutRollbackTracking, no upstream wiki) |
| 4 | Occurred | datetime | YES | Timestamp of the rollback status modification (ModificationDate from CashoutRollbackTracking). (Tier 3 — Billing.CashoutRollbackTracking, no upstream wiki) |
| 5 | CreditTypeID | tinyint | YES | Hardcoded to 33 (cashout rollback credit type). Not sourced from production data in this SP. (Tier 2 — SP_Withdraw_Rollback_PIPs) |
| 6 | TransactionID | varchar(200) | YES | Synthetic identifier: CAST(WithdrawPaymentID AS VARCHAR(30)) + 'W'. Matches the TransactionID convention in BI_DB_DepositWithdrawFee for reconciliation. (Tier 2 — SP_Withdraw_Rollback_PIPs) |
| 7 | Date | date | YES | Calendar date of the rollback status modification. Derived: CAST(ModificationDate AS DATE). (Tier 2 — External_etoro_Billing_CashoutRollbackTracking) |
| 8 | Customer | varchar(50) | YES | APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 9 | TransactionType | varchar(50) | YES | Rollback event classification. CASE on CashoutStatusID: Reversed/Partially Reversed='CashoutRollback' (71%), Processed='CancelledCashoutRollback' (29%), else 'NA'. (Tier 2 — SP_Withdraw_Rollback_PIPs) |
| 10 | PaymentMethod | varchar(50) | YES | Payment method name. COALESCE of Dim_FundingType.Name via FundingTypeID_Funding (actual instrument), falling back to FundingTypeID_Withdraw (requested method). (Tier 2 — Fact_BillingWithdraw / Dim_FundingType) |
| 11 | Amount | numeric(38,8) | YES | Rollback amount in original currency (RollbackAmountInCurrency from CashoutRollbackTracking). May be negative. (Tier 3 — Billing.CashoutRollbackTracking, no upstream wiki) |
| 12 | Currency | varchar(20) | YES | Ticker symbol. "USD", "EUR", "AAPL.US". UNIQUE constraint in production. The primary identifier used in UIs and APIs. Passthrough from Dim_Currency via Fact_BillingWithdraw.ProcessCurrencyID. (Tier 1 — Dictionary.Currency) |
| 13 | ExchangeRate | numeric(38,8) | YES | Exchange rate on the rollback event from CashoutRollbackTracking. (Tier 3 — Billing.CashoutRollbackTracking, no upstream wiki) |
| 14 | AmountUSD | numeric(38,8) | YES | Rollback amount in USD (RollbackAmountInUSD from CashoutRollbackTracking). May be negative. (Tier 3 — Billing.CashoutRollbackTracking, no upstream wiki) |
| 15 | RegulationID | int | YES | Customer's regulatory jurisdiction at the time of the event. Sourced from Fact_SnapshotCustomer via Dim_Range point-in-time lookup. (Tier 2 — Fact_SnapshotCustomer) |
| 16 | LabelID | int | YES | Internal segment label. FK to Dictionary.Label. LabelID=26 = BonusOnly customer (triggers IsHedged=0). Default=0. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 17 | PlayerLevelID | int | YES | Customer experience/permission level. FK to Dictionary.PlayerLevel. 1=Bronze; 4=Internal; 7=Diamond. Determines available features and risk limits. Default=0. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 18 | Regulation | varchar(50) | YES | Short code for the regulation. Values match production Dictionary.Regulation.Name. Dim-lookup passthrough via Fact_SnapshotCustomer.RegulationID. (Tier 1 — Dictionary.Regulation) |
| 19 | Label | varchar(50) | YES | Brand name displayed in BackOffice interfaces, reports, and internal systems. Dim-lookup passthrough via Dim_Label.LabelID. (Tier 1 — Dictionary.Label) |
| 20 | IsValidCustomer | int | YES | DWH-computed: 1 when PlayerLevelID!=4 AND LabelID NOT IN (30,26) AND CountryID!=250. Used in reporting to filter out non-standard customers. Passthrough from Dim_Customer. (Tier 2 — Dim_Customer) |
| 21 | UpdateDate | datetime | NO | Row load timestamp (GETDATE() at insert). (Tier 2 — SP_Withdraw_Rollback_PIPs) |
| 22 | BaseExchangeRate | numeric(38,8) | YES | Reference exchange rate before fee markup. Conditionally inverted (1/rate) for reciprocal forex pairs where USD is the buy-side currency; otherwise passthrough from Fact_BillingWithdraw. (Tier 2 — Fact_BillingWithdraw) |
| 23 | ExchangeFee | numeric(38,8) | YES | Exchange fee in provider-specific integer units. Passthrough from Fact_BillingWithdraw. (Tier 1 — Billing.WithdrawToFunding) |
| 24 | ExternalTransactionID | varchar(1000) | YES | Provider reference number from the rollback tracking record (ReferenceNumber). (Tier 3 — Billing.CashoutRollbackTracking, no upstream wiki) |
| 25 | Depot | varchar(1000) | YES | Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports. Dim-lookup passthrough via Fact_BillingWithdraw.DepotID. (Tier 1 — Billing.Depot) |
| 26 | MIDValue | varchar(1000) | YES | Resolved Merchant ID string. Complex depot-specific cascade: credit card depots use BackOffice merchant details, wire uses BPMS Value, others fall back through WTF MerchantAccount, BPMS MerchantAccount, MapMerchantCodeToMid. (Tier 2 — SP_Withdraw_Rollback_PIPs) |
| 27 | Club | varchar(1000) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup passthrough via Fact_SnapshotCustomer.PlayerLevelID. (Tier 1 — Dictionary.PlayerLevel) |
| 28 | PlayerStatus | varchar(1000) | YES | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Dim-lookup passthrough via Fact_SnapshotCustomer.PlayerStatusID. (Tier 1 — Dictionary.PlayerStatus) |
| 29 | PIPsCalculation | numeric(38,8) | YES | Rollback PIPs in USD. Computed as pro-rated share of original withdrawal PIPs (RollbackAmount/Amount * original PIPs), with fallback to legacy formula using BaseExchangeRate. Negated when RollbackAmount > 0. NULL when original PIPs record not found. (Tier 2 — Fact_BillingWithdraw / BI_DB_DepositWithdrawFee) |
| 30 | RegCountry | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup passthrough from Dim_Country via Dim_Customer.CountryID. (Tier 1 — Dictionary.Country) |
| 31 | RegCountryByIP | varchar(50) | YES | Full country name in English. Dim-lookup passthrough from Dim_Country via Dim_Customer.CountryIDByIP. (Tier 1 — Dictionary.Country) |
| 32 | CardType | varchar(50) | YES | Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Dim-lookup passthrough from Dim_CardType via Dim_CountryBin.CardTypeID from Fact_BillingWithdraw.BinCodeAsString. (Tier 1 — Dictionary.CardType) |
| 33 | CardCategory | varchar(50) | YES | Not populated for rollbacks. Hardcoded 'NA'. (Tier 2 — SP_Withdraw_Rollback_PIPs) |
| 34 | BinCountry | varchar(100) | YES | Not populated for rollbacks. Hardcoded 'NA'. (Tier 2 — SP_Withdraw_Rollback_PIPs) |
| 35 | MOPCountry | varchar(100) | YES | Not populated for rollbacks. Hardcoded 'NA'. (Tier 2 — SP_Withdraw_Rollback_PIPs) |
| 36 | IsGermanBaFin | int | YES | Not populated for rollbacks. Hardcoded NULL. (Tier 2 — SP_Withdraw_Rollback_PIPs) |
| 37 | Entity | varchar(100) | YES | Resolved MID entity/merchant name. Complex depot-specific cascade: credit card depots use BackOffice merchant BODescription, wire uses BPMS Description, others fall back through WTF MerchantAccount, BPMS MerchantAccount, DR2 regulation name. (Tier 2 — SP_Withdraw_Rollback_PIPs) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| DateID | SP parameter | @StartDateInt | ETL-computed |
| CID | Billing.CashoutRollbackTracking | CID | Passthrough |
| DepositWithdrawID | Billing.CashoutRollbackTracking | WithdrawID | Rename |
| Occurred | Billing.CashoutRollbackTracking | ModificationDate | Rename |
| CreditTypeID | — | — | Hardcoded 33 |
| TransactionID | Billing.WithdrawToFunding | ID (WithdrawPaymentID) | CAST + 'W' suffix |
| Date | Billing.CashoutRollbackTracking | ModificationDate | CAST AS DATE |
| Customer | Customer.CustomerStatic | ExternalID | Passthrough via Dim_Customer |
| TransactionType | Billing.CashoutRollbackTracking / Dim_CashoutStatus | CashoutStatusID | CASE mapping |
| PaymentMethod | Dictionary.FundingType | Name | COALESCE(funding, withdraw) |
| Amount | Billing.CashoutRollbackTracking | RollbackAmountInCurrency | Passthrough |
| Currency | Dictionary.Currency | Abbreviation | Dim-lookup via ProcessCurrencyID |
| ExchangeRate | Billing.CashoutRollbackTracking | ExchangeRate | Passthrough |
| AmountUSD | Billing.CashoutRollbackTracking | RollbackAmountInUSD | Passthrough |
| RegulationID | Fact_SnapshotCustomer | RegulationID | Point-in-time snapshot |
| LabelID | Customer.CustomerStatic | LabelID | Passthrough via Dim_Customer |
| PlayerLevelID | Customer.CustomerStatic | PlayerLevelID | Passthrough via Dim_Customer |
| Regulation | Dictionary.Regulation | Name | Dim-lookup |
| Label | Dictionary.Label | Name | Dim-lookup |
| IsValidCustomer | Dim_Customer | IsValidCustomer | ETL-computed passthrough |
| UpdateDate | — | — | GETDATE() |
| BaseExchangeRate | Billing.WithdrawToFunding | BaseExchangeRate | Conditional inversion for reciprocal forex |
| ExchangeFee | Billing.WithdrawToFunding | ExchangeFee | Passthrough |
| ExternalTransactionID | Billing.CashoutRollbackTracking | ReferenceNumber | Rename |
| Depot | Billing.Depot | Name | Dim-lookup |
| MIDValue | Multi-source (MerchantAccount, BPMS, MapMerchantCodeToMid) | — | Complex depot-specific cascade |
| Club | Dictionary.PlayerLevel | Name | Dim-lookup |
| PlayerStatus | Dictionary.PlayerStatus | Name | Dim-lookup |
| PIPsCalculation | Fact_BillingWithdraw + BI_DB_DepositWithdrawFee | BaseExchangeRate, PIPsCalculation | Ratio-based recalculation |
| RegCountry | Dictionary.Country | Name | Dim-lookup via Dim_Customer.CountryID |
| RegCountryByIP | Dictionary.Country | Name | Dim-lookup via Dim_Customer.CountryIDByIP |
| CardType | Dictionary.CardType | Name (CarTypeName) | Dim-lookup via BIN code chain |
| CardCategory | — | — | Hardcoded 'NA' |
| BinCountry | — | — | Hardcoded 'NA' |
| MOPCountry | — | — | Hardcoded 'NA' |
| IsGermanBaFin | — | — | Hardcoded NULL |
| Entity | Multi-source (MerchantAccount, BPMS, Regulation) | — | Complex depot-specific cascade |

### 5.2 ETL Pipeline

```
etoro.Billing.CashoutRollbackTracking (production)
  |-- External table (BI_DB_dbo) --|
  v
External_etoro_Billing_CashoutRollbackTracking
  + DWH_dbo.Fact_CustomerAction (ActionTypeID=42, daily filter)
  + DWH_dbo.Fact_BillingWithdraw (payment execution details)
  + External_etoro_billing_vWithdrawToFunding_Alltime (WTF details)
  + External_Etoro_History_vWithdrawToFundingAction (CashoutStatusID)
  + DWH_dbo.Fact_SnapshotCustomer + Dim_Range (customer snapshot)
  + External_eToro_Dictionary_MerchantAccount (MID resolution)
  + External_eToro_Billing_MerchantAccountRouting (depot routing)
  + External_eToro_Dictionary_MapMerchantCodeToMid (MID mapping)
  + DWH_dbo.Dim_BillingProtocolMIDSettingsID (BPMS Values)
  + DWH_dbo.Fact_BillingDeposit (refund deposit DepotID)
  + BI_DB_dbo.BI_DB_DepositWithdrawFee (original PIPs)
  + DWH_dbo.Dim_Customer, Dim_Label, Dim_Country, Dim_Regulation,
    Dim_Currency, Dim_BillingDepot, Dim_FundingType, Dim_CountryBin,
    Dim_CardType, Dim_PlayerLevel, Dim_PlayerStatus, Dim_Instrument
  |
  |-- SP_Withdraw_Rollback_PIPs @Date (DELETE DateID + INSERT) --|
  v
BI_DB_dbo.BI_DB_Withdraw_Rollback_PIPs (149 rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Event detection | Fact_CustomerAction WHERE ActionTypeID=42 AND DateID=@StartDateInt | Identifies cashout rollback credit events for the day |
| Rollback details | External_etoro_Billing_CashoutRollbackTracking WHERE ModificationDate=@StartDate AND CashoutStatusID IN (3,16,17) | Gets rollback amounts, dates, reasons |
| Payment details | Fact_BillingWithdraw JOIN on WithdrawID + WithdrawPaymentID | Gets payment execution amounts, exchange rates, depot |
| MID resolution | Multi-step: MerchantAccountRouting → MerchantAccount → BPMS → MapMerchantCodeToMid | Depot-specific cascade for MID and Entity |
| PIPs computation | Fact_BillingWithdraw amounts + BI_DB_DepositWithdrawFee.PIPsCalculation | Ratio-based rollback PIPs |
| Customer enrichment | Dim_Customer (ExternalID, CountryID, LabelID, PlayerLevelID) + Fact_SnapshotCustomer (RegulationID, PlayerStatusID) | Customer attributes at event time |
| Dimension lookups | Dim_Regulation, Dim_Label, Dim_Country, Dim_PlayerLevel, Dim_PlayerStatus, Dim_Currency, Dim_BillingDepot, Dim_FundingType, Dim_CountryBin, Dim_CardType | Name/label resolution |
| Load | DELETE WHERE DateID=@StartDateInt → INSERT | Daily idempotent reload |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer master |
| RegulationID | DWH_dbo.Dim_Regulation (ID) | Regulatory jurisdiction |
| LabelID | DWH_dbo.Dim_Label (LabelID) | Brand/label |
| PlayerLevelID | DWH_dbo.Dim_PlayerLevel (PlayerLevelID) | Club tier |
| DateID | DWH_dbo.Dim_Date (DateID) | Calendar |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Finance reporting | — | Used for cashout rollback PIPs reconciliation and payment analytics |

---

## 7. Sample Queries

### 7.1 Daily rollback summary by type
```sql
SELECT DateID,
       TransactionType,
       COUNT(*) AS RollbackCount,
       SUM(AmountUSD) AS TotalUSD,
       SUM(PIPsCalculation) AS TotalPIPs
FROM [BI_DB_dbo].[BI_DB_Withdraw_Rollback_PIPs]
GROUP BY DateID, TransactionType
ORDER BY DateID DESC;
```

### 7.2 Rollback PIPs by regulation and payment method
```sql
SELECT Regulation,
       PaymentMethod,
       COUNT(*) AS EventCount,
       SUM(PIPsCalculation) AS TotalPIPs,
       SUM(AmountUSD) AS TotalAmountUSD
FROM [BI_DB_dbo].[BI_DB_Withdraw_Rollback_PIPs]
WHERE TransactionType = 'CashoutRollback'
GROUP BY Regulation, PaymentMethod
ORDER BY TotalPIPs DESC;
```

### 7.3 Rollback details for a specific customer
```sql
SELECT DateID, TransactionType, Amount, Currency, AmountUSD,
       PIPsCalculation, Depot, Entity, MIDValue,
       RegCountry, Regulation, PlayerStatus
FROM [BI_DB_dbo].[BI_DB_Withdraw_Rollback_PIPs]
WHERE CID = @cid
ORDER BY DateID DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode — skipped Phase 10).

---

*Generated: 2026-04-30 | Quality: 8.0/10 | Phases: 11/14*
*Tiers: 12 T1, 16 T2, 7 T3, 0 T4, 0 T5 | Elements: 37/37, Logic: 9/10, Relationships: 6/10, Sources: 7/10*
*Object: BI_DB_dbo.BI_DB_Withdraw_Rollback_PIPs | Type: Table | Production Source: Billing.CashoutRollbackTracking via SP_Withdraw_Rollback_PIPs*
