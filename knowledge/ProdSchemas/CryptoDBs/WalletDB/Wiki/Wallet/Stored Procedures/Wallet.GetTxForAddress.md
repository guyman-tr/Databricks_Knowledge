# Wallet.GetTxForAddress

> Retrieves saga-tracked send transactions for a given blockchain address with pagination, used by AML and balance services to inspect outbound transaction details for a specific wallet address.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns SagaSendTx rows by wallet address with pagination |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves saga-tracked outbound transactions for a specific blockchain address. It first resolves the address to a WalletID via the legacy `WalletAddress` table (note: references `WalletAddress` without schema prefix, suggesting a dbo synonym or legacy table), then queries `Wallet.SagaSendTx` for all send transactions from that wallet.

Two services consume this: the AML service (investigating outbound transaction patterns for a specific address) and the balance service (reconciling address-level send history). The procedure supports pagination via @ItemsPerPage and @PageNumber, and time filtering via @StartTime, though the current implementation does not use @StartTime or the pagination parameters in the actual query - these appear to be reserved for future use.

---

## 2. Business Logic

### 2.1 Address-to-Wallet Resolution

**What**: Resolves a blockchain address to its internal WalletID before querying transactions.

**Columns/Parameters Involved**: `@address`, `WalletAddress.address`, `WalletAddress.WalletID`

**Rules**:
- Uses the legacy WalletAddress table (dbo schema) to resolve address -> WalletID
- The resolved WalletID is then used to filter SagaSendTx
- If the address doesn't exist in WalletAddress, @walletId will be NULL and no results return

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @address | varchar(512) | NO | - | VERIFIED | The blockchain address to look up send transactions for. Resolved to WalletID via WalletAddress table. |
| 2 | @ItemsPerPage | int | NO | - | CODE-BACKED | Pagination: items per page. Currently unused in the query body (reserved for future use). |
| 3 | @PageNumber | int | NO | - | CODE-BACKED | Pagination: page number. Currently unused in the query body (reserved for future use). |
| 4 | @StartTime | datetime | NO | - | CODE-BACKED | Time filter. Currently unused in the query body (reserved for future use). |
| 5 | DestAddress (output) | varchar | NO | - | CODE-BACKED | Destination blockchain address of the send transaction. |
| 6 | CryptoID (output) | int | NO | - | CODE-BACKED | Cryptocurrency sent. FK to Wallet.CryptoTypes. |
| 7 | Amount (output) | decimal | NO | - | CODE-BACKED | Amount of crypto sent. |
| 8 | TxHash (output) | nvarchar | YES | - | CODE-BACKED | On-chain transaction hash. |
| 9 | CurrentStepIndex (output) | tinyint | YES | - | CODE-BACKED | Current saga step index. Indicates how far the saga has progressed. |
| 10 | Confirmations (output) | int | YES | - | CODE-BACKED | Number of blockchain confirmations received. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @address | WalletAddress (dbo) | Lookup | Resolves address to WalletID |
| WalletID | Wallet.SagaSendTx.WalletID | Filter | Filters saga send transactions by wallet |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AmlUser | - | EXECUTE | AML investigation of outbound patterns |
| BalanceUser | - | EXECUTE | Address-level send reconciliation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetTxForAddress (procedure)
+-- WalletAddress (legacy table, dbo schema)
+-- Wallet.SagaSendTx (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| WalletAddress | Table (dbo/legacy) | Address-to-WalletID resolution |
| Wallet.SagaSendTx | Table | Send transaction query by WalletID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AmlUser | Service Account | EXECUTE grant |
| BalanceUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get saga send transactions for an address
```sql
EXEC Wallet.GetTxForAddress
    @address = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
    @ItemsPerPage = 100,
    @PageNumber = 1,
    @StartTime = '2026-01-01';
```

### 8.2 Direct query equivalent
```sql
DECLARE @walletId INT = (SELECT WalletID FROM WalletAddress WHERE address = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa');
SELECT DestAddress, CryptoID, Amount, TxHash, CurrentStepIndex, Confirmations
FROM Wallet.SagaSendTx WITH (NOLOCK)
WHERE WalletID = @walletId;
```

### 8.3 Check all addresses for a wallet
```sql
SELECT address FROM WalletAddress WITH (NOLOCK) WHERE WalletID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetTxForAddress | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetTxForAddress.sql*
