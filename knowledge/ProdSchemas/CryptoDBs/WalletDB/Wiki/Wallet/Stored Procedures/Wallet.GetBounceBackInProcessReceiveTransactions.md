# Wallet.GetBounceBackInProcessReceiveTransactions

> Retrieves received crypto transactions that are in the "bounce back initiated" state (request status 36) for a customer, used to display pending return-to-sender transactions in the UI.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns received transactions with bounce-back status |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves received transactions that are in the process of being bounced back (returned to sender). A bounce-back occurs when eToro receives crypto that cannot be credited to a customer (e.g., sent to a deactivated wallet, from a sanctioned address, or exceeding limits). The system initiates a return of the funds to the sender. This procedure provides the list of such in-progress bounce-backs for a customer.

Without this procedure, the application could not display pending bounce-back transactions to customers or operations, leaving them unaware that received funds are being returned.

The procedure uses a CTE with CROSS APPLY to efficiently find requests with the latest status = 36 (BounceBackInitiated), then joins through CorrelatedRequests to find the associated ReceivedTransactions.

---

## 2. Business Logic

### 2.1 Bounce-Back Status Filter

**What**: Identifies transactions in the bounce-back pipeline via request status 36.

**Columns/Parameters Involved**: `RequestStatuses.RequestStatusId`, `CorrelatedRequests`, `ReceivedTransactions`

**Rules**:
- Finds Requests for the customer where the latest RequestStatusId = 36 (BounceBackInitiated)
- Joins through CorrelatedRequests to link the bounce-back request to the original receive
- Uses ReceivedTransactions.ReceiveRequestCorrelationId = CorrelatedRequests.ParentRequestCorrelationId for the link
- Returns a hardcoded Status column = 'BounceBackInitiated'
- Note: SenderAddress is aliased as ToAddress and ReceiverAddress as FromAddress (reversed because the bounce-back sends BACK to the original sender)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID whose bounce-back transactions to retrieve. |
| 2 | @Limit | int | YES | 10 | CODE-BACKED | Maximum number of records to return. Defaults to 10. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.Requests | Reader | Finds requests with bounce-back status |
| - | Wallet.RequestStatuses | Reader | Gets latest status per request |
| - | Wallet.CorrelatedRequests | Reader | Links bounce-back request to original receive |
| - | Wallet.ReceivedTransactions | Reader | Source of received transaction details |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetBounceBackInProcessReceiveTransactions (procedure)
  ├── Wallet.Requests (table)
  ├── Wallet.RequestStatuses (table)
  ├── Wallet.CorrelatedRequests (table)
  └── Wallet.ReceivedTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | CTE source - finds requests for GCID |
| Wallet.RequestStatuses | Table | CROSS APPLY - latest status check |
| Wallet.CorrelatedRequests | Table | JOIN - links bounce request to receive |
| Wallet.ReceivedTransactions | Table | JOIN - gets received transaction details |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- SET NOCOUNT ON
- NOLOCK hints on all tables
- CTE with CROSS APPLY for efficient latest-status pattern
- TOP(@Limit) ORDER BY Occurred DESC

---

## 8. Sample Queries

### 8.1 Get bounce-back transactions for a customer
```sql
EXEC Wallet.GetBounceBackInProcessReceiveTransactions @Gcid = 12345678, @Limit = 20
```

### 8.2 Find all requests in bounce-back status
```sql
SELECT r.Id, r.CorrelationId, r.Gcid
FROM Wallet.Requests r WITH (NOLOCK)
CROSS APPLY (
    SELECT TOP 1 RequestStatusId FROM Wallet.RequestStatuses WITH (NOLOCK)
    WHERE RequestId = r.Id ORDER BY Id DESC
) rs
WHERE rs.RequestStatusId = 36
```

### 8.3 Count bounce-backs by crypto
```sql
SELECT rt.CryptoId, COUNT(*) AS BounceBackCount
FROM Wallet.ReceivedTransactions rt WITH (NOLOCK)
JOIN Wallet.CorrelatedRequests cr WITH (NOLOCK) ON rt.ReceiveRequestCorrelationId = cr.ParentRequestCorrelationId
JOIN Wallet.Requests r WITH (NOLOCK) ON r.CorrelationId = cr.ParentRequestCorrelationId
CROSS APPLY (
    SELECT TOP 1 RequestStatusId FROM Wallet.RequestStatuses WITH (NOLOCK)
    WHERE RequestId = r.Id ORDER BY Id DESC
) rs
WHERE rs.RequestStatusId = 36
GROUP BY rt.CryptoId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetBounceBackInProcessReceiveTransactions | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetBounceBackInProcessReceiveTransactions.sql*
