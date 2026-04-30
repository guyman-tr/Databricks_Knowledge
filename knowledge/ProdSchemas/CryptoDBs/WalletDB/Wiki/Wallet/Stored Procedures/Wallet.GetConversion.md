# Wallet.GetConversion

> Retrieves a crypto-to-crypto conversion record by correlation ID, including the customer, source/destination wallets and cryptos, amounts, and current conversion status.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns conversion details by CorrelationId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the details of a crypto-to-crypto conversion (e.g., BTC to ETH). Conversions allow customers to exchange one cryptocurrency for another within their wallet. The procedure returns the conversion record with resolved customer information from both the source and destination wallets, plus the current conversion status.

Without this procedure, the application could not retrieve conversion details for status display, confirmation, or reconciliation.

The procedure joins Conversions to CustomerWalletsView twice (once for from-wallet, once for to-wallet) to resolve customer and wallet details, and uses a correlated subquery to get the latest conversion status.

---

## 2. Business Logic

### 2.1 Latest Status Resolution

**What**: Gets the most recent conversion status via correlated subquery.

**Columns/Parameters Involved**: ConversionStatuses.ConversionStatusId

**Rules**:
- TOP 1 ORDER BY Occurred DESC on ConversionStatuses for the conversion's Id
- Returns the single most recent status

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Correlation ID of the conversion to retrieve. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.Conversions | Reader | Core conversion data |
| - | Wallet.CustomerWalletsView | Reader (x2) | Source and destination wallet details |
| - | Wallet.ConversionStatuses | Reader | Latest status subquery |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetConversion (procedure)
  ├── Wallet.Conversions (table)
  ├── Wallet.CustomerWalletsView (view) [x2]
  └── Wallet.ConversionStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Conversions | Table | SELECT source |
| Wallet.CustomerWalletsView | View | JOIN (from + to wallets) |
| Wallet.ConversionStatuses | Table | Subquery for latest status |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- NOLOCK hints, SET NOCOUNT ON
- Two JOINs to CustomerWalletsView with CryptoId matching

---

## 8. Sample Queries

### 8.1 Get conversion by correlation
```sql
EXEC Wallet.GetConversion @CorrelationId = '4B26D85F-BF00-4E27-9166-4F8AF2D599D6'
```

### 8.2 Recent conversions with status
```sql
SELECT TOP 20 c.Id, c.FromCryptoId, c.ToCryptoId, c.FromAmount, c.ToAmount,
    (SELECT TOP 1 ConversionStatusId FROM Wallet.ConversionStatuses WITH (NOLOCK) WHERE ConversionId = c.Id ORDER BY Occurred DESC) StatusId
FROM Wallet.Conversions c WITH (NOLOCK)
ORDER BY c.Id DESC
```

### 8.3 Conversion volume by crypto pair
```sql
SELECT FromCryptoId, ToCryptoId, COUNT(*) AS Cnt, SUM(FromAmount) AS TotalFromAmount
FROM Wallet.Conversions WITH (NOLOCK)
GROUP BY FromCryptoId, ToCryptoId
ORDER BY Cnt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetConversion | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetConversion.sql*
