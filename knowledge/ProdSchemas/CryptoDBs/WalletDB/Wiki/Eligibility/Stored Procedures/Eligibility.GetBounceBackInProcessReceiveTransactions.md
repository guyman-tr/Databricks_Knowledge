# Eligibility.GetBounceBackInProcessReceiveTransactions

> Retrieves incoming crypto transactions for a customer that are pending bounce-back processing, where a BounceBackPending status exists without a subsequent BounceBackInitiated status.

| Property | Value |
|----------|-------|
| **Schema** | Eligibility |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns received transaction details with 'BounceBackInitiated' status label |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure identifies incoming cryptocurrency transactions that are in the "bounce-back" processing pipeline for a specific customer. Bounce-back is a compliance mechanism where received crypto that cannot be accepted (due to travel rule violations, eligibility restrictions, or other compliance reasons) is returned to the sender's address.

The procedure finds transactions where a BounceBackPending status (36) has been recorded but no subsequent BounceBackInitiated status (37) has followed. These are transactions stuck in the bounce-back queue, possibly awaiting operator action or system processing. The results are used by the Eligibility Service or back-office tools to display in-process bounce-backs.

Note: A newer version of this procedure exists in the Wallet schema (`Wallet.GetBounceBackInProcessReceiveTransactions`) with an updated implementation using CROSS APPLY for better performance. The Eligibility version uses a CTE-based approach.

---

## 2. Business Logic

### 2.1 Bounce-Back Status Detection

**What**: Identifies requests with BounceBackPending but no subsequent BounceBackInitiated.

**Columns/Parameters Involved**: `@Gcid`, Wallet.RequestStatuses.RequestStatusId (36, 37)

**Rules**:
- A request is "in process" if it has RequestStatusId = 36 (BounceBackPending)
- It is excluded if a subsequent record with RequestStatusId = 37 (BounceBackInitiated) exists with a higher Id than the BounceBackPending record
- The MAX(Id) comparison ensures temporal ordering of status records
- Results are joined to ReceivedTransactions via CorrelationId to get transaction details

**Diagram**:
```
Request Status Flow:
  ... -> [36: BounceBackPending] -> [37: BounceBackInitiated] -> ...

This SP finds requests stuck at:
  ... -> [36: BounceBackPending] -> (no 37 yet) = IN PROCESS
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | BIGINT (IN) | NO | - | CODE-BACKED | Global Customer ID to filter bounce-back transactions for. Only transactions belonging to this customer are returned. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | - | CODE-BACKED | ReceivedTransactions.Id - unique identifier of the received transaction record |
| 2 | Occurred | datetime2 | NO | - | CODE-BACKED | Timestamp when the transaction was received on the blockchain |
| 3 | WalletId | bigint | NO | - | CODE-BACKED | Internal wallet that received the transaction |
| 4 | SenderAddress | nvarchar | NO | - | CODE-BACKED | Blockchain address that sent the funds (the address to bounce back to) |
| 5 | ReceiverAddress | nvarchar | NO | - | CODE-BACKED | Blockchain address that received the funds (the customer's wallet address) |
| 6 | Amount | decimal | NO | - | CODE-BACKED | Amount of cryptocurrency received in the transaction |
| 7 | ProviderTransactionId | nvarchar | YES | - | CODE-BACKED | External transaction hash/ID from the blockchain provider |
| 8 | Status | varchar | NO | - | CODE-BACKED | Hardcoded string 'BounceBackInitiated' indicating these transactions are in bounce-back processing |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Wallet.Requests | JOIN | Filters requests by Gcid and finds those with BounceBackPending status |
| FROM | Wallet.RequestStatuses | Subquery | Checks for presence/absence of specific status codes (36, 37) |
| FROM | Wallet.ReceivedTransactions | JOIN | Gets transaction details for matching requests |
| FROM | Wallet.CustomerWalletsView | JOIN | Links wallet to customer Gcid |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.GetBounceBackInProcessReceiveTransactions | Equivalent | Related procedure | Newer Wallet-schema version with updated implementation |

---

## 6. Dependencies

```
Eligibility.GetBounceBackInProcessReceiveTransactions (procedure)
+-- Wallet.Requests (table)
+-- Wallet.RequestStatuses (table)
+-- Wallet.ReceivedTransactions (table)
+-- Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | Filtered by Gcid, joined via CorrelationId |
| Wallet.RequestStatuses | Table | Checked for BounceBackPending (36) and BounceBackInitiated (37) statuses |
| Wallet.ReceivedTransactions | Table | Source of transaction detail columns returned |
| Wallet.CustomerWalletsView | View | Links WalletId to Gcid for customer filtering |

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

### 8.1 Execute to find bounce-back transactions for a customer
```sql
EXEC Eligibility.GetBounceBackInProcessReceiveTransactions @Gcid = 12345678
```

### 8.2 Check if a customer has any pending bounce-backs
```sql
DECLARE @Results TABLE (Id BIGINT, Occurred DATETIME2, WalletId BIGINT, SenderAddress NVARCHAR(512), ReceiverAddress NVARCHAR(512), Amount DECIMAL(38,18), ProviderTransactionId NVARCHAR(256), Status VARCHAR(50))
INSERT INTO @Results EXEC Eligibility.GetBounceBackInProcessReceiveTransactions @Gcid = 12345678
SELECT COUNT(*) AS PendingBouncebacks FROM @Results
```

### 8.3 Review all RequestStatuses for a bounce-back request
```sql
SELECT rs.Id, rs.RequestStatusId, rs.RequestId
FROM Wallet.RequestStatuses rs WITH (NOLOCK)
WHERE rs.RequestId = @RequestId
ORDER BY rs.Id DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Eligibility.GetBounceBackInProcessReceiveTransactions | Type: Stored Procedure | Source: WalletDB/Eligibility/Stored Procedures/Eligibility.GetBounceBackInProcessReceiveTransactions.sql*
