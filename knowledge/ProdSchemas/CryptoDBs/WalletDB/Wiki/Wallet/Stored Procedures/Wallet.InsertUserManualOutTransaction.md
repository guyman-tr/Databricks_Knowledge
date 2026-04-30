# Wallet.InsertUserManualOutTransaction

> Creates a user-level manual outbound transaction (Gcid != 0) with validation that exactly one active UserMoneyOut external address exists for the crypto, always emptying the entire wallet balance.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into ManualOutTransactions (user-level, Gcid!=0, EmptyWallet=1) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure creates a manual outbound transaction for a specific customer (not omnibus). Unlike InsertOmnibusManualOutTransaction (Gcid=0), this requires Gcid != 0 and validates that exactly one active 'UserMoneyOut' external address exists for the crypto (RAISERROR if zero or more than one). EmptyWallet is always set to 1 (sends the entire wallet balance). A new CorrelationId is auto-generated.

Three validations: (1) Gcid != 0, (2) at least one active external address exists, (3) exactly one UserMoneyOut address exists (no ambiguity).

---

## 2. Business Logic

### 2.1 Three-Step Validation

**What**: Validates Gcid, address existence, and address uniqueness before insertion.

**Rules**:
- @Gcid = 0 -> RAISERROR "Gcid must not be 0"
- No active EtoroExternalAddresses for @CryptoId -> RAISERROR "No external address found"
- More than one active UserMoneyOut address for @CryptoId -> RAISERROR "More than one external address found"
- EmptyWallet = 1 (always sends entire balance, unlike omnibus which sends specific amount)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | VERIFIED | Customer (must be non-zero). |
| 2 | @CryptoId | int | NO | - | VERIFIED | Cryptocurrency. |
| 3 | @WalletId | uniqueidentifier | NO | - | VERIFIED | Source wallet. |
| 4 | @Amount | decimal(36,18) | NO | - | CODE-BACKED | Amount (though EmptyWallet=1 sends all). |
| 5 | @Comment | nvarchar(256) | NO | - | CODE-BACKED | Operator's reason. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.ManualOutTransactions | INSERT | Creates manual out record |
| @CryptoId | Wallet.EtoroExternalAddresses | JOIN | UserMoneyOut address resolution |
| - | Dictionary.ExternalAddressTypes | JOIN | Type filter ('UserMoneyOut') |
| @WalletId | Wallet.CustomerWalletsView | JOIN | Wallet validation |

### 5.2 Referenced By (other objects point to this)

No direct EXECUTE grants found. Called through admin interfaces.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertUserManualOutTransaction (procedure)
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
| Dictionary.ExternalAddressTypes | Table | Type filter |
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

### 8.1 Create a user manual out transaction
```sql
EXEC Wallet.InsertUserManualOutTransaction @Gcid=30351701, @CryptoId=1, @WalletId='WALLET-GUID', @Amount=0.5, @Comment='Manual withdrawal approved';
```

### 8.2 Compare with omnibus version
```sql
-- User (Gcid!=0, EmptyWallet=1, this SP): EXEC Wallet.InsertUserManualOutTransaction @Gcid=30351701, ...
-- Omnibus (Gcid=0, EmptyWallet=0): EXEC Wallet.InsertOmnibusManualOutTransaction @Gcid=0, ...
```

### 8.3 Check UserMoneyOut addresses
```sql
SELECT eea.* FROM Wallet.EtoroExternalAddresses eea WITH (NOLOCK) JOIN Dictionary.ExternalAddressTypes eat ON eat.Id = eea.ExternalAddressTypeId WHERE eat.Name = 'UserMoneyOut' AND eea.CryptoId = 1 AND eea.IsActive = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertUserManualOutTransaction | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertUserManualOutTransaction.sql*
