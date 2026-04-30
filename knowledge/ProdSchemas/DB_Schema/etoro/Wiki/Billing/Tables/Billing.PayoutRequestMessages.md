# Billing.PayoutRequestMessages

> Execution message queue for the new payout service (Generation 1), storing per-withdrawal payout request payloads with status tracking, protocol/depot parameters, and step-level progress for the withdrawal fulfillment pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | RequestID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK clustered, FILLFACTOR=95) |

---

## 1. Business Meaning

Billing.PayoutRequestMessages stores the execution records for eToro's new payout service (PayoutGeneration=1). For each withdrawal payout submitted to the new payout service, one row is created here containing the withdrawal identifiers, amount, currency, payment parameters, and a step-by-step progress tracker. The table functions as both a message queue (picking up StatusID=0 records) and an audit log of payout execution (completed records remain with StatusID=3).

This table is distinct from Billing.PayoutProcess: PayoutProcess is the control record managed by the back-office payout pipeline for both legacy and new services; PayoutRequestMessages is specific to the new payout service and contains the richer message payload (ProtocolParameters, DepotParameters) that the new service needs to submit the payment to the provider.

The table covers Jan 2023 onwards (392,222 rows), aligning with the new payout service rollout. 81% of rows have StatusID=3 ("step process completed"), confirming the new service processes payouts successfully. PayoutTypeID is always 1 (only one payout type in use). Currency column is NULL in all recent records - CurrencyID is the operative identifier.

---

## 2. Business Logic

### 2.1 Payout Request Lifecycle

**What**: Each request goes through status states from creation (0) to completion (3) or failure.

**Columns/Parameters Involved**: `StatusID`, `HandleCount`, `LastSuccessStep`, `Modified`

**Rules**:
- StatusID=0 (54,155 rows, 14%): Initial state or reset state. Indicates the record is ready to be processed or has been reset for retry.
- StatusID=1 (3,663 rows, 1%): In-progress - the payout service is actively processing.
- StatusID=2 (15,745 rows, 4%): Intermediate completion state - partially processed or waiting for provider confirmation.
- StatusID=3 (318,659 rows, 81%): Final success state - "step process completed". The dominant terminal state.
- HandleCount: Number of times the payout service has attempted to process this request. Most records: HandleCount=1. Maximum observed: 7 (retried multiple times). Average: 1.
- LastSuccessStep: String label of the last successfully completed processing step (e.g., "step process completed"). Enables the service to resume from the last good checkpoint rather than restart from scratch on retry.
- Modified = GETUTCDATE() on every UPDATE by UpsertPayoutRequestMessage.

### 2.2 MERGE Upsert Pattern

**What**: UpsertPayoutRequestMessage uses a MERGE to handle both new record creation and updates.

**Columns/Parameters Involved**: `RequestID`, `StatusID`, `HandleCount`, `ProtocolParameters`, `DepotParameters`

**Rules**:
- MATCH: On RequestID. When matched, updates Currency, CurrencyID, StatusID, HandleCount, LastSuccessStep, FundingTypeID (ISNULL preserved), ProtocolParameters, DepotParameters, Modified.
- NOT MATCHED (INSERT): Inserts full record with Created=Modified=GETUTCDATE().
- @RequestID=-1 on initial call (no match) triggers INSERT path. Subsequent calls with the returned RequestID trigger UPDATE path.
- OUTPUT clause returns the new RequestID on INSERT to the caller (@PayoutRequestID OUTPUT).

### 2.3 Payment Parameters

**What**: ProtocolParameters and DepotParameters contain provider-specific serialized payloads for submitting the payout.

**Columns/Parameters Involved**: `ProtocolParameters`, `DepotParameters`, `FundingTypeID`, `CurrencyID`, `Amount`

