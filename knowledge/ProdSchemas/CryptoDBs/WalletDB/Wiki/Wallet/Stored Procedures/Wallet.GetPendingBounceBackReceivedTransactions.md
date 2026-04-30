# Wallet.GetPendingBounceBackReceivedTransactions

> Retrieves received transactions in BounceBackPending state (RequestStatusId=36) that have not yet been initiated for bounceback, including travel rule context for transaction type classification.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns received transactions ready for bounceback execution |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure identifies received crypto transactions that are queued for bounceback (return to sender) and have not yet been initiated. Unlike `Wallet.GetMustBouncebackTransactions` which identifies travel-rule-failed transactions that SHOULD be bounced back, this procedure finds transactions that have already been flagged for bounceback (RequestStatusId=36) and are ready for the execution service to process.

The bounceback flow involves two stages: (1) flagging a transaction as BounceBackPending (status 36), and (2) initiating the actual return transaction (status 37). This procedure bridges the gap between stages by finding transactions at stage 1 that haven't reached stage 2. The NOT EXISTS clause with the ID comparison handles resubmission: if a transaction was re-flagged as BounceBackPending AFTER a failed BounceBackInitiated, it will appear again.

The TransactionType output (2 or 15) classifies the bounceback based on whether the transaction has a travel rule cancellation. Type 15 indicates a travel-rule-related bounceback; type 2 is a standard bounceback.

---

## 2. Business Logic

### 2.1 BounceBack State Machine

**What**: Finds receive requests in BounceBackPending state not yet progressed to BounceBackInitiated.

**Columns/Parameters Involved**: `RequestStatusId`, `RequestTypeId`

**Rules**:
- RequestTypeId=8 (Receive requests only)
- EXISTS RequestStatusId=36 (BounceBackPending - the request has been flagged for return)
- NOT EXISTS RequestStatusId=37 (BounceBackInitiated) with Id > max BounceBackPending Id
- This handles resubmission: if a bounceback failed and was re-queued, the latest 36 must not have a corresponding 37 after it
- TOP @RecordsLimit caps the batch, ordered by rt.Id DESC (newest first)

### 2.2 Transaction Type Classification

**What**: Determines whether the bounceback is travel-rule-related.

**Columns/Parameters Involved**: `TravelRuleStatusId`, `TransactionType`

**Rules**:
- If no travel rule information or no Canceled status (trs.Id IS NULL): TransactionType = 2 (standard bounceback)
- If travel rule status Canceled exists (TravelRuleStatusId=2): TransactionType = 15 (travel-rule bounceback)
- This classification affects how the bounceback is processed and reported

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RecordsLimit | INT | YES | 1000 | CODE-BACKED | Maximum number of pending bounceback transactions to return. Default 1000. Controls batch size for the bounceback execution service. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | ReceivedTransactionId | BIGINT | NO | - | CODE-BACKED | ReceivedTransactions record ID. Identifies the incoming transaction to be returned. |
| 3 | Gcid | BIGINT | NO | - | CODE-BACKED | Global Customer ID from the request. Identifies the customer whose received transaction is being bounced back. |
| 4 | WalletId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | The wallet that received the funds. The bounceback transaction will be sent FROM this wallet. |
| 5 | Address | NVARCHAR | YES | - | CODE-BACKED | Sender's address (aliased from SenderAddress). The bounceback transaction sends funds TO this address (back to original sender). |
| 6 | Amount | DECIMAL | NO | - | CODE-BACKED | Amount of crypto received. The bounceback will return this amount (minus fees). |
| 7 | Fee | DECIMAL | YES | - | CODE-BACKED | Blockchain fee from the original received transaction (aliased from BlockchainFee). |
| 8 | CorrelationId | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Request correlation ID. Links this bounceback to the original receive request. |
| 9 | RequestId | BIGINT | NO | - | CODE-BACKED | Request record ID. Used to update request status to BounceBackInitiated (37) after processing. |
| 10 | CryptoId | INT | NO | - | CODE-BACKED | Cryptocurrency of the transaction. FK to Wallet.CryptoTypes. |
| 11 | TransactionType | INT | NO | - | CODE-BACKED | Bounceback classification: 2=standard bounceback, 15=travel-rule-related bounceback. Determined by presence of travel rule cancellation status. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RequestTypeId, RequestStatusId | Wallet.Requests + Wallet.RequestStatuses | CTE | Finds receive requests in BounceBackPending state |
| ReceiveRequestCorrelationId | Wallet.ReceivedTransactions | JOIN | Gets received transaction details |
| RequestId | Wallet.TransactionTravelRuleInformation | LEFT JOIN | Travel rule context |
| TransactionTravelRuleInformationId | Wallet.TransactionTravelRuleStatuses | LEFT JOIN | Travel rule cancellation check |

### 5.2 Referenced By (other objects point to this)

No direct SQL callers found. Called by the bounceback execution service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetPendingBounceBackReceivedTransactions (procedure)
+-- Wallet.Requests (table)
+-- Wallet.RequestStatuses (table)
+-- Wallet.ReceivedTransactions (table)
+-- Wallet.TransactionTravelRuleInformation (table)
+-- Wallet.TransactionTravelRuleStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | CTE - receive request lookup |
| Wallet.RequestStatuses | Table | EXISTS/NOT EXISTS - status 36/37 check |
| Wallet.ReceivedTransactions | Table | JOIN - transaction details |
| Wallet.TransactionTravelRuleInformation | Table | LEFT JOIN - travel rule context |
| Wallet.TransactionTravelRuleStatuses | Table | LEFT JOIN - travel rule cancellation check |

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

### 8.1 Get pending bounceback transactions
```sql
EXEC Wallet.GetPendingBounceBackReceivedTransactions @RecordsLimit = 50;
```

### 8.2 Count pending bouncebacks by crypto
```sql
SELECT rt.CryptoId, COUNT(*) AS PendingCount
FROM Wallet.Requests r WITH (NOLOCK)
JOIN Wallet.ReceivedTransactions rt WITH (NOLOCK) ON rt.ReceiveRequestCorrelationId = r.CorrelationId
WHERE r.RequestTypeId = 8
    AND EXISTS (SELECT 1 FROM Wallet.RequestStatuses rs WITH (NOLOCK) WHERE rs.RequestId = r.Id AND rs.RequestStatusId = 36)
    AND NOT EXISTS (SELECT 1 FROM Wallet.RequestStatuses rs2 WITH (NOLOCK) WHERE rs2.RequestId = r.Id AND rs2.RequestStatusId = 37)
GROUP BY rt.CryptoId;
```

### 8.3 Check bounceback request status distribution
```sql
SELECT rs.RequestStatusId, COUNT(*) AS RequestCount
FROM Wallet.Requests r WITH (NOLOCK)
JOIN Wallet.RequestStatuses rs WITH (NOLOCK) ON rs.RequestId = r.Id
WHERE r.RequestTypeId = 8 AND rs.RequestStatusId IN (36, 37)
GROUP BY rs.RequestStatusId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetPendingBounceBackReceivedTransactions | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetPendingBounceBackReceivedTransactions.sql*
