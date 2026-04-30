# Business Glossary - MoneyBusDB

> Canonical definitions for business terms, value domains, and concepts.
> Object docs reference this glossary for shared terminology.
> Terms are progressively enriched as more objects are documented.

*Last updated: 2026-04-15 | Terms: 6 lookup-backed, 0 concept-based | Sources: 6 Dictionary tables, 36 object docs*

---

## Lookup-Backed Terms

### Account Type {#account-type}

**Definition**: Classifies the type of financial account involved in a money transfer transaction. Each side of a transfer (creditor/debitor) has an account type that determines the product context and applicable business rules for the movement of funds.

**Source Table**: `Dictionary.AccountTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Trading | Standard trading account used for equity/CFD positions and related fund movements |
| 2 | Options | Options trading account for options-specific fund flows and margin operations |
| 3 | IBAN | IBAN-based bank account used for external deposit/withdrawal operations via SEPA or wire transfers |
| 4 | MoneyFarm | Managed portfolio (robo-advisor) account for automated investment fund flows |

**Key Characteristics**:
- Referenced by both creditor and debitor sides of transactions (CreditorTypeID, DebitorTypeID)
- Also used in withdrawal requests (AccountTypeID) and transfer limits (DebitAccountTypeID, CreditAccountTypeID)
- Transaction group initiators also carry an account type (InitiatorAccountTypeId)

**Used By**: Dictionary.AccountTypes, MoneyBus.Transactions, MoneyBus.TransferLimits, MoneyBus.TransactionsGroup, MoneyBus.Withdrawals, History.MoneyBusWithdrawals, MoneyBus.ALERT_ConsecutiveTransactionFailuresAlert

---

### Transaction Status {#transaction-status}

**Definition**: Top-level lifecycle state of a money transfer transaction. Represents the high-level outcome category that groups multiple detailed sub-reasons. Every transaction progresses through InProcess and terminates in one of the final states.

**Source Table**: `Dictionary.TransactionStatuses`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | InProcess | Transaction is actively being processed - funds are moving through hold/debit/credit steps but have not reached a terminal state |
| 2 | Success | Transaction completed successfully - all fund movements (hold, debit, credit) finished without error |
| 3 | Decline | Transaction was declined by the payment provider or internal validation - funds were not moved or were reversed |
| 4 | Technical | Transaction failed due to a technical/system error (timeout, connectivity, unexpected exception) rather than a business rule decline |
| 5 | Canceled | Transaction was explicitly canceled - either by user action, backoffice intervention, or an abort workflow |

**Key Characteristics**:
- Terminal states: Success (2), Decline (3), Technical (4), Canceled (5)
- Non-terminal state: InProcess (1) - transaction is still in flight
- Parent status for TransactionStatusReasons which provide granular sub-states

**Used By**: MoneyBus.Transactions, Dictionary.TransactionStatusReasons, MoneyBus.ALERT_ConsecutiveTransactionFailuresAlert

---

### Transaction Status Reason {#transaction-status-reason}

**Definition**: Granular sub-state within a transaction's lifecycle, providing the specific step or outcome detail. Each reason maps to exactly one parent TransactionStatus, enabling fine-grained tracking of where a transaction is in the hold-debit-credit pipeline or why it reached its terminal state.

**Source Table**: `Dictionary.TransactionStatusReasons`

**Values**:

| ID | Name | TransactionStatusID | Business Meaning |
|----|------|---------------------|-----------------|
| 1 | Created | 1 (InProcess) | Transaction record created, processing not yet started |
| 2 | Success | 2 (Success) | All steps completed successfully - terminal success state |
| 3 | Held | 1 (InProcess) | Funds successfully placed on hold in the source account |
| 4 | Credited | 1 (InProcess) | Funds successfully credited to the destination account |
| 5 | Debited | 1 (InProcess) | Funds successfully debited from the source account |
| 6 | HoldDecline | 3 (Decline) | Hold step was declined by the provider - insufficient funds or account restriction |
| 7 | CreditDecline | 1 (InProcess) | Credit step failed but transaction remains in-process for retry or reversal |
| 8 | DebitDecline | 1 (InProcess) | Debit step failed but transaction remains in-process for retry or reversal |
| 9 | ValidateDecline | 3 (Decline) | Pre-execution validation failed - transaction rejected before any fund movement |
| 10 | Technical | 4 (Technical) | System/technical failure during processing |
| 11 | DebitInitiated | 1 (InProcess) | Debit operation sent to provider, awaiting confirmation |
| 12 | HoldInitiated | 1 (InProcess) | Hold operation sent to provider, awaiting confirmation |
| 13 | CreditInitiated | 1 (InProcess) | Credit operation sent to provider, awaiting confirmation |
| 14 | HoldCanceled | 5 (Canceled) | Previously held funds released due to cancellation |
| 15 | ReconciliationAborted | 5 (Canceled) | Transaction aborted during reconciliation - typically a stale or orphaned transaction cleaned up by automated processes |

**Key Characteristics**:
- Follows a pipeline pattern: Created -> HoldInitiated -> Held -> DebitInitiated -> Debited -> CreditInitiated -> Credited -> Success
- Decline sub-reasons (CreditDecline=7, DebitDecline=8) map to InProcess (not Decline) because the transaction may still be recoverable
- HoldDecline (6) and ValidateDecline (9) map to terminal Decline because recovery is not possible

**Used By**: MoneyBus.Transactions (StatusReasonID)

---

### Withdraw Cancellation Source {#withdraw-cancellation-source}

**Definition**: Identifies who or what initiated the cancellation of a withdrawal request. Used to distinguish user-initiated cancellations from system or backoffice-driven ones for audit and reporting purposes.

**Source Table**: `Dictionary.WithdrawCancellationSources`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | No cancellation - default value when the withdrawal has not been canceled |
| 1 | User | Cancellation initiated by the end user through the platform UI or API |
| 2 | BackOffice | Cancellation initiated by backoffice/operations staff via admin tools |
| 3 | Abort | Cancellation triggered by the system's automated abort workflow (e.g., failed payout reversal) |

**Key Characteristics**:
- ID 0 (None) serves as the default/null-safe value for non-canceled withdrawals
- Unique constraint on Name column ensures no duplicate source labels

**Used By**: MoneyBus.WithdrawCancelRequest

---

### Withdraw Status {#withdraw-status}

**Definition**: Top-level lifecycle state of a withdrawal request. Mirrors the transaction status pattern but is specific to the withdrawal workflow which includes hold, authorize, and payout steps before funds leave the platform.

**Source Table**: `Dictionary.WithdrawStatuses`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | InProcess | Withdrawal is actively being processed through the hold-authorize-payout pipeline |
| 2 | Success | Withdrawal completed successfully - funds have been paid out to the user |
| 3 | Decline | Withdrawal was declined at one of the processing steps (hold, authorize, or payout) |
| 4 | Technical | Withdrawal failed due to a technical/system error |
| 5 | Cancelled | Withdrawal was explicitly cancelled by user, backoffice, or abort workflow |

**Key Characteristics**:
- Terminal states: Success (2), Decline (3), Technical (4), Cancelled (5)
- Non-terminal state: InProcess (1)
- Note spelling difference: "Cancelled" (double-l) vs Transaction Status "Canceled" (single-l)
- Parent status for WithdrawStatusReasons which provide step-level detail

**Used By**: MoneyBus.Withdrawals, Dictionary.WithdrawStatusReasons

---

### Withdraw Status Reason {#withdraw-status-reason}

**Definition**: Granular sub-state within a withdrawal's lifecycle, tracking the specific step in the hold-authorize-payout pipeline. Each reason maps to exactly one parent WithdrawStatus. The withdrawal pipeline is more complex than the transaction pipeline because it adds an authorization step and risk review gate.

**Source Table**: `Dictionary.WithdrawStatusReasons`

**Values**:

| ID | Name | WithdrawStatusID | Business Meaning |
|----|------|------------------|-----------------|
| 1 | Created | 1 (InProcess) | Withdrawal request created, processing not yet started |
| 2 | Success | 2 (Success) | Withdrawal completed successfully - terminal success |
| 3 | HoldInitiated | 1 (InProcess) | Hold operation sent to freeze funds in the user's account |
| 4 | HoldApproved | 1 (InProcess) | Funds successfully frozen/held in the user's account |
| 5 | HoldDeclined | 3 (Decline) | Hold failed - insufficient funds or account restriction |
| 6 | AuthorizeInitiated | 1 (InProcess) | Authorization request sent to payment provider |
| 7 | AuthorizeApproved | 1 (InProcess) | Payment provider approved the withdrawal authorization |
| 8 | AuthorizeDeclined | 1 (InProcess) | Authorization declined but withdrawal remains in-process for retry or alternative routing |
| 9 | PayoutInitiated | 1 (InProcess) | Payout instruction sent to payment provider to transfer funds externally |
| 10 | PayoutApproved | 2 (Success) | Payout confirmed by provider - funds sent to user. Maps to terminal Success |
| 11 | PayoutDeclined | 1 (InProcess) | Payout declined by provider but withdrawal remains in-process for retry |
| 12 | AbortInitiated | 1 (InProcess) | Abort/reversal process started to release held funds |
| 13 | AbortCompleted | 5 (Cancelled) | Abort completed - held funds released back to user's account |
| 14 | AbortFailed | 1 (InProcess) | Abort attempt failed - requires manual intervention |
| 15 | RiskManualReview | 1 (InProcess) | Withdrawal flagged by risk engine and queued for manual compliance/fraud review |

**Key Characteristics**:
- Pipeline pattern: Created -> HoldInitiated -> HoldApproved -> AuthorizeInitiated -> AuthorizeApproved -> PayoutInitiated -> PayoutApproved -> Success
- RiskManualReview (15) is a gating state that pauses the pipeline until compliance clears the withdrawal
- AbortFailed (14) maps to InProcess (not a terminal state) because manual intervention is still expected
- PayoutApproved (10) is the only reason that maps directly to Success (2), confirming funds left the platform

**Used By**: MoneyBus.Withdrawals (StatusReasonID), Dictionary.WithdrawStatusReasonGet

---

## Business Concepts

*No concept-based terms yet. Will be populated as MoneyBus schema objects are documented.*
