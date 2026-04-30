# Wallet.FiatMarketRatesMappings

> Maps fiat currencies to their market rate feed symbols, enabling the system to fetch real-time exchange rates for crypto-to-fiat conversion calculations.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active NC UNIQUE + 1 clustered PK |

---

## 1. Business Meaning

This table maps each supported fiat currency to its market rate feed symbol. When the system needs to convert crypto values to a fiat currency (e.g., showing a BTC balance in EUR), it looks up the fiat's `MarketRatesCurrencySymbol` here to query the correct rate feed. The mapping is necessary because internal FiatIds may not match the rate feed's symbol naming convention.

Without this table, the system could not resolve which market rate feed to query for each fiat currency, breaking all crypto-to-fiat conversion displays and transaction calculations.

The table has 4 rows matching the 4 supported fiat currencies. Rows are inserted when new fiats are added. Referenced by `Wallet.GetFiatMarketRatesMappings` for rate resolution.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The table is a simple 1:1 mapping between FiatId and MarketRatesCurrencySymbol.

---

## 3. Data Overview

| Id | FiatId | MarketRatesCurrencySymbol | Meaning |
|---|---|---|---|
| 1 | 2 | EUR | Euro rate feed - used for displaying crypto values in EUR for EU customers |
| 2 | 3 | GBP | British Pound rate feed - used for UK-regulated entity operations |
| 3 | 1 | USD | US Dollar rate feed - base currency, rate is effectively 1:1 |
| 4 | 5 | AUD | Australian Dollar rate feed - added Nov 2025 for eToroAUS entity |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | FiatId | int | NO | - | VERIFIED | References the fiat currency being mapped. FK to Wallet.FiatTypes.FiatId. Unique constraint ensures each fiat has exactly one rate mapping. Values: 1=USD, 2=EUR, 3=GBP, 5=AUD. |
| 3 | MarketRatesCurrencySymbol | varchar(20) | NO | - | CODE-BACKED | The symbol used to query the market rate feed for this fiat currency. Typically matches the ISO 4217 code (USD, EUR, GBP, AUD). Unique constraint ensures no duplicate symbols. |
| 4 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when this mapping was created. Original 3 currencies share 2019-11-26; AUD added 2025-11-09. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FiatId | Wallet.FiatTypes | FK | Links to the fiat currency definition |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.GetFiatMarketRatesMappings | - | Reader | Reads all mappings for rate resolution |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.FiatMarketRatesMappings (table)
└── Wallet.FiatTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.FiatTypes | Table | FK target for FiatId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetFiatMarketRatesMappings | Stored Procedure | Reads all mappings |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FiatMarketRatesMappings | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_FiatMarketRatesMappings__FiatId | NC UNIQUE | FiatId ASC | - | - | Active |
| IX_Wallet_FiatMarketRatesMappings__MarketRatesCurrencySymbol | NC UNIQUE | MarketRatesCurrencySymbol ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Wallet_FiatMarketRatesMappings__Occurred | DEFAULT | getutcdate() |
| FK_...FiatId__Wallet_FiatTypes_FiatId | FK | FiatId -> Wallet.FiatTypes.FiatId |

---

## 8. Sample Queries

### 8.1 Get all fiat rate mappings with currency names
```sql
SELECT fmr.FiatId, ft.FiatName, fmr.MarketRatesCurrencySymbol
FROM Wallet.FiatMarketRatesMappings fmr WITH (NOLOCK)
JOIN Wallet.FiatTypes ft WITH (NOLOCK) ON fmr.FiatId = ft.FiatId
ORDER BY fmr.Id
```

### 8.2 Find the rate symbol for a specific fiat
```sql
SELECT MarketRatesCurrencySymbol
FROM Wallet.FiatMarketRatesMappings WITH (NOLOCK)
WHERE FiatId = 2  -- EUR
```

### 8.3 List all rate symbols
```sql
SELECT FiatId, MarketRatesCurrencySymbol, Occurred
FROM Wallet.FiatMarketRatesMappings WITH (NOLOCK)
ORDER BY Occurred
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.FiatMarketRatesMappings | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.FiatMarketRatesMappings.sql*
