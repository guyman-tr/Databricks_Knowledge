# Wallet.GetInstrument

> Stored procedure that looks up a trading instrument ID by its buy and sell currency pair.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns InstrumentId (int) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetInstrument resolves a trading instrument ID from a buy/sell currency pair. When the application needs to look up exchange rates for a specific currency conversion (e.g., BTC->USD), it needs the InstrumentId that represents that pair. This procedure performs that lookup.

---

## 2. Business Logic

No complex business logic. Simple SELECT of InstrumentId from Wallet.Instruments WHERE BuyCurrencyId and SellCurrencyId match.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BuyCurrencyId | int | NO | - | CODE-BACKED | The "buy" side currency ID of the trading pair. Can be a CryptoId or FiatId. |
| 2 | @SellCurrencyId | int | NO | - | CODE-BACKED | The "sell" side currency ID of the trading pair. |
| 3 | InstrumentId (result) | int | YES | - | CODE-BACKED | The trading instrument ID for this pair, or empty result set if no instrument is configured for this combination. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BuyCurrencyId, @SellCurrencyId | Wallet.Instruments | FROM | Currency pair lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | - | EXEC | Exchange rate instrument resolution |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetInstrument (procedure)
+-- Wallet.Instruments (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Instruments | Table | FROM with NOLOCK - pair lookup |

### 6.2 Objects That Depend On This

No database object dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Look up BTC/USD instrument
```sql
EXEC Wallet.GetInstrument @BuyCurrencyId = 1, @SellCurrencyId = 1  -- BTC buy, USD sell
```

### 8.2 Inline equivalent
```sql
SELECT InstrumentId FROM Wallet.Instruments WITH (NOLOCK) WHERE BuyCurrencyId = 1 AND SellCurrencyId = 2
```

### 8.3 List all instrument pairs with currency names
```sql
SELECT i.InstrumentId, bc.Name AS BuyCurrency, sc.Name AS SellCurrency
FROM Wallet.Instruments i WITH (NOLOCK)
LEFT JOIN Wallet.CryptoTypes bc WITH (NOLOCK) ON bc.CryptoId = i.BuyCurrencyId
LEFT JOIN Wallet.CryptoTypes sc WITH (NOLOCK) ON sc.CryptoId = i.SellCurrencyId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetInstrument | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetInstrument.sql*
