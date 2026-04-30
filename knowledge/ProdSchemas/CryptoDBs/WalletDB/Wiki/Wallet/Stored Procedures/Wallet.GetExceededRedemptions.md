# Wallet.GetExceededRedemptions

> Identifies customers whose total redemption amounts (net of fees) exceed a specified threshold for a given cryptocurrency and time period, breaking down amounts by status (Pending, Processing, Sent).

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns customers exceeding redemption threshold |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a risk monitoring tool that identifies customers with unusually high redemption (withdrawal) volumes. It aggregates each customer's net redemption amounts (requested minus eToro fee) for a specific cryptocurrency within a time window, then returns only those exceeding the threshold. The breakdown by status (Pending=0, Processing=1, WasSent=2) helps operations understand the pipeline state.

Without this procedure, the risk team could not detect high-volume withdrawal patterns that might indicate account compromise, money laundering, or coordinated withdrawal attacks.

The results are ordered by total net amount descending, surfacing the highest-volume customers first.

---

## 2. Business Logic

### 2.1 Status-Segmented Aggregation

**What**: Breaks down total redemption volume by status for each customer.

**Columns/Parameters Involved**: Redemptions.RedemptionStatus, RequestedAmount, eToroFeeAmount

**Rules**:
- Pending (status=0): Requests awaiting processing
- Processing (status=1): Actively being processed on blockchain
- WasSent (status=2): Successfully sent
- Total = sum across all statuses
- Net amount = RequestedAmount - eToroFeeAmount
- HAVING clause filters to customers exceeding @UnitsThreshold
- Ordered by Total DESC (highest volume first)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency to analyze. |
| 2 | @UnitsThreshold | decimal(36,18) | NO | - | CODE-BACKED | Minimum net redemption total (in crypto units) to include a customer in results. Customers below this threshold are excluded. |
| 3 | @From | datetime2(7) | NO | - | CODE-BACKED | Start of the analysis period. |
| 4 | @To | datetime2(7) | NO | - | CODE-BACKED | End of the analysis period. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.Redemptions | Reader | Source of redemption data |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetExceededRedemptions (procedure)
  └── Wallet.Redemptions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Redemptions | Table | SELECT with GROUP BY HAVING |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- NOLOCK hint, SET NOCOUNT ON
- GROUP BY with HAVING for threshold filtering
- CASE expressions for status-segmented aggregation
- ORDER BY total DESC

---

## 8. Sample Queries

### 8.1 Find BTC customers exceeding 1 BTC in last 7 days
```sql
EXEC Wallet.GetExceededRedemptions
    @CryptoId = 1,
    @UnitsThreshold = 1.0,
    @From = '2026-04-08',
    @To = '2026-04-15'
```

### 8.2 Manual equivalent query
```sql
SELECT r.RequestingGcid, r.CryptoId,
    SUM(r.RequestedAmount - r.eToroFeeAmount) AS Total
FROM Wallet.Redemptions r WITH (NOLOCK)
WHERE r.CryptoId = 1 AND r.BeginDate BETWEEN '2026-04-08' AND '2026-04-15'
GROUP BY r.RequestingGcid, r.CryptoId
HAVING SUM(r.RequestedAmount - r.eToroFeeAmount) > 1.0
ORDER BY Total DESC
```

### 8.3 Redemption volume by crypto
```sql
SELECT CryptoId, COUNT(DISTINCT RequestingGCID) AS Customers, SUM(RequestedAmount - eToroFeeAmount) AS NetTotal
FROM Wallet.Redemptions WITH (NOLOCK)
WHERE BeginDate >= DATEADD(DAY, -7, GETDATE())
GROUP BY CryptoId
ORDER BY NetTotal DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetExceededRedemptions | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetExceededRedemptions.sql*
