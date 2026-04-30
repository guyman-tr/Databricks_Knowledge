# Monitoring Schema - MoneyTransfer Database

## Overview

The Monitoring schema in the MoneyTransfer database contains operational health monitoring procedures. It provides real-time diagnostic capabilities for the money transfer pipeline, enabling operations teams and automated alerting systems to detect anomalies in transfer processing.

## Schema Statistics

| Metric | Value |
|--------|-------|
| **Tables** | 0 |
| **Views** | 0 |
| **Functions** | 0 |
| **Stored Procedures** | 1 |
| **Total Objects** | 1 |

## Objects

### Stored Procedures

| Object | Purpose |
|--------|---------|
| [GetLastTransfersStatusesInPercentage](Stored Procedures/Monitoring.GetLastTransfersStatusesInPercentage.md) | Calculates percentage distribution of transfer statuses within a configurable time window for operational health monitoring |

## Cross-Schema Dependencies

The Monitoring schema is a **consumer-only** schema - it reads from other schemas but is not referenced by any other schema in the database.

| Dependency | Schema | How Used |
|-----------|--------|----------|
| Billing.Transfers | Billing | Scans recent transfers by TransferID range for status counts |
| Dictionary.TransferStatus | Dictionary | LEFT JOINs to resolve status IDs to names |

## Architecture Role

The Monitoring schema sits at the **observation layer** of the MoneyTransfer database. It does not participate in the transactional flow (transfer creation, status updates, routing) but provides read-only visibility into the health and throughput of that flow. The single procedure uses NOLOCK hints for non-blocking reads, appropriate for monitoring that prioritizes availability over strict consistency.

---

*Generated: 2026-04-16*
