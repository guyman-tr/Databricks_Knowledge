# BI_DB_dbo.BI_DB_Deposit_Reversals_PIPs

> 8,817-row deposit reversal PIPs table tracking chargebacks, refunds, reversed deposits, and their cancellations for 3,561 customers from 2023-03-01 to 2025-09-10. Populated daily by SP_Deposit_Reversals_PIPs via DELETE+INSERT, sourcing from Fact_BillingDeposit, Fact_CustomerAction (status history), Fact_SnapshotCustomer, and external rollback/credit tables. Computes reversal-specific PIPs by applying rollback amount ratios to base deposit PIPs from BI_DB_DepositWithdrawFee.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | SP_Deposit_Reversals_PIPs (Author: Guy Manova, 2024-02-16) — temporary solution replicating BO PIPs logic in Synapse |
| **Refresh** | Daily (DELETE by DateID + INSERT) |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (Date ASC, CID ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_Deposit_Reversals_PIPs captures deposit reversal events — chargebacks, refunds, reversed deposits, chargeback reversals, and their cancelled variants — with associated PIPs (payment processing cost) calculations. It is a temporary DWH-side replication of the production BackOffice.GetRiskExposureReportPCIVersion logic, created because the BO report was not available in Synapse. The SP reconstructs deposit status history from Fact_CustomerAction (ActionTypeID 7,11,12,13,43), determines the transaction type via a complex current/previous status matrix, and computes PIPs by scaling base deposit PIPs (from BI_DB_DepositWithdrawFee) by the rollback amount ratio. 8,817 rows across 3,561 distinct CIDs, date range 2023-03-01 to 2025-09-10.

---

## 2. Business Logic

### 2.1 Transaction Type Matrix

**What**: Maps (current deposit status, previous deposit status) pairs to reversal transaction type names.
**Columns Involved**: `TransactionType`, derived from Fact_CustomerAction status history
**Rules**:
- Chargeback → Refund = "Refund"
- Approved → Chargeback = "Chargeback"
- Chargeback → ChargebackReversal = "ChargebackReversal"
- Approved → ReversedDeposit = "ReversedDeposit"
- Cancelled variants prefix "Cancelled" (e.g., Refund → Approved = "CancelledRefund")
- Unknown combinations → "NA"

### 2.2 PIPs Ratio Calculation

**What**: Computes reversal PIPs by scaling base deposit PIPs proportionally to the rollback amount.
**Columns Involved**: `PIPsCalculation`, from BI_DB_DepositWithdrawFee
**Rules**:
- `PIPsCalculation = ROUND(DW_fee.PIPsCalculation, 2) * ROUND(RollbackAmountInCurrency / Amount, 32)`
- Base PIPs come from BI_DB_DepositWithdrawFee matched on DepositID
- Ratio handles partial reversals (rollback amount < full deposit amount)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CID) distribution with CLUSTERED INDEX on (Date ASC, CID ASC). Filter on Date and CID for efficient queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Reversal PIPs for a date range | `WHERE Date BETWEEN @start AND @end` |
| Customer reversal history | `WHERE CID = @cid ORDER BY Date` |
| Total PIPs by transaction type | `GROUP BY TransactionType` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Customer demographics |
| BI_DB_dbo.BI_DB_DepositWithdrawFee | ON DepositWithdrawID = DepositWithdrawID | Base deposit PIPs |
| DWH_dbo.Fact_BillingDeposit | ON DepositWithdrawID = DepositID | Full deposit details |

### 3.4 Gotchas

