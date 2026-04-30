# Billing.PayoutProcess

> Operational tracking table recording the payout execution state for each withdrawal request, serving as the control record for the payout service to claim, process, and finalize cashout payments to external providers.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ProcessID (INT IDENTITY, PK CLUSTERED) - natural key: WithdrawToFundingID (UNIQUE NC) |
| **Partition** | PRIMARY filegroup (PAGE compressed PK) |
| **Indexes** | 4 active (PK clustered + UNIQUE NC on WithdrawToFundingID + NC on InProcess+CashoutStatusID + filtered NC for instant payout) |

---

## 1. Business Meaning

Billing.PayoutProcess is the execution record for eToro's cashout (withdrawal) payout pipeline. When a customer's withdrawal request has been reviewed and approved, it moves from Billing.WithdrawToFunding to this table via PayoutProcess_CreateRecords. Each row represents a single withdrawal (WithdrawToFundingID) at a specific point in the payout lifecycle (CashoutStatusID), with tracking fields for the provider's response, external reference codes, correlation IDs, and which back-office manager initiated the payout.

The UNIQUE constraint on WithdrawToFundingID means one withdrawal = one active payout process record. The payout service workers use the filtered index (CashoutStatusID IN (0,12) AND InProcess=0) to efficiently find payouts awaiting processing. InProcess=1 means a worker has "claimed" the record and is actively submitting it to the payment provider.

PayoutGeneration=1 (318,651 rows = 79%) indicates the newer payout service generation; PayoutGeneration=0 (84,280 = 21%) is the legacy service. The table has 402,930 total rows, dominated by CashoutStatusID=3 (Processed/final - 280,797 rows = 70%), confirming most payouts complete successfully.

---

## 2. Business Logic

### 2.1 Payout Record Creation

**What**: A PayoutProcess row is created when the back-office approves a WithdrawToFunding record for payout.

**Columns/Parameters Involved**: `WithdrawToFundingID`, `CashoutStatusID`, `ManagerID`, `BoCorrelationID`, `PayoutGeneration`

**Rules**:
- PayoutProcess_CreateRecords inserts a row with CashoutStatusID=12 (ReceivedByBilling) for each approved withdrawal.
- Source records must be in WithdrawToFunding.CashoutStatusID=11 (SentToBilling) with no VerificationCode (verified) AND no existing PayoutProcess row (UNIQUE guard).
- Simultaneously, WithdrawToFunding.CashoutStatusID is updated from 11 to 12 (atomic transaction).
- ManagerID=-1 means the billing service triggered the payout automatically (not a human manager).
- BoCorrelationID: A back-office correlation UUID (36-char) linking this batch to the approving BO session.
- PayoutGeneration: 0=legacy payout service, 1=new payout service (default since 2020). Determines which payout pipeline processes the record.

### 2.2 Payout Worker Claim and Processing

**What**: Payout service workers query for unclaimed records, set InProcess=1 to claim them, then submit to the payment provider.

**Columns/Parameters Involved**: `InProcess`, `InProcessDate`, `CashoutStatusID`, `CorrelationID`

**Rules**:
- The filtered index ix_CoveringForPayoutProcess_GetNewRecordsForInstantPayout covers WHERE CashoutStatusID IN (0,12) AND InProcess=0 - these are the "ready for processing" states.
- CashoutStatusID=12 (ReceivedByBilling): newly created, not yet picked up.
- CashoutStatusID=0: an initialization/reset state (not a standard Dictionary.CashoutStatus value - possibly a legacy zero-default state).
- InProcess=1 + InProcessDate: when a worker claims a record. Default InProcess=0, InProcessDate=GETUTCDATE().
- CorrelationID: worker-assigned UUID tracking the payment provider submission session (distinct from BoCorrelationID which is the BO approval session).
- IX_BillingPayoutProcess_InProcessCashoutStatusID: NC on (InProcess, CashoutStatusID) - used for finding active/pending records without the filtered index precision.

### 2.3 Status Finalization

**What**: PayoutProcess_UpdateStatus sets the final state after the payment provider responds.

**Columns/Parameters Involved**: `CashoutStatusID`, `ExtReferenceCode`, `ExtReferenceCode2`, `ProviderReasonCode`, `PayoutProcessStatusDate`, `PayoutProcessReasonID`, `InProcess`

