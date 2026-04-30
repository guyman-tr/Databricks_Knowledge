# Wallet.InsertOmnibusManualOutTransaction

> Creates an omnibus-level manual outbound transaction for system-wide fund movements (Gcid must be 0), validating the destination address against the active OmnibusMoneyOut external address registry.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Wallet.ManualOutTransactions (omnibus only, Gcid=0) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure creates a manual outbound transaction for omnibus wallet operations - system-level fund movements (not customer-initiated). It enforces that Gcid must be 0 (omnibus, not a real customer), validates the destination address exists as an active 'OmnibusMoneyOut' external address, and confirms the wallet exists in CustomerWalletsView. A new CorrelationId (NEWID()) is generated for each transaction. EmptyWallet is always 0 (send specific amount, not entire balance).

Unlike InsertUserManualOutTransaction (for customer Gcid != 0), this is for operations team rebalancing between omnibus/hot wallets.

---

## 2. Business Logic

### 2.1 Omnibus-Only Guard

**What**: Enforces Gcid = 0 for omnibus operations.

**Columns/Parameters Involved**: `@Gcid`

**Rules**:
- If @Gcid != 0, RAISERROR and RETURN
- Only system/omnibus wallets (Gcid=0) can use this procedure
- Customer withdrawals use InsertUserManualOutTransaction instead

### 2.2 External Address Validation

**What**: Validates destination against active OmnibusMoneyOut addresses.

**Columns/Parameters Involved**: `@ToAddress`, `@CryptoId`, `EtoroExternalAddresses`, `Dictionary.ExternalAddressTypes`

**Rules**:
- JOIN to EtoroExternalAddresses WHERE Address = @ToAddress AND CryptoId = @CryptoId AND IsActive = 1
- JOIN to Dictionary.ExternalAddressTypes WHERE Name = 'OmnibusMoneyOut'
- If no matching active address exists, INSERT returns 0 rows (silent failure)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | VERIFIED | Must be 0 (omnibus). Non-zero raises an error. |
| 2 | @CryptoId | int | NO | - | VERIFIED | Cryptocurrency for the transaction. FK to Wallet.CryptoTypes. |
| 3 | @WalletId | uniqueidentifier | NO | - | VERIFIED | Source omnibus wallet. Must exist in CustomerWalletsView. |
| 4 | @ToAddress | nvarchar(512) | NO | - | CODE-BACKED | Destination blockchain address. Must be an active OmnibusMoneyOut address. |
| 5 | @Amount | decimal(36,18) | NO | - | CODE-BACKED | Amount of crypto to send. |
| 6 | @Comment | nvarchar(256) | NO | - | CODE-BACKED | Operator's reason/comment for the manual transaction. Required for audit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.ManualOutTransactions | INSERT | Creates manual out record |
| @ToAddress | Wallet.EtoroExternalAddresses | JOIN | Validates destination address |
| ExternalAddressTypeId | Dictionary.ExternalAddressTypes | JOIN | Validates 'OmnibusMoneyOut' type |
| @WalletId | Wallet.CustomerWalletsView | JOIN | Validates wallet exists |

### 5.2 Referenced By (other objects point to this)

No direct EXECUTE grants found. Likely called through privileged admin interfaces.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertOmnibusManualOutTransaction (procedure)
+-- Wallet.ManualOutTransactions (table)
+-- Wallet.EtoroExternalAddresses (table)
+-- Dictionary.ExternalAddressTypes (table)
+-- Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ManualOutTransactions | Table | INSERT target |
| Wallet.EtoroExternalAddresses | Table | Address validation |
| Dictionary.ExternalAddressTypes | Table | Type filter ('OmnibusMoneyOut') |
| Wallet.CustomerWalletsView | View | Wallet validation |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Create an omnibus manual out transaction
```sql
EXEC Wallet.InsertOmnibusManualOutTransaction
    @Gcid = 0, @CryptoId = 1, @WalletId = 'OMNIBUS-WALLET-GUID',
    @ToAddress = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
    @Amount = 1.5, @Comment = 'Rebalancing hot wallet';
```

### 8.2 Compare with user manual out
```sql
-- Omnibus (Gcid=0, this SP): EXEC Wallet.InsertOmnibusManualOutTransaction @Gcid=0, ...
-- User (Gcid!=0): EXEC Wallet.InsertUserManualOutTransaction @Gcid=30351701, ...
```

### 8.3 Check pending manual out transactions
```sql
SELECT * FROM Wallet.ManualOutTransactions WITH (NOLOCK) WHERE Gcid = 0 ORDER BY Id DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertOmnibusManualOutTransaction | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertOmnibusManualOutTransaction.sql*
