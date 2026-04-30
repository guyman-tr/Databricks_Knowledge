# Wallet.StuckInProcessRedeems

> Identifies redemptions stuck in SentToExecuter status (status=2) for longer than a configurable threshold, used by the monitoring team and Splunk for operational alerting on processing stalls.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns Redemptions WHERE RedemptionStatus=2 AND age > threshold |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure finds redemptions that have been in SentToExecuter status (status=2) for longer than @MaxMinutes (default 720 = 12 hours). These represent redemptions where the execution service picked up the request but hasn't reported completion or failure. The monitoring team and Splunk use this for operational alerting. Companion to StuckPendingRedemptions (which checks status=0, Persisted).

---

## 2. Business Logic

### 2.1 Age-Based Stuck Detection

**What**: Finds SentToExecuter redemptions older than the threshold.

**Rules**:
- RedemptionStatus = 2 (SentToExecuter)
- BeginDate < DATEADD(MINUTE, -@MaxMinutes, GETDATE())
- Default @MaxMinutes = 720 (12 hours)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxMinutes | int | YES | 720 | VERIFIED | Maximum minutes before a redemption is considered stuck. Default 12 hours. |
| 2 | SendRequestCorrelationId (output) | uniqueidentifier | YES | - | CODE-BACKED | Correlation ID for the send request. |
| 3 | PositionId (output) | bigint | YES | - | CODE-BACKED | Trading position being redeemed. |
| 4 | RequestingGcid (output) | bigint | NO | - | CODE-BACKED | Customer. |
| 5 | CryptoId (output) | int | NO | - | CODE-BACKED | Cryptocurrency. |
| 6 | RequestedAmount (output) | decimal | NO | - | CODE-BACKED | Redemption amount. |
| 7 | RedemptionStatus (output) | tinyint | NO | - | CODE-BACKED | Always 2 (SentToExecuter). |
| 8 | BillingTransId (output) | bigint | YES | - | CODE-BACKED | Billing transaction ID. |
| 9 | BillingRedeemId (output) | bigint | YES | - | CODE-BACKED | Billing redemption ID. |
| 10 | BeginDate (output) | datetime2(7) | YES | - | CODE-BACKED | When the redemption was created. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RedemptionStatus=2 | Wallet.Redemptions | Filter | SentToExecuter redemptions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MonitorTeam, SplunkUser | - | EXECUTE | Operational monitoring |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.StuckInProcessRedeems (procedure)
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

### 8.1 Find stuck in-process redeems (default 12h)
```sql
EXEC Wallet.StuckInProcessRedeems;
```

### 8.2 Custom threshold (1 hour)
```sql
EXEC Wallet.StuckInProcessRedeems @MaxMinutes = 60;
```

### 8.3 Compare with pending stuck
```sql
-- In-process (status=2, this SP): EXEC Wallet.StuckInProcessRedeems;
-- Pending (status=0): EXEC Wallet.StuckPendingRedemptions;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.StuckInProcessRedeems | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.StuckInProcessRedeems.sql*
