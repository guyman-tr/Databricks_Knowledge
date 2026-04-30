# Billing.PayoutProcess_GetNewRecordsForInstantPayout

> Instant-payout record fetcher for the legacy (old-generation) payout service: atomically creates PayoutProcess entries for eligible SentToBilling withdrawals of specified funding types, claims them by setting InProcess=1, and returns the full payment details for provider submission.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Ids (FundingTypeID list) + @MaxNumOfItems |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PayoutProcess_GetNewRecordsForInstantPayout` implements the "fetch and claim" pattern for the instant payout path in eToro's legacy cashout pipeline. When the SecurePay integration (SQL_SecurePay role) needs to process cashouts for specific funding types (e.g., credit card refunds), it calls this procedure with a list of FundingTypeIDs and a batch size. The procedure atomically creates the PayoutProcess entries, immediately claims them (sets InProcess=1), and returns the full payment data needed for provider submission in a single round-trip.

This is an "instant" payout variant because it bypasses the normal payout service queuing and directly prepares records for immediate processing. The procedure only handles `PayoutGeneration=0` records (legacy payout service). The new payout service uses a different path.

Data flow: (1) Identify eligible WithdrawToFunding records (CashoutStatusID=11, no existing PayoutProcess entry, VerificationCode IS NULL, WithdrawData IS NOT NULL, matching FundingTypeID from @Ids). (2) Create PayoutProcess entries via PayoutProcess_CreateRecords. (3) Re-query the newly created entries filtering on PayoutGeneration=0. (4) Return full payment dataset. (5) Mark those entries as claimed (InProcess=1, CorrelationID set).

---

## 2. Business Logic

### 2.1 Eligibility Filter for Instant Payout

**What**: Restricts which WithdrawToFunding records qualify for instant payout creation.

**Parameters Involved**: `@Ids`, `Billing.WithdrawToFunding.CashoutStatusID`, `Billing.PayoutProcess.ProcessID`, `WTF.VerificationCode`, `WTF.WithdrawData`

**Rules**:
- WTF.CashoutStatusID = 11 (SentToBilling): the withdrawal has been sent to the billing service and is ready for payout.
- PP.ProcessID IS NULL: no existing PayoutProcess record (not already queued or processed).
- WTF.VerificationCode IS NULL: only withdrawals that have NOT been verified via the separate verification flow (PAYUA-1058). Verified withdrawals go through a different path.
- WTF.WithdrawData IS NOT NULL: payment provider data must exist (added PAYUA-2306 to filter incomplete records).
- FundingTypeID in @Ids TVP: only the funding types explicitly requested (e.g., specific CC providers).
- TOP @MaxNumOfItems ordered by WTF.CreationDate: FIFO processing, batch-capped.

### 2.2 Atomic Claim Pattern

**What**: The procedure claims records for the caller in a single transaction to prevent double-processing.

**Columns Involved**: `Billing.PayoutProcess.InProcess`, `Billing.PayoutProcess.InProcessDate`, `Billing.PayoutProcess.CorrelationID`

**Rules**:
- After creating PayoutProcess entries and selecting the result set, the UPDATE inside BEGIN TRANSACTION sets InProcess=1, InProcessDate=GETUTCDATE(), CorrelationID=@CorrelationId.
- This claim flag prevents other workers from picking up the same records simultaneously.
- Old-generation only: WHERE PayoutGeneration=0 in the re-query ensures the new payout service doesn't interfere.

**Diagram**:
```
@Ids (FundingTypeIDs) + @MaxNumOfItems + @CorrelationId
              |
    Find eligible WTF records (CashoutStatusID=11, PP IS NULL,
    VerificationCode IS NULL, WithdrawData IS NOT NULL, FundingType in @Ids)
              |
    EXEC PayoutProcess_CreateRecords(@WtfIds, 0, @CorrelationId, 0)
              |
    SELECT newly created PP records (CashoutStatusID IN (0,12), InProcess=0, PayoutGen=0)
              |
    JOIN to WTF, Withdraw, Funding, Deposit, Depot, CustomerToFunding
              |
    SELECT result set (all payment details for provider submission)
              |
    BEGIN TRANSACTION
      UPDATE PP SET InProcess=1, InProcessDate=NOW, CorrelationID=@CorrelationId
    COMMIT
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Ids | dbo.IdIntList (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing the list of FundingTypeIDs for which to fetch payout records. The procedure JOINs `Billing.Funding.FundingTypeID` to this list, filtering to only the requested funding types (e.g., specific credit card or e-wallet types). |
| 2 | @MaxNumOfItems | int | NO | - | CODE-BACKED | Maximum number of WithdrawToFunding records to create PayoutProcess entries for in this batch. Applied as TOP in the initial WTF eligibility query. Controls batch size to prevent overwhelming the payment provider. |
| 3 | @CorrelationId | varchar(36) | NO | - | CODE-BACKED | UUID correlation ID for this batch of payout requests. Written to `Billing.PayoutProcess.CorrelationID` when records are claimed (InProcess=1). Enables tracing all records processed in a single payout service invocation. Passed to PayoutProcess_CreateRecords as the BO correlation ID. |

**Result Set Columns**:

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | WithdrawID | Billing.WithdrawToFunding.WithdrawID | The parent withdrawal request ID |
| 2 | FundingID | Billing.WithdrawToFunding.FundingID | The customer's funding instrument ID |
| 3 | (0) | Literal | Hardcoded 0 - legacy field |
| 4 | CashoutStatusID | Billing.WithdrawToFunding.CashoutStatusID | Current WTF status at time of selection |
| 5 | ProcessCurrencyID | Billing.WithdrawToFunding.ProcessCurrencyID | Currency in which the payout is processed |
| 6 | ExchangeRate | Billing.WithdrawToFunding.ExchangeRate | Exchange rate applied to the payout amount |
| 7 | Amount | Billing.WithdrawToFunding.Amount | Payout amount |
| 8 | ID (WTF) | Billing.WithdrawToFunding.ID | WithdrawToFundingID - the payout record key |
| 9 | RefundAmountInDepositCurrency | Billing.WithdrawToFunding.RefundAmountInDepositCurrency | Refund amount in original deposit currency |
| 10 | CashoutTypeID | Billing.WithdrawToFunding.CashoutTypeID | Cashout type (normal vs refund) |
| 11 | VerificationCode | Billing.WithdrawToFunding.VerificationCode | Payment verification code (NULL for this path) |
| 12 | DepositID | Billing.WithdrawToFunding.DepositID | Source deposit ID (for refund flows) |
| 13 | DepotID | Billing.WithdrawToFunding.DepotID | Payment depot/gateway ID |
| 14 | ExTransactionID | Billing.Deposit.ExTransactionID | External transaction ID from the original deposit |
| 15 | PaymentData | CAST(Billing.WithdrawToFunding.WithdrawData AS NVARCHAR(1000)) | Payment provider metadata (JSON/structured) |
| 16 | ProtocolID | Billing.Depot.ProtocolID | Payment protocol used by the depot |
| 17 | FundingTypeID | Billing.Withdraw.FundingTypeID | Funding type of the parent withdrawal request |
| 18 | FundingIsBlocked | Billing.CustomerToFunding.IsBlocked | Whether the funding instrument is blocked |
| 19 | FundingData | CAST(Billing.Funding.FundingData AS NVARCHAR(1000)) | Funding instrument metadata |
| 20 | CID | Billing.Withdraw.CID | Customer ID |
| 21 | WithdrawData | Billing.WithdrawToFunding.WithdrawData | Raw payment data (full, uncast) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WTF.FundingID | [Billing.WithdrawToFunding](../Tables/Billing.WithdrawToFunding.md) | Read/Claim | Selects eligible records; result set source |
| PP.WithdrawToFundingID | [Billing.PayoutProcess](../Tables/Billing.PayoutProcess.md) | Read/Write | LEFT JOIN to detect existing records; UPDATE to claim |
| F.FundingTypeID | Billing.Funding | Read | JOIN to get FundingTypeID for @Ids filter |
| bwtf.WithdrawID | Billing.Withdraw | Read | JOIN to get CID and FundingTypeID |
| bd.DepositID | Billing.Deposit | Read (LEFT JOIN) | Gets ExTransactionID for refund flows |
| bdpt.DepotID | Billing.Depot | Read (LEFT JOIN) | Gets ProtocolID |
| CTF.FundingID+CID | Billing.CustomerToFunding | Read | Gets FundingIsBlocked status |
| @WtfIds | Billing.PayoutProcess_CreateRecords | EXEC (callee) | Creates the PayoutProcess entries before claiming |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_SecurePay (db role) | - | EXEC | SecurePay payment provider integration calls this for instant payout processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayoutProcess_GetNewRecordsForInstantPayout (procedure)
├── Billing.WithdrawToFunding (table)
├── Billing.Funding (table)
├── Billing.PayoutProcess (table)
├── Billing.Withdraw (table)
├── Billing.Deposit (table) - LEFT JOIN
├── Billing.Depot (table) - LEFT JOIN
├── Billing.CustomerToFunding (table)
└── Billing.PayoutProcess_CreateRecords (procedure)
      └── [Documented - Batch 27]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.WithdrawToFunding](../Tables/Billing.WithdrawToFunding.md) | Table | Eligibility filter + result set source |
