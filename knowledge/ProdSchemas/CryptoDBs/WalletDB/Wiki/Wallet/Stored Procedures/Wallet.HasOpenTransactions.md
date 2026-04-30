# Wallet.HasOpenTransactions

> Checks whether a customer has any open (non-final) wallet transactions within the last 24 hours for a specific crypto, excluding a specified correlation ID, used by the back-office API to prevent concurrent operations.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns scalar 1/0 for open transaction existence |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure checks whether a customer has any in-progress wallet operations that haven't reached a final state. It's a concurrency guard - the back-office API calls this before allowing new operations to prevent conflicts (e.g., a customer shouldn't start a conversion while a send is still pending). The check is limited to the last 24 hours and only considers specific operation types: SendTransaction(1), Conversion(4), ConversionToFiat(7), ConversionToPosition(9).

The @CorrelationId parameter excludes the current operation from the check (preventing it from blocking itself). The @FinalStatusIds parameter is a comma-separated list of status IDs that are considered "final" (completed/failed) - any request NOT in a final status is considered "open."

---

## 2. Business Logic

### 2.1 Open Transaction Detection

**What**: Detects non-final requests within a 24-hour window.

**Columns/Parameters Involved**: `@Gcid`, `@CryptoId`, `@FinalStatusIds`, `@CorrelationId`

**Rules**:
- Checks Requests WHERE RequestTypeId IN (1, 4, 7, 9) - only fund-moving operations
- 24-hour window: Timestamp >= DATEADD(HOUR, -24, GETUTCDATE())
- CROSS APPLY gets latest RequestStatuses.RequestStatusId
- If latest status NOT IN @FinalStatuses (parsed from comma-separated string) -> open
- Excludes the current operation via CorrelationId <> @CorrelationId
- Returns 1 if any open transaction found, 0 otherwise

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | VERIFIED | Customer ID to check. |
| 2 | @CryptoId | int | NO | - | VERIFIED | Cryptocurrency to check. |
| 3 | @FinalStatusIds | varchar(100) | NO | - | VERIFIED | Comma-separated list of final request status IDs (e.g., '1,2,5,6,7,16,26,27,33'). Parsed via STRING_SPLIT. |
| 4 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Current operation's CorrelationId to exclude from the check. |
| 5 | HasOpenTransactions (output) | int | NO | - | CODE-BACKED | 1 = at least one open transaction exists, 0 = no open transactions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Gcid + @CryptoId | Wallet.Requests | Filter | Customer+crypto requests in 24h |
| RequestId | Wallet.RequestStatuses | CROSS APPLY | Latest status check |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | - | EXECUTE | Concurrency guard before new operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.HasOpenTransactions (procedure)
+-- Wallet.Requests (table)
+-- Wallet.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | Request lookup by Gcid+CryptoId+type+24h |
| Wallet.RequestStatuses | Table | CROSS APPLY for latest status |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackApiUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check for open transactions
```sql
EXEC Wallet.HasOpenTransactions
    @Gcid = 30351701,
    @CryptoId = 1,
    @FinalStatusIds = '1,2,5,6,7,16,26,27,33',
    @CorrelationId = 'CURRENT-OPERATION-GUID';
```

### 8.2 Direct equivalent
```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM Wallet.Requests r WITH (NOLOCK)
    CROSS APPLY (SELECT TOP 1 rs.RequestStatusId FROM Wallet.RequestStatuses rs WITH (NOLOCK) WHERE rs.RequestId = r.Id ORDER BY rs.Id DESC) ls
    WHERE r.Gcid = 30351701 AND r.CryptoId = 1
        AND r.RequestTypeId IN (1, 4, 7, 9)
        AND r.Timestamp >= DATEADD(HOUR, -24, GETUTCDATE())
        AND ls.RequestStatusId NOT IN (1, 2, 5, 6, 7, 16, 26, 27, 33)
        AND r.CorrelationId <> 'CURRENT-GUID'
) THEN 1 ELSE 0 END;
```

### 8.3 List all open transactions for a customer
```sql
SELECT r.Id, r.CorrelationId, r.RequestTypeId, r.Timestamp,
    (SELECT TOP 1 rs.RequestStatusId FROM Wallet.RequestStatuses rs WITH (NOLOCK) WHERE rs.RequestId = r.Id ORDER BY rs.Id DESC) LatestStatus
FROM Wallet.Requests r WITH (NOLOCK)
WHERE r.Gcid = 30351701 AND r.CryptoId = 1 AND r.RequestTypeId IN (1,4,7,9)
    AND r.Timestamp >= DATEADD(HOUR, -24, GETUTCDATE());
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.HasOpenTransactions | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.HasOpenTransactions.sql*