- **Label column maps to Dim_PlayerLevel.Name**, not Dim_Label.Name — SP quirk.
- **MOPCountry is hardcoded 'NA'**, IsGermanBaFin is hardcoded NULL — not populated.
- **TransactionType "NA"** (108 rows) indicates unmatched status combinations in the CASE matrix.
- **Currency column uses Dim_Currency.Abbreviation** which is the ticker symbol (e.g., "AAPL.US" for stocks), not ISO currency codes — context is deposit currency only.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★☆ | Tier 1 | `(Tier 1 — upstream wiki, source)` |
| ★★★☆☆ | Tier 2 | `(Tier 2 — SP_Deposit_Reversals_PIPs)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Business date as YYYYMMDD integer, derived from @date parameter via CAST(CONVERT(VARCHAR(8), @date, 112) AS INT). (Tier 2 — SP_Deposit_Reversals_PIPs) |
| 2 | CID | int | YES | Customer ID (RealCID). Hash distribution key. References Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 3 | DepositWithdrawID | int | YES | Source deposit ID from Fact_BillingDeposit.DepositID, renamed for schema compatibility with BI_DB_DepositWithdrawFee. (Tier 2 — SP_Deposit_Reversals_PIPs) |
| 4 | Occurred | datetime | YES | Reversal event timestamp. CASE: rollback CreateDate when available, else credit.Occurred from External_etoro_history_credit_yesterday. (Tier 2 — SP_Deposit_Reversals_PIPs) |
| 5 | CreditTypeID | tinyint | YES | Credit type from External_etoro_history_credit_yesterday. Reversal types: 11=Chargeback, 12=Refund, 16=ChargebackReversal, 32=ReverseDeposit. (Tier 2 — SP_Deposit_Reversals_PIPs) |
| 6 | TransactionID | varchar(200) | YES | Synthetic identifier: CAST(DepositID AS VARCHAR(20)) + 'D'. (Tier 2 — SP_Deposit_Reversals_PIPs) |
| 7 | Date | date | YES | Calendar date from @date parameter. (Tier 2 — SP_Deposit_Reversals_PIPs) |
| 8 | Customer | varchar(200) | YES | APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. (Tier 1 — Customer.CustomerStatic) |
| 9 | TransactionType | varchar(200) | YES | Reversal category derived from (current, previous) deposit status matrix. 10 values: Refund (60%), Chargeback (30%), ChargebackReversal, CancelledRefund, NA, CancelledChargeback, ReversedDeposit, CancelledReversedDeposit, CancelledChargebackReversal, RefundReversal. (Tier 2 — SP_Deposit_Reversals_PIPs) |
| 10 | PaymentMethod | varchar(200) | YES | Payment method name resolved via FundingID → External_eToro_Billing_FundingPaymentDetailsForWithdraw → Dim_FundingType.Name. (Tier 2 — SP_Deposit_Reversals_PIPs) |
| 11 | Amount | numeric(38,8) | YES | Rollback amount in original currency from External_etoro_Billing_DepositRollbackTracking.RollbackAmountInCurrency. (Tier 2 — SP_Deposit_Reversals_PIPs) |
| 12 | Currency | varchar(200) | YES | Ticker symbol / ISO currency abbreviation. Resolved via Dim_Currency.Abbreviation on CurrencyID. (Tier 1 — Dictionary.Currency) |
| 13 | ExchangeRate | numeric(38,8) | YES | Exchange rate from rollback tracking or Fact_BillingDeposit. Cannot be 0 in production. (Tier 1 — Billing.Deposit) |
| 14 | AmountUSD | numeric(38,8) | YES | USD amount: COALESCE(RollbackAmountInUSD, ReturnedAmount) from rollback tracking / credit history. (Tier 2 — SP_Deposit_Reversals_PIPs) |
| 15 | RegulationID | int | YES | Customer's regulatory jurisdiction from Fact_SnapshotCustomer at event date. 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, etc. FK to Dim_Regulation. (Tier 1 — Dictionary.Regulation) |
| 16 | LabelID | int | YES | Brand/label from Fact_SnapshotCustomer. FK to Dim_Label. Labels 26 and 30 excluded from valid customer segment. (Tier 2 — SP_Deposit_Reversals_PIPs) |
| 17 | PlayerLevelID | int | YES | eToro Club loyalty tier from Fact_SnapshotCustomer. 1=Bronze, 2=Platinum, 3=Gold, 5=Silver, 6=Platinum Plus, 7=Diamond, 4=Internal (excluded). FK to Dim_PlayerLevel. (Tier 1 — Dictionary.PlayerLevel) |
| 18 | Regulation | varchar(200) | YES | Regulation short code resolved via Dim_Regulation.Name. (Tier 1 — Dictionary.Regulation) |
| 19 | Label | varchar(200) | YES | **NOTE: maps to Dim_PlayerLevel.Name, NOT Dim_Label.Name** — SP quirk. Shows club tier name (Bronze, Silver, Gold, etc.). (Tier 2 — SP_Deposit_Reversals_PIPs) |
| 20 | IsValidCustomer | int | YES | 1 if customer is a valid retail customer for analytics (excludes demo, blocked countries, excluded labels). From Fact_SnapshotCustomer. (Tier 2 — SP_Fact_SnapshotCustomer) |
| 21 | UpdateDate | datetime | YES | ETL load timestamp set to GETDATE() at SP execution. (Tier 2 — SP_Deposit_Reversals_PIPs) |
| 22 | BaseExchangeRate | numeric(38,8) | YES | Reference exchange rate before fee markup. Fee spread = ExchangeRate - BaseExchangeRate. (Tier 1 — Billing.Deposit) |
| 23 | ExchangeFee | numeric(38,8) | YES | Exchange fee from rollback tracking (named ConversionFee in the SP). (Tier 2 — SP_Deposit_Reversals_PIPs) |
| 24 | ExternalTransactionID | varchar(200) | YES | COALESCE(ReferenceNumber from rollback tracking, RefundVerificationCode from Fact_BillingDeposit). Provider-side reconciliation identifier. (Tier 2 — SP_Deposit_Reversals_PIPs) |
| 25 | Depot | varchar(200) | YES | Acquirer/gateway name resolved via Dim_BillingDepot.Name on DepotID. (Tier 2 — SP_Deposit_Reversals_PIPs) |
| 26 | MIDValue | varchar(200) | YES | Merchant ID value. Complex CASE: FundingTypeID=2 → BPMSValue; DepotID IN (78,79,80,4,75,86) → merchant account Name; ELSE COALESCE chain from Dim_BillingProtocolMIDSettingsID and merchant routing. (Tier 2 — SP_Deposit_Reversals_PIPs) |
| 27 | Club | varchar(200) | YES | eToro Club tier name. Resolved via Dim_PlayerLevel.Name on PlayerLevelID. 1=Bronze, 2=Platinum, 3=Gold, 5=Silver, 6=Platinum Plus, 7=Diamond. (Tier 1 — Dictionary.PlayerLevel) |
| 28 | PlayerStatus | varchar(200) | YES | Account restriction state name. Resolved via Dim_PlayerStatus.Name on PlayerStatusID from Fact_SnapshotCustomer. (Tier 1 — Dictionary.PlayerStatus) |
| 29 | PIPsCalculation | numeric(38,8) | YES | Reversal PIPs in USD: ROUND(base_deposit_PIPs, 2) × ROUND(RollbackAmountInCurrency / Amount, 32). Base PIPs from BI_DB_DepositWithdrawFee matched on DepositID. (Tier 2 — SP_Deposit_Reversals_PIPs) |
| 30 | RegCountry | varchar(200) | YES | Registration country name resolved via Dim_Country.Name on Fact_SnapshotCustomer.CountryID. (Tier 1 — Dictionary.Country) |
| 31 | RegCountryByIP | varchar(200) | YES | Country detected from customer IP at registration. Resolved via Dim_Country.Name on Dim_Customer.CountryIDByIP. (Tier 1 — Dictionary.Country) |
| 32 | CardType | varchar(50) | YES | Card network brand name. Resolved via Dim_CardType.CarTypeName on Fact_BillingDeposit.CardTypeIDAsInteger. Active: 1=Visa, 2=Master Card, 3=Diners, 8=Maestro. (Tier 1 — Dictionary.CardType) |
| 33 | CardCategory | varchar(200) | YES | Card category label from Fact_BillingDeposit.CardCategory. (Tier 2 — SP_Deposit_Reversals_PIPs) |
| 34 | BinCountry | varchar(200) | YES | Country of the card BIN resolved via Dim_Country.Name on Fact_BillingDeposit.BinCountryIDAsInteger. (Tier 1 — Dictionary.Country) |
| 35 | MOPCountry | varchar(200) | YES | Hardcoded literal 'NA' — not populated in the current SP. (Tier 2 — SP_Deposit_Reversals_PIPs) |
| 36 | IsGermanBaFin | int | YES | Hardcoded NULL — not populated in the current SP. (Tier 2 — SP_Deposit_Reversals_PIPs) |
| 37 | Entity | varchar(200) | YES | Merchant entity description. Complex CASE: FundingTypeID=2 → BPMSDescription; DepotID IN (78,79,80,4,75,86) → merchant BODescription; ELSE COALESCE chain. (Tier 2 — SP_Deposit_Reversals_PIPs) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| CID | Fact_BillingDeposit / Fact_SnapshotCustomer | CID / RealCID | Passthrough |
| DepositWithdrawID | Fact_BillingDeposit | DepositID | Rename |
| TransactionType | ETL-computed | DepositStatus + PreviousStatus | CASE matrix (22+ branches) |
| Amount | External_etoro_Billing_DepositRollbackTracking | RollbackAmountInCurrency | Passthrough |
| AmountUSD | Rollback tracking / credit history | RollbackAmountInUSD / ReturnedAmount | COALESCE |
| PIPsCalculation | BI_DB_DepositWithdrawFee + ETL | PIPsCalculation × ratio | Base × ROUND(RollbackAmt/Amt, 32) |
| Regulation | Dim_Regulation | Name | Dim-lookup passthrough |
| RegCountry / RegCountryByIP / BinCountry | Dim_Country | Name | Dim-lookup passthrough |
| Club | Dim_PlayerLevel | Name | Dim-lookup passthrough |
| PlayerStatus | Dim_PlayerStatus | Name | Dim-lookup passthrough |
| CardType | Dim_CardType | CarTypeName | Dim-lookup passthrough |
| Currency | Dim_Currency | Abbreviation | Dim-lookup passthrough |
| MIDValue / Entity | Complex CASE chain | Multiple sources | FundingType + Depot routing |

### 5.2 ETL Pipeline

```
Fact_BillingDeposit (deposit metadata)
  + Fact_CustomerAction (status history: ActionTypeID 7,11,12,13,43)
  + Fact_SnapshotCustomer (customer attributes at event date)
  + External_etoro_history_credit_yesterday (reversal credits)
  + External_etoro_Billing_DepositRollbackTracking (rollback amounts)
  + BI_DB_DepositWithdrawFee (base PIPs)
  |
  v [SP_Deposit_Reversals_PIPs @date]
    1. Build status history from Fact_CustomerAction
    2. Reconstruct previous deposit status per deposit
    3. Map (current, previous) → TransactionType
    4. Join rollback tracking for amounts
    5. Compute PIPs ratio from base deposit PIPs
    6. DELETE by DateID + INSERT
  |
  v