**Rules**:
- On finalization: CashoutStatusID is updated to the provider's response status, InProcess is reset to 0, PayoutProcessStatusDate = GETUTCDATE().
- ExtReferenceCode / ExtReferenceCode2: The provider's transaction reference codes (up to 50 chars each). Used for reconciliation and dispute resolution. Preserved via ISNULL on update (not overwritten if null is passed).
- ProviderReasonCode: Numeric code from the provider explaining why a payout was rejected (for CashoutStatusID=8 RejectedByProvider, or 13 Failed).
- PayoutProcessReasonID distribution: 0=328,985 (default/no specific reason), 6=56,312, 1=17,467, 2=161, 3=6. Reason IDs are not in a discovered dictionary table.
- PayoutProcess_Update is the atomic wrapper: calls PayoutProcess_UpdateStatus AND WithdrawToFundingChangePaymentStatus in a single transaction to keep both tables in sync.

### 2.4 CashoutStatus Distribution (Live Data)

| CashoutStatusID | Name | Count | % | Meaning |
|----------------|------|-------|---|---------|
| 3 | Processed | 280,797 | 70% | Successfully paid out - final state |
| 8 | RejectedByProvider | 54,745 | 14% | Provider declined - final state |
| 13 | Failed | 19,141 | 5% | Processing error - final state |
| 12 | ReceivedByBilling | 18,044 | 4% | Pending payout - active queue |
| 10 | SentToProvider | 15,481 | 4% | Submitted, awaiting provider confirmation |
| 9 | PendingByProvider | 14,659 | 4% | Provider processing - intermediate |
| 4 | Canceled | 59 | <1% | Cancelled without money transfer - final |
| 2 | InProcess | 3 | <1% | Active worker claim |
| 1 | Pending | 1 | <1% | Initial state |

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | 402,930 |
| PayoutGeneration=1 (new service) | 318,651 (79%) |
| PayoutGeneration=0 (legacy service) | 84,280 (21%) |
| Final-state rows (3+8+13+4) | 354,742 (88%) |
| Active/in-flight rows (12+10+9+2+1) | 48,188 (12%) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProcessID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. NOT FOR REPLICATION. Business operations use WithdrawToFundingID as the natural key. |
| 2 | WithdrawToFundingID | int | NO | - | CODE-BACKED | FK to Billing.WithdrawToFunding.ID. The withdrawal request being processed. UNIQUE NC index enforces one PayoutProcess record per withdrawal. This is the primary business key used by all SPs. |
| 3 | CashoutStatusID | int | NO | - | VERIFIED | Current payout processing state. FK to Dictionary.CashoutStatus (no declared constraint). Values observed: 1=Pending, 2=InProcess, 3=Processed(final), 4=Canceled(final), 8=RejectedByProvider(final), 9=PendingByProvider, 10=SentToProvider, 12=ReceivedByBilling, 13=Failed(final). The filtered index covers CashoutStatusID IN (0,12) as "ready to process" states. |
| 4 | PayoutProcessReasonID | int | YES | - | CODE-BACKED | Reason code for the current status, particularly for rejection/failure states. No dictionary table discovered. Observed values: 0=no specific reason (328,985 rows), 1=17,467, 2=161, 3=6, 6=56,312. Set by PayoutProcess_UpdateStatus. NULL on initial creation (CreateRecords inserts 0). |
| 5 | PayoutProcessStatusDate | datetime | YES | - | CODE-BACKED | UTC timestamp when the payout status was last changed by PayoutProcess_UpdateStatus. NULL until the first status update after creation. Distinct from Occurred (creation) and InProcessDate (worker claim). |
| 6 | ManagerID | int | YES | - | CODE-BACKED | ID of the back-office user who created the payout record. -1 when triggered automatically by the billing service (not a human action). Used for audit trail in History.WithdrawToFundingAction. |
| 7 | Occurred | datetime | NO | GETUTCDATE() | CODE-BACKED | UTC timestamp when the PayoutProcess record was created (when the withdrawal entered the payout pipeline). Default GETUTCDATE(). Used for aging analysis. |
| 8 | ExtReferenceCode | varchar(50) | YES | - | CODE-BACKED | Primary external reference code assigned by the payment provider after submission. Used for provider-side reconciliation and dispute resolution. Preserved (not overwritten) if NULL is passed to PayoutProcess_UpdateStatus. |
| 9 | ExtReferenceCode2 | varchar(50) | YES | - | CODE-BACKED | Secondary external reference code from the payment provider. Some providers return multiple reference identifiers. Preserved via ISNULL logic on update. |
| 10 | CorrelationID | varchar(36) | YES | - | CODE-BACKED | UUID assigned by the payout service worker when it claims and submits the record to the provider. Tracks the payment provider submission session. Distinct from BoCorrelationID (BO approval batch). Included in the filtered covering index. |
| 11 | InProcess | bit | NO | 0 | CODE-BACKED | Worker claim flag. 0=available for processing, 1=currently being processed by a payout worker. Default 0. Reset to 0 by PayoutProcess_UpdateStatus after finalization. The filtered index WHERE InProcess=0 is how workers find unclaimed records. |
| 12 | InProcessDate | datetime | YES | GETUTCDATE() | CODE-BACKED | UTC timestamp when InProcess was last set to 1 (worker claimed the record). Default GETUTCDATE() on row creation. Used to detect stalled/stuck payout workers (InProcess=1 but InProcessDate is old). |
| 13 | BoCorrelationID | varchar(36) | YES | - | CODE-BACKED | UUID from the back-office approval session that created this payout batch. Links all records created in the same BO approval action. Set at creation time via @CorrelationID parameter in PayoutProcess_CreateRecords. |
| 14 | ProviderResponseID | int | YES | - | CODE-BACKED | Provider's numeric response/transaction ID. Distinct from ExtReferenceCode (which is a string reference). May be the provider's internal transaction identifier for API-level lookups. |
| 15 | ProviderReasonCode | int | YES | - | CODE-BACKED | Provider's numeric reason code for rejection or failure. Set by PayoutProcess_UpdateStatus via @ProviderReasonCode. Used for diagnosing provider-specific rejection patterns (e.g., insufficient funds, closed account, compliance block). |
| 16 | PayoutGeneration | int | NO | 0 | CODE-BACKED | Identifies which payout service generation processed this record. 0=legacy payout service (84,280 rows), 1=new payout service (318,651 rows). Added 2020-08-02 (Elrom). Default 0 for backwards compatibility but new records use 1. Determines routing to the appropriate processing pipeline. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawToFundingID | Billing.WithdrawToFunding | Implicit FK (no constraint declared) | References the withdrawal request being processed. UNIQUE NC enforces 1:1 relationship. |
| CashoutStatusID | Dictionary.CashoutStatus | Implicit FK | References payout lifecycle state. No declared FK constraint. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.PayoutProcess_CreateRecords | WithdrawToFundingID, CashoutStatusID, ManagerID | INSERT writer | Creates new records when BO approves withdrawals for payout. Inserts with CashoutStatusID=12. |
| Billing.PayoutProcess_UpdateStatus | CashoutStatusID, ExtReferenceCode, ProviderReasonCode, InProcess | UPDATE writer | Updates status after provider response. Resets InProcess=0. |
| Billing.PayoutProcess_Update | (via UpdateStatus + WithdrawToFundingChangePaymentStatus) | Orchestrator | Atomic wrapper updating both PayoutProcess and WithdrawToFunding in one transaction. |
| Billing.PayoutProcess_GetNewRecords | CashoutStatusID, InProcess | SELECT reader | Fetches records ready for the legacy payout service. |
| Billing.PayoutProcess_GetNewRecordsForInstantPayout | ProcessID, CorrelationID, WithdrawToFundingID | SELECT reader | Uses filtered index. Fetches CashoutStatusID IN (0,12) AND InProcess=0 records for the instant payout service. |
| Billing.PayoutProcess_GetProviderRecords | - | SELECT reader | Reads payout records for provider-side reconciliation. |
| Billing.PayoutProcess_GetShopperData | - | SELECT reader | Retrieves shopper (customer) data for payout submission. |
| Billing.PayoutProcess_Abort | CashoutStatusID, InProcess | UPDATE writer | Aborts an in-progress payout, resetting status. |
| Billing.PayoutProcess_IsProcessingID | ProcessID | SELECT reader | Checks if a given ProcessID is actively being processed. |
| Billing.PayoutProcess_IsDepositID | - | SELECT reader | Validates deposit-related payout linkage. |
| Billing.PayoutProcess_FinalizeRequest | - | UPDATE writer | Finalizes payout requests. |
| Billing.PayoutProcess_FinalizeRequest_v2 | - | UPDATE writer | V2 finalization for new payout service. |
| Billing.LoadPayoutProcessData | - | SELECT reader | Loads payout process data for reporting/BO display. |
| Billing.LoadPayoutProcessData_v2 | - | SELECT reader | V2 loader for new payout service data. |
| Billing.GetPayoutProcessData | - | SELECT reader | Returns payout data for BO/API. |
| Billing.GetPayoutProcessMessageByID | ProcessID | SELECT reader | Returns payout message for a specific process ID. |
| Billing.RedeemPayoutProcess_CreateRecords | WithdrawToFundingID | INSERT writer | Creates PayoutProcess records for copy-trading redemption payouts. |
| Billing.RedeemPayoutProcess_Update | - | UPDATE writer | Updates status for redemption payouts. |
| Billing.RedeemPayoutProcess_UpdateStatus | - | UPDATE writer | Updates status for redemption payouts. |
| Billing.RedeemPayoutProcess_GetNewRecords | - | SELECT reader | Fetches new redemption payout records. |
| Billing.RedeemPayoutProcess_Abort | - | UPDATE writer | Aborts redemption payout. |
| Billing.WithdrawToFundingProcess | - | Orchestrator | Main withdrawal processing flow. |
| Billing.WithdrawToFundingProcess_v2 | - | Orchestrator | V2 main processing flow. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayoutProcess (table)
  (leaf - tables have no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No FK constraints declared. Logically depends on Billing.WithdrawToFunding (source records) and Dictionary.CashoutStatus (status values).

### 6.2 Objects That Depend On This

26 stored procedures - see Section 5.2.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Billing_WithdrawToFundingPayoutProcess | CLUSTERED PK | ProcessID ASC | - | - | Active (PAGE compressed, FILLFACTOR=90) |
| Idx_Billing_PayoutProcess_WithdrawToFundingID | NC UNIQUE | WithdrawToFundingID ASC | ProcessID, CashoutStatusID, PayoutProcessReasonID, PayoutProcessStatusDate, ManagerID, Occurred, ExtReferenceCode, ExtReferenceCode2, CorrelationID, InProcess, InProcessDate, BoCorrelationID, ProviderResponseID, ProviderReasonCode, PayoutGeneration | - | Active (FILLFACTOR=95, ALLOW_PAGE_LOCKS=OFF) - covering index returns all columns via WithdrawToFundingID lookup without PK touch |
| IX_BillingPayoutProcess_InProcessCashoutStatusID | NC | InProcess ASC, CashoutStatusID ASC | - | - | Active (PAGE compressed, FILLFACTOR=95) - supports finding active/pending records |
| ix_CoveringForPayoutProcess_GetNewRecordsForInstantPayout | NC | ProcessID ASC | CorrelationID, WithdrawToFundingID | CashoutStatusID IN (0,12) AND InProcess=0 | Active (FILLFACTOR=95) - filtered covering index for instant payout worker queue |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Billing_WithdrawToFundingPayoutProcess | PRIMARY KEY | ProcessID clustered |
| Df_Billing_PayoutProcess_Occurred | DEFAULT | GETUTCDATE() for Occurred |
| Df_Billing_PayoutProcess_InProcess | DEFAULT | 0 for InProcess |
| Df_Billing_PayoutProcess_InProcessDate | DEFAULT | GETUTCDATE() for InProcessDate |
| (unnamed) | DEFAULT | 0 for PayoutGeneration |

---

## 8. Sample Queries

### 8.1 Get payout records currently queued for processing

```sql
SELECT ProcessID, WithdrawToFundingID, CashoutStatusID, InProcess, InProcessDate, CorrelationID
FROM Billing.PayoutProcess WITH (NOLOCK)
WHERE CashoutStatusID IN (0, 12)
  AND InProcess = 0
ORDER BY Occurred ASC
```

### 8.2 Find stalled payout workers (InProcess=1 for too long)

```sql
SELECT ProcessID, WithdrawToFundingID, InProcess, InProcessDate, CorrelationID
FROM Billing.PayoutProcess WITH (NOLOCK)
WHERE InProcess = 1
  AND InProcessDate < DATEADD(HOUR, -1, GETUTCDATE())
ORDER BY InProcessDate ASC
```

### 8.3 Payout status summary

```sql
SELECT cs.Name AS Status, COUNT(1) AS cnt
FROM Billing.PayoutProcess pp WITH (NOLOCK)
INNER JOIN Dictionary.CashoutStatus cs WITH (NOLOCK) ON pp.CashoutStatusID = cs.CashoutStatusID
GROUP BY cs.Name
ORDER BY cnt DESC
```

### 8.4 Look up payout for a specific withdrawal

```sql
SELECT pp.*, cs.Name AS StatusName
FROM Billing.PayoutProcess pp WITH (NOLOCK)
INNER JOIN Dictionary.CashoutStatus cs WITH (NOLOCK) ON pp.CashoutStatusID = cs.CashoutStatusID
WHERE pp.WithdrawToFundingID = @WithdrawToFundingID
```

---

## 9. Atlassian Knowledge Sources

Code comments in dependent SPs reference:
- Jira 43131: "DB - Cashout new SP" (Geri Reshef, Jan 2017) - original table creation
- Jira 51612: PayoutProcess_UpdateStatus update (Ran Ovadia, May 2018)
- PAYUS-20163: Add @MerchantAccountID to PayoutProcess_Update (Shay Oren, Dec 2020)
- Elrom (Aug 2020): Added @PayoutGeneration parameter (new vs legacy payout service distinction)

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.PayoutProcess | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.PayoutProcess.sql*
