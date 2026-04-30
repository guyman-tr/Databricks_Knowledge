# Business Glossary - MoneyTransfer

> Canonical definitions for business terms, value domains, and concepts.
> Object docs reference this glossary for shared terminology.
> Terms are progressively enriched as more objects are documented.

*Last updated: 2026-04-15 | Terms: 2 lookup-backed, 0 concept-based | Sources: 2 Dictionary tables, 0 object docs*

---

## Lookup-Backed Terms

### Post Transfer Status {#post-transfer-status}

**Definition**: Represents the lifecycle state of a post-transfer action - a secondary operation that occurs after the primary money transfer has been initiated. Post-transfer actions may include notifications, reconciliation steps, or follow-up processing.

**Source Table**: `Dictionary.PostTransferStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| *(empty - no rows in table)* | - | Table exists but contains no data. May be reserved for future use or populated in a different environment. |

**Key Characteristics**:
- Identity column (auto-increment) as PK
- Has Name (varchar 50) and optional Description (varchar 100) columns
- Currently empty - no post-transfer statuses defined in this environment
- Referenced by `Billing.PostTransferActions.PostTransferStatusID`
- Managed via `Billing.CreatePostTransfer` and `Billing.UpdatePostTransferStatus`
- MIMO service account has SELECT access (external monitoring/reporting)

**Used By**: Billing.PostTransferActions, Billing.CreatePostTransfer, Billing.UpdatePostTransferStatus, Billing.GetPostTransfer

---

### Transfer Status {#transfer-status}

**Definition**: Represents the lifecycle state of a money transfer transaction. Tracks the progression of a transfer from initial creation through processing to final resolution (success, failure, or cancellation).

**Source Table**: `Dictionary.TransferStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | New | Transfer record has been created but no processing has begun. Initial state upon creation. |
| 1 | Init | Transfer initialization has started - preliminary validation and setup steps are underway. |
| 2 | Pending | Transfer has been validated and is awaiting processing or external confirmation. |
| 4 | Technical | Transfer encountered a technical issue (infrastructure, connectivity, or system error) distinct from a business-logic failure. |
| 7 | Cancel | Transfer has been cancelled - either by user request or system rule before completion. |
| 8 | Fail | Transfer processing completed with a failure - the funds were not successfully moved. |
| 9 | Sent | Transfer has been dispatched to the destination system/provider. Awaiting confirmation of receipt. |
| 10 | Received | Transfer has been confirmed as received at the destination. Terminal success state. |

**Key Characteristics**:
- Identity column (auto-increment) as PK
- ID gaps exist (3, 5, 6 are missing) - likely deprecated or removed statuses
- Lifecycle flow: New(0) -> Init(1) -> Pending(2) -> Sent(9) -> Received(10)
- Failure branches: Technical(4), Cancel(7), Fail(8) can occur from intermediate states
- Terminal states: Received(10) for success; Fail(8) and Cancel(7) for unsuccessful outcomes
- Success statuses: Sent(9) and Received(10) - used in `WHERE TransferStatusID IN (9,10)` for success queries
- Received(10) is the definitive success check - `Billing.GetDepotIdOfLastSuccessfulTransferByCid` uses `TransferStatusID = 10`
- `Billing.UpdateTransferStatus` prevents overwriting Received(10) status - idempotency guard
- Indexed in `Billing.Transfers` alongside CurrencyID for query performance
- MIMO service account has SELECT access (external monitoring/reporting)

**Used By**: Billing.Transfers, History.Transfers, Billing.UpdateTransferStatus, Billing.CreateTransfer, Billing.GetDepotIdOfLastSuccessfulTransferByCid, Billing.GetLastDepotIdForTransferStatusesByCid, Billing.GetLastSuccessTransferDataByCid, Billing.GetTransferByExReference, Billing.GetTransferByReferenceID, Billing.GetTransfersByCID, Monitoring.GetLastTransfersStatusesInPercentage

---

## Business Concepts

*(No concept-based terms yet - will be populated as objects are documented)*
