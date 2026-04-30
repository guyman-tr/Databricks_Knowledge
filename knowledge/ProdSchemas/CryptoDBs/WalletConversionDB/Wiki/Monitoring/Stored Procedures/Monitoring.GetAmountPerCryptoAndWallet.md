# Monitoring.GetAmountPerCryptoAndWallet

> Aggregates total crypto and USD amounts per crypto asset and wallet address for conversions after a given ID, supporting wallet-level monitoring and reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: CryptoId, ToAddress, SumCryptoAmount, SumUsdAmount, MaxId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetAmountPerCryptoAndWallet aggregates conversion amounts by crypto asset and blockchain destination address, starting from a given conversion ID. This is used for wallet-level reconciliation - tracking how much of each crypto asset was sent to a specific address and the corresponding USD value. The MaxId return enables cursor-based pagination for incremental processing.

---

## 2. Business Logic

### 2.1 Wallet-Level Aggregation

**What**: Groups completed conversions by CryptoId and ToAddress, summing amounts.

**Columns/Parameters Involved**: `@Id`, `@Address`

**Rules**:
- INNER JOINs Conversions + FiatTransactions + CryptoTransactions (all three required)
- Filters: c.Id > @Id AND ct.ToAddress = @Address
- Groups by CryptoId and ToAddress
- Returns SUM(ct.Amount), SUM(ft.UsdAmount), MAX(c.Id) per group
- Uses CTE for clean aggregation

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Id | bigint | NO | - | VERIFIED | Starting conversion ID (exclusive). Only conversions with Id > @Id are included. Enables incremental processing. |
| 2 | @Address | varchar(64) | NO | - | VERIFIED | Blockchain destination address to filter by. Matches CryptoTransactions.ToAddress. |

**Return Columns:**

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | CryptoId | int | VERIFIED | Crypto asset identifier |
| 2 | ToAddress | varchar(64) | VERIFIED | Blockchain destination address |
| 3 | SumCryptoAmount | decimal | VERIFIED | Total crypto amount sent to this address for this asset |
| 4 | SumUsdAmount | decimal | VERIFIED | Total USD equivalent value |
| 5 | MaxId | bigint | VERIFIED | Highest conversion ID in the result (cursor for next call) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | C2F.Conversions | SELECT (FROM) | Filtered by Id > @Id |
| - | C2F.FiatTransactions | INNER JOIN | USD amounts |
| - | C2F.CryptoTransactions | INNER JOIN | Crypto amounts and ToAddress filter |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetAmountPerCryptoAndWallet (procedure)
├── C2F.Conversions (table)
├── C2F.FiatTransactions (table)
└── C2F.CryptoTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| C2F.Conversions | Table | FROM - Id filter |
| C2F.FiatTransactions | Table | INNER JOIN - USD amounts |
| C2F.CryptoTransactions | Table | INNER JOIN - crypto amounts + address filter |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get amounts for a specific wallet address
```sql
EXEC Monitoring.GetAmountPerCryptoAndWallet @Id = 0, @Address = '0x1A968A2887Dd6658eD6E68F46De36D13BA69C2e3'
```

### 8.2 Incremental call using MaxId from previous result
```sql
EXEC Monitoring.GetAmountPerCryptoAndWallet @Id = 15000, @Address = '0x1A968A2887Dd6658eD6E68F46De36D13BA69C2e3'
```

### 8.3 Direct aggregation query
```sql
SELECT ct.ToAddress, c.CryptoId, SUM(ct.Amount) AS TotalCrypto, SUM(ft.UsdAmount) AS TotalUsd
FROM C2F.Conversions c WITH (NOLOCK)
INNER JOIN C2F.FiatTransactions ft WITH (NOLOCK) ON c.Id = ft.ConversionId
INNER JOIN C2F.CryptoTransactions ct WITH (NOLOCK) ON c.Id = ct.ConversionId
GROUP BY ct.ToAddress, c.CryptoId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetAmountPerCryptoAndWallet | Type: Stored Procedure | Source: WalletConversionDB/Monitoring/Stored Procedures/Monitoring.GetAmountPerCryptoAndWallet.sql*
