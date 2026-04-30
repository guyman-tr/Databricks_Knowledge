# Wallet.GetStuckRedeemRequests

> Identifies redemption requests that are stuck in the execution pipeline by finding records sent to the executer but whose associated request status has not progressed beyond 'ExecuterEnqueued' or 'ReadByExecuter' within a configurable timeout window.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns stuck redemption rows exceeding processing time threshold |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure detects redemption requests that are stuck in the blockchain execution pipeline. When a customer redeems a trading position into crypto, the redemption is sent to the executer service for blockchain submission. If the associated request remains in 'ExecuterEnqueued' or 'ReadByExecuter' status beyond a configurable timeout, it indicates a processing stall - the executer picked up the request but hasn't reported success or failure.

Two consumers use this procedure: the redeem scheduler service (for automated retry/escalation of stuck redemptions) and the monitoring team (for operational alerting). Stuck redemptions represent customer funds in limbo - the trading position has been adjusted but the crypto hasn't been delivered to the wallet, making timely detection critical.

The procedure joins four tables to build a comprehensive diagnostic view: Redemptions (the redemption details), Requests (linked via SendRequestCorrelationId), RequestStatuses with Dictionary.RequestStatuses (for human-readable status names and timestamps), and CustomerWalletsView (for the destination wallet and address). The CROSS APPLY resolves the latest request status with its Dictionary name for the status-name-based filter.

---

## 2. Business Logic

### 2.1 Stuck Detection Criteria

**What**: A redemption is "stuck" when it's been sent to the executer but the request hasn't progressed past the initial execution states within the timeout.

**Columns/Parameters Involved**: `RedemptionStatus`, `Dictionary.RequestStatuses.Name`, `@ExecuterMaxProcessingTimeMinutes`

**Rules**:
- Only examines redemptions with RedemptionStatus = 2 (SentToExecuter)
- Checks the latest request status name (not ID) against: 'ExecuterEnqueued', 'ReadByExecuter'
- Calculates time elapsed: DATEDIFF(MINUTE, LastStatusOccurred, GETDATE())
- If elapsed time > @ExecuterMaxProcessingTimeMinutes, the redemption is stuck
- This catches both queued-but-not-picked-up and picked-up-but-not-completed scenarios

**Diagram**:
```
Redemption (status=2 SentToExecuter)
        |
        v
Request Status Timeline:
  [ExecuterEnqueued] --> [ReadByExecuter] --> [ExecuterCompleted]
        |                      |                     |
        |<-- STUCK if >N min ->|<-- STUCK if >N min ->|
        |                      |                     NOT stuck (progressed)
```

### 2.2 Cross-Schema Status Resolution

**What**: Joins to the Dictionary.RequestStatuses table to filter by human-readable status names rather than numeric IDs.

**Columns/Parameters Involved**: `RequestStatuses.RequestStatusId`, `Dictionary.RequestStatuses.Name`

