# Wallet.EtoroExternalAddresses

> Registry of eToro-controlled external blockchain addresses used to route outbound funds - covering omnibus consolidation, user withdrawals, crypto-to-fiat conversions, and crypto-to-position movements.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK + FK indexes on CryptoId, ExternalAddressTypeId |

---

## 1. Business Meaning

This table maintains the authoritative list of blockchain addresses that eToro itself controls for routing outbound crypto funds. Unlike customer wallet addresses, these are institutional addresses owned and operated by eToro for specific operational purposes: consolidating omnibus wallets, processing user withdrawals, converting crypto to fiat, and moving crypto into position accounts. With 170 rows spanning multiple cryptocurrencies, the table is a tightly-managed configuration registry rather than a high-volume transaction log.

The table is the source of truth for "where should funds go?" when the system needs to move crypto off the platform or between internal systems. Operations teams manage this list carefully - adding an incorrect address could result in irreversible loss of funds on the blockchain. The `IsActive` flag allows addresses to be decommissioned without deletion, preserving historical referenceability.

An insert-only trigger enforces immutability of existing rows - once an address is written, its data cannot be modified. Any change requires inserting a new row (typically with the old row set to `IsActive=0`). This protects the integrity of the address registry and provides an implicit audit trail. `Wallet.ManualOutTransactions` references these addresses when constructing manual withdrawal instructions.

---

## 2. Business Logic

### 2.1 Address Type Routing

**What**: Each address is classified by its operational purpose, determining which outbound flow uses it.

**Columns/Parameters Involved**: `ExternalAddressTypeId`, `Address`, `CryptoId`, `IsActive`

**Rules**:
- ExternalAddressTypeId=1 (OmnibusMoneyOut): Address receives consolidated funds from omnibus wallets during sweep operations
- ExternalAddressTypeId=2 (UserMoneyOut): Destination for customer-initiated withdrawal (crypto sent to external user wallet)
- ExternalAddressTypeId=3 (CryptoToFiat): Address used when converting crypto holdings to fiat currency via an exchange or liquidity provider
- ExternalAddressTypeId=4 (CryptoToPosition): Internal routing address for moving crypto into leveraged position collateral
- Only `IsActive=1` rows should be used for new transactions; `IsActive=0` rows are retired
- Implicit FK to Dict.ExternalAddressTypes; enforced FK to Dict.ExternalAddressTypes via ExternalAddressTypeId column

### 2.2 Insert-Only Trigger (Immutability)

**What**: A DML trigger prevents UPDATE and DELETE operations, ensuring the address registry is append-only.

**Columns/Parameters Involved**: All columns

**Rules**:
- Any attempt to UPDATE or DELETE a row raises an error
- To retire an address, a new row must be inserted with `IsActive=0` referencing the same address, or the address is superseded by a new active row
- This guarantees that historical references from ManualOutTransactions always resolve to the original address value

---

## 3. Data Overview

