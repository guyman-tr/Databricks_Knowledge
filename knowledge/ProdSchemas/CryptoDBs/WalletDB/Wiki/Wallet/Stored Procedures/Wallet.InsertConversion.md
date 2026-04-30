# Wallet.InsertConversion

> Creates a new crypto-to-crypto conversion record with idempotency protection, auto-resolving wallet IDs from Gcid+CryptoId when not provided, and atomically inserting the initial conversion status within a transaction.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Wallet.Conversions + ConversionStatuses (transactional) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure creates a new conversion record - representing a crypto-to-crypto swap (e.g., BTC to ETH). The conversion service calls this when a customer initiates a swap. The procedure is transactional (BEGIN/COMMIT) and idempotent: it checks if a conversion with the same CorrelationId already exists before inserting, raising an error if duplicate.

The procedure auto-resolves wallet IDs from CustomerWalletsView when @FromWalletId or @ToWalletId are NULL or empty GUIDs, using @Gcid + the respective CryptoId. It also supports backward-compatible CryptoId resolution. After inserting the conversion, it atomically creates the initial status record (ConversionStatusId=1, Started) in ConversionStatuses.

---

## 2. Business Logic

### 2.1 Idempotent Creation with Transaction

**What**: Creates conversion + initial status atomically, rejecting duplicates.

**Columns/Parameters Involved**: `@CorrelationId`, `Conversions`, `ConversionStatuses`

**Rules**:
- WHERE NOT EXISTS (SELECT 1 FROM Conversions WHERE CorrelationId = @CorrelationId)
- If @ConversionId IS NULL after INSERT (duplicate detected), RAISERROR
- Initial status ConversionStatusId = 1 (Started) inserted atomically
- Transaction ensures both inserts succeed or both roll back

### 2.2 Wallet ID Auto-Resolution

**What**: Resolves From/To wallet IDs from Gcid + CryptoId when not provided.

**Columns/Parameters Involved**: `@FromWalletId`, `@ToWalletId`, `@Gcid`, `@FromCryptoId`, `@ToCryptoId`

**Rules**:
- If @FromWalletId IS NULL or empty GUID -> resolve from CustomerWalletsView(Gcid, FromCryptoId)
- If @ToWalletId IS NULL or empty GUID -> resolve from CustomerWalletsView(Gcid, ToCryptoId)
- If CryptoId IS NULL -> resolve from base-chain entry (CryptoId = BlockchainCryptoId)
- Backward compatibility for older callers that don't pass wallet IDs

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | VERIFIED | Customer initiating the conversion. Used for wallet resolution. |
| 2 | @FromCryptoId | int | YES | - | VERIFIED | Source cryptocurrency. Auto-resolved if NULL. |
| 3 | @ToCryptoId | int | YES | - | VERIFIED | Destination cryptocurrency. Auto-resolved if NULL. |
| 4 | @FromWalletId | uniqueidentifier | YES | - | CODE-BACKED | Source wallet. Auto-resolved from Gcid+FromCryptoId if NULL/empty. |
| 5 | @ToWalletId | uniqueidentifier | YES | - | CODE-BACKED | Destination wallet. Auto-resolved from Gcid+ToCryptoId if NULL/empty. |
| 6 | @ConversionTypeId | tinyint | NO | - | VERIFIED | Type of conversion. FK to Dictionary.ConversionTypes. |
| 7 | @FromAmount | decimal(36,18) | NO | - | CODE-BACKED | Amount of source crypto to swap. |
| 8 | @ToAmount | decimal(36,18) | NO | - | CODE-BACKED | Expected amount of destination crypto. |
| 9 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Idempotency key and cross-service correlation. Must be unique. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.Conversions | INSERT | Creates conversion record |
| - | Wallet.ConversionStatuses | INSERT | Creates initial status (Started) |
| @Gcid + CryptoId | Wallet.CustomerWalletsView | Lookup | Wallet auto-resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ConversionUser | - | EXECUTE | Creates new conversions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertConversion (procedure)
+-- Wallet.Conversions (table)
+-- Wallet.ConversionStatuses (table)
+-- Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Conversions | Table | INSERT target |
| Wallet.ConversionStatuses | Table | Initial status INSERT |
| Wallet.CustomerWalletsView | View | Wallet ID auto-resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ConversionUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses explicit BEGIN/COMMIT TRANSACTION.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Create a BTC-to-ETH conversion
```sql
EXEC Wallet.InsertConversion
    @Gcid = 30351701, @FromCryptoId = 1, @ToCryptoId = 2,
    @FromWalletId = NULL, @ToWalletId = NULL,
    @ConversionTypeId = 1, @FromAmount = 0.5, @ToAmount = 8.5,
    @CorrelationId = 'NEW-GUID';
```

### 8.2 Check conversion exists
```sql
SELECT * FROM Wallet.Conversions WITH (NOLOCK) WHERE CorrelationId = 'YOUR-GUID';
```

### 8.3 Check conversion status
```sql
SELECT cs.* FROM Wallet.ConversionStatuses cs WITH (NOLOCK)
    JOIN Wallet.Conversions c WITH (NOLOCK) ON c.Id = cs.ConversionId
WHERE c.CorrelationId = 'YOUR-GUID' ORDER BY cs.Id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertConversion | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertConversion.sql*
