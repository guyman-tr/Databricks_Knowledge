# Billing.LoadPayoutProcessData_v2

> Improved version of LoadPayoutProcessData that fetches payout execution data for a single withdrawal-to-funding record without Customer.Customer dependency, includes CreationDate, and uses LEFT JOIN on PayoutProcess so records without a payout process row are still returned.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WTF_ID INT - the WithdrawToFunding.ID to look up |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.LoadPayoutProcessData_v2 is the current, actively-used version of the payout data loader, replacing the older Billing.LoadPayoutProcessData. It retrieves all fields needed to process a single cashout payment by joining four tables: Billing.WithdrawToFunding, Billing.Withdraw, Billing.Funding, and Billing.PayoutProcess.

This version was introduced to address three issues with v1:
1. **Removed Customer.Customer dependency** (PAYIL-3960, 2022-05-02): Eliminated the INNER JOIN to Customer.Customer that could fail for edge-case CIDs, simplifying the dependency chain and improving reliability.
2. **Added CreationDate** (PINT-820, 2025-11-14): WTF.CreationDate is now returned, providing the payout service with the timestamp when the withdrawal-to-funding record was created.
3. **LEFT JOIN on PayoutProcess** (PAYIL-6210, 2023-03-26): Changed from INNER to LEFT JOIN so that WTF records without a matching PayoutProcess row still return data (important for records in transitional states where the PayoutProcess row may not exist yet).

The procedure is called by the current payout service when it picks up a payment to process. It provides everything needed - withdrawal details, funding instrument, payout tracking state - in a single database call.

**Change history**:
- 2020-08-20 (PAYIL-1371): Removed ExecutingManagerID from SELECT.
- 2021-12-08 (PAYIL-3464): Added MerchantAccountID to return.
- 2022-05-02 (PAYIL-3960): Removed Customer.Customer dependency (dropped GCID from output).
- 2023-03-26 (PAYIL-6210): Changed PayoutProcess JOIN from INNER to LEFT (FirstApproved WTF returning NULL fix).
- 2025-11-14 (PINT-820): Added WTF.CreationDate to result columns.

---

## 2. Business Logic

### 2.1 Single WTF Record Lookup (Improved Robustness vs v1)

**What**: Fetches complete payout data for one WithdrawToFunding record, now resilient to missing PayoutProcess rows and not dependent on Customer.Customer.

**Columns/Parameters Involved**: `@WTF_ID`, `WTF.CashoutStatusID`, `BPP.InProcess`

**Rules**:
- Filters WHERE WTF.ID = @WTF_ID - returns exactly one row (or zero if WTF.ID not found).
- LEFT JOIN on Billing.PayoutProcess: if no PayoutProcess row exists for this WTF, all BPP columns return NULL. v1 would return zero rows in this case.
- No Customer.Customer JOIN: GCID is not in the output. The payout service no longer needs GCID for payment processing.
- WTF.CreationDate is included (added PINT-820, 2025-11-14): NULL for records created before early 2023 (per WithdrawToFunding table definition).
- Otherwise identical to v1: same WTF, Withdraw, and Funding field selection.

### 2.2 v1 vs v2 Difference Summary

**What**: Key differences between the two procedure versions.

**Columns/Parameters Involved**: `GCID` (dropped), `CreationDate` (added), `PayoutProcess JOIN type`

**Rules**:
- v1 output includes: GCID (from Customer.Customer)
- v2 output includes: WTF.CreationDate (instead of GCID)
- v1 fails if: WTF has no PayoutProcess row OR CID not in Customer.Customer
- v2 handles: Missing PayoutProcess (returns NULLs for BPP columns), no Customer.Customer dependency
- v2 is the production-active version for new payout service (PayoutGeneration=1).