| Id | Address (truncated) | ExternalAddressTypeId | CryptoId | IsActive | Meaning |
|---|---|---|---|---|---|
| 1 | 1A1zP1eP... | 1 (OmnibusMoneyOut) | 1 (BTC) | 1 | Primary BTC omnibus sweep destination - funds consolidated from all BTC customer wallets |
| 45 | 0x71C776... | 3 (CryptoToFiat) | 3 (ETH) | 1 | ETH-to-fiat conversion address - ETH sent here is exchanged for fiat on the liquidity provider |
| 88 | rHb9CJAm... | 2 (UserMoneyOut) | 5 (XRP) | 0 | Retired XRP user withdrawal address - superseded by a newer address |
| 120 | 0x89205A... | 4 (CryptoToPosition) | 3 (ETH) | 1 | ETH position collateral address - moves ETH into leveraged position backing |
| 165 | bc1qxy2k... | 1 (OmnibusMoneyOut) | 1 (BTC) | 1 | Secondary BTC omnibus sweep address used for SegWit transactions |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. Referenced by Wallet.ManualOutTransactions to identify the destination address used. |
| 2 | Address | nvarchar(512) | YES | - | VERIFIED | Blockchain address string (Base58, hex, or Bech32 depending on the crypto). The actual on-chain destination for funds. Must be valid for the corresponding CryptoId network. |
| 3 | Comment | nvarchar(256) | YES | - | CODE-BACKED | Free-text description entered by operations when adding or retiring an address. Documents the purpose, provider name, or decommission reason. |
| 4 | IsActive | bit | YES | - | VERIFIED | 1=address is currently operational and eligible for use; 0=retired/decommissioned. Query should always filter IsActive=1 for new transactions. |
| 5 | Occurred | datetime2(7) | YES | - | CODE-BACKED | UTC timestamp of when the address row was inserted. Because the trigger prevents updates, this is always the original insertion time. |
| 6 | CryptoId | int | NO | - | VERIFIED | Identifies the blockchain network the address belongs to. FK to Wallet.CryptoTypes. An ETH address must not be used for BTC transactions. |
| 7 | ExternalAddressTypeId | tinyint | NO | - | VERIFIED | Operational purpose classification: 1=OmnibusMoneyOut, 2=UserMoneyOut, 3=CryptoToFiat, 4=CryptoToPosition. FK to Dict.ExternalAddressTypes. Drives routing logic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CryptoId | Wallet.CryptoTypes | FK | Identifies the blockchain network of the address |
| ExternalAddressTypeId | Dict.ExternalAddressTypes | FK | Classifies the operational purpose of the address |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.ManualOutTransactions | ExternalAddressId (implicit) | Implicit | References the destination address for manual outbound transactions |

---

## 6. Dependencies

### 6.0 Dependency Chain

Wallet.CryptoTypes → Wallet.EtoroExternalAddresses
Dict.ExternalAddressTypes → Wallet.EtoroExternalAddresses

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoTypes | Table | FK target for CryptoId - validates the blockchain network |
| Dict.ExternalAddressTypes | Table | FK target for ExternalAddressTypeId - validates the address purpose |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ManualOutTransactions | Table | References external addresses for manual withdrawal routing |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EtoroExternalAddresses | CLUSTERED PK | Id ASC | - | - | Active |
| FK index on CryptoId | NC | CryptoId ASC | - | - | Active |
| FK index on ExternalAddressTypeId | NC | ExternalAddressTypeId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_EtoroExternalAddresses_CryptoId | FK | CryptoId -> Wallet.CryptoTypes.Id |
| FK_EtoroExternalAddresses_ExternalAddressTypeId | FK | ExternalAddressTypeId -> Dict.ExternalAddressTypes.Id |
| Insert-only trigger | TRIGGER | Prevents UPDATE and DELETE - table is append-only for audit integrity |

---

## 8. Sample Queries

### 8.1 List all active addresses by type and crypto
```sql
SELECT ea.Id, ea.Address, ea.Comment, ea.Occurred,
       ea.CryptoId, ea.ExternalAddressTypeId
FROM Wallet.EtoroExternalAddresses ea WITH (NOLOCK)
WHERE ea.IsActive = 1
ORDER BY ea.ExternalAddressTypeId, ea.CryptoId
```

### 8.2 Find active withdrawal addresses for a specific crypto
```sql
SELECT ea.Id, ea.Address, ea.Comment
FROM Wallet.EtoroExternalAddresses ea WITH (NOLOCK)
WHERE ea.CryptoId = 1
  AND ea.ExternalAddressTypeId = 2   -- UserMoneyOut
  AND ea.IsActive = 1
```

### 8.3 Audit history of all addresses for a crypto including retired ones
```sql
SELECT ea.Id, ea.Address, ea.ExternalAddressTypeId,
       ea.IsActive, ea.Occurred, ea.Comment
FROM Wallet.EtoroExternalAddresses ea WITH (NOLOCK)
WHERE ea.CryptoId = 3  -- ETH
ORDER BY ea.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.EtoroExternalAddresses | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.EtoroExternalAddresses.sql*