| Billing.Funding | Table | JOIN to get FundingTypeID for filtering |
| [Billing.PayoutProcess](../Tables/Billing.PayoutProcess.md) | Table | LEFT JOIN (detect existing), UPDATE (claim) |
| [Billing.Withdraw](../Tables/Billing.Withdraw.md) | Table | JOIN for CID and FundingTypeID |
| [Billing.Deposit](../Tables/Billing.Deposit.md) | Table | LEFT JOIN for ExTransactionID |
| Billing.Depot | Table | LEFT JOIN for ProtocolID |
| Billing.CustomerToFunding | Table | JOIN for IsBlocked status |
| Billing.PayoutProcess_CreateRecords | Stored Procedure | EXEC - creates PayoutProcess entries before returning records. Documented Batch 27. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_SecurePay application role | Application | Instant payout processing for SecurePay flows |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

The eligibility query (finding WTF records with no PayoutProcess entry for specified FundingTypes) benefits from `Billing.PayoutProcess`'s unique index on WithdrawToFundingID for the LEFT JOIN null-check. The PayoutProcess claim query uses the filtered index `ix_CoveringForPayoutProcess_GetNewRecordsForInstantPayout` which covers WHERE CashoutStatusID IN (0,12) AND InProcess=0 - this is the performance-critical path for finding newly-created payout records.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Fetch instant payout records for credit card funding types (batch of 10)

