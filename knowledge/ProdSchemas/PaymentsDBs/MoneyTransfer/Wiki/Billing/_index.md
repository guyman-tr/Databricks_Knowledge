# Billing Schema - MoneyTransfer Database

| Metric | Value |
|--------|-------|
| **Total Objects** | 23 |
| **Documented** | 25 (100%) |
| **Last Updated** | 2026-04-15 |
| **Batches Completed** | 1 |
| **Enrichment** | Complete (2026-04-15) |
| **Schema Overview** | [_schema_overview.md](_schema_overview.md) |
| **Average Quality** | 9.0 |

---

## Tables (3)

| Object | Quality | Status |
|--------|---------|--------|
| [Billing.UpgradeScript](Tables/Billing.UpgradeScript.md) | 8.2 | Done (Batch 1) |
| [Billing.Transfers](Tables/Billing.Transfers.md) | 9.2 | Done (Batch 1) |
| [Billing.PostTransferActions](Tables/Billing.PostTransferActions.md) | 9.0 | Done (Batch 1) |

## Stored Procedures (20)

| Object | Quality | Status |
|--------|---------|--------|
| [Billing.CreateTransfer](Stored Procedures/Billing.CreateTransfer.md) | 9.0 | Done (Batch 1) |
| [Billing.GetDepotIdOfLastSuccessfulTransferByCid](Stored Procedures/Billing.GetDepotIdOfLastSuccessfulTransferByCid.md) | 9.0 | Done (Batch 1) |
| [Billing.GetLastDepotIdForTransferStatusesByCid](Stored Procedures/Billing.GetLastDepotIdForTransferStatusesByCid.md) | 9.0 | Done (Batch 1) |
| [Billing.GetLastSuccessTransferDataByCid](Stored Procedures/Billing.GetLastSuccessTransferDataByCid.md) | 9.0 | Done (Batch 1) |
| [Billing.GetTransferByExReference](Stored Procedures/Billing.GetTransferByExReference.md) | 9.0 | Done (Batch 1) |
| [Billing.GetTransferByReferenceID](Stored Procedures/Billing.GetTransferByReferenceID.md) | 9.0 | Done (Batch 1) |
| [Billing.GetTransfersByCID](Stored Procedures/Billing.GetTransfersByCID.md) | 9.0 | Done (Batch 1) |
| [Billing.SaveExtRefId](Stored Procedures/Billing.SaveExtRefId.md) | 9.0 | Done (Batch 1) |
| [Billing.SaveExtTransactionId](Stored Procedures/Billing.SaveExtTransactionId.md) | 9.0 | Done (Batch 1) |
| [Billing.SaveRoutingInfo](Stored Procedures/Billing.SaveRoutingInfo.md) | 9.0 | Done (Batch 1) |
| [Billing.SaveTransferDestination](Stored Procedures/Billing.SaveTransferDestination.md) | 9.0 | Done (Batch 1) |
| [Billing.SaveTransferDestinationFundingId](Stored Procedures/Billing.SaveTransferDestinationFundingId.md) | 9.0 | Done (Batch 1) |
| [Billing.SaveTransferInitFundingId](Stored Procedures/Billing.SaveTransferInitFundingId.md) | 9.0 | Done (Batch 1) |
| [Billing.SaveTransferOrigin](Stored Procedures/Billing.SaveTransferOrigin.md) | 9.0 | Done (Batch 1) |
| [Billing.SaveTransferOriginFundingId](Stored Procedures/Billing.SaveTransferOriginFundingId.md) | 9.0 | Done (Batch 1) |
| [Billing.UpdateTransferStatus](Stored Procedures/Billing.UpdateTransferStatus.md) | 9.2 | Done (Batch 1) |
| [Billing.CreatePostTransfer](Stored Procedures/Billing.CreatePostTransfer.md) | 9.0 | Done (Batch 1) |
| [Billing.GetPostTransfer](Stored Procedures/Billing.GetPostTransfer.md) | 9.0 | Done (Batch 1) |
| [Billing.UpdatePostTransferPayload](Stored Procedures/Billing.UpdatePostTransferPayload.md) | 9.0 | Done (Batch 1) |
| [Billing.UpdatePostTransferStatus](Stored Procedures/Billing.UpdatePostTransferStatus.md) | 9.0 | Done (Batch 1) |

## Cross-Schema Dependencies (Dictionary)

| Object | Quality | Status |
|--------|---------|--------|
| [Dictionary.TransferStatus](../Dictionary/Tables/Dictionary.TransferStatus.md) | 9.0 | Done (Batch 1) |
| [Dictionary.PostTransferStatus](../Dictionary/Tables/Dictionary.PostTransferStatus.md) | 8.5 | Done (Batch 1) |
