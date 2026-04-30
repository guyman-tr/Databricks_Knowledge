# Billing.FundingTypeCurrency_MOT

> Memory-Optimized Table (MOT) TVP type carrying FundingTypeID-to-CurrencyID mappings for high-performance in-memory currency validation during payment processing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | User Defined Type |
| **Key Identifier** | FundingTypeID (indexed for fast lookup) |
| **Partition** | N/A |
| **Indexes** | 1 - IX_FundingTypeID (NONCLUSTERED on FundingTypeID ASC) |

---

## 1. Business Meaning

`Billing.FundingTypeCurrency_MOT` is a Memory-Optimized Table (MOT) type - a SQL Server In-Memory OLTP table-valued parameter. It carries pairs of `FundingTypeID` (payment method) and `CurrencyID` (currency), representing valid currency options for each funding type. The `MEMORY_OPTIMIZED = ON` attribute means this type is designed for use in hot-path stored procedures where latency is critical.

This type exists to enable fast, lock-free passing of funding-type/currency combinations to stored procedures that validate or route payments. Using a memory-optimized type eliminates the overhead of TempDB allocation and conventional locking that would apply to standard TVP types.

Data flows from in-memory application caches: the calling service pre-loads the permitted funding type/currency combinations into this type and passes it to a stored procedure for currency validation or routing decisions. The nonclustered index on `FundingTypeID` enables fast lookup by payment method within the TVP.

---

## 2. Business Logic

### 2.1 Memory-Optimized Hot Path Design

**What**: This type is specifically designed for high-throughput, low-latency payment processing paths where standard TVP types would introduce unacceptable locking overhead.

**Columns/Parameters Involved**: `FundingTypeID`, `CurrencyID`

**Rules**:
- `MEMORY_OPTIMIZED = ON` means the type exists entirely in RAM - no TempDB, no disk I/O
- The nonclustered index on `FundingTypeID` enables O(log n) lookup by payment method
- `CurrencyID` is nullable - NULL may represent "all currencies permitted" or "currency not yet determined"
- Multiple rows with the same `FundingTypeID` represent multiple permitted currencies for that payment method

**Diagram**:
```
Funding Type -> Valid Currencies:
  FundingTypeID=1 (CreditCard)  -> CurrencyID=1 (USD), CurrencyID=2 (EUR), CurrencyID=5 (GBP)
  FundingTypeID=3 (PayPal)      -> CurrencyID=1 (USD), CurrencyID=2 (EUR)
  FundingTypeID=2 (WireTransfer)-> CurrencyID=NULL (any currency permitted)
```

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method identifier. Indexed by IX_FundingTypeID for fast lookup. See [Funding Type](_glossary.md#funding-type) for values (e.g., 1=CreditCard, 2=WireTransfer, 3=PayPal, 27=eToroCryptoWallet). Multiple rows with the same FundingTypeID represent multiple valid currencies for that payment method. |
| 2 | CurrencyID | int | YES | NULL | CODE-BACKED | Currency identifier for this funding type/currency combination. References `Dictionary.Currency` (implicit). NULL may represent an unrestricted or unspecified currency. Multiple CurrencyID values per FundingTypeID indicate that the payment method supports multiple currencies. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID | Dictionary.FundingType | Lookup | Payment method identifier |
| CurrencyID | Dictionary.Currency | Lookup | Currency the funding type supports |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IX_FundingTypeID | NONCLUSTERED | FundingTypeID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Inspect type column definitions and index

```sql
SELECT
    tt.name AS type_name,
    tt.is_memory_optimized,
    c.name AS column_name,
    t.name AS data_type,
    c.is_nullable,
    i.name AS index_name,
    i.type_desc AS index_type
FROM sys.table_types tt WITH (NOLOCK)
JOIN sys.columns c WITH (NOLOCK) ON c.object_id = tt.type_table_object_id
JOIN sys.types t WITH (NOLOCK) ON t.user_type_id = c.user_type_id
LEFT JOIN sys.indexes i WITH (NOLOCK) ON i.object_id = tt.type_table_object_id
WHERE tt.schema_id = SCHEMA_ID('Billing')
  AND tt.name = 'FundingTypeCurrency_MOT'
ORDER BY c.column_id
```

### 8.2 View valid currencies per funding type from the source table

```sql
-- The runtime data this TVP would carry, sourced from Billing.FundingTypeToCurrency
SELECT
    ft.FundingTypeID,
    ft.Name AS FundingTypeName,
    c.CurrencyID,
    c.Symbol AS CurrencySymbol
FROM Billing.FundingTypeToCurrency ftc WITH (NOLOCK)
JOIN Dictionary.FundingType ft WITH (NOLOCK) ON ft.FundingTypeID = ftc.FundingTypeID
JOIN Dictionary.Currency c WITH (NOLOCK) ON c.CurrencyID = ftc.CurrencyID
ORDER BY ft.FundingTypeID, c.CurrencyID
```

### 8.3 Find active funding types with their currency count

```sql
SELECT
    FundingTypeID,
    COUNT(DISTINCT CurrencyID) AS SupportedCurrencyCount
FROM Billing.FundingTypeToCurrency WITH (NOLOCK)
GROUP BY FundingTypeID
ORDER BY SupportedCurrencyCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingTypeCurrency_MOT | Type: User Defined Type | Source: etoro/etoro/Billing/User Defined Types/Billing.FundingTypeCurrency_MOT.sql*
