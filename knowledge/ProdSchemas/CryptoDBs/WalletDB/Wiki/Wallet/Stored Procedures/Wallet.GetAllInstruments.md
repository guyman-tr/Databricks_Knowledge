# Wallet.GetAllInstruments

> Stored procedure that returns all trading instrument configurations from the Instruments table, ordered by InstrumentId.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all rows from Wallet.Instruments |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetAllInstruments returns the complete list of trading instruments configured in the wallet system. Each instrument represents a tradeable currency pair defined by a buy currency and sell currency. These instruments are referenced by the market rates system for exchange rate lookups during conversions and crypto-to-fiat transactions.

The procedure reads from `Wallet.Instruments` with NOLOCK and returns Id, InstrumentId, BuyCurrencyId, and SellCurrencyId for all configured instruments.

---

## 2. Business Logic

No complex business logic. Direct SELECT from Wallet.Instruments ordered by InstrumentId.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Internal auto-increment primary key. |
| 2 | InstrumentId | int | NO | - | CODE-BACKED | Trading instrument identifier used by the market rates system. Maps to eToro's instrument registry. |
| 3 | BuyCurrencyId | int | NO | - | CODE-BACKED | The "buy" side currency ID of the pair. Can be a CryptoId or FiatId depending on the pair. |
| 4 | SellCurrencyId | int | NO | - | CODE-BACKED | The "sell" side currency ID of the pair. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.Instruments | FROM | Reads all instrument configurations |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | - | EXEC | Instrument configuration loading |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetAllInstruments (procedure)
+-- Wallet.Instruments (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Instruments | Table | FROM - reads all instrument configurations |

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

### 8.1 Get all instruments
```sql
EXEC Wallet.GetAllInstruments
```

### 8.2 Find instrument for a specific currency pair
```sql
SELECT InstrumentId FROM Wallet.Instruments WITH (NOLOCK)
WHERE BuyCurrencyId = 1 AND SellCurrencyId = 2  -- e.g., BTC/ETH
```

### 8.3 List all instruments with their currency names
```sql
SELECT i.InstrumentId, b.Name AS BuyCurrency, s.Name AS SellCurrency
FROM Wallet.Instruments i WITH (NOLOCK)
LEFT JOIN Wallet.CryptoTypes b WITH (NOLOCK) ON b.CryptoId = i.BuyCurrencyId
LEFT JOIN Wallet.CryptoTypes s WITH (NOLOCK) ON s.CryptoId = i.SellCurrencyId
ORDER BY i.InstrumentId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetAllInstruments | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetAllInstruments.sql*