**Diagram**:
```
@WTF_ID
    |
    v
Billing.WithdrawToFunding (WTF)
    |--- INNER JOIN Billing.Withdraw (BW) ON WTF.WithdrawID = BW.WithdrawID
    |--- INNER JOIN Billing.Funding (BF) ON WTF.FundingID = BF.FundingID
    |--- LEFT JOIN Billing.PayoutProcess (BPP) ON WTF.ID = BPP.WithdrawToFundingID
    |         [NULL if no PayoutProcess record yet]
    |
    v
Combined payout record (38 fields, no GCID, includes CreationDate)
-> Current Payout Service (PayoutGeneration=1)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WTF_ID | int | NO | - | CODE-BACKED | The WithdrawToFunding.ID (primary key) of the payment leg to retrieve. The payout service worker passes this after claiming a PayoutProcess record from the processing queue. |

**Output columns (from joined tables):**

| # | Element | Source | Confidence | Description |
|---|---------|--------|------------|-------------|
| 1 | WithdrawID | WTF.WithdrawID | CODE-BACKED | Parent withdrawal request ID (FK to Billing.Withdraw). |
| 2 | CID | BW.CID | CODE-BACKED | Customer ID who made the withdrawal. |
| 3 | IPAddress | BW.IPAddress | CODE-BACKED | Customer IP at withdrawal submission time. |
| 4 | FundingID | WTF.FundingID | CODE-BACKED | Payment instrument identifier (FK to Billing.Funding). |
| 5 | FundingTypeID | BF.FundingTypeID | CODE-BACKED | Payment instrument type (FK to Dictionary.FundingType). |
| 6 | FundingData | BF.FundingData | CODE-BACKED | Encrypted payment instrument details from Billing.Funding. |
| 7 | CashoutStatusID | WTF.CashoutStatusID | CODE-BACKED | Execution status of this WTF payment leg. |
| 8 | ProcessCurrencyID | WTF.ProcessCurrencyID | CODE-BACKED | Processing currency for this payout (FK to Dictionary.Currency). |
| 9 | ManagerID | WTF.ManagerID | CODE-BACKED | Back-office manager ID. -1 = system-initiated. |
| 10 | ExchangeRate | WTF.ExchangeRate | CODE-BACKED | Exchange rate applied to convert to processing currency. |
| 11 | Amount | WTF.Amount | CODE-BACKED | Payout amount in processing currency. |
| 12 | ModificationDate | WTF.ModificationDate | CODE-BACKED | Last update timestamp of the WTF record. |
| 13 | WithdrawData | WTF.WithdrawData | CODE-BACKED | XML blob with provider-specific execution response data. |
| 14 | WithdrawToFundingID | WTF.ID AS WithdrawToFundingID | CODE-BACKED | WTF primary key, aliased. Same as @WTF_ID input. |
| 15 | DepositID | WTF.DepositID | CODE-BACKED | For refunds: ID of original deposit. NULL for direct cashouts. |
| 16 | RefundAmountInDepositCurrency | WTF.RefundAmountInDepositCurrency | CODE-BACKED | For refunds: refund amount in original deposit currency. |
| 17 | CashoutTypeID | WTF.CashoutTypeID | CODE-BACKED | 1=Cashout (direct withdrawal), 2=Refund (deposit reversal). |
| 18 | VerificationCode | WTF.VerificationCode | CODE-BACKED | Verification/OTP code, if applicable. |
| 19 | ProcessorValueDate | WTF.ProcessorValueDate | CODE-BACKED | Value date from the payment processor. |
| 20 | MatchStatusID | WTF.MatchStatusID | CODE-BACKED | Reconciliation match status. |
| 21 | DepotID | WTF.DepotID | CODE-BACKED | Payment depot/gateway routing ID (FK to Billing.Depot). |
| 22 | AutoPaymentStartDate | WTF.AutoPaymentStartDate | CODE-BACKED | Auto-processing start date. |
| 23 | ProtocolMIDSettingsID | WTF.ProtocolMIDSettingsID | CODE-BACKED | MID settings for merchant account routing. |
| 24 | BaseExchangeRate | WTF.BaseExchangeRate | CODE-BACKED | Base rate before fee adjustment. |
| 25 | ExchangeFee | WTF.ExchangeFee | CODE-BACKED | Exchange fee component. |
| 26 | CashoutModeID | WTF.CashoutModeID | CODE-BACKED | Cashout processing mode (FK to Dictionary.CashoutMode). |
| 27 | AdditionalInformation | WTF.AdditionalInformation | CODE-BACKED | Additional provider-specific data. |
| 28 | MerchantAccountID | WTF.MerchantAccountID | CODE-BACKED | Merchant account ID for processing (added PAYIL-3464, 2021-12-08). |
| 29 | CreationDate | WTF.CreationDate | CODE-BACKED | Timestamp when the WTF record was created (added PINT-820, 2025-11-14). NULL for records created before early 2023. |
| 30 | ProcessID | BPP.ProcessID | CODE-BACKED | PayoutProcess primary key. NULL if no PayoutProcess row (LEFT JOIN). |
| 31 | PayoutProcessReasonID | BPP.PayoutProcessReasonID | CODE-BACKED | Reason code for this payout process. NULL if no PayoutProcess row. |
| 32 | ExtReferenceCode | BPP.ExtReferenceCode | CODE-BACKED | External provider reference code. NULL if no PayoutProcess row. |
| 33 | ExtReferenceCode2 | BPP.ExtReferenceCode2 | CODE-BACKED | Secondary provider reference code. NULL if no PayoutProcess row. |
| 34 | ProviderReasonCode | BPP.ProviderReasonCode | CODE-BACKED | Provider-specific reason for outcome. NULL if no PayoutProcess row. |
| 35 | CorrelationID | BPP.CorrelationID | CODE-BACKED | Worker session UUID for this payment submission. NULL if no PayoutProcess row. |
| 36 | InProcess | BPP.InProcess | CODE-BACKED | 1=active worker processing; 0=available. NULL if no PayoutProcess row. |
| 37 | InProcessDate | BPP.InProcessDate | CODE-BACKED | Worker claim timestamp. NULL if no PayoutProcess row. |
| 38 | BoCorrelationID | BPP.BoCorrelationID | CODE-BACKED | Back-office session UUID from the approving manager. NULL if no PayoutProcess row. |
| 39 | ProviderResponseID | BPP.ProviderResponseID | CODE-BACKED | Provider response ID (FK to Dictionary.Response). NULL if no PayoutProcess row. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WTF_ID | Billing.WithdrawToFunding | INNER JOIN (PK) | Primary table - returns payout execution fields. |
| WTF.WithdrawID | Billing.Withdraw | INNER JOIN | Retrieves CID and IPAddress. |
| WTF.FundingID | Billing.Funding | INNER JOIN | Retrieves payment instrument type and data. |
| WTF.ID | Billing.PayoutProcess | LEFT JOIN | Retrieves payout state; NULLs returned if no row exists. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payout Service (current/v2) | @WTF_ID | EXEC | Active payout service calls this procedure to load data needed for payment submission. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadPayoutProcessData_v2 (procedure)
├── Billing.WithdrawToFunding (table)
├── Billing.Withdraw (table)
├── Billing.Funding (table)
└── Billing.PayoutProcess (table)  [LEFT JOIN - optional]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Primary table - filtered by @WTF_ID. |
| Billing.Withdraw | Table | INNER JOIN - provides CID, IPAddress. |
| Billing.Funding | Table | INNER JOIN - provides FundingTypeID, FundingData. |
| Billing.PayoutProcess | Table | LEFT JOIN - provides payout tracking state (BPP columns NULL if no row). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payout Service (current) | Application | EXEC - called for every payout payment execution. |

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
EXEC Billing.LoadPayoutProcessData_v2 @WTF_ID = 12345;
```