```sql
DECLARE @FundingTypes dbo.IdIntList;
INSERT INTO @FundingTypes (ID) VALUES (1), (5), (12);  -- example CC FundingTypeIDs

EXEC Billing.PayoutProcess_GetNewRecordsForInstantPayout
    @Ids           = @FundingTypes,
    @MaxNumOfItems = 10,
    @CorrelationId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
```

### 8.2 Check eligible records before calling the procedure

```sql
-- Preview what this procedure would pick up (WTF status 11, no PayoutProcess, no VerificationCode, has WithdrawData)
SELECT TOP 10
    WTF.ID AS WithdrawToFundingID,
    WTF.WithdrawID,
    WTF.FundingID,
    F.FundingTypeID,
    WTF.CreationDate
FROM Billing.WithdrawToFunding WTF WITH (NOLOCK)
JOIN Billing.Funding F WITH (NOLOCK) ON WTF.FundingID = F.FundingID
LEFT JOIN Billing.PayoutProcess PP WITH (NOLOCK) ON PP.WithdrawToFundingID = WTF.ID
WHERE WTF.CashoutStatusID = 11
  AND PP.ProcessID IS NULL
  AND WTF.VerificationCode IS NULL
  AND WTF.WithdrawData IS NOT NULL
ORDER BY WTF.CreationDate;
```

### 8.3 Monitor claimed (InProcess=1) records for the legacy payout service

```sql
SELECT
    pp.ProcessID,
    pp.WithdrawToFundingID,
    pp.CorrelationID,
    pp.InProcessDate,
    pp.PayoutGeneration
FROM Billing.PayoutProcess pp WITH (NOLOCK)
WHERE pp.InProcess = 1
  AND pp.PayoutGeneration = 0  -- legacy service
ORDER BY pp.InProcessDate;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYUA-1058 | Jira (referenced in code comment) | Added VerificationCode IS NULL filter - verified withdrawals should not go through the instant payout path |
| PAYUA-1210 | Jira (referenced in code comment) | Transaction management changed to reduce locks |
| PAYUA-2306 | Jira (referenced in code comment) | Added WithdrawData IS NOT NULL filter to skip incomplete payment records |
| PAYUA-3049 | Jira (referenced in code comment) | Added WithdrawData column to result set |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 applicable*
*Sources: Atlassian: 0 Confluence + 4 Jira (code comments) | Procedures: 1 callee (PayoutProcess_CreateRecords) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PayoutProcess_GetNewRecordsForInstantPayout | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PayoutProcess_GetNewRecordsForInstantPayout.sql*
