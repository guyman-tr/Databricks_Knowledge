# Wallet.ConvertAddresses

> Records address format conversion operations where blockchain addresses are translated between different encoding formats (e.g., Bitcoin legacy to SegWit, BCH to CashAddr).

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

This table logs address format conversion operations. Some blockchains support multiple address formats (e.g., Bitcoin has legacy/SegWit/bech32, BCH has legacy/CashAddr, Litecoin has legacy/M-prefix). When a user submits an address in one format, the system may need to convert it to another format for internal processing. Each row records one such conversion with the original and converted addresses and their format types. With 280K rows, this is actively used.

---

## 2. Business Logic

No complex logic. Address format conversion audit log.

---

## 3. Data Overview

N/A for address conversion log.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. |
| 2 | CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency whose address was converted. Implicit reference to Wallet.CryptoTypes. |
| 3 | FromAddress | nvarchar(512) | YES | - | CODE-BACKED | Original address before conversion. |
| 4 | ToAddress | nvarchar(512) | YES | - | CODE-BACKED | Converted address in the target format. |
| 5 | FromType | nvarchar(64) | NO | - | CODE-BACKED | Original address format type (e.g., "3prefix", "cashaddr", "Mprefix"). See [Address Type Display Name](../../_glossary.md#address-type-display-name). |
| 6 | ToType | nvarchar(64) | NO | - | CODE-BACKED | Target address format type. |
| 7 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Links to the parent request. |
| 8 | Occured | datetime2(7) | NO | - | CODE-BACKED | Timestamp of conversion. Note: column name typo "Occured". |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.AddAddressConvert | - | Writer | Records conversions |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AddAddressConvert | Stored Procedure | Inserts records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ConvertAddresses | CLUSTERED PK | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 Recent address conversions
```sql
SELECT TOP 20 Id, CryptoId, FromType, ToType, Occured FROM Wallet.ConvertAddresses WITH (NOLOCK) ORDER BY Id DESC
```

### 8.2 Conversions by type pair
```sql
SELECT FromType, ToType, COUNT(*) AS Cnt FROM Wallet.ConvertAddresses WITH (NOLOCK) GROUP BY FromType, ToType ORDER BY Cnt DESC
```

### 8.3 Find conversion by correlation
```sql
SELECT FromAddress, ToAddress, FromType, ToType FROM Wallet.ConvertAddresses WITH (NOLOCK)
WHERE CorrelationId = '4B26D85F-BF00-4E27-9166-4F8AF2D599D6'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.ConvertAddresses | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.ConvertAddresses.sql*
