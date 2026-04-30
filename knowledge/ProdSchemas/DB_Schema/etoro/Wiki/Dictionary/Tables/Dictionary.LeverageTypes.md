# Dictionary.LeverageTypes

> Lookup table defining the 2 leverage policy types (Proportional, Fixed) used to determine how leverage is applied to positions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | LeverageTypeID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.LeverageTypes classifies how leverage values are assigned and applied to trading positions. This is distinct from Dictionary.Leverage (which defines the actual leverage multiplier values) — LeverageTypes defines the METHOD of leverage application.

The distinction affects how leverage interacts with copy-trading: proportional leverage preserves the copied trader's leverage ratio, while fixed leverage applies a specific value regardless of the leader's choice. This is important for risk management in copy-trading scenarios where copiers may have different risk tolerances than the traders they follow.

LeverageTypeID is referenced by instrument and copy-trading configuration.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| LeverageTypeID | LeverageTypeName | Meaning |
|---|---|---|
| 1 | Proportional | Leverage is applied proportionally to the base position. In copy-trading, the copier uses the same leverage ratio as the leader. The standard mode for most instruments. |
| 2 | Fixed | A fixed leverage value is applied regardless of other factors. In copy-trading, the copier's leverage is independent of the leader's choice. Used when regulation or risk policy requires a specific leverage cap. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LeverageTypeID | int | NO | IDENTITY(1,1) NOT FOR REPLICATION | CODE-BACKED | Primary key (auto-increment). 1=Proportional, 2=Fixed. NOT FOR REPLICATION prevents identity conflicts in replicated environments. See [Leverage Types](_glossary.md#leverage-types). (Dictionary.LeverageTypes) |
| 2 | LeverageTypeName | nvarchar(50) | YES | - | CODE-BACKED | Leverage application method name. NULL allowed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Instrument / copy-trading config | LeverageTypeID | Implicit Lookup | Determines how leverage is applied |

---

## 6. Dependencies

This object has no dependencies.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_LeverageTypes | CLUSTERED PK | LeverageTypeID ASC | - | - | Active |

---

## 8. Sample Queries

### 8.1 List leverage types
```sql
SELECT LeverageTypeID, LeverageTypeName
FROM [Dictionary].[LeverageTypes] WITH (NOLOCK) ORDER BY LeverageTypeID;
```

---

*Generated: 2026-03-13 | Quality: 7.0/10*
*Object: Dictionary.LeverageTypes | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.LeverageTypes.sql*
