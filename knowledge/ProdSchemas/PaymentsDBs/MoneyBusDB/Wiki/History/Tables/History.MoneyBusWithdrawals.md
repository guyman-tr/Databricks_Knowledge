# History.MoneyBusWithdrawals

> System-versioned temporal history table that preserves every prior state of withdrawal requests, automatically maintained by SQL Server when rows in MoneyBus.Withdrawals are updated.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | ID (bigint) - matches MoneyBus.Withdrawals.ID; not unique here as each withdrawal ID can have many historical versions |
| **Partition** | No |
| **Indexes** | 1 active (clustered on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.MoneyBusWithdrawals is the temporal history archive for the MoneyBus withdrawal system. Every time a withdrawal request in `MoneyBus.Withdrawals` is updated (e.g., status advances through the hold-authorize-payout pipeline, or exchange rates are populated), SQL Server automatically copies the old row version into this table before applying the update. Each row represents a prior state of a withdrawal at a specific point in time, bounded by the ValidFrom/ValidTo window.

This table exists because the withdrawal pipeline involves multiple state transitions that are critical for audit and compliance. A single withdrawal passes through Created, HoldInitiated, HoldApproved, AuthorizeInitiated, AuthorizeApproved, PayoutInitiated, and finally PayoutApproved/Success. Alternatively, withdrawals may be declined at any step or flagged for RiskManualReview. Without temporal history, the system would lose visibility into when each step occurred, when exchange rates were set, and what error descriptions were associated with failed steps.

Data flows into this table automatically via SQL Server's `SYSTEM_VERSIONING` mechanism on `MoneyBus.Withdrawals`. The `MoneyBusWithdrawExecuter` application service calls `MoneyBus.WithdrawUpdate` to advance the withdrawal through each pipeline step, and each UPDATE triggers a history row. No stored procedure or application code writes to this table directly. The Trace column reveals that virtually all updates originate from the `WithdrawUpdate` stored procedure called by the `MoneyBusWithdrawExecuter` Kubernetes pod.

---

## 2. Business Logic

### 2.1 Withdrawal Pipeline Audit Trail

**What**: Each withdrawal accumulates multiple historical rows as it progresses through the hold-authorize-payout pipeline, creating a complete audit trail of every state transition.

**Columns/Parameters Involved**: `ID`, `StatusID`, `StatusReasonID`, `ValidFrom`, `ValidTo`, `ExchangeRate`, `AmountInUsd`

**Rules**:
- A single withdrawal ID appears multiple times - once for each state transition
- The StatusReasonID progression for a successful withdrawal: 1 (Created) -> 3 (HoldInitiated) -> 4 (HoldApproved) -> 6 (AuthorizeInitiated) -> 7 (AuthorizeApproved) -> 9 (PayoutInitiated) -> 10 (PayoutApproved/Success)
- ExchangeRate and AmountInUsd are populated during early processing (typically between Created and HoldInitiated states) - history rows before that point have NULL values
- Decline paths terminate early: 5 (HoldDeclined) or 15 (RiskManualReview) pause or end the pipeline
- Abort paths: 12 (AbortInitiated) -> 13 (AbortCompleted) or 14 (AbortFailed)

**Diagram**:
```
Withdrawal ID 4 - Historical State Progression:
[Created]          ValidFrom=12:27:51 -> ValidTo=12:27:51  (<1 sec)
    |
[Created+ExchRate] ValidFrom=12:27:51 -> ValidTo=12:27:52  (1 sec, ExchangeRate populated)
    |
[HoldInitiated]    ValidFrom=12:27:52 -> ValidTo=13:30:57  (~63 min wait for hold)
    |
[HoldApproved]     ValidFrom=13:30:57 -> ValidTo=13:30:58  (<1 sec, ExtraData updated with extWithdrawId)
    v
(Continues in live table through Authorize -> Payout -> Success)
```

### 2.2 Currency Conversion Tracking

**What**: Withdrawals track exchange rate and USD-equivalent amount to support multi-currency payouts. These values are populated asynchronously after creation.

**Columns/Parameters Involved**: `CurrencyID`, `ExchangeRate`, `AmountInUsd`, `Amount`

**Rules**:
- Amount is the withdrawal amount in the local currency (CurrencyID)
- ExchangeRate is the conversion rate to USD at the time of processing
- AmountInUsd = Amount * ExchangeRate (the USD equivalent, used for reporting and limits)
- These values are set during an early UPDATE (before HoldInitiated), so the first history row always has NULL exchange rate/USD amount
- Historical rows preserve the exchange rate at each point in time, which is important if exchange rates fluctuate during a long-running withdrawal

---

## 3. Data Overview

| ID | GCID | StatusReasonID | Amount | CurrencyID | ExchangeRate | AmountInUsd | Meaning |
|----|------|----------------|--------|------------|--------------|-------------|---------|
| 1 | 36911954 | 1 | 50 | 3 | NULL | NULL | Initial creation snapshot of a 50-unit withdrawal before exchange rate was set - shows the first state captured before any processing |
| 2 | 30468476 | 1 | 0.1 | 2 | 1.17486 | 0.11 | Second version of withdrawal #2 - exchange rate has been populated (1.17486) and AmountInUsd calculated (0.11), still in Created status before hold step |
| 3 | 30468476 | 3 | 0.3 | 2 | 1.17295 | 0.35 | Withdrawal #3 after HoldInitiated (StatusReasonID=3) - hold operation has been sent to freeze funds in the user's account |
| 4 | 30468476 | 4 | 0.6 | 2 | 1.17158 | 0.7 | Withdrawal #4 after HoldApproved (StatusReasonID=4) - funds frozen successfully, ExtraData updated with extWithdrawId from external provider |
| 4 | 30468476 | 1 | 0.6 | 2 | NULL | NULL | Initial creation of withdrawal #4 - earliest version before any processing, no exchange rate yet |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | - | CODE-BACKED | Withdrawal request identifier, matching the IDENTITY PK of MoneyBus.Withdrawals. Not unique in this history table - each update to the live withdrawal creates an additional history row with the same ID. |
| 2 | GCID | bigint | NO | - | CODE-BACKED | Global Customer ID - identifies the customer who initiated the withdrawal request. Required parameter in MoneyBus.WithdrawAdd. |
| 3 | AccountID | nvarchar(200) | YES | - | CODE-BACKED | Target account identifier for the withdrawal destination. Stored as a GUID string identifying the external payment account (e.g., bank account) where funds will be sent. |
| 4 | AccountTypeID | int | NO | - | VERIFIED | Account type for the withdrawal: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. Overwhelmingly IBAN (3) as withdrawals typically go to external bank accounts. See [Account Type](../../_glossary.md#account-type). (Dictionary.AccountTypes) |
| 5 | Created | datetime | NO | - | CODE-BACKED | Timestamp when the withdrawal request was originally created. Defaults to GETDATE() via DF_Withdrawals_Created. Immutable after creation. |
| 6 | Modified | datetime | NO | - | CODE-BACKED | Timestamp of the last modification to the live withdrawal row. Updated on every status change via WithdrawUpdate. Defaults to GETDATE() via DF_Withdrawals_Modified. |
| 7 | StatusID | int | NO | - | VERIFIED | Top-level withdrawal lifecycle state: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Cancelled. In history rows, captures what the status WAS during the ValidFrom-ValidTo window. See [Withdraw Status](../../_glossary.md#withdraw-status). (Dictionary.WithdrawStatuses) |
| 8 | StatusReasonID | int | NO | - | VERIFIED | Granular sub-state within the withdrawal lifecycle: 1=Created, 2=Success, 3=HoldInitiated, 4=HoldApproved, 5=HoldDeclined, 6=AuthorizeInitiated, 7=AuthorizeApproved, 8=AuthorizeDeclined, 9=PayoutInitiated, 10=PayoutApproved, 11=PayoutDeclined, 12=AbortInitiated, 13=AbortCompleted, 14=AbortFailed, 15=RiskManualReview. See [Withdraw Status Reason](../../_glossary.md#withdraw-status-reason). (Dictionary.WithdrawStatusReasons) |
| 9 | ReferenceID | nvarchar(500) | YES | - | CODE-BACKED | External reference identifier (GUID) linking the withdrawal to the originating system or request. Immutable after creation. |
| 10 | PaymentMethodID | nvarchar(200) | YES | - | CODE-BACKED | Identifier (GUID) for the payment method used for the withdrawal - e.g., a specific bank account, e-wallet, or card on file. Determines the payout routing. |
| 11 | Amount | money | NO | - | CODE-BACKED | Withdrawal amount in the currency specified by CurrencyID. Represents the face value the customer requested to withdraw. Immutable after creation. |
| 12 | CurrencyID | int | NO | - | CODE-BACKED | Application-defined currency identifier for the withdrawal denomination. No database-side dictionary table exists. Observed values: 2, 3 in sample data. Currency mapping is maintained in the application layer. |
| 13 | ApprovalID | int | YES | - | NAME-INFERRED | Approval workflow identifier. Likely references an external approval system or internal approval step. NULL when no manual approval is required. |
| 14 | ExtID | nvarchar(200) | YES | - | CODE-BACKED | External system identifier assigned by the payment provider after the withdrawal is submitted. Populated during authorize or payout steps. NULL before provider interaction. |
| 15 | CorrelationID | varchar(200) | YES | - | CODE-BACKED | Distributed tracing correlation identifier (GUID) used to track the withdrawal across microservices. Enables end-to-end request tracing in logs and monitoring. |
| 16 | ExtraData | nvarchar(4000) | YES | - | CODE-BACKED | Free-form JSON payload for extensible withdrawal metadata. Initially empty ("{}"). Updated during processing with provider-specific data such as extWithdrawId and statusCode. |
| 17 | ManagerID | int | YES | - | NAME-INFERRED | Identifier of the manager or backoffice agent involved in the withdrawal. Populated when a withdrawal requires manual intervention, approval, or was initiated by backoffice staff. NULL for automated/user-initiated withdrawals. |
| 18 | Comments | varchar(200) | YES | - | CODE-BACKED | Free-text comments attached to the withdrawal request. Set by the user or backoffice agent at creation time. Used for internal notes or test annotations. |
| 19 | Trace | nvarchar(733) | NO | - | CODE-BACKED | Execution context captured as JSON at the time of the UPDATE on the live table. Contains HostName (K8s pod name), AppName (MoneyBusWithdrawExecuter), SUserName (managed identity), SPID, DBName, and ObjectName (calling procedure, typically WithdrawUpdate). In the live table this is a computed column; in history it is the materialized string. |
| 20 | ValidFrom | datetime2(7) | NO | - | VERIFIED | Start of the temporal validity window for this row version. Marks when this version became the active row in MoneyBus.Withdrawals. |
| 21 | ValidTo | datetime2(7) | NO | - | VERIFIED | End of the temporal validity window for this row version. Marks when this version was superseded by a newer version (the next UPDATE occurred). The clustered index on (ValidTo, ValidFrom) optimizes temporal range queries. |
| 22 | ExchangeRate | decimal(16,8) | YES | - | CODE-BACKED | Currency-to-USD exchange rate at the time of withdrawal processing. Populated during an early UPDATE (between Created and HoldInitiated). NULL in the initial creation state and for pre-exchange-rate history versions. |
| 23 | AmountInUsd | money | YES | - | CODE-BACKED | USD equivalent of the withdrawal amount, calculated as Amount * ExchangeRate. Used for regulatory reporting, limit enforcement, and cross-currency analytics. NULL before exchange rate is set. |
| 24 | StatusReasonDescription | nvarchar(4000) | YES | - | CODE-BACKED | Extended human-readable description of the current status reason. Provides additional context beyond what the StatusReasonID code conveys, especially for decline or error scenarios. |
| 25 | ErrorDescription | nvarchar(4000) | YES | - | CODE-BACKED | Detailed error message when the withdrawal encounters a failure. Populated by the payment provider or internal system when a step (hold, authorize, payout) fails. NULL for successful steps. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ID | MoneyBus.Withdrawals | Temporal History | Each row is a prior version of a withdrawal in the live table |
| AccountTypeID | Dictionary.AccountTypes | Implicit Lookup | Maps to account type name (Trading, Options, IBAN, MoneyFarm) |
| StatusID | Dictionary.WithdrawStatuses | Implicit Lookup | Maps to top-level status name (InProcess, Success, Decline, Technical, Cancelled) |
| StatusReasonID | Dictionary.WithdrawStatusReasons | Implicit Lookup | Maps to granular sub-state name and its parent status |

### 5.2 Referenced By (other objects point to this)

This table is not directly referenced by any views, procedures, or other tables. It is maintained exclusively by SQL Server's temporal versioning mechanism and is queried ad-hoc for audit, reconciliation, and point-in-time analysis.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.MoneyBusWithdrawals (table)
  (no code-level dependencies - leaf node)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Withdrawals | Table | This is the HISTORY_TABLE for MoneyBus.Withdrawals via SYSTEM_VERSIONING. SQL Server writes here automatically on UPDATE. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_MoneyBusWithdrawals | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page-level compression to reduce storage for the large volume of historical rows |

---

## 8. Sample Queries

### 8.1 Retrieve full withdrawal lifecycle history
```sql
SELECT ID, StatusID, StatusReasonID, ExchangeRate, AmountInUsd,
       ExtraData, Modified, ValidFrom, ValidTo
FROM History.MoneyBusWithdrawals WITH (NOLOCK)
WHERE ID = 4
ORDER BY ValidFrom ASC
```

### 8.2 Find withdrawals that were pending risk review at a point in time
```sql
SELECT h.ID, h.GCID, h.Amount, h.CurrencyID, h.AmountInUsd
FROM History.MoneyBusWithdrawals h WITH (NOLOCK)
WHERE h.ValidFrom <= '2025-08-01 12:00:00'
  AND h.ValidTo > '2025-08-01 12:00:00'
  AND h.StatusReasonID = 15  -- RiskManualReview at that moment
```

### 8.3 Join with Dictionary tables for human-readable status progression
```sql
SELECT h.ID, h.GCID,
       ws.Name AS StatusName,
       wsr.Name AS StatusReasonName,
       h.Amount, h.CurrencyID, h.ExchangeRate, h.AmountInUsd,
       h.ValidFrom, h.ValidTo
FROM History.MoneyBusWithdrawals h WITH (NOLOCK)
JOIN Dictionary.WithdrawStatuses ws WITH (NOLOCK) ON h.StatusID = ws.ID
JOIN Dictionary.WithdrawStatusReasons wsr WITH (NOLOCK) ON h.StatusReasonID = wsr.ID
WHERE h.ID = 4
ORDER BY h.ValidFrom ASC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Hold and Release - LLD | Confluence | Documents the hold/release pattern in the withdrawal pipeline (HoldInitiated -> HoldApproved flow) |
| STD Internal Transfer Iban <> Trading | Confluence | Confirms withdrawal flow from Trading accounts to IBAN external accounts |
| Phase 1.5 PRD: MIMO Two Ways In / Two Ways Out | Confluence | Establishes MoneyBus as the MIMO system; withdrawals are the "Money Out" pathway |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.4/10 (Elements: 9.2/10, Logic: 7.0/10, Relationships: 7.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 3 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.MoneyBusWithdrawals | Type: Table (Temporal History) | Source: MoneyBusDB/History/Tables/History.MoneyBusWithdrawals.sql*
