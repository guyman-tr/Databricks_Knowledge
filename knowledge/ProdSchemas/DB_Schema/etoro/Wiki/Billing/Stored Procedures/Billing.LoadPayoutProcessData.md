# Billing.LoadPayoutProcessData

> Fetches the complete payout execution data set for a single withdrawal-to-funding record, joining five tables to return all fields needed by the payout service to process a cashout payment.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WTF_ID INT - the WithdrawToFunding.ID to look up |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.LoadPayoutProcessData retrieves all information needed to process a single cashout (withdrawal) payment for a specific WithdrawToFunding record. It joins five tables - Billing.WithdrawToFunding, Billing.Withdraw, Customer.Customer, Billing.Funding, and Billing.PayoutProcess - and returns a merged result set containing the withdrawal details, customer GCID, funding instrument info, and the payout process tracking fields.

This procedure is called by the legacy payout service (generation 0) when it picks up a payment to process. It supplies the payout service with everything it needs in a single call: the amount, currency, exchange rate, routing information, the customer's global ID (GCID), the funding instrument type and data, and the current payout process state (InProcess flag, provider reference codes, correlation IDs).

**Version note**: This is v1 of the procedure. Billing.LoadPayoutProcessData_v2 is the current replacement, introduced to remove the Customer.Customer dependency (PAYIL-3960, 2022-05-02) and to change the PayoutProcess JOIN from INNER to LEFT (PAYIL-6210, 2023-03-26) so that WTF records without a PayoutProcess row are still returned. The v1 column `GCID` was dropped in v2.

**Change history**:
- 2020-08-20 (PAYIL-1371): Removed ExecutingManagerID from SELECT - column removed from source table.
- 2024-02-24 (PAYIL-3782): Added MerchantAccountID to SELECT.

---

## 2. Business Logic

### 2.1 Single WTF Record Lookup

**What**: Fetches complete payout data for one WithdrawToFunding record via its primary key.

**Columns/Parameters Involved**: `@WTF_ID`, `WTF.ID`, `WTF.CashoutStatusID`, `BPP.InProcess`

**Rules**:
- Filters WHERE WTF.ID = @WTF_ID - returns exactly one row (or zero if ID not found).
- INNER JOIN on Billing.PayoutProcess means the WTF must have a PayoutProcess row; without one, zero rows are returned. This is a known limitation fixed in v2 (changed to LEFT JOIN).
- INNER JOIN on Customer.Customer means the procedure fails if CID is not in Customer.Customer - this dependency was removed in v2 (PAYIL-3960).
- The combined result gives the payout service worker all fields needed to submit the payment to the external provider.

### 2.2 Multi-Table Join Structure

**What**: The five-table join provides a complete view of the payout context.

**Columns/Parameters Involved**: `WTF.*`, `BW.CID`, `BW.IPAddress`, `CC.GCID`, `BF.FundingTypeID`, `BF.FundingData`, `BPP.*`

**Rules**:
- WTF (WithdrawToFunding): primary entity - payment execution leg (amount, status, currency, routing)
- BW (Withdraw): parent withdrawal request - provides CID and IPAddress
- CC (Customer.Customer): provides GCID (global customer ID) - removed in v2
- BF (Funding): customer's payment instrument - provides FundingTypeID and FundingData (card/bank details)
- BPP (PayoutProcess): payout tracking record - provides provider reference codes, correlation IDs, InProcess flag

