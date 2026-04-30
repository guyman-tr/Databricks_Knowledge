# MoneyBus Schema Overview

> The MoneyBus schema is the core payment processing engine for the MoneyBus platform, handling all money transfer transactions and withdrawal operations across multiple account types (Trading, Options, IBAN, MoneyFarm).

---

## Schema Summary

| Metric | Value |
|--------|-------|
| **Database** | MoneyBusDB |
| **Schema** | MoneyBus |
| **Total Objects** | 36 |
| **Tables** | 7 |
| **Views** | 0 |
| **Functions** | 0 |
| **Stored Procedures** | 27 |
| **User Defined Types** | 2 |
| **Documentation Sessions** | 2 (Batch 1: 25 objects, Batch 2: 11 objects) |
| **Average Quality** | 8.4/10 |
| **Completed** | 2026-04-15 |

---

## Business Domain

The MoneyBus schema manages two primary financial workflows:

### 1. Transaction Pipeline (Hold -> Debit -> Credit)

Processes fund transfers between account types. Used for trading position opens/closes, internal transfers, and deposits/withdrawals.

**Core objects**: `Transactions`, `TransactionsGroup`, `Containers`

**Flow**:
```
Application Request
    |
    v
TransactionsAndGroupAdd / TransactionsGroupAdd + TransactionAdd
    |
    v
ContainerUpsert (persist SAGA state)
    |
    v
Hold -> Debit -> Credit (via TransactionUpdate at each step)
    |
    v
Success / Decline / Technical / Canceled
    |
    v
ContainerDelete (cleanup)
```

**Key characteristics**:
- ~7.7M transactions, active since 2023
- Partitioned across 100 buckets (ID % 100) for performance
- System-versioned with History.MoneyBusTransactions
- ~98% success rate
- Supports cross-currency with exchange rate tracking on both creditor and debitor sides
- ExtraData JSON carries rich trading context (instrument, units, leverage, action)

### 2. Withdrawal Pipeline (Hold -> Authorize -> Payout)

Processes user withdrawal requests from platform accounts to external destinations (currently 100% IBAN).

**Core objects**: `Withdrawals`, `WithdrawContainers`, `WithdrawCancelRequest`

**Flow**:
```
WithdrawAdd (create request)
    |
    v
WithdrawContainerUpsert (persist SAGA state)
    |
    v
Hold -> Authorize -> Payout (via WithdrawUpdate at each step)
    |                             |
    v                             v
RiskManualReview (gate)    PayoutApproved = Success
    |                             |
    v                             v
[Manual decision]          WithdrawContainerDelete (cleanup)
    |
    v
AbortInitiated -> AbortCompleted (via WithdrawCancelRequestAdd)
```

**Key characteristics**:
- ~773K withdrawals, active since 2025-07
- System-versioned with History.MoneyBusWithdrawals
- ~96% success rate, ~4% aborted
- Risk review gate (StatusReasonID=15) for compliance flagging
- Exchange rate and USD-equivalent tracked for reporting

---

## Architecture Patterns

### SAGA Orchestration via Container Tables

Both pipelines use a SAGA pattern where execution state is persisted in container tables (`Containers` for transactions, `WithdrawContainers` for withdrawals). The ContainerData JSON stores the full execution context, enabling the service to resume from any step after interruption.

**Container lifecycle**: Upsert (create/update) -> Get (read for resumption) -> Delete (cleanup after terminal state)

### Selective Update Pattern (ISNULL)

Both `TransactionUpdate` and `WithdrawUpdate` use `SET Col = ISNULL(@Param, Col)` so that only non-NULL parameters modify their columns. This enables incremental state updates where each pipeline step only changes its relevant fields.

### Partition Elimination

`Transactions` uses `PartitionCol = ID % 100` (persisted computed column) with the PS_Transactions partition scheme. The `TransactionGet` and `TransactionUpdate` procedures include `AND PartitionCol = @ID % 100` for single-partition access.

### Idempotency via Unique Constraints

- `TransactionsGroup`: UNIQUE on (GCID, ReferenceID) prevents duplicate groups
- `WithdrawCancelRequest`: UNIQUE on WithdrawID prevents duplicate cancellation requests

---

## Object Inventory

### Tables (7)

| Table | Purpose | Rows | Key Relationships |
|-------|---------|------|-------------------|
| Transactions | Core ledger of all fund movements | ~7.7M | -> TransactionsGroup, <- Containers |
| TransactionsGroup | Groups related transaction legs | ~7.7M | <- Transactions |
| Withdrawals | Withdrawal requests and lifecycle | ~773K | <- WithdrawCancelRequest, <- WithdrawContainers |
| Containers | Transaction SAGA state | Large | -> Transactions |
| WithdrawContainers | Withdrawal SAGA state | ~40K | -> Withdrawals |
| WithdrawCancelRequest | Withdrawal cancellation audit | ~37K | -> Withdrawals |
| TransferLimits | Min/max amount configuration | 8 | Config table, no FK deps |

### User Defined Types (2)

| Type | Purpose | Used By |
|------|---------|---------|
| IDs | Batch ID list parameter | WithdrawGetList, WithdrawGetListV2 |
| TransactionsTable_New | Batch transaction insert parameter | TransactionsAndGroupAdd |

### Stored Procedures (27)

**Transaction CRUD**: TransactionAdd, TransactionGet, TransactionUpdate, TransactionsGetByParams, UserTransactionsGet, TransactionsAndGroupAdd, TransactionsGroupAdd, TransactionsGroupGet

**Transaction Support**: ContainerDelete, ContainerGet, ContainerUpsert, TransactionLogGet, TransactionLogInsert, TransactionStepAdd, TransactionStatusReasonsGet, TransferLimitsGet

**Withdrawal CRUD**: WithdrawAdd, WithdrawGet, WithdrawGetList, WithdrawGetListV2, WithdrawUpdate

**Withdrawal Support**: WithdrawContainerDelete, WithdrawContainerGet, WithdrawContainerUpsert, WithdrawCancelRequestAdd, WithdrawCancelRequestGet

**Monitoring**: ALERT_ConsecutiveTransactionFailuresAlert

---

## Cross-Schema Dependencies

| Schema | Tables Used | Purpose |
|--------|------------|---------|
| Dictionary | AccountTypes, TransactionStatuses, TransactionStatusReasons, WithdrawStatuses, WithdrawStatusReasons, WithdrawCancellationSources | Lookup/enum values for all status and type columns |
| History | MoneyBusTransactions, MoneyBusWithdrawals, TransactionsLog | System-versioning history + API call logging |
| Log | TransactionStep | Pipeline step execution logging |

---

## Glossary Terms

All lookup values are documented in [Business Glossary](../_glossary.md):
- [Account Type](../_glossary.md#account-type) - 4 values (Trading, Options, IBAN, MoneyFarm)
- [Transaction Status](../_glossary.md#transaction-status) - 5 values (InProcess, Success, Decline, Technical, Canceled)
- [Transaction Status Reason](../_glossary.md#transaction-status-reason) - 15 values (Created through ReconciliationAborted)
- [Withdraw Status](../_glossary.md#withdraw-status) - 5 values (InProcess, Success, Decline, Technical, Cancelled)
- [Withdraw Status Reason](../_glossary.md#withdraw-status-reason) - 15 values (Created through RiskManualReview)
- [Withdraw Cancellation Source](../_glossary.md#withdraw-cancellation-source) - 4 values (None, User, BackOffice, Abort)

---

*Generated: 2026-04-15 | Schema documentation completed in 2 batch sessions*
