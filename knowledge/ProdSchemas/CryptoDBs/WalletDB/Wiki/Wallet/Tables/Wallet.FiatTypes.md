# Wallet.FiatTypes

> Reference table of supported fiat currencies for crypto-to-fiat conversions and payment operations within the eToro wallet platform.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY, CLUSTERED PK); FiatId (unique business key) |
| **Partition** | No |
| **Indexes** | 3 active NC UNIQUE + 1 clustered PK |

---

## 1. Business Meaning

This table defines all fiat currencies available for operations within the crypto wallet system. Each row represents a fiat currency (e.g., USD, EUR, GBP) with its display properties, precision rules, and linkage to the trading platform's instrument system. This table is essential for crypto-to-fiat conversion flows, payment operations, and market rate lookups.

Without this table, the system could not determine which fiat currencies are available for crypto conversions, what precision to apply when displaying fiat amounts, or how to map fiat currencies to their trading instruments for rate calculation. It anchors the fiat side of all crypto-fiat operations.

Rows are manually inserted when new fiat currencies are added to the platform. The table is rarely modified. It is referenced by `Wallet.Payments` (which stores the fiat currency of each payment) and `Wallet.FiatMarketRatesMappings` (which links fiats to market rate feeds). Stored procedures like `Wallet.GetAllFiats` and `Wallet.GetCustomerPaymentById` consume this data for API responses.

---

## 2. Business Logic

### 2.1 Dual Identity System

**What**: Each fiat has both a surrogate key (`Id`) and a business key (`FiatId`) with separate uniqueness constraints.

**Columns/Parameters Involved**: `Id`, `FiatId`

**Rules**:
- `Id` is the auto-increment surrogate PK used within WalletDB
- `FiatId` is the business identifier used across eToro systems (e.g., 1=USD, 2=EUR, 3=GBP, 5=AUD)
- `FiatId` has a unique index for cross-system lookups
- The gap between FiatId 3 (GBP) and 5 (AUD) suggests FiatId 4 was reserved or removed (possibly JPY or CHF)

### 2.2 Instrument Linkage

**What**: Fiat currencies link to eToro trading instruments for exchange rate calculation.

**Columns/Parameters Involved**: `InstrumentId`, `FiatName`

**Rules**:
- USD (the base currency) has InstrumentId=NULL because all crypto prices are already quoted in USD
- EUR, GBP, AUD each have an InstrumentId pointing to their USD exchange rate instrument
- This linkage enables the system to convert crypto values to any supported fiat currency via the trading platform's rate feeds

---

## 3. Data Overview

| Id | FiatId | FiatName | IsActive | Precision | InstrumentId | NumericCode | Meaning |
|---|---|---|---|---|---|---|---|
| 1 | 1 | USD | true | 5 | NULL | 840 | US Dollar - base currency for all crypto pricing. No instrument needed since crypto rates are natively in USD. ISO 4217 code 840. |
| 2 | 2 | EUR | true | 5 | 1 | 978 | Euro - linked to InstrumentId 1 (EUR/USD rate) for conversion calculations. Second most common fiat for crypto operations. |
| 3 | 3 | GBP | true | 5 | 2 | 826 | British Pound - linked to InstrumentId 2 (GBP/USD rate). Used by UK-regulated entity (eToroUK). |
| 4 | 5 | AUD | true | 5 | 7 | 36 | Australian Dollar - linked to InstrumentId 7 (AUD/USD rate). Used by Australian-regulated entity (eToroAUS). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key within WalletDB. Used as FK target by Wallet.Payments. |
| 2 | FiatId | int | NO | - | VERIFIED | Business identifier for the fiat currency used across eToro platform systems. Unique constraint (UQ_Wallet_FiatTypes_FiatId). Values: 1=USD, 2=EUR, 3=GBP, 5=AUD. Referenced by Wallet.FiatMarketRatesMappings as FK. |
| 3 | FiatName | nvarchar(24) | NO | - | VERIFIED | ISO 4217 three-letter currency code (e.g., USD, EUR, GBP, AUD). Unique constraint enforced. Used for display and API parameter matching. |
| 4 | IsActive | bit | NO | - | CODE-BACKED | Whether this fiat currency is currently available for crypto operations. All current entries are active (1). Setting to 0 would disable conversions and payments in this currency. |
| 5 | AvatarUrl | nvarchar(100) | NO | - | NAME-INFERRED | URL to the currency's display icon hosted on S3. Used in the eToro wallet UI for visual identification of fiat currencies. |
| 6 | Precision | tinyint | YES | - | CODE-BACKED | Number of decimal places used when displaying and calculating amounts in this currency. All current currencies use 5 decimal places for precision in conversion calculations. |
| 7 | InstrumentId | int | YES | - | VERIFIED | Links to the eToro trading platform instrument representing the exchange rate for this fiat vs USD. NULL for USD (base currency). EUR=1, GBP=2, AUD=7. Used to fetch real-time exchange rates for crypto-to-fiat conversions. Implicit reference to Wallet.Instruments. |
| 8 | NumericCode | int | YES | - | CODE-BACKED | ISO 4217 numeric currency code (e.g., 840=USD, 978=EUR, 826=GBP, 36=AUD). Used for standardized integrations with payment providers and regulatory reporting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentId | Wallet.Instruments | Implicit | Links fiat currency to its exchange rate instrument for crypto-fiat conversions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.Payments | FiatId | FK | Each payment references the fiat currency it operates in |
| Wallet.FiatMarketRatesMappings | FiatId | FK | Maps fiat currencies to market rate feed symbols |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Payments | Table | FK on FiatId |
| Wallet.FiatMarketRatesMappings | Table | FK on FiatId |
| Wallet.GetAllFiats | Stored Procedure | Reads all fiat currencies for API listing |
| Wallet.GetCustomerPaymentById | Stored Procedure | JOINs to resolve fiat currency details for payments |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FiatTypes | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_FiatTypes__FiatId | NC UNIQUE | FiatId ASC | - | - | Active |
| IX_Wallet_FiatTypes__FiatName | NC UNIQUE | FiatName ASC | - | - | Active |
| UQ_Wallet_FiatTypes_FiatId | NC UNIQUE | FiatId ASC | - | - | Active |

### 7.2 Constraints

None (beyond PK and unique indexes).

---

## 8. Sample Queries

### 8.1 List all active fiat currencies
```sql
SELECT FiatId, FiatName, Precision, NumericCode
FROM Wallet.FiatTypes WITH (NOLOCK)
WHERE IsActive = 1
ORDER BY FiatName
```

### 8.2 Find fiat by ISO numeric code
```sql
SELECT FiatId, FiatName, InstrumentId
FROM Wallet.FiatTypes WITH (NOLOCK)
WHERE NumericCode = 978  -- EUR
```

### 8.3 Get fiat currencies with their instrument details
```sql
SELECT ft.FiatName, ft.NumericCode, i.InstrumentId, i.BuyCurrencyId, i.SellCurrencyId
FROM Wallet.FiatTypes ft WITH (NOLOCK)
LEFT JOIN Wallet.Instruments i WITH (NOLOCK) ON ft.InstrumentId = i.InstrumentId
ORDER BY ft.FiatId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 9.4/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.FiatTypes | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.FiatTypes.sql*
