# Wallet.GetConversionTransaction

> Retrieves the conversion transaction details for a specific leg of a crypto-to-crypto conversion, identified by the conversion's correlation ID and the target cryptocurrency.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns conversion transaction for correlation + crypto |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the transaction-level details of one side (leg) of a crypto conversion. A conversion has two legs - the "from" side (debit) and the "to" side (credit). This procedure returns the details of the leg matching @CryptoId, including the USD rate, destination address, amount, eToro fee percentage, calculated fee, and estimated blockchain fee.

Without this procedure, the application could not display or process individual conversion legs, which are needed for fee calculation, blockchain execution, and transaction confirmation.

The procedure resolves the customer's wallet for the specified CryptoId via CustomerWalletsView and joins to ConversionTransactions to get the leg details.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Multi-table JOIN to resolve conversion leg details. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Correlation ID of the parent conversion. |
| 2 | @CryptoId | int | NO | - | CODE-BACKED | The cryptocurrency leg to retrieve (determines which side of the conversion). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.Conversions | Reader | Parent conversion record |
| - | Wallet.ConversionTransactions | Reader | Transaction leg details |
| - | Wallet.CustomerWalletsView | Reader (x2) | Resolves from-wallet customer and target crypto wallet |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetConversionTransaction (procedure)
  ├── Wallet.Conversions (table)
  ├── Wallet.ConversionTransactions (table)
  └── Wallet.CustomerWalletsView (view) [x2]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Conversions | Table | JOIN to find conversion by CorrelationId |
| Wallet.ConversionTransactions | Table | JOIN for transaction leg details |
| Wallet.CustomerWalletsView | View | JOIN to resolve wallets (from + target crypto) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- NOLOCK hints, SET NOCOUNT ON
- Three JOINs to resolve the conversion leg

---

## 8. Sample Queries

### 8.1 Get conversion transaction for BTC leg
```sql
EXEC Wallet.GetConversionTransaction @CorrelationId = '4B26D85F-BF00-4E27-9166-4F8AF2D599D6', @CryptoId = 1
```

### 8.2 View conversion transactions with fees
```sql
SELECT TOP 20 ct.ConversionId, ct.CryptoId, ct.Amount, ct.CryptoRateUsd,
       ct.EtoroFeePercentage, ct.EtoroFeeCalculated, ct.EstimatedBlockChainFee
FROM Wallet.ConversionTransactions ct WITH (NOLOCK)
ORDER BY ct.Id DESC
```

### 8.3 Conversion transactions joined to parent
```sql
SELECT c.CorrelationId, ct.CryptoId, ct.Amount, ct.ToAddress, ct.CryptoRateUsd
FROM Wallet.Conversions c WITH (NOLOCK)
JOIN Wallet.ConversionTransactions ct WITH (NOLOCK) ON ct.ConversionId = c.Id
WHERE c.CorrelationId = '4B26D85F-BF00-4E27-9166-4F8AF2D599D6'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetConversionTransaction | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetConversionTransaction.sql*