BI_DB_dbo.BI_DB_Deposit_Reversals_PIPs (8,817 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer identity |
| RegulationID | DWH_dbo.Dim_Regulation | Regulatory jurisdiction |
| LabelID | DWH_dbo.Dim_Label | White-label brand |
| PlayerLevelID | DWH_dbo.Dim_PlayerLevel | Club tier |
| DepositWithdrawID | DWH_dbo.Fact_BillingDeposit | Source deposit |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Finance reporting | N/A | Deposit reversal PIPs analysis |

---

## 7. Sample Queries

### 7.1 Total reversal PIPs by transaction type for a date range

```sql
SELECT
    TransactionType,
    COUNT(*) AS ReversalCount,
    SUM(PIPsCalculation) AS TotalPIPs,
    SUM(AmountUSD) AS TotalUSD
FROM [BI_DB_dbo].[BI_DB_Deposit_Reversals_PIPs]
WHERE Date >= '2025-01-01' AND Date < '2025-10-01'
GROUP BY TransactionType
ORDER BY TotalPIPs DESC;
```

### 7.2 Customer reversal history with payment details

```sql
SELECT
    drp.Date,
    drp.Customer,
    drp.TransactionType,
    drp.Amount,
    drp.Currency,
    drp.AmountUSD,
    drp.PIPsCalculation,
    drp.PaymentMethod,
    drp.CardType,
    drp.Regulation
FROM [BI_DB_dbo].[BI_DB_Deposit_Reversals_PIPs] drp
WHERE drp.CID = @cid
ORDER BY drp.Date DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-29 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 12 T1, 25 T2, 0 T3, 0 T4, 0 T5 | Elements: 37/37, Logic: 8/10, Relationships: 7/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_Deposit_Reversals_PIPs | Type: Table | Production Source: SP_Deposit_Reversals_PIPs (Guy Manova, 2024-02-16)*