### 8.2 Test behavior when PayoutProcess row is missing (LEFT JOIN returns NULLs)
```sql
SELECT WTF.ID, WTF.CashoutStatusID,
       BPP.ProcessID AS PayoutProcessID,
       BPP.InProcess
FROM Billing.WithdrawToFunding WTF WITH (NOLOCK)
LEFT JOIN Billing.PayoutProcess BPP WITH (NOLOCK)
    ON WTF.ID = BPP.WithdrawToFundingID
WHERE WTF.ID = 99999;
-- BPP columns will be NULL if no PayoutProcess row exists
```

### 8.3 Find WTF records processed recently with CreationDate (added in PINT-820)
```sql
SELECT WTF.ID, WTF.CreationDate, WTF.Amount, WTF.CashoutStatusID
FROM Billing.WithdrawToFunding WTF WITH (NOLOCK)
INNER JOIN Billing.PayoutProcess BPP WITH (NOLOCK)
    ON WTF.ID = BPP.WithdrawToFundingID
WHERE WTF.CreationDate >= DATEADD(DAY, -7, GETUTCDATE())
ORDER BY WTF.CreationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Payout Service Gen 2.0 - Changes](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1218937110) | Confluence | Payout service v2 architecture that this procedure supports (MG space - access restricted) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 39 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 1 Confluence + 0 Jira (access restricted) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadPayoutProcessData_v2 | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadPayoutProcessData_v2.sql*
