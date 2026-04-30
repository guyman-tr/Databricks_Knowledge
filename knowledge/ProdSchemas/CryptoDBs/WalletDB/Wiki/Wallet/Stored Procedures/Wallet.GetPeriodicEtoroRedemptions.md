# Wallet.GetPeriodicEtoroRedemptions

> Aggregates eToro crypto redemption amounts by cryptocurrency and status for a specified time period, providing a summary of pending, processing, and sent redemption volumes.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns redemption volume summary grouped by CryptoId and status |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure produces a periodic summary report of crypto redemption activity, breaking down the net redemption amounts (requested minus eToro fee) by cryptocurrency and redemption status. It enables operations and finance teams to monitor redemption volumes over any time window - for example, daily, weekly, or monthly totals of how much crypto is pending redemption, currently being processed, or already sent.

Without this procedure, there would be no efficient way to get an aggregated view of redemption pipeline health across all cryptocurrencies. It answers questions like: "How much BTC is stuck in pending status this week?" or "What is the total ETH volume we sent out in March?"

Data comes from `Wallet.Redemptions` filtered by BeginDate within the specified time range. The amounts reported are net amounts (RequestedAmount minus eToroFeeAmount), reflecting the actual crypto the customer receives. Results are grouped by CryptoId and ordered by CryptoId for consistent reporting.

---

## 2. Business Logic

### 2.1 Redemption Status Breakdown

**What**: Aggregates net redemption amounts per cryptocurrency, split by redemption workflow status.

**Columns/Parameters Involved**: `RedemptionStatus`, `RequestedAmount`, `eToroFeeAmount`, `CryptoId`

**Rules**:
- Net amount per redemption = RequestedAmount - eToroFeeAmount (the actual amount the customer receives)
- Status 0 (Pending): Redemptions requested but not yet picked up for processing
- Status 1 (Processing): Redemptions currently being executed by the send pipeline
- Status 2 (WasSent): Redemptions where the blockchain transaction has been submitted
- Total column sums ALL statuses regardless of status value (including any statuses beyond 0/1/2)
- Only redemptions with BeginDate within [@From, @To] range are included

**Diagram**:
```
Redemption Lifecycle:
  Pending (0) --> Processing (1) --> WasSent (2)

Report Output per CryptoId:
  | CryptoId | Pending | Processing | WasSent | Total |
  |     1    | 0.5 BTC |  1.2 BTC   | 10.0 BTC| 11.7 BTC|
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @From | datetime2(7) | NO | - | CODE-BACKED | Start of the reporting period (inclusive). Filters Redemptions.BeginDate >= @From. |
| 2 | @To | datetime2(7) | NO | - | CODE-BACKED | End of the reporting period (inclusive). Filters Redemptions.BeginDate <= @To. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency identifier. FK to Wallet.CryptoTypes (e.g., 1=BTC, 2=ETH). Groups the summary by cryptocurrency. |
| 2 | Pending | decimal | YES | - | CODE-BACKED | Total net amount (RequestedAmount - eToroFeeAmount) of redemptions in Pending status (RedemptionStatus=0) for this crypto in the period. NULL if no pending redemptions. |
| 3 | Proccesing | decimal | YES | - | CODE-BACKED | Total net amount of redemptions in Processing status (RedemptionStatus=1). Note: column name has a typo ("Proccesing" with double c) - preserved from original SP for backward compatibility. |
| 4 | WasSent | decimal | YES | - | CODE-BACKED | Total net amount of redemptions in WasSent status (RedemptionStatus=2) - blockchain transaction submitted. |
| 5 | Total | decimal | YES | - | CODE-BACKED | Total net amount across all redemption statuses for this crypto in the period. May include statuses beyond 0/1/2. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Wallet.Redemptions | FROM | Main data source - redemption records |
| CryptoId | Wallet.CryptoTypes | Lookup | Cryptocurrency classification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No SQL callers found) | - | - | Likely called from application layer for periodic reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetPeriodicEtoroRedemptions (procedure)
└── Wallet.Redemptions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Redemptions | Table | Main data source - SELECT with NOLOCK, aggregated by CryptoId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No dependents found in SQL) | - | Called from application/reporting layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK hint | Read isolation | Reads Redemptions with NOLOCK for non-blocking reporting queries |
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Get redemption summary for the last 7 days
```sql
EXEC Wallet.GetPeriodicEtoroRedemptions
    @From = '2026-04-08',
    @To = '2026-04-15';
```

### 8.2 Manual query to see redemption breakdown with crypto names
```sql
SELECT r.CryptoId, ct.CryptoName,
    SUM(CASE WHEN r.RedemptionStatus = 0 THEN r.RequestedAmount - r.eToroFeeAmount ELSE 0 END) AS Pending,
    SUM(CASE WHEN r.RedemptionStatus = 1 THEN r.RequestedAmount - r.eToroFeeAmount ELSE 0 END) AS Processing,
    SUM(CASE WHEN r.RedemptionStatus = 2 THEN r.RequestedAmount - r.eToroFeeAmount ELSE 0 END) AS WasSent,
    SUM(r.RequestedAmount - r.eToroFeeAmount) AS Total
FROM Wallet.Redemptions r WITH (NOLOCK)
    JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoID = r.CryptoId
WHERE r.BeginDate BETWEEN '2026-04-01' AND '2026-04-15'
GROUP BY r.CryptoId, ct.CryptoName
ORDER BY r.CryptoId;
```

### 8.3 Compare eToro fees collected vs net amounts by crypto
```sql
SELECT r.CryptoId,
    SUM(r.eToroFeeAmount) AS TotalFees,
    SUM(r.RequestedAmount - r.eToroFeeAmount) AS NetToCustomers,
    SUM(r.RequestedAmount) AS GrossRequested
FROM Wallet.Redemptions r WITH (NOLOCK)
WHERE r.BeginDate BETWEEN '2026-04-01' AND '2026-04-15'
GROUP BY r.CryptoId
ORDER BY r.CryptoId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetPeriodicEtoroRedemptions | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetPeriodicEtoroRedemptions.sql*
