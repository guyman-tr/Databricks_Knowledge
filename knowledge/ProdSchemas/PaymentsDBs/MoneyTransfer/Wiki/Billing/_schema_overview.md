# Billing Schema Overview - MoneyTransfer Database

> The Billing schema manages the complete lifecycle of money transfers between funding sources (bank accounts, trading accounts), from initial creation through multi-step pipeline processing to terminal resolution.

*Generated: 2026-04-15 | Objects: 23 (3 tables, 20 stored procedures) + 2 cross-schema Dictionary lookups*

---

## 1. Schema Purpose

The Billing schema is the transactional core of the MoneyTransfer database. It records every money transfer between a customer's bank account (IBAN) and their eToro Trading account, tracking the transfer through a multi-step processing pipeline orchestrated by the MoneyBus payment system.

The schema follows a **hub-and-spoke architecture**: the central `Billing.Transfers` table stores the transfer record, and a collection of single-purpose stored procedures incrementally populate and update specific fields as the transfer progresses through the pipeline.

---

## 2. Key Tables

### Billing.Transfers (Hub Table)
The central table storing all transfer records. Each row represents a single fund movement between origin and destination funding sources. Key characteristics:
- **~4.88M rows** (active production data as of 2026-04-15)
- **System-versioned** with `History.Transfers` for full audit trail
- **ReferenceID** (GUID) is the UNIQUE CLUSTERED index and primary business key
- **TransferID** (int IDENTITY) is the NONCLUSTERED PK
- **Dynamic Data Masking** on OriginFundingData and DestinationFundingData (PII protection)
- **Trigger** `TR_Transfers_ModificationDate` auto-updates ModificationDate on every UPDATE

### Billing.PostTransferActions (Satellite Table)
Stores follow-up actions triggered after a primary transfer is initiated. Decoupled from the main transfer lifecycle:
- **~2.59M rows**
- Linked to parent transfer via TransferID (implicit FK)
- Independent status lifecycle (PostTransferStatusID: 1=in-progress, 2=completed)
- Payload contains masked PII

### Billing.UpgradeScript (Utility Table)
Schema migration tracking table. 6 rows from May 2022, recording the initial schema setup scripts. No longer actively used (SSDT CI/CD pipeline handles deployments).

---

## 3. Transfer Lifecycle

```
                        CreateTransfer (INSERT, Status=0)
                               |
                               v
  [SaveRoutingInfo]       New(0) --> Init(1) --> Pending(2) --> Sent(9) --> Received(10)
  [SaveTransferOrigin]       |           |            |                      [TERMINAL]
  [SaveTransferDestination]  |           +--> Cancel(7)
  [Save*FundingId]           |           |            |
  [SaveExtRefId]             |           |            +--> Technical(4)
  [SaveExtTransactionId]     |           |
                             |           +--> Fail(8)
                             |
                        [UpdateTransferStatus advances state]
                        [ModificationDate auto-updated by trigger]
                        [History.Transfers captures every change]

  After transfer reaches processing state:
  [CreatePostTransfer] --> PostTransferAction(Status=1) --> [UpdatePostTransferStatus] --> Status=2
                           [UpdatePostTransferPayload]        (completed)
```

### Status Definitions (Dictionary.TransferStatus)

| ID | Name | Type | Description |
|----|------|------|-------------|
| 0 | New | Entry | Initial state on creation |
| 1 | Init | Intermediate | Provider setup in progress |
| 2 | Pending | Intermediate | Awaiting provider processing |
| 4 | Technical | Terminal (failure) | Infrastructure/system error |
| 7 | Cancel | Terminal | Cancelled before completion |
| 8 | Fail | Terminal (failure) | Business-level rejection |
| 9 | Sent | Near-terminal (success) | Funds dispatched to provider |
| 10 | Received | Terminal (success) | Funds confirmed - IMMUTABLE |

---

## 4. Multi-Step Field Population Pattern

Transfer records are created with minimal fields and progressively enriched by single-purpose stored procedures:

| Pipeline Step | Procedure | Fields Set |
|--------------|-----------|------------|
| 1. Creation | CreateTransfer | ReferenceID, CID, CurrencyID, FundingTypeIDs, Amount, TransferStatusID=0, ExReferenceID |
| 2. Routing | SaveRoutingInfo | DepotId, CountryId |
| 3. Origin details | SaveTransferOrigin | OriginFundingData (masked PII) |
| 4. Destination details | SaveTransferDestination | DestinationFundingData (masked PII) |
| 5. Funding IDs | SaveTransferInitFundingId, SaveTransferOriginFundingId, SaveTransferDestinationFundingId | InitFundingId, OriginFundingId, DestinationFundingId |
| 6. External refs | SaveExtRefId, SaveExtTransactionId | ExReferenceID (update), ExtTransactionId |
| 7. Status progression | UpdateTransferStatus | TransferStatusID (with terminal guard) |
| 8. Post-transfer | CreatePostTransfer | New PostTransferActions row |

All UPDATE procedures locate rows by **ReferenceID** (UNIQUE CLUSTERED index - single seek).

---

## 5. Architecture Context

The Billing schema operates within the MoneyBus payment orchestration pipeline:

- **MoneyBus** (Payments domain): Orchestrates fund movements between systems
- **MoneyBusAdapter** (Money/Banking domain): Communicates with banking providers (Tink, etc.)
- **MoneyTransfer service**: Application layer that calls Billing stored procedures
- **MIMO**: External monitoring/reporting service with SELECT access