**Rules**:
- CROSS APPLY gets TOP 1 status ordered by Id DESC (latest status)
- Joins to Dictionary.RequestStatuses for the Name field
- Filters WHERE LastStatusName IN ('ExecuterEnqueued', 'ReadByExecuter')
- Uses names rather than IDs for readability and resilience to ID changes

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExecuterMaxProcessingTimeMinutes | int | NO | - | VERIFIED | Maximum allowed time in minutes for a redemption to remain in executer queue before being flagged as stuck. Typically configured to 30-60 minutes. |
| 2 | Id (output) | bigint | NO | - | CODE-BACKED | Redemption record ID from Wallet.Redemptions. |
| 3 | PositionId (output) | bigint | NO | - | VERIFIED | Trading position being redeemed. Links to the trading platform's position system. |
| 4 | RequestingGcid (output) | bigint | NO | - | CODE-BACKED | Customer who initiated the redemption. Used for customer notification and escalation. |
| 5 | CryptoId (output) | int | NO | - | VERIFIED | Cryptocurrency being redeemed. FK to Wallet.CryptoTypes. Determines which blockchain network the transfer uses. |
| 6 | DestinationAddress (output) | nvarchar | YES | - | CODE-BACKED | Customer's wallet address where redeemed crypto should be sent. Resolved from CustomerWalletsView.Address. |
| 7 | RequestedAmount (output) | decimal | NO | - | CODE-BACKED | Gross amount of crypto the customer is redeeming from their position. |
| 8 | EtoroFeeAmount (output) | decimal | NO | - | CODE-BACKED | eToro service fee for this redemption. Aliased from eToroFeeAmount. |
| 9 | RedemptionStatus (output) | tinyint | NO | - | VERIFIED | Always 2 (SentToExecuter) for stuck redemptions - the filter criterion. See [Redemption Status](../../_glossary.md#redemption-status). |
| 10 | InitialFeeAmount (output) | decimal | NO | - | CODE-BACKED | Fixed base fee component. Typically 0. |
| 11 | RecordId (output) | bigint | YES | - | CODE-BACKED | Wallet record ID from CustomerWalletsView.WalletRecordId. Used by retry logic to re-submit the redemption. |
| 12 | WalletId (output) | uniqueidentifier | YES | - | VERIFIED | Customer's destination wallet ID. Resolved from CustomerWalletsView.Id. |
| 13 | ProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider's reference ID for the wallet. From CustomerWalletsView.BlockchainProviderWalletId. Used when re-submitting to the blockchain provider. |
| 14 | SendRequestCorrelationId (output) | uniqueidentifier | YES | - | VERIFIED | CorrelationId linking the redemption to its send request in Wallet.Requests. Primary key for cross-table tracing. |
| 15 | RequestTime (output) | datetime2(7) | YES | - | CODE-BACKED | When the send request was created. Aliased from Requests.Timestamp. Shows how long the redemption has been waiting overall. |
| 16 | EstimatedBlockchainFee (output) | decimal | YES | - | CODE-BACKED | Estimated network fee for the blockchain transfer. May differ from actual fee post-execution. |
| 17 | SourceWalletId (output) | uniqueidentifier | YES | - | CODE-BACKED | Source wallet (omnibus/redeem wallet) from which the crypto is being sent. |
| 18 | TransactionTypeId (output) | tinyint | YES | - | CODE-BACKED | Transaction type for the send operation. Typically 0 (Redeem). See [Transaction Type](../../_glossary.md#transaction-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RedemptionStatus=2 | Wallet.Redemptions | Filter | Only SentToExecuter redemptions |
| SendRequestCorrelationId | Wallet.Requests.CorrelationId | JOIN | Links redemption to its send request |
| RequestStatusId | Wallet.RequestStatuses | CROSS APPLY | Latest status for time-based filtering |
| Dictionary.RequestStatuses.Name | Dictionary.RequestStatuses | JOIN | Human-readable status names for filter |
| Gcid + CryptoId | Wallet.CustomerWalletsView | JOIN | Resolves destination wallet details |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RedeemSchedulerUser | - | EXECUTE | Automated detection and retry of stuck redemptions |
| MonitorTeam | - | EXECUTE | Operational alerting for stuck redemptions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetStuckRedeemRequests (procedure)
+-- Wallet.Redemptions (table)
+-- Wallet.Requests (table)
+-- Wallet.RequestStatuses (table)
+-- Dictionary.RequestStatuses (table)
+-- Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Redemptions | Table | Source of redemption records filtered by RedemptionStatus=2 |
| Wallet.Requests | Table | JOINed via SendRequestCorrelationId for request context |
| Wallet.RequestStatuses | Table | CROSS APPLY for latest status timestamp and ID |
| Dictionary.RequestStatuses | Table | JOINed for human-readable status names |
| Wallet.CustomerWalletsView | View | JOINed for destination wallet address and IDs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RedeemSchedulerUser | Service Account | EXECUTE grant |
| MonitorTeam | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Find redemptions stuck for more than 30 minutes
```sql
EXEC Wallet.GetStuckRedeemRequests
    @ExecuterMaxProcessingTimeMinutes = 30;
```

### 8.2 Direct diagnostic query for stuck redemptions
```sql
SELECT re.Id, re.PositionId, re.RequestingGcid, re.CryptoId,
    re.RedemptionStatus, re.SendRequestCorrelationId,
    rs.LastStatusName, rs.LastStatusOccurred,
    DATEDIFF(MINUTE, rs.LastStatusOccurred, GETDATE()) AS MinutesStuck
FROM Wallet.Redemptions re WITH (NOLOCK)
    JOIN Wallet.Requests r WITH (NOLOCK) ON r.CorrelationId = re.SendRequestCorrelationId
    CROSS APPLY (
        SELECT TOP 1 rs.Timestamp AS LastStatusOccurred, drs.Name AS LastStatusName
        FROM Wallet.RequestStatuses rs WITH (NOLOCK)
            JOIN Dictionary.RequestStatuses drs WITH (NOLOCK) ON drs.Id = rs.RequestStatusId
        WHERE rs.RequestId = r.Id
        ORDER BY rs.Id DESC
    ) rs
WHERE re.RedemptionStatus = 2
    AND rs.LastStatusName IN ('ExecuterEnqueued', 'ReadByExecuter');
```

### 8.3 Count stuck redemptions by crypto
```sql
-- Run the SP and aggregate
DECLARE @Results TABLE (Id BIGINT, CryptoId INT, MinutesStuck INT);
-- Use the direct query above with DATEDIFF and GROUP BY CryptoId for aggregation
SELECT CryptoId, COUNT(*) AS StuckCount
FROM (/* inner query from 8.2 */) x
WHERE DATEDIFF(MINUTE, LastStatusOccurred, GETDATE()) > 30
GROUP BY CryptoId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetStuckRedeemRequests | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetStuckRedeemRequests.sql*