**Rules**:
- ProtocolParameters (nvarchar 2000): Provider API parameters needed to execute the payout (e.g., account details, routing codes). Content is protocol/provider-specific JSON or structured text.
- DepotParameters (nvarchar 2000): Depot/destination parameters (e.g., IBAN, wallet address, bank account details). Provider-specific.
- Amount is decimal(18,0) - whole-number USD cents or whole currency units. Observed values: 25-30 USD.
- Currency (varchar 20): Text currency code. NULL in all recent records - superseded by CurrencyID.
- MassCorrelationID: Groups requests that were submitted as a batch payout run.
- CorrelationID: Per-request correlation UUID for distributed tracing.

---

## 3. Data Overview

| StatusID | Name (inferred) | Count | % |
|---------|----------------|-------|---|
| 0 | Initial/Reset | 54,155 | 14% |
| 1 | InProgress | 3,663 | 1% |
| 2 | PartialComplete | 15,745 | 4% |
| 3 | Completed | 318,659 | 81% |
| **Total** | | **392,222** | |

Date range: Jan 2023 - Mar 2026 (new payout service era)
PayoutTypeID: Only value observed is 1 (single type in use)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RequestID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. Returned to caller via @PayoutRequestID OUTPUT on INSERT. Used as the MERGE match key on subsequent updates. |
| 2 | PayoutID | int | NO | - | CODE-BACKED | Reference to the payout execution record (likely Billing.PayoutProcess.ProcessID). Links the payment request message to its parent payout process control record. |
| 3 | WithdrawID | int | NO | - | CODE-BACKED | The customer withdrawal request ID (FK to Billing.Withdraw). The original withdrawal that triggered this payout. |
| 4 | FundingID | int | YES | - | CODE-BACKED | The funding method record ID (FK to Billing.Funding). The specific payment account/wallet to which the payout is being sent. |
| 5 | Amount | decimal(18,0) | YES | - | CODE-BACKED | Payout amount in the account currency. Decimal(18,0) means whole numbers only (no cents fraction). Observed values: 25-30 USD. |
| 6 | Currency | varchar(20) | YES | - | CODE-BACKED | Text currency code (e.g., "USD", "GBP"). NULL in all recent records - superseded by CurrencyID. Legacy field from early implementation. |
| 7 | CurrencyID | int | YES | - | CODE-BACKED | Currency identifier. FK to Dictionary.Currency (no constraint declared). Observed: 1=USD, 3=GBP. Operative currency field; Currency (text) is obsolete. |
| 8 | FundingTypeID | int | YES | - | CODE-BACKED | Payment method type. FK to Dictionary.FundingType (no constraint). Preserved via ISNULL on UPDATE (not overwritten if null is passed). Observed: 1=Credit Card, 33=Skrill (or similar e-wallet). |
| 9 | MassCorrelationID | varchar(50) | YES | - | CODE-BACKED | Correlation ID grouping a batch of payout requests submitted together in a single mass payout run. Links to the submitting session or batch job. |
| 10 | CorrelationID | varchar(50) | YES | - | CODE-BACKED | Per-request correlation UUID for distributed tracing across the payout service components. Distinct from MassCorrelationID (per-batch). Note: 50-char here vs 36-char in PayoutProcess (UUID format may differ). |
| 11 | ManagerID | int | YES | - | CODE-BACKED | ID of the manager/service account that initiated the payout. 0 when set by the automated payout service (from UpsertPayoutRequestMessage default). |
| 12 | Created | datetime | YES | - | CODE-BACKED | UTC timestamp when the payout request message was first created. Set to GETUTCDATE() on INSERT. Never updated after creation. |
| 13 | Modified | datetime | YES | - | CODE-BACKED | UTC timestamp of the most recent update. Set to GETUTCDATE() on both INSERT and every UPDATE by UpsertPayoutRequestMessage. Delta between Created and Modified = total processing duration. |
| 14 | PayoutTypeID | int | YES | - | CODE-BACKED | Type of payout operation. Only one distinct value observed (1). May distinguish standard withdrawal from special payout types (crypto, ACH, etc.) though no other types are in use. |
| 15 | StatusID | int | YES | - | CODE-BACKED | Payout request processing status. Not FK-constrained. Values: 0=Initial/Reset (ready to process), 1=InProgress (active), 2=PartialComplete/intermediate, 3=Completed. Different from the CashoutStatus domain used by PayoutProcess. |
| 16 | ProtocolParameters | nvarchar(2000) | YES | - | CODE-BACKED | Provider API parameters required to submit the payout to the payment provider. JSON or structured text content specific to the protocol (FundingTypeID). Updated on each MERGE update. |
| 17 | DepotParameters | nvarchar(2000) | YES | - | CODE-BACKED | Destination account parameters for the payout (bank account, wallet details, routing numbers). Provider-specific format. Updated on each MERGE update. |
| 18 | HandleCount | int | YES | - | CODE-BACKED | Number of times the payout service has attempted to process this request. Incremented on each retry. Most records = 1. Maximum observed = 7. Used to detect/limit retry loops. |
| 19 | LastSuccessStep | varchar(50) | YES | - | CODE-BACKED | Name of the last successfully completed processing step. Enables resume-on-retry: the service can skip steps already completed. Observed terminal value: "step process completed". Updated on each MERGE update. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID | Billing.Withdraw | Implicit | References the withdrawal request. No declared FK. |
| FundingID | Billing.Funding | Implicit | References the payment account for the payout. No declared FK. |
| CurrencyID | Dictionary.Currency | Implicit | References the payout currency. No declared FK. |
| PayoutID | Billing.PayoutProcess | Implicit | References the parent payout control record. No declared FK. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.UpsertPayoutRequestMessage | RequestID, PayoutID, WithdrawID, StatusID | MERGE writer | Primary writer. Creates new records or updates existing ones. Returns @PayoutRequestID on insert. |
| Billing.GetPayoutProcessMessageByID | RequestID | SELECT reader | Returns all fields for a given RequestID. Used by BO/API to inspect payout message state. Referenced in Jira PAYUS-1560. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayoutRequestMessages (table)
  (leaf - tables have no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No FK constraints declared. Logically depends on Billing.Withdraw, Billing.Funding, and Dictionary.Currency.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.UpsertPayoutRequestMessage | Stored Procedure | MERGE writer - inserts and updates payout request messages |
| Billing.GetPayoutProcessMessageByID | Stored Procedure | SELECT reader - retrieves payout message by RequestID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PayoutRequestMessages | CLUSTERED PK | RequestID ASC | - | - | Active (FILLFACTOR=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_PayoutRequestMessages | PRIMARY KEY | RequestID clustered |

---

## 8. Sample Queries

### 8.1 Get pending payout requests for processing

```sql
SELECT RequestID, PayoutID, WithdrawID, Amount, CurrencyID, FundingTypeID, HandleCount, Created
FROM Billing.PayoutRequestMessages WITH (NOLOCK)
WHERE StatusID = 0  -- ready to process
ORDER BY Created ASC
```

### 8.2 Find failed/stalled payout requests

```sql
SELECT RequestID, PayoutID, WithdrawID, StatusID, HandleCount, LastSuccessStep, Modified
FROM Billing.PayoutRequestMessages WITH (NOLOCK)
WHERE StatusID IN (1, 2)
  AND Modified < DATEADD(HOUR, -1, GETUTCDATE())
ORDER BY Modified ASC
```

### 8.3 Get payout message for a specific withdrawal

```sql
SELECT prm.*, cs.Name AS CurrencyName
FROM Billing.PayoutRequestMessages prm WITH (NOLOCK)
LEFT JOIN Dictionary.Currency cs WITH (NOLOCK) ON prm.CurrencyID = cs.CurrencyID
WHERE prm.WithdrawID = @WithdrawID
```

---

## 9. Atlassian Knowledge Sources

Code comments in Billing.UpsertPayoutRequestMessage reference PAYIL-1371 (Shay Oren, 29/09/2020 - added MERGE and protocol/depot parameters). GetPayoutProcessMessageByID references PAYUS-1560 (initial version).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.9/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.PayoutRequestMessages | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.PayoutRequestMessages.sql*
