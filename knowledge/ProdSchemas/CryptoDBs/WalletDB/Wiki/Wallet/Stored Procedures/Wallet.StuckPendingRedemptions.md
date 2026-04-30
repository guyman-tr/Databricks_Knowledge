# Wallet.StuckPendingRedemptions

> Identifies redemptions stuck in Persisted status (status=0) for longer than a configurable threshold, used by the monitoring team and Splunk for alerting on pickup stalls before execution begins.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns Redemptions WHERE RedemptionStatus=0 AND age > threshold |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure finds redemptions that are stuck in Persisted status (status=0) - meaning they were created but never picked up by the HandlePendingRedemptions process. Default threshold is 720 minutes (12 hours). Companion to StuckInProcessRedeems (which checks status=2).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Same structure as StuckInProcessRedeems but filters RedemptionStatus=0 instead of 2.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxMinutes | int | YES | 720 | VERIFIED | Threshold in minutes. Default 12 hours. |
| 2-10 | (same output columns as StuckInProcessRedeems) | - | - | - | CODE-BACKED | SendRequestCorrelationId, PositionId, RequestingGcid, CryptoId, RequestedAmount, RedemptionStatus (always 0), BillingTransId, BillingRedeemId, BeginDate |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RedemptionStatus=0 | Wallet.Redemptions | Filter | Persisted/pending redemptions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MonitorTeam, SplunkUser | - | EXECUTE | Pickup stall alerting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.StuckPendingRedemptions (procedure)
+-- Wallet.Redemptions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Redemptions | Table | Status + age filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MonitorTeam, SplunkUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Find stuck pending redemptions
```sql
EXEC Wallet.StuckPendingRedemptions;
```

### 8.2 Custom threshold
```sql
EXEC Wallet.StuckPendingRedemptions @MaxMinutes = 60;
```

### 8.3 Full redemption monitoring
```sql
EXEC Wallet.StuckPendingRedemptions; -- Status=0, never picked up
EXEC Wallet.StuckInProcessRedeems;   -- Status=2, picked up but not completed
EXEC Wallet.GetStuckRedeemRequests @ExecuterMaxProcessingTimeMinutes=30; -- Request-level stuck
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.StuckPendingRedemptions | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.StuckPendingRedemptions.sql*
