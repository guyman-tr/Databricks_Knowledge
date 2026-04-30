# Wallet.ManualOutTransactions

> Records manually-initiated outbound crypto transactions authorized by operations staff, used for omnibus and user-specific manual withdrawals with an insert-only audit trigger.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active NC + 1 clustered PK |
| **Trigger** | OmnibusManualOutTransactionsInsertOnly - prevents DELETE and UPDATE |

---

## 1. Business Meaning

This table stores manually-initiated outbound crypto transactions that bypass the normal automated pipeline. These are authorized by operations staff for scenarios like omnibus wallet rebalancing, manual user withdrawals, or emergency fund movements. Each row records the wallet, crypto, amount, destination address (via EtoroExternalAddressId), and an operator comment.

The insert-only trigger `OmnibusManualOutTransactionsInsertOnly` prevents any DELETE or UPDATE, ensuring a tamper-proof audit trail of all manual fund movements.

---

## 2. Business Logic

### 2.1 Insert-Only Audit Trail

**What**: Once recorded, manual transactions cannot be modified or deleted.

**Columns/Parameters Involved**: All columns

**Rules**:
- INSTEAD OF DELETE/UPDATE trigger raises error: "Delete is not allowed on this table"
- Ensures regulatory compliance for manual fund movement auditing
- EmptyWallet flag indicates whether the entire wallet balance was sent

---

## 3. Data Overview

N/A for operations-controlled table with audit trigger.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. |
| 2 | Gcid | bigint | NO | - | CODE-BACKED | Customer whose wallet the manual transaction is from. |
| 3 | CryptoId | int | NO | - | VERIFIED | Cryptocurrency being sent. FK to Wallet.CryptoTypes.CryptoID. |
| 4 | WalletId | uniqueidentifier | NO | - | VERIFIED | Source wallet. FK to Wallet.Wallets.WalletId. |
| 5 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Links to the request tracking this manual operation. |
| 6 | EtoroExternalAddressId | int | NO | - | VERIFIED | Destination address from the eToro external addresses registry. FK to Wallet.EtoroExternalAddresses.Id. |
| 7 | Amount | decimal(26,18) | NO | - | CODE-BACKED | Amount of crypto to send. |
| 8 | Comment | nvarchar(256) | NO | - | CODE-BACKED | Operator's reason/comment for the manual transaction. Required for audit trail. |
| 9 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp of creation. |
| 10 | EmptyWallet | bit | NO | 0 | CODE-BACKED | Whether to send the entire wallet balance: 1=send all, 0=send specified amount. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CryptoId | Wallet.CryptoTypes | FK | Crypto being sent |
| WalletId | Wallet.Wallets | FK | Source wallet |
| EtoroExternalAddressId | Wallet.EtoroExternalAddresses | FK | Destination address |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.InsertOmnibusManualOutTransaction | - | Writer | Creates records |
| Wallet.InsertUserManualOutTransaction | - | Writer | Creates user manual out records |
| Wallet.GetPendingOmnibusManualOutTransactions | - | Reader | Finds pending manual outs |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.ManualOutTransactions (table)
├── Wallet.CryptoTypes (table)
├── Wallet.Wallets (table)
└── Wallet.EtoroExternalAddresses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoTypes | Table | FK target for CryptoId |
| Wallet.Wallets | Table | FK target for WalletId |
| Wallet.EtoroExternalAddresses | Table | FK target for EtoroExternalAddressId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.InsertOmnibusManualOutTransaction | Stored Procedure | Inserts omnibus manual outs |
| Wallet.InsertUserManualOutTransaction | Stored Procedure | Inserts user manual outs |
| Wallet.GetPendingOmnibusManualOutTransactions | Stored Procedure | Reads pending |
| Wallet.GetPendingUserManualOutTransactions | Stored Procedure | Reads pending user outs |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_OmnibusManualOutTransactions | CLUSTERED PK | Id ASC | - | - | Active |
| IX_...CryptoId_WalletId | NC | CryptoId, WalletId | - | - | Active |
| IX_...Occurred | NC | Occurred DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_...Occurred | DEFAULT | getutcdate() |
| DF (EmptyWallet) | DEFAULT | 0 |
| FK_...CryptoId | FK | -> Wallet.CryptoTypes.CryptoID |
| FK_...EtoroExternalAddressId | FK | -> Wallet.EtoroExternalAddresses.Id |
| FK_...WalletId | FK | -> Wallet.Wallets.WalletId |
| OmnibusManualOutTransactionsInsertOnly | TRIGGER | Prevents DELETE and UPDATE operations |

---

## 8. Sample Queries

### 8.1 Recent manual out transactions
```sql
SELECT mot.Id, ct.Name AS Crypto, mot.Amount, mot.Comment, mot.Occurred
FROM Wallet.ManualOutTransactions mot WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON mot.CryptoId = ct.CryptoID
ORDER BY mot.Occurred DESC
```

### 8.2 Manual outs by crypto
```sql
SELECT ct.Name AS Crypto, COUNT(*) AS Cnt, SUM(mot.Amount) AS TotalAmount
FROM Wallet.ManualOutTransactions mot WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON mot.CryptoId = ct.CryptoID
GROUP BY ct.Name ORDER BY Cnt DESC
```

### 8.3 Find manual out by correlation
```sql
SELECT mot.Id, mot.Gcid, mot.Amount, mot.Comment
FROM Wallet.ManualOutTransactions mot WITH (NOLOCK)
WHERE mot.CorrelationId = '4B26D85F-BF00-4E27-9166-4F8AF2D599D6'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.ManualOutTransactions | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.ManualOutTransactions.sql*
