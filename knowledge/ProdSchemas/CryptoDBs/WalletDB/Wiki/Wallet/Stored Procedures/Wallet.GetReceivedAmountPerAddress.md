# Wallet.GetReceivedAmountPerAddress

> Calculates the total received crypto amount per blockchain address for a given set of addresses, used for balance reconciliation and address utilization tracking.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns total received amount per address |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure computes the total amount of cryptocurrency received at each blockchain address from a caller-provided list. It sums all inbound transactions recorded in `Wallet.ReceivedTransactions` for each address, regardless of transaction status or type.

This is useful for balance reconciliation - comparing the total received on-chain against the wallet system's recorded balance to detect discrepancies. It can also be used for address utilization analysis to understand which addresses have received the most volume.

The procedure accepts a table-valued parameter of addresses (Wallet.NvarcharListType) and JOINs directly to ReceivedTransactions on ReceiverAddress. Addresses with no received transactions will not appear in the results.

---

## 2. Business Logic

### 2.1 Address-Level Aggregation

**What**: Sums all received transaction amounts per receiver address.

**Columns/Parameters Involved**: `@Addresses`, `ReceivedTransactions.ReceiverAddress`, `ReceivedTransactions.Amount`

**Rules**:
- JOIN (not LEFT JOIN) means addresses with zero received transactions are excluded from results
- All received transactions are included regardless of status (no status filtering)
- Amount is summed with full precision (decimal)
- Results grouped by address (a.Item)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Addresses | Wallet.NvarcharListType | NO | READONLY | CODE-BACKED | Table-valued parameter containing the blockchain addresses to query. Each Item is a receiver address string to look up in ReceivedTransactions. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Address | nvarchar | NO | - | CODE-BACKED | The blockchain receiver address from the input list. Aliased from @Addresses.Item. |
| 2 | Amount | decimal | YES | - | CODE-BACKED | Total sum of all received transaction amounts for this address. NULL only if no transactions found (though JOIN prevents this). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Addresses | Wallet.NvarcharListType | UDT | Table-valued parameter type for address list |
| ReceiverAddress | Wallet.ReceivedTransactions | JOIN | Matches addresses to received transactions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No SQL callers found) | - | - | Called from application layer for reconciliation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetReceivedAmountPerAddress (procedure)
├── Wallet.ReceivedTransactions (table)
└── Wallet.NvarcharListType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ReceivedTransactions | Table | JOIN to sum amounts by receiver address |
| Wallet.NvarcharListType | User Defined Type | Parameter type for address list |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No dependents found in SQL) | - | Called from application/reconciliation layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No NOLOCK hint | Read isolation | Unlike most procedures, this one does NOT use NOLOCK - reads are fully consistent (important for reconciliation accuracy) |

---

## 8. Sample Queries

### 8.1 Check received amounts for specific addresses
```sql
DECLARE @Addrs Wallet.NvarcharListType;
INSERT INTO @Addrs (Item) VALUES ('bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh');
INSERT INTO @Addrs (Item) VALUES ('0x742d35Cc6634C0532925a3b844Bc9e7595f2bD18');
EXEC Wallet.GetReceivedAmountPerAddress @Addresses = @Addrs;
```

### 8.2 Manual query to find top receiving addresses
```sql
SELECT TOP 10 ReceiverAddress, SUM(Amount) AS TotalReceived, COUNT(*) AS TxCount
FROM Wallet.ReceivedTransactions WITH (NOLOCK)
GROUP BY ReceiverAddress
ORDER BY TotalReceived DESC;
```

### 8.3 Reconcile received amounts against wallet balances
```sql
SELECT rt.ReceiverAddress, SUM(rt.Amount) AS TotalReceived,
    wb.Balance AS CurrentBalance
FROM Wallet.ReceivedTransactions rt WITH (NOLOCK)
    JOIN Wallet.WalletAddresses wa WITH (NOLOCK) ON wa.Address = rt.ReceiverAddress
    JOIN Wallet.WalletBalances wb WITH (NOLOCK) ON wb.WalletId = wa.WalletId
GROUP BY rt.ReceiverAddress, wb.Balance;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetReceivedAmountPerAddress | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetReceivedAmountPerAddress.sql*
