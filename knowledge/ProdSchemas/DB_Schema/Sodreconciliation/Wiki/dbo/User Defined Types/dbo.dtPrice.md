# dbo.dtPrice

> User-defined type alias for decimal(16,8). Provides a standardized price data type with 8 decimal places of precision, used across the SOD reconciliation database for price-related columns.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | User-Defined Type (Alias) |
| **Base Type** | decimal(16,8) NOT NULL |
| **Nullability** | NOT NULL (enforced by type) |

---

## 1. Business Meaning

This user-defined type establishes a standard representation for price values throughout the Sodreconciliation database. By defining `dtPrice` as `decimal(16,8)`, it ensures that all price columns using this type have consistent precision and scale:

- **Precision 16**: Up to 16 total digits, allowing prices up to 99,999,999.99999999
- **Scale 8**: 8 decimal places, providing sub-penny precision required for fractional share pricing, forex rates, and securities that trade in fractions of a cent

The 8-decimal precision is important for the reconciliation system because Apex Clearing and eToro may report prices at different precision levels, and having sufficient decimal places prevents rounding-induced false breaks during position and trade comparisons.

The type enforces NOT NULL at the type level, meaning any column declared as `dtPrice` will not accept NULL values unless explicitly overridden with `NULL` in the column definition.

---

## 2. Business Logic

### 2.1 Price Precision Standard

**What**: Enforces consistent decimal(16,8) precision for all price-related data.

**Rules**:
- 8 decimal places accommodate sub-penny pricing used in US equities, fractional shares, and derived price calculations
- NOT NULL enforcement at the type level ensures price values are always explicitly provided
- Maximum representable value: 99,999,999.99999999
- Minimum representable value: -99,999,999.99999999

---

## 3. Data Overview

N/A - This is a type definition, not a data-holding object.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (base type) | decimal(16,8) | NO | - | CODE-BACKED | Alias for decimal with 16-digit precision and 8-decimal scale. Enforces NOT NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

None. Type aliases do not reference other objects.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (various tables) | Price columns | Column type | Any column declared as `dbo.dtPrice` uses this type definition |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.dtPrice (user-defined type)
  (no dependencies)
```

### 6.1 Objects This Depends On

None.

### 6.2 Objects That Depend On This

Any table columns declared with the `dtPrice` type depend on this UDT. The type cannot be dropped while columns reference it.

---

## 7. Technical Details

### 7.1 Type Definition

```sql
CREATE TYPE [dbo].[dtPrice] FROM [decimal](16, 8) NOT NULL
```

### 7.2 Storage

- Storage size: 9 bytes per value (standard for decimal(16,8))
- Precision: 16 digits total
- Scale: 8 decimal places

---

## 8. Sample Queries

### 8.1 Find columns using this type

```sql
SELECT t.name AS TableName, c.name AS ColumnName, tp.name AS TypeName
FROM sys.columns c
JOIN sys.types tp ON c.user_type_id = tp.user_type_id
JOIN sys.tables t ON c.object_id = t.object_id
WHERE tp.name = 'dtPrice'
ORDER BY t.name, c.name;
```

### 8.2 Declare a variable using the type

```sql
DECLARE @price dbo.dtPrice = 123.45678901;
SELECT @price AS PriceValue;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources directly reference this type.

---

*Generated: 2026-04-11 | Quality: 6.0/10 (Elements: 8/10, Logic: 6/10, Relationships: 4/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Object: dbo.dtPrice | Type: User-Defined Type | Source: Sodreconciliation/Sodreconciliation/dbo/User Defined Types/dbo.dtPrice.sql*
