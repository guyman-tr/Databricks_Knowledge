# Wallet.AddAddressConvert

> Inserts a new address format conversion record into the ConvertAddresses table, logging when a blockchain address is translated between encoding formats.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | New row in Wallet.ConvertAddresses |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records an address format conversion event. Some blockchains support multiple address encoding formats (e.g., Bitcoin legacy vs SegWit/bech32, BCH legacy vs CashAddr, Litecoin legacy vs M-prefix). When the system converts a user-submitted address from one format to another for internal processing, this procedure logs the conversion for audit and traceability.

Without this procedure, there would be no record of address format translations, making it impossible to trace how an original user-provided address maps to the internally stored format. This supports compliance, debugging, and reconciliation workflows.

Data flows in from the wallet service layer when an address conversion is performed. The procedure inserts a single row into Wallet.ConvertAddresses with the original address, converted address, their format types, the cryptocurrency, a correlation ID linking to the parent request, and a timestamp.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple audit-log INSERT with no conditional branching, validation, or status management. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CryptoId | int | NO | - | CODE-BACKED | Identifies the cryptocurrency whose address is being converted. Maps to Wallet.CryptoTypes.CryptoID (e.g., 1=BTC, 2=ETH, 4=BCH, 5=LTC). |
| 2 | @FromAddress | nvarchar(512) | NO | - | CODE-BACKED | The original blockchain address before format conversion (e.g., a legacy Bitcoin address starting with "1" or "3"). |
| 3 | @ToAddress | nvarchar(512) | NO | - | CODE-BACKED | The converted blockchain address in the target format (e.g., a bech32 address starting with "bc1"). |
| 4 | @FromType | nvarchar(64) | NO | - | CODE-BACKED | The source address format type identifier (e.g., "3prefix", "legacy", "Mprefix"). See Wallet.ConvertAddresses doc for known values. |
| 5 | @ToType | nvarchar(64) | NO | - | CODE-BACKED | The target address format type identifier (e.g., "cashaddr", "bech32", "segwit"). |
| 6 | @CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Links this conversion event to the parent wallet request for end-to-end traceability. |
| 7 | @Occured | datetime2(7) | NO | - | CODE-BACKED | Timestamp when the conversion occurred. Note: column name has a typo ("Occured" instead of "Occurred") - matches the target table column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CryptoId | Wallet.CryptoTypes | Implicit | Cryptocurrency being converted |
| INSERT target | Wallet.ConvertAddresses | Writer | Inserts conversion audit records |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase. Called exclusively by application services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AddAddressConvert (procedure)
  └── Wallet.ConvertAddresses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ConvertAddresses | Table | INSERT target |

### 6.2 Objects That Depend On This

No dependents found in SQL codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Simple INSERT with no validation logic.

---

## 8. Sample Queries

### 8.1 Execute the procedure to log a BTC address conversion
```sql
EXEC Wallet.AddAddressConvert
    @CryptoId = 1,
    @FromAddress = '3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy',
    @ToAddress = 'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq',
    @FromType = '3prefix',
    @ToType = 'bech32',
    @CorrelationId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890',
    @Occured = '2026-04-15T10:30:00'
```

### 8.2 Verify recent conversions for a specific crypto
```sql
SELECT TOP 10 Id, FromAddress, ToAddress, FromType, ToType, Occured
FROM Wallet.ConvertAddresses WITH (NOLOCK)
WHERE CryptoId = 1
ORDER BY Id DESC
```

### 8.3 Check conversion patterns by format pair
```sql
SELECT ct.CryptoName, ca.FromType, ca.ToType, COUNT(*) AS ConversionCount
FROM Wallet.ConvertAddresses ca WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoID = ca.CryptoId
GROUP BY ct.CryptoName, ca.FromType, ca.ToType
ORDER BY ConversionCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AddAddressConvert | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.AddAddressConvert.sql*
