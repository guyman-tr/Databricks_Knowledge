# Eligibility.GetPendingTravelRuleTransactions

> Retrieves incoming crypto transactions for a customer that are pending manual travel rule approval or have been canceled, including their travel rule status and fiat equivalents.

| Property | Value |
|----------|-------|
| **Schema** | Eligibility |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns received transaction details with travel rule status |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure finds incoming cryptocurrency transactions that are held up by travel rule compliance. Under travel rule regulations, transfers above certain thresholds require originator/beneficiary information exchange between service providers. When this information is missing or unverified, transactions are placed in a pending state awaiting manual compliance review.

The procedure identifies transactions with travel rule status 0 (PendingManualApproval) or 2 (Canceled) for a given customer, returning the transaction details, fiat equivalent amounts, and correlation IDs needed for compliance officers to take action.

Note: A newer version exists in the Wallet schema (`Wallet.GetPendingTravelRuleTransactions`) with updated logic that uses status codes 0 (PendingManualApproval) and 3 (PendingBeneficiaryDetails) instead of 0 and 2.

---

## 2. Business Logic

### 2.1 Travel Rule Status Filtering

**What**: Identifies transactions by their latest travel rule status.

**Columns/Parameters Involved**: `@Gcid`, Wallet.TransactionTravelRuleStatuses.TravelRuleStatusId

**Rules**:
- Uses RANK() OVER PARTITION BY RequestId to find the latest travel rule status per request
- Filters for TravelRuleStatusId = 0 (PendingManualApproval) or TravelRuleStatusId = 2 (Canceled)
- Uses a temp table (#TempTravelRuleStatus) to store intermediate status rankings
- Maps status codes to human-readable labels via CASE expression

**Diagram**:
```
Travel Rule Status Flow:
  [0: PendingManualApproval] -> [1: Approved] (via whitelist or manual)
  [0: PendingManualApproval] -> [2: Canceled]

This SP returns transactions at status 0 or 2.
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | BIGINT (IN) | NO | - | CODE-BACKED | Global Customer ID to filter travel rule transactions for. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | - | CODE-BACKED | Wallet.Requests.Id - the request associated with the received transaction |
| 2 | Occurred | datetime2 | YES | - | CODE-BACKED | Timestamp when the transaction was received |
| 3 | WalletId | bigint | YES | - | CODE-BACKED | Internal wallet that received the transaction |
| 4 | SenderAddress | nvarchar | YES | - | CODE-BACKED | Blockchain address that sent the funds |
| 5 | ReceiverAddress | nvarchar | YES | - | CODE-BACKED | Blockchain address that received the funds |
| 6 | Amount | decimal | YES | - | CODE-BACKED | Amount of cryptocurrency received |
| 7 | ProviderTransactionId | nvarchar | YES | - | CODE-BACKED | External blockchain transaction hash/ID |
| 8 | Status | varchar | NO | - | CODE-BACKED | Human-readable label: 'PendingManualApproval' (TravelRuleStatusId=0) or 'Canceled' (TravelRuleStatusId=2) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Wallet.TransactionTravelRuleStatuses | JOIN | Gets travel rule status records |
| FROM | Wallet.TransactionTravelRuleInformation | JOIN | Links travel rule info to requests |
| FROM | Wallet.Requests | JOIN | Filters by Gcid, links via CorrelationId |
| FROM | Wallet.ReceivedTransactions | LEFT JOIN | Gets transaction details |
| FROM | Wallet.CustomerWalletsView | JOIN | Links wallet to customer Gcid |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.GetPendingTravelRuleTransactions | Equivalent | Related procedure | Newer Wallet-schema version with updated status codes |

---

## 6. Dependencies

```
Eligibility.GetPendingTravelRuleTransactions (procedure)
+-- Wallet.TransactionTravelRuleStatuses (table)
+-- Wallet.TransactionTravelRuleInformation (table)
+-- Wallet.Requests (table)
+-- Wallet.ReceivedTransactions (table)
+-- Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionTravelRuleStatuses | Table | Source of travel rule status records |
| Wallet.TransactionTravelRuleInformation | Table | Links status records to requests |
| Wallet.Requests | Table | Filtered by Gcid |
| Wallet.ReceivedTransactions | Table | Source of transaction detail columns |
| Wallet.CustomerWalletsView | View | Links wallet to customer |

### 6.2 Objects That Depend On This

No callers found in the SSDT project. Called by the Eligibility Service at the application layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute to find pending travel rule transactions
```sql
EXEC Eligibility.GetPendingTravelRuleTransactions @Gcid = 12345678
```

### 8.2 Check how many transactions are pending travel rule approval
```sql
SELECT COUNT(*) FROM Wallet.TransactionTravelRuleStatuses trts WITH (NOLOCK)
JOIN Wallet.TransactionTravelRuleInformation tri WITH (NOLOCK) ON tri.Id = trts.TransactionTravelRuleInformationId
WHERE trts.TravelRuleStatusId IN (0, 2)
```

### 8.3 View travel rule status history for a specific request
```sql
SELECT trts.Id, trts.TravelRuleStatusId, tri.RequestId
FROM Wallet.TransactionTravelRuleStatuses trts WITH (NOLOCK)
JOIN Wallet.TransactionTravelRuleInformation tri WITH (NOLOCK) ON tri.Id = trts.TransactionTravelRuleInformationId
WHERE tri.RequestId = @RequestId
ORDER BY trts.Id DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Eligibility.GetPendingTravelRuleTransactions | Type: Stored Procedure | Source: WalletDB/Eligibility/Stored Procedures/Eligibility.GetPendingTravelRuleTransactions.sql*
