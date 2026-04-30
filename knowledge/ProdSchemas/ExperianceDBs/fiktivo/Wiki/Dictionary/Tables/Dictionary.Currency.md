# Dictionary.Currency

> Lookup table defining the supported currencies in the affiliate platform, used for payment denominations and eCost history tracking.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CurrencyID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK) |

---

## 1. Business Meaning

This table defines the set of currencies supported by the affiliate platform for financial operations - primarily affiliate payments and eCost (marketing expense) tracking. Each currency is identified by its standard ISO 4217 three-letter code.

The currency system is essential for multi-national affiliate operations. Affiliates in different countries may prefer to receive payments in their local currency, and marketing expenses (eCost) must be tracked in the currency they were incurred in.

Rows are semi-static reference data with IDENTITY-based IDs (unlike most Dictionary tables that use manually assigned IDs). The `NOT FOR REPLICATION` flag on the identity indicates this table participates in database replication. CurrencyID is referenced by `dbo.tblaff_eCostHistory.CurrencyID` via an explicit FK.

---

## 2. Business Logic

### 2.1 Currency Gaps in ID Sequence

**What**: The CurrencyID sequence has a large gap (5 to 38), suggesting currencies were added and removed over time as the platform's geographic reach evolved.

**Columns/Parameters Involved**: `CurrencyID`, `CurrencyName`

**Rules**:
- IDs 1-5 represent the original major Western currencies (USD, EUR, GBP, CAD, AUD)
- ID 38 (RMB) was added much later, likely when the platform expanded to Chinese markets
- The gap from 6-37 suggests other currencies were once supported but later removed or consolidated

---

## 3. Data Overview

| CurrencyID | CurrencyName | Meaning |
|---|---|---|
| 1 | USD | US Dollar - the platform's base/default currency. Most affiliate payments and internal calculations use USD |
| 2 | EUR | Euro - primary currency for EU-based affiliates and European marketing expenses |
| 3 | GBP | British Pound Sterling - used for UK-based affiliates |
| 4 | CAD | Canadian Dollar - used for Canadian affiliates |
| 5 | AUD | Australian Dollar - used for Australian affiliates and APAC operations |
| 38 | RMB | Chinese Renminbi/Yuan - added for Chinese market expansion, large ID gap indicates it was added well after the initial currencies |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CurrencyID | int | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing primary key identifying the currency. Values: 1=USD, 2=EUR, 3=GBP, 4=CAD, 5=AUD, 38=RMB. Referenced by dbo.tblaff_eCostHistory.CurrencyID via explicit FK. Also referenced by dbo.tblaff_Affiliates.PrefferedCurrencyID (implicit). NOT FOR REPLICATION identity. |
| 2 | CurrencyName | nchar(3) | NO | - | VERIFIED | ISO 4217 three-letter currency code. Fixed-width NCHAR(3) matches the ISO standard exactly. Used for display in payment reports and eCost summaries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_eCostHistory | CurrencyID | FK | Denominates the currency of each marketing expense (eCost) record |
| dbo.tblaff_Affiliates | PrefferedCurrencyID | Implicit | The affiliate's preferred payment currency |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_eCostHistory | Table | FK constraint on CurrencyID |
| dbo.tblaff_Affiliates | Table | Implicit reference via PrefferedCurrencyID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary.Currency | CLUSTERED PK | CurrencyID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all supported currencies
```sql
SELECT CurrencyID, CurrencyName
FROM Dictionary.Currency WITH (NOLOCK)
ORDER BY CurrencyID
```

### 8.2 Find eCost history with currency names
```sql
SELECT ech.eCostHistoryID, ech.AffiliateID, ech.TotalAmount, c.CurrencyName, ech.RequestDate
FROM dbo.tblaff_eCostHistory ech WITH (NOLOCK)
JOIN Dictionary.Currency c WITH (NOLOCK) ON ech.CurrencyID = c.CurrencyID
ORDER BY ech.RequestDate DESC
```

### 8.3 Summarize eCost by currency
```sql
SELECT c.CurrencyName, COUNT(*) AS RecordCount, SUM(ech.TotalAmount) AS TotalAmount
FROM dbo.tblaff_eCostHistory ech WITH (NOLOCK)
JOIN Dictionary.Currency c WITH (NOLOCK) ON ech.CurrencyID = c.CurrencyID
GROUP BY c.CurrencyName
ORDER BY TotalAmount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Currency | Type: Table | Source: fiktivo/Dictionary/Tables/Dictionary.Currency.sql*
