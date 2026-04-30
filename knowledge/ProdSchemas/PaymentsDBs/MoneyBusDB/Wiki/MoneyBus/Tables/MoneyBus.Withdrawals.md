# MoneyBus.Withdrawals

> Core transactional table tracking withdrawal requests from users, recording the full lifecycle from creation through hold, authorize, payout (or abort) with audit trail via system versioning.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Table |
| **Key Identifier** | ID (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No (clustered on PK, DATA_COMPRESSION = PAGE) |
| **Indexes** | 3 active (PK + IX_Created + IX_GCID) |

---

## 1. Business Meaning

MoneyBus.Withdrawals is the central table tracking every withdrawal request in the MoneyBus payment system. Each row represents a single withdrawal operation where a user requests funds to be moved from their platform account to an external destination (currently exclusively IBAN bank accounts). The table records the full lifecycle: creation, risk review, hold, authorization, payout, and potential abort/cancellation.

This table exists as the authoritative record of all withdrawal activity for compliance, audit, and operational purposes. It provides a complete history of every withdrawal attempt including those that were declined, aborted, or flagged for manual review. The system-versioning (temporal table) with History.MoneyBusWithdrawals ensures that every state change is preserved - critical for regulatory requirements around fund movement traceability.

Data flows in via WithdrawAdd (creates the initial record), is updated through WithdrawUpdate as the withdrawal progresses through pipeline stages, and is read by WithdrawGet/WithdrawGetList/WithdrawGetListV2 for status checks and listing. The StatusID and StatusReasonID columns track the withdrawal through a Hold -> Authorize -> Payout pipeline (or abort if any step fails). The StatusReasonDescription and ErrorDescription fields capture human-readable details about risk review failures and provider errors.

---

## 2. Business Logic

### 2.1 Withdrawal Lifecycle Pipeline

**What**: Each withdrawal progresses through a multi-step pipeline of hold, authorize, and payout, tracked by StatusID and StatusReasonID.

**Columns/Parameters Involved**: `StatusID`, `StatusReasonID`, `StatusReasonDescription`, `ErrorDescription`

**Rules**:
- StatusID maps to Dictionary.WithdrawStatuses: 1=InProcess, 2=Success, 3=Decline, 5=Cancelled
- StatusReasonID maps to Dictionary.WithdrawStatusReasons for step-level detail
- The dominant happy path: Created(1) -> HoldInitiated(3) -> HoldApproved(4) -> AuthorizeInitiated(6) -> AuthorizeApproved(7) -> PayoutInitiated(9) -> PayoutApproved(10=Success)
- Abort path: Any failure -> AbortInitiated(12) -> AbortCompleted(13=Cancelled)
- Risk gate: RiskManualReview(15) pauses the pipeline until compliance clears or rejects

**Diagram**:
```
Created(1/1) -> HoldInitiated(1/3) -> HoldApproved(1/4) -> AuthorizeInitiated(1/6)
    |                |                                           |
    |                v                                           v
    |           HoldDeclined(3/5)                     AuthorizeDeclined(1/8)
    |                |                                           |
    v                v                                           v
RiskManualReview  AbortInitiated(1/12) <----- PayoutDeclined(1/11)
   (1/15)            |                              ^
    |                v                              |
    |         AbortCompleted(5/13)          PayoutInitiated(1/9)
    |              or                               |
    |         AbortFailed(1/14)                     v
    |                                        PayoutApproved(2/10) = SUCCESS
    v
[Manual decision -> continue or abort]

Legend: (StatusID/StatusReasonID)
```

### 2.2 Risk Review Gate

**What**: Withdrawals can be flagged by the risk engine for manual compliance review before proceeding.

**Columns/Parameters Involved**: `StatusReasonID`, `StatusReasonDescription`

**Rules**:
- When StatusReasonID = 15 (RiskManualReview), the pipeline is paused
- StatusReasonDescription contains JSON with failed risk rules, e.g.: `"Manual Review Failed rules :{\"failedRules\":[{\"ruleName\":\"AlertType\",\"details\":{\"38\":\"PossibleCompromisedAccount\"}}]}"`
- Common risk triggers: PossibleCompromisedAccount, DividendCheckRequired
- A compliance officer must review and either approve (continue) or reject (abort)

### 2.3 Currency Conversion Tracking

**What**: Withdrawals in non-USD currencies track the exchange rate and USD-equivalent amount.

**Columns/Parameters Involved**: `Amount`, `CurrencyID`, `ExchangeRate`, `AmountInUsd`

**Rules**:
- Amount is in the user's withdrawal currency (identified by CurrencyID)
- ExchangeRate records the conversion rate applied at withdrawal time
- AmountInUsd = Amount * ExchangeRate (approximately) for reporting normalization
- All three are populated together during processing

---

## 3. Data Overview

| ID | GCID | AccountTypeID | StatusID | StatusReasonID | Amount | CurrencyID | Meaning |
|---|---|---|---|---|---|---|---|
| 773487 | 41952489 | 3 (IBAN) | 2 (Success) | 10 (PayoutApproved) | 900 | 3 | Successful withdrawal of 900 in currency 3, paid out to IBAN with exchange rate 1.3556 (AmountInUsd=1220.04) |
| 773480 | 47436082 | 3 (IBAN) | 5 (Cancelled) | 13 (AbortCompleted) | 590.29 | 2 | Withdrawal aborted - account was suspended. Error: "Account suspended", abort initiated by system. Held funds released. |
| 773459 | 47546102 | 3 (IBAN) | 1 (InProcess) | 15 (RiskManualReview) | 50 | 2 | Small withdrawal stuck in risk review - flagged for PossibleCompromisedAccount. Pending compliance decision. |
| 773425 | 34992228 | 3 (IBAN) | 1 (InProcess) | 15 (RiskManualReview) | 25709.73 | 2 | Large withdrawal in risk review - flagged for DividendCheckRequired. High value requires manual review. |
| 773368 | 46224874 | 3 (IBAN) | 5 (Cancelled) | 13 (AbortCompleted) | 60 | 2 | Withdrawal aborted - "Account limit has been reached". Even small amounts can be blocked by account-level limits. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. Referenced by WithdrawCancelRequest.WithdrawID and WithdrawContainers.WithdrawID. Used as the unique identifier for all withdrawal operations. |
| 2 | GCID | bigint | NO | - | CODE-BACKED | Global Customer ID - identifies the user requesting the withdrawal. High cardinality. Indexed (IX_Withdrawals_GCID) for efficient user-level queries. |
| 3 | AccountID | nvarchar(200) | YES | - | CODE-BACKED | Identifier of the specific external account the funds are being sent to (e.g., specific IBAN number or payment account reference). Nullable if the destination is determined later in the flow. |
| 4 | AccountTypeID | int | NO | - | CODE-BACKED | Type of account being withdrawn from: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See [Account Type](../../_glossary.md#account-type). (Dictionary.AccountTypes). Currently 100% of withdrawals use IBAN (3). |
| 5 | Created | datetime | NO | GETDATE() | CODE-BACKED | UTC timestamp when the withdrawal request was created. Indexed (IX_Withdrawals_Created) for time-range queries. Range: 2025-07-07 to present. |
| 6 | Modified | datetime | NO | GETDATE() | CODE-BACKED | UTC timestamp of the last status change. Updated by WithdrawUpdate on every state transition in the pipeline. |
| 7 | StatusID | int | NO | - | CODE-BACKED | High-level withdrawal lifecycle state: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Cancelled. See [Withdraw Status](../../_glossary.md#withdraw-status). (Dictionary.WithdrawStatuses). ~96% reach Success. |
| 8 | StatusReasonID | int | NO | - | CODE-BACKED | Detailed pipeline step: 1=Created, 3=HoldInitiated, 4=HoldApproved, 6=AuthorizeInitiated, 7=AuthorizeApproved, 9=PayoutInitiated, 10=PayoutApproved, 12=AbortInitiated, 13=AbortCompleted, 15=RiskManualReview. See [Withdraw Status Reason](../../_glossary.md#withdraw-status-reason). (Dictionary.WithdrawStatusReasons). |
| 9 | ReferenceID | nvarchar(500) | YES | - | CODE-BACKED | External reference identifier from the calling system. Used for cross-system correlation and idempotency checks. |
| 10 | PaymentMethodID | nvarchar(200) | YES | - | CODE-BACKED | UUID identifying the payment method/instrument used for the withdrawal (e.g., specific bank card, IBAN endpoint). Provider-assigned identifier. |
| 11 | Amount | money | NO | - | CODE-BACKED | Withdrawal amount in the currency specified by CurrencyID. This is the user-facing amount in their local currency. |
| 12 | CurrencyID | int | NO | - | CODE-BACKED | Currency of the withdrawal amount. Maps to an external currency reference. Common values: 2, 3 observed. Used with ExchangeRate to compute AmountInUsd. |
| 13 | ApprovalID | int | YES | - | CODE-BACKED | External approval/authorization reference from the compliance or payment gateway system. Populated for both successful and failed withdrawals. |
| 14 | ExtID | nvarchar(200) | YES | - | CODE-BACKED | External transaction identifier from the payment provider. Used for reconciliation and tracking the withdrawal on the provider side. |
| 15 | CorrelationID | varchar(200) | YES | - | CODE-BACKED | Distributed tracing correlation ID linking this withdrawal across microservice calls for end-to-end request tracking. |
| 16 | ExtraData | nvarchar(4000) | YES | - | CODE-BACKED | JSON blob for extensible metadata that varies by flow or payment method. Schema is not fixed - used for provider-specific data. |
| 17 | ManagerID | int | YES | - | CODE-BACKED | ID of the back-office manager who took action on this withdrawal (approval, cancellation, manual review decision). NULL for automated flows (majority of cases). |
| 18 | Comments | varchar(200) | YES | - | CODE-BACKED | Free-text comments from back-office staff when manually intervening in the withdrawal. NULL for automated flows. |
| 19 | Trace | (computed) | - | - | CODE-BACKED | Computed: `CONCAT('{"HostName": "',HOST_NAME(),...})`. Non-persisted JSON audit trail capturing the SQL Server session context (hostname, app name, login, SPID, database, procedure) at the time of the last modification. Used for debugging which service/process modified the row. |
| 20 | ValidFrom | datetime2(7) | NO | (system-managed) | CODE-BACKED | System-versioning start timestamp. Marks when this row version became the current version. Auto-managed by SQL Server temporal tables. |
| 21 | ValidTo | datetime2(7) | NO | (system-managed) | CODE-BACKED | System-versioning end timestamp. Set to 9999-12-31 for the current version. When the row is updated, the old version moves to History.MoneyBusWithdrawals with the actual end time. |
| 22 | ExchangeRate | decimal(16,8) | YES | - | CODE-BACKED | Exchange rate applied to convert the withdrawal Amount to USD at the time of processing. Set by WithdrawUpdate during the payout step. |
| 23 | AmountInUsd | money | YES | - | CODE-BACKED | USD-equivalent of the withdrawal Amount, calculated as Amount * ExchangeRate. Used for normalized reporting and compliance thresholds. |
| 24 | StatusReasonDescription | nvarchar(4000) | YES | - | CODE-BACKED | Human-readable description of the current status reason. For risk review (StatusReasonID=15), contains structured JSON with failed rule details (rule names, alert types). For aborted withdrawals, contains "Withdraw cancel request initiated by {source} with comments: {text}". |
| 25 | ErrorDescription | nvarchar(4000) | YES | - | CODE-BACKED | Error message from the payment provider or system. Common values: "Account suspended", "Account limit has been reached". NULL for successful withdrawals. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AccountTypeID | Dictionary.AccountTypes | Implicit Lookup | Type of account the withdrawal is from (currently 100% IBAN) |
| StatusID | Dictionary.WithdrawStatuses | Implicit Lookup | High-level lifecycle state of the withdrawal |
| StatusReasonID | Dictionary.WithdrawStatusReasons | Implicit Lookup | Detailed pipeline step within the lifecycle |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MoneyBus.WithdrawCancelRequest | WithdrawID | Implicit FK | Links a cancellation request to the withdrawal being cancelled |
| MoneyBus.WithdrawContainers | WithdrawID | Implicit FK | Links container/metadata blobs to the parent withdrawal |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.WithdrawCancelRequest | Table | WithdrawID references Withdrawals.ID |
| MoneyBus.WithdrawContainers | Table | WithdrawID references Withdrawals.ID |
| MoneyBus.WithdrawAdd | Stored Procedure | Writer - creates initial withdrawal record |
| MoneyBus.WithdrawGet | Stored Procedure | Reader - retrieves single withdrawal by ID |
| MoneyBus.WithdrawGetList | Stored Procedure | Reader - retrieves multiple withdrawals by ID list |
| MoneyBus.WithdrawGetListV2 | Stored Procedure | Reader - paginated/filtered withdrawal retrieval |
| MoneyBus.WithdrawUpdate | Stored Procedure | Modifier - updates status, amounts, and error details |
| History.MoneyBusWithdrawals | Table | System-versioning history table - receives old row versions on UPDATE |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Withdrawals | CLUSTERED PK | ID ASC | - | - | Active (DATA_COMPRESSION=PAGE) |
| IX_Withdrawals_Created | NONCLUSTERED | Created ASC | - | - | Active |
| IX_Withdrawals_GCID | NONCLUSTERED | GCID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Withdrawals | PRIMARY KEY | Clustered on ID with PAGE compression for storage efficiency |
| DF_Withdrawals_Created | DEFAULT | GETDATE() for Created - auto-timestamps on insert |
| DF_Withdrawals_Modified | DEFAULT | GETDATE() for Modified - auto-timestamps, updated by procedure |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.MoneyBusWithdrawals - preserves all historical state changes |

---

## 8. Sample Queries

### 8.1 Get withdrawal with all status details resolved
```sql
SELECT w.ID, w.GCID, w.Amount, w.CurrencyID, w.AmountInUsd,
       ws.Name AS Status, wsr.Name AS StatusReason,
       at.Name AS AccountType,
       w.StatusReasonDescription, w.ErrorDescription
FROM MoneyBus.Withdrawals w WITH (NOLOCK)
JOIN Dictionary.WithdrawStatuses ws WITH (NOLOCK) ON ws.ID = w.StatusID
JOIN Dictionary.WithdrawStatusReasons wsr WITH (NOLOCK) ON wsr.ID = w.StatusReasonID
JOIN Dictionary.AccountTypes at WITH (NOLOCK) ON at.ID = w.AccountTypeID
WHERE w.ID = @WithdrawID;
```

### 8.2 Find all withdrawals stuck in risk review
```sql
SELECT w.ID, w.GCID, w.Amount, w.CurrencyID, w.Created, w.StatusReasonDescription
FROM MoneyBus.Withdrawals w WITH (NOLOCK)
WHERE w.StatusID = 1 AND w.StatusReasonID = 15
ORDER BY w.Created ASC;
```

### 8.3 View withdrawal history (all state changes) using temporal query
```sql
SELECT ID, StatusID, StatusReasonID, Modified, ValidFrom, ValidTo
FROM MoneyBus.Withdrawals
FOR SYSTEM_TIME ALL
WHERE ID = @WithdrawID
ORDER BY ValidFrom;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 25 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.Withdrawals | Type: Table | Source: MoneyBusDB/MoneyBus/Tables/MoneyBus.Withdrawals.sql*
