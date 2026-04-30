# Wallet.GetPendingTravelRuleTransactions

> Retrieves received crypto transactions for a customer that are pending travel rule manual approval or beneficiary details, ready for compliance review.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns pending travel rule transactions with amounts and fiat context |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure surfaces incoming crypto transactions that require travel rule compliance action: either manual approval by compliance staff (TravelRuleStatusId=0, PendingManualApproval) or additional beneficiary details from the customer (TravelRuleStatusId=3, PendingBeneficiaryDetails). Under the FATF Travel Rule, incoming transfers above certain thresholds must have verified originator and beneficiary information before the funds can be released.

The customer-facing application calls this to show the customer which incoming transactions are on hold pending compliance action. It also powers the compliance dashboard where reviewers process pending travel rule verifications. Unlike `Wallet.GetMustBouncebackTransactions` (which finds failed/rejected transactions), this finds transactions still awaiting a decision.

The procedure uses three CTEs: LatestStatuses (latest travel rule status per request), Amounts (aggregated received amounts per correlation), and RepresentativeRows (one representative received transaction per correlation). Only receive requests (RequestTypeId=8) for the specified customer with TravelRuleStatusId IN (0, 3) are returned.

---

## 2. Business Logic

### 2.1 Travel Rule Pending States

**What**: Identifies transactions in one of two pending travel rule states.

**Columns/Parameters Involved**: `TravelRuleStatusId`, `RequestTypeId`, `@Gcid`

**Rules**:
- TravelRuleStatusId=0: PendingManualApproval - waiting for compliance review
- TravelRuleStatusId=3: PendingBeneficiaryDetails - waiting for customer to provide beneficiary information
- ROW_NUMBER() OVER (PARTITION BY RequestId ORDER BY trts.Id DESC) gets the latest status per request
- Only receive requests (RequestTypeId=8) for the specified customer (@Gcid)
- Status='PendingManualApproval' is hardcoded as the output label for both states
- TOP @Limit (default 10) ordered by Occurred DESC (most recent first)

### 2.2 Amount Aggregation

**What**: Sums all received amounts per request correlation since a single request may produce multiple received transactions.

**Columns/Parameters Involved**: `ReceiveRequestCorrelationId`, `Amount`, `TotalAmount`

**Rules**:
- Same pattern as GetMustBouncebackTransactions
- SUM(Amount) grouped by ReceiveRequestCorrelationId = TotalAmount
- Representative row (latest by Occurred, then Id DESC) provides transaction details
- FiatAmount and FiatSymbol from TransactionTravelRuleInformation provide fiat-equivalent context

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | BIGINT | NO | - | CODE-BACKED | Global Customer ID. Retrieves pending travel rule transactions for this customer. |
| 2 | @Limit | INT | YES | 10 | CODE-BACKED | Maximum number of pending transactions to return. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | Id | BIGINT | NO | - | CODE-BACKED | ReceivedTransactions record ID. Representative transaction for this request. |
| 4 | Gcid | BIGINT | NO | - | CODE-BACKED | Customer's Global ID (echoed from @Gcid). |
| 5 | Occurred | DATETIME2 | NO | - | CODE-BACKED | When the received transaction was recorded. |
| 6 | WalletId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Receiving wallet ID. |
| 7 | CryptoId | INT | NO | - | CODE-BACKED | Cryptocurrency. FK to Wallet.CryptoTypes. |
| 8 | FromAddress | NVARCHAR | YES | - | CODE-BACKED | Sender's blockchain address (aliased from SenderAddress). |
| 9 | ToAddress | NVARCHAR | YES | - | CODE-BACKED | Receiver's blockchain address (aliased from ReceiverAddress). |
| 10 | Amount | DECIMAL | NO | - | CODE-BACKED | Total received crypto amount (aggregated across all received transactions for this correlation). |
| 11 | FiatAmount | DECIMAL | YES | - | CODE-BACKED | Fiat-equivalent value from TransactionTravelRuleInformation. Used for threshold checking and reporting. |
| 12 | RequestCorrelationId | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Correlation ID from travel rule information. Links to the original receive request. |
| 13 | FiatSymbol | VARCHAR | YES | - | CODE-BACKED | Fiat currency symbol (e.g., USD, EUR). |
| 14 | ProviderTransactionId | NVARCHAR | YES | - | CODE-BACKED | Custody provider's transaction identifier. |
| 15 | Status | VARCHAR | NO | - | CODE-BACKED | Hardcoded value 'PendingManualApproval'. Indicates this transaction is awaiting travel rule compliance action. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Gcid, RequestTypeId | Wallet.Requests | JOIN | Anchors receive requests for this customer |
| RequestId | Wallet.TransactionTravelRuleInformation | JOIN | Travel rule details |
| TransactionTravelRuleInformationId | Wallet.TransactionTravelRuleStatuses | JOIN | Latest travel rule status per request |
| ReceiveRequestCorrelationId | Wallet.ReceivedTransactions | CTE | Received transaction amounts and details |

### 5.2 Referenced By (other objects point to this)

No direct SQL callers found. Called by customer-facing APIs and compliance dashboards.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetPendingTravelRuleTransactions (procedure)
+-- Wallet.TransactionTravelRuleStatuses (table)
+-- Wallet.TransactionTravelRuleInformation (table)
+-- Wallet.Requests (table)
+-- Wallet.ReceivedTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionTravelRuleStatuses | Table | CTE - latest travel rule status |
| Wallet.TransactionTravelRuleInformation | Table | JOIN - travel rule details, fiat amounts |
| Wallet.Requests | Table | JOIN - receive request context |
| Wallet.ReceivedTransactions | Table | CTE - amounts and transaction details |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get pending travel rule transactions for a customer
```sql
EXEC Wallet.GetPendingTravelRuleTransactions @Gcid = 12345, @Limit = 5;
```

### 8.2 Count pending travel rule transactions across all customers
```sql
SELECT r.Gcid, COUNT(*) AS PendingCount
FROM Wallet.TransactionTravelRuleStatuses trts WITH (NOLOCK)
JOIN Wallet.TransactionTravelRuleInformation tri WITH (NOLOCK) ON tri.Id = trts.TransactionTravelRuleInformationId
JOIN Wallet.Requests r WITH (NOLOCK) ON r.Id = tri.RequestId
WHERE r.RequestTypeId = 8 AND trts.TravelRuleStatusId IN (0, 3)
GROUP BY r.Gcid
ORDER BY PendingCount DESC;
```

### 8.3 Check travel rule status distribution
```sql
SELECT trts.TravelRuleStatusId, COUNT(*) AS StatusCount
FROM Wallet.TransactionTravelRuleStatuses trts WITH (NOLOCK)
JOIN Wallet.TransactionTravelRuleInformation tri WITH (NOLOCK) ON tri.Id = trts.TransactionTravelRuleInformationId
GROUP BY trts.TravelRuleStatusId
ORDER BY trts.TravelRuleStatusId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetPendingTravelRuleTransactions | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetPendingTravelRuleTransactions.sql*
