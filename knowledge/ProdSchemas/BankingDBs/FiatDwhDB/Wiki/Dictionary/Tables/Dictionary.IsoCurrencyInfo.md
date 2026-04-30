# Dictionary.IsoCurrencyInfo

> Reference table containing ISO 4217 currency codes with alphabetical code, numeric code, and minor unit (decimal places) for all supported currencies.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AlphabeticalCode (VARCHAR(3), CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 0 active (PK only) |

---

## 1. Business Meaning

Dictionary.IsoCurrencyInfo stores ISO 4217 currency reference data. Unlike other Dictionary tables (Id+Name pattern), this uses AlphabeticalCode as the PK. Contains 155 currencies with their 3-letter alpha code, 3-digit numeric code, and minor unit (decimal places).

See [ISO Currency Info](../../_glossary.md#iso-currency-info) in the Business Glossary for key currencies and platform usage.

---

## 2. Business Logic

### 2.1 Minor Unit Precision

**What**: MinorUnit determines decimal precision for currency amounts.

**Rules**:
- MinorUnit=2: Most currencies (USD, EUR, GBP) - amounts have 2 decimal places
- MinorUnit=0: JPY, KRW, etc. - no fractional amounts
- MinorUnit=3: BHD, KWD, OMR - 3 decimal places
- MinorUnit=4: CLF, UYW - 4 decimal places
- CurrencyISON columns in dbo tables reference NumericCode values

---

## 3. Data Overview

| AlphabeticalCode | NumericCode | MinorUnit | Meaning |
|---|---|---|---|
| GBP | 826 | 2 | UK pound sterling - primary UK region currency |
| EUR | 978 | 2 | Euro - primary EU region currency |
| USD | 840 | 2 | US dollar - base conversion currency |
| AUD | 036 | 2 | Australian dollar - AUS region |
| JPY | 392 | 0 | Japanese yen - zero minor units |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AlphabeticalCode | varchar(3) | NO | - | CODE-BACKED | ISO 4217 three-letter currency code (e.g., USD, EUR, GBP). Primary key. |
| 2 | NumericCode | varchar(3) | NO | - | CODE-BACKED | ISO 4217 three-digit numeric code (e.g., 840, 978, 826). Referenced by CurrencyISON columns. |
| 3 | MinorUnit | int | NO | - | CODE-BACKED | Number of decimal places (0-4). Determines amount precision. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Referenced by: dbo.FiatCurrencyBalances (CurrencyISON), dbo.BalanceReports (CurrencyIson), dbo.FiatTransactionsStatuses (HolderCurrency, TransactionCurrency)

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (leaf reference table).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

dbo tables that store currency codes reference this for validation.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_dic_IsoCurrency | CLUSTERED | AlphabeticalCode ASC | - | - | Active |

### 7.2 Constraints

None (beyond PK).

---

## 8. Sample Queries

### 8.1 View all currencies
```sql
SELECT * FROM Dictionary.IsoCurrencyInfo WITH (NOLOCK) ORDER BY AlphabeticalCode;
```

### 8.2 Find zero-minor-unit currencies
```sql
SELECT AlphabeticalCode, NumericCode FROM Dictionary.IsoCurrencyInfo WITH (NOLOCK) WHERE MinorUnit = 0;
```

### 8.3 Resolve numeric code to alpha
```sql
SELECT AlphabeticalCode, MinorUnit FROM Dictionary.IsoCurrencyInfo WITH (NOLOCK) WHERE NumericCode = '978';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.IsoCurrencyInfo | Type: Table | Source: FiatDwhDB/Dictionary/Tables/Dictionary.IsoCurrencyInfo.sql*