**Diagram**:
```
@WTF_ID
    |
    v
Billing.WithdrawToFunding (WTF)
    |--- INNER JOIN Billing.Withdraw (BW) ON WTF.WithdrawID = BW.WithdrawID
    |         |--- INNER JOIN Customer.Customer (CC) ON BW.CID = CC.CID [v1 only]
    |--- INNER JOIN Billing.Funding (BF) ON WTF.FundingID = BF.FundingID
    |--- INNER JOIN Billing.PayoutProcess (BPP) ON WTF.ID = BPP.WithdrawToFundingID
    |
    v
Combined payout record (49 fields) -> Payout Service
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WTF_ID | int | NO | - | CODE-BACKED | The WithdrawToFunding.ID (primary key) of the payment leg to retrieve. The payout service worker passes this ID after claiming a PayoutProcess record from the processing queue. |

**Output columns (from joined tables):**

| # | Element | Source | Confidence | Description |
|---|---------|--------|------------|-------------|
| 1 | WithdrawID | WTF.WithdrawID | CODE-BACKED | Parent withdrawal request ID (FK to Billing.Withdraw). Links this payment leg to the original customer withdrawal request. |
| 2 | CID | BW.CID | CODE-BACKED | Customer ID who made the withdrawal request. From Billing.Withdraw via INNER JOIN. |
| 3 | IPAddress | BW.IPAddress | CODE-BACKED | Customer's IP address at withdrawal submission time. From Billing.Withdraw. |
| 4 | GCID | CC.GCID | CODE-BACKED | Customer's global ID from Customer.Customer. Used to identify the customer in cross-system contexts. Removed in v2 (PAYIL-3960). |
| 5 | FundingID | WTF.FundingID | CODE-BACKED | Payment instrument ID (FK to Billing.Funding). Identifies the credit card, bank account, or wallet to receive the funds. |
| 6 | FundingTypeID | BF.FundingTypeID | CODE-BACKED | Type of payment instrument (FK to Dictionary.FundingType): credit card, wire transfer, PayPal, etc. |
| 7 | FundingData | BF.FundingData | CODE-BACKED | Encrypted payment instrument details (card number, bank account info) from Billing.Funding. |
| 8 | CashoutStatusID | WTF.CashoutStatusID | CODE-BACKED | Current payout execution status of this WTF record. Values: 1=Pending, 3=Processed, 4=Canceled, 12=ReceivedByBilling, etc. |
| 9 | ProcessCurrencyID | WTF.ProcessCurrencyID | CODE-BACKED | Currency in which the payout is being processed (FK to Dictionary.Currency). |
| 10 | ManagerID | WTF.ManagerID | CODE-BACKED | Back-office manager ID who approved/initiated this payout leg. -1 = automatic/system-initiated. |
| 11 | ExchangeRate | WTF.ExchangeRate | CODE-BACKED | Exchange rate applied to convert the withdrawal amount to the processing currency. |
| 12 | Amount | WTF.Amount | CODE-BACKED | Payout amount in the processing currency. |
| 13 | ModificationDate | WTF.ModificationDate | CODE-BACKED | Last modification timestamp of the WithdrawToFunding record. |
| 14 | WithdrawData | WTF.WithdrawData | CODE-BACKED | XML blob containing provider-specific execution response data (auth codes, rejection reasons). |
| 15 | WithdrawToFundingID | WTF.ID AS WithdrawToFundingID | CODE-BACKED | The WithdrawToFunding primary key, aliased for clarity in the result set. Same value as @WTF_ID input. |
| 16 | DepositID | WTF.DepositID | CODE-BACKED | For refund-type payouts (CashoutTypeID=2): the original deposit being refunded. NULL for direct cashouts. |
| 17 | RefundAmountInDepositCurrency | WTF.RefundAmountInDepositCurrency | CODE-BACKED | For refunds: the refund amount expressed in the original deposit's currency. |
| 18 | CashoutTypeID | WTF.CashoutTypeID | CODE-BACKED | Distinguishes payout type: 1=Cashout (direct withdrawal), 2=Refund (deposit reversal). |
| 19 | VerificationCode | WTF.VerificationCode | CODE-BACKED | Verification/OTP code associated with this withdrawal, if applicable. |
| 20 | ProcessorValueDate | WTF.ProcessorValueDate | CODE-BACKED | Value date provided by the payment processor for this payout. |
| 21 | MatchStatusID | WTF.MatchStatusID | CODE-BACKED | Reconciliation match status between eToro records and bank statement. |
| 22 | DepotID | WTF.DepotID | CODE-BACKED | Payment depot/gateway configuration ID (FK to Billing.Depot) through which this payout is routed. |
| 23 | AutoPaymentStartDate | WTF.AutoPaymentStartDate | CODE-BACKED | Date when automatic payment processing started for this record. |
| 24 | ProtocolMIDSettingsID | WTF.ProtocolMIDSettingsID | CODE-BACKED | MID (Merchant ID) settings ID used for routing this payout to the correct merchant account. |
| 25 | BaseExchangeRate | WTF.BaseExchangeRate | CODE-BACKED | Base exchange rate before any fee adjustment. |
| 26 | ExchangeFee | WTF.ExchangeFee | CODE-BACKED | Fee component of the exchange rate. |
| 27 | CashoutModeID | WTF.CashoutModeID | CODE-BACKED | Cashout processing mode (FK to Dictionary.CashoutMode): manual, automatic, batch, etc. |
| 28 | AdditionalInformation | WTF.AdditionalInformation | CODE-BACKED | Free-text or XML field for additional provider-specific payout data. |
| 29 | MerchantAccountID | WTF.MerchantAccountID | CODE-BACKED | Merchant account ID used for processing (added PAYIL-3782, 2022-02-24). |
| 30 | ProcessID | BPP.ProcessID | CODE-BACKED | PayoutProcess primary key. The payout service worker's tracking ID for this execution. |
| 31 | PayoutProcessReasonID | BPP.PayoutProcessReasonID | CODE-BACKED | Reason code associated with this payout process record. |
| 32 | ExtReferenceCode | BPP.ExtReferenceCode | CODE-BACKED | External reference code returned by the payment provider upon submission. |
| 33 | ExtReferenceCode2 | BPP.ExtReferenceCode2 | CODE-BACKED | Secondary external reference code from the provider. |
| 34 | ProviderReasonCode | BPP.ProviderReasonCode | CODE-BACKED | Provider-specific reason code for payout outcome (success or failure). |
| 35 | CorrelationID | BPP.CorrelationID | CODE-BACKED | Worker-assigned UUID tracking the payment provider submission session. |
| 36 | InProcess | BPP.InProcess | CODE-BACKED | 1 = a payout worker has claimed and is actively processing this record; 0 = available for processing. |
| 37 | InProcessDate | BPP.InProcessDate | CODE-BACKED | Timestamp when the worker claimed this record (InProcess set to 1). |
| 38 | BoCorrelationID | BPP.BoCorrelationID | CODE-BACKED | Back-office correlation UUID from the manager session that approved this payout. |
| 39 | ProviderResponseID | BPP.ProviderResponseID | CODE-BACKED | Provider's response record ID, linking back to Dictionary.Response for response code interpretation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WTF_ID | Billing.WithdrawToFunding | INNER JOIN (PK) | Primary filtered table - returns data for this specific payment leg. |
| WTF.WithdrawID | Billing.Withdraw | INNER JOIN | Retrieves withdrawal request details (CID, IPAddress). |
| BW.CID | Customer.Customer | INNER JOIN | Retrieves customer GCID. This dependency was removed in v2. |
| WTF.FundingID | Billing.Funding | INNER JOIN | Retrieves payment instrument type and encrypted data. |
| WTF.ID | Billing.PayoutProcess | INNER JOIN | Retrieves payout process state (InProcess, reference codes). Changed to LEFT JOIN in v2. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payout Service (v1/legacy) | @WTF_ID | EXEC | Legacy payout service calls this to load all data needed to submit a payment to the external provider. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadPayoutProcessData (procedure)
├── Billing.WithdrawToFunding (table)
├── Billing.Withdraw (table)
├── Customer.Customer (table)
├── Billing.Funding (table)
└── Billing.PayoutProcess (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Primary table - filtered by @WTF_ID, provides payment execution details. |
| Billing.Withdraw | Table | INNER JOIN on WithdrawID - provides CID and IPAddress. |
| Customer.Customer | Table | INNER JOIN on CID - provides GCID. (Removed in v2.) |
| Billing.Funding | Table | INNER JOIN on FundingID - provides payment instrument FundingTypeID and FundingData. |
| Billing.PayoutProcess | Table | INNER JOIN on WTF.ID - provides payout tracking state. (Changed to LEFT JOIN in v2.) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payout Service (legacy/v1) | Application | EXEC - called when processing a payout payment. Superseded by v2 for new payout service. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute for a specific WithdrawToFunding ID
```sql
EXEC Billing.LoadPayoutProcessData @WTF_ID = 12345;
```

### 8.2 Check what payout data would be returned for a pending WTF
```sql
SELECT WTF.ID AS WithdrawToFundingID, WTF.CashoutStatusID, WTF.Amount,
       BPP.InProcess, BPP.CorrelationID
FROM Billing.WithdrawToFunding WTF WITH (NOLOCK)
INNER JOIN Billing.PayoutProcess BPP WITH (NOLOCK)
    ON WTF.ID = BPP.WithdrawToFundingID
WHERE BPP.CashoutStatusID = 12 AND BPP.InProcess = 0;
```

### 8.3 Compare v1 vs v2 output for the same WTF ID
```sql
-- v1 (includes GCID, requires Customer.Customer and PayoutProcess rows)
EXEC Billing.LoadPayoutProcessData @WTF_ID = 12345;
-- v2 (no GCID, includes CreationDate, LEFT JOIN on PayoutProcess)
EXEC Billing.LoadPayoutProcessData_v2 @WTF_ID = 12345;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Payout Service Gen 2.0 - Changes](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1218937110) | Confluence | Referenced changes to payout service that led to LoadPayoutProcessData_v2 (page in MG space - access restricted) |
| [Payout Service Recovery Design](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/2284388374) | Confluence | Payout service architecture context (page in MG space - access restricted) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 39 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 2 Confluence + 0 Jira (access restricted) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadPayoutProcessData | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadPayoutProcessData.sql*
