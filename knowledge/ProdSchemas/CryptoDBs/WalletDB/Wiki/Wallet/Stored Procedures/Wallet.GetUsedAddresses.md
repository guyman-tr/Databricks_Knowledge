# Wallet.GetUsedAddresses

> Collects all unique blockchain addresses associated with a cryptocurrency - including customer wallet addresses, send destinations, and receive sender/receiver addresses - with pagination for AML and compliance scanning.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns UNION of all addresses for a CryptoId with pagination |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure aggregates all blockchain addresses that have been used in the wallet system for a specific cryptocurrency. It combines four sources using UNION (deduplicating): (1) customer wallet addresses from CustomerWalletsView, (2) send transaction output destination addresses, (3) received transaction sender addresses, and (4) received transaction receiver addresses. The result is a comprehensive address list for a given crypto, sorted alphabetically with OFFSET/FETCH pagination.

The back-office API uses this for compliance scanning - checking all known addresses against watchlists, sanctions lists, or blockchain analytics providers.

---

## 2. Business Logic

### 2.1 Four-Source Address Aggregation

**What**: Combines all address sources into a deduplicated list.

**Columns/Parameters Involved**: `@CryptoId`, `@Take`, `@Skip`

**Rules**:
- Source 1: CustomerWalletsView.Address WHERE CryptoId = @CryptoId
- Source 2: SentTransactionOutputs.ToAddress WHERE SentTransactions.CryptoId = @CryptoId AND ToAddress IS NOT NULL
- Source 3: ReceivedTransactions.SenderAddress WHERE CryptoId = @CryptoId AND SenderAddress IS NOT NULL
- Source 4: ReceivedTransactions.ReceiverAddress WHERE CryptoId = @CryptoId AND ReceiverAddress IS NOT NULL
- UNION deduplicates across all four sources
- ORDER BY Address with OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CryptoId | int | NO | - | VERIFIED | Cryptocurrency to collect addresses for. FK to Wallet.CryptoTypes. |
| 2 | @Take | int | YES | 10000 | CODE-BACKED | Number of addresses to return per page. |
| 3 | @Skip | int | YES | 0 | CODE-BACKED | Number of addresses to skip for pagination. |
| 4 | Address (output) | nvarchar | NO | - | CODE-BACKED | A blockchain address from any of the four sources. Deduplicated across sources. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CryptoId | Wallet.CustomerWalletsView | Filter | Customer wallet addresses |
| @CryptoId | Wallet.SentTransactions + SentTransactionOutputs | JOIN + Filter | Send destination addresses |
| @CryptoId | Wallet.ReceivedTransactions | Filter | Sender and receiver addresses |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | - | EXECUTE | Compliance address scanning |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetUsedAddresses (procedure)
+-- Wallet.CustomerWalletsView (view)
+-- Wallet.SentTransactions (table)
+-- Wallet.SentTransactionOutputs (table)
+-- Wallet.ReceivedTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | Customer wallet addresses |
| Wallet.SentTransactions | Table | JOINed for CryptoId filter on outputs |
| Wallet.SentTransactionOutputs | Table | Send destination addresses |
| Wallet.ReceivedTransactions | Table | Sender and receiver addresses |

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

### 8.1 Get first page of BTC addresses
```sql
EXEC Wallet.GetUsedAddresses @CryptoId = 1, @Take = 1000, @Skip = 0;
```

### 8.2 Get second page
```sql
EXEC Wallet.GetUsedAddresses @CryptoId = 1, @Take = 1000, @Skip = 1000;
```

### 8.3 Count total addresses for a crypto
```sql
SELECT COUNT(DISTINCT Address) FROM (
    SELECT Address FROM Wallet.CustomerWalletsView WHERE CryptoId = 1
    UNION
    SELECT sto.ToAddress FROM Wallet.SentTransactionOutputs sto WITH (NOLOCK)
        JOIN Wallet.SentTransactions st WITH (NOLOCK) ON sto.SentTransactionId = st.Id
    WHERE st.CryptoId = 1 AND sto.ToAddress IS NOT NULL
    UNION
    SELECT SenderAddress FROM Wallet.ReceivedTransactions WITH (NOLOCK) WHERE CryptoId = 1 AND SenderAddress IS NOT NULL
    UNION
    SELECT ReceiverAddress FROM Wallet.ReceivedTransactions WITH (NOLOCK) WHERE CryptoId = 1 AND ReceiverAddress IS NOT NULL
) x;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetUsedAddresses | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetUsedAddresses.sql*