Transfer types include:
- **Internal transfers**: IBAN bank account to/from eToro Trading account
- **Deposits/Withdrawals**: Movements between banking and trading domains

Key infrastructure:
- **Depot 104**: Primary/default processing infrastructure
- **Depot 166**: Secondary processing infrastructure
- **Currencies**: 2 (EUR), 3 (GBP) observed in recent data
- **Funding Types**: 38 (origin), 33 (destination) most common

---

## 6. Cross-Schema Dependencies

| Schema | Table | Role |
|--------|-------|------|
| Dictionary | TransferStatus | Transfer lifecycle state definitions (8 values) |
| Dictionary | PostTransferStatus | Post-transfer action status definitions (empty - app-managed) |
| History | Transfers | System-versioned audit trail for Billing.Transfers |
| History | TransferStepsLog | Transfer step logging (not in Billing schema scope) |
| Monitoring | GetLastTransfersStatusesInPercentage | Operational health monitoring SP |

---

## 7. Security Model

| Principal | Access |
|-----------|--------|
| MoneyTransferUser | EXECUTE on all Billing SPs, SELECT on PostTransferActions |
| MIMO | SELECT on Billing.PostTransferActions, Dictionary.TransferStatus, Dictionary.PostTransferStatus |
| BI_reader | SELECT access for reporting |
| CICD_DB | Deployment access |

---

## 8. Documentation Summary

| Category | Count | Avg Quality |
|----------|-------|-------------|
| Tables | 3 | 8.8 |
| Stored Procedures | 20 | 9.0 |
| Cross-Schema (Dictionary) | 2 | 8.8 |
| **Total** | **25** | **9.0** |

All objects documented in **1 batch** across **2 sessions** (2026-04-15).

---

## 9. Object Index

### Tables
- [Billing.Transfers](Tables/Billing.Transfers.md) - Core transfer records (9.2)
- [Billing.PostTransferActions](Tables/Billing.PostTransferActions.md) - Follow-up actions (9.0)
- [Billing.UpgradeScript](Tables/Billing.UpgradeScript.md) - Migration tracking (8.2)

### Stored Procedures - Writers
- [Billing.CreateTransfer](Stored Procedures/Billing.CreateTransfer.md) - Creates transfer (9.0)
- [Billing.CreatePostTransfer](Stored Procedures/Billing.CreatePostTransfer.md) - Creates post-transfer action (9.0)

### Stored Procedures - Readers
- [Billing.GetTransferByReferenceID](Stored Procedures/Billing.GetTransferByReferenceID.md) - Lookup by business key (9.0)
- [Billing.GetTransferByExReference](Stored Procedures/Billing.GetTransferByExReference.md) - Lookup by provider ref (9.0)
- [Billing.GetTransfersByCID](Stored Procedures/Billing.GetTransfersByCID.md) - Customer transfer list (9.0)
- [Billing.GetDepotIdOfLastSuccessfulTransferByCid](Stored Procedures/Billing.GetDepotIdOfLastSuccessfulTransferByCid.md) - Last success depot (9.0)
- [Billing.GetLastDepotIdForTransferStatusesByCid](Stored Procedures/Billing.GetLastDepotIdForTransferStatusesByCid.md) - Depot by allowed statuses (9.0)
- [Billing.GetLastSuccessTransferDataByCid](Stored Procedures/Billing.GetLastSuccessTransferDataByCid.md) - Last success metadata (9.0)
- [Billing.GetPostTransfer](Stored Procedures/Billing.GetPostTransfer.md) - Post-transfer actions lookup (9.0)

### Stored Procedures - Modifiers (Transfer Pipeline)
- [Billing.UpdateTransferStatus](Stored Procedures/Billing.UpdateTransferStatus.md) - Status advancement with guard (9.2)
- [Billing.SaveRoutingInfo](Stored Procedures/Billing.SaveRoutingInfo.md) - Sets depot/country (9.0)
- [Billing.SaveTransferOrigin](Stored Procedures/Billing.SaveTransferOrigin.md) - Sets origin data (9.0)
- [Billing.SaveTransferDestination](Stored Procedures/Billing.SaveTransferDestination.md) - Sets destination data (9.0)
- [Billing.SaveTransferInitFundingId](Stored Procedures/Billing.SaveTransferInitFundingId.md) - Sets init funding ID (9.0)
- [Billing.SaveTransferOriginFundingId](Stored Procedures/Billing.SaveTransferOriginFundingId.md) - Sets origin funding ID (9.0)
- [Billing.SaveTransferDestinationFundingId](Stored Procedures/Billing.SaveTransferDestinationFundingId.md) - Sets destination funding ID (9.0)
- [Billing.SaveExtRefId](Stored Procedures/Billing.SaveExtRefId.md) - Updates external reference (9.0)
- [Billing.SaveExtTransactionId](Stored Procedures/Billing.SaveExtTransactionId.md) - Sets provider transaction ID (9.0)

### Stored Procedures - Modifiers (Post-Transfer)
- [Billing.UpdatePostTransferStatus](Stored Procedures/Billing.UpdatePostTransferStatus.md) - Advances action status (9.0)
- [Billing.UpdatePostTransferPayload](Stored Procedures/Billing.UpdatePostTransferPayload.md) - Updates action payload (9.0)

### Cross-Schema Dependencies
- [Dictionary.TransferStatus](../Dictionary/Tables/Dictionary.TransferStatus.md) - Transfer status lookup (9.0)
- [Dictionary.PostTransferStatus](../Dictionary/Tables/Dictionary.PostTransferStatus.md) - Post-transfer status lookup (8.5)
