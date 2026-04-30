# Trade.GetRolloverFeeMarkups

> Returns the global rollover fee buy and sell markup values from Maintenance.Feature (FeatureID 100050 and 100051). No parameters.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (no parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure reads the global rollover (overnight) fee markup configuration from the `Maintenance.Feature` key-value store. Rollover fees are the charges applied when customers hold leveraged positions overnight. eToro applies a markup on top of the raw interbank/exchange overnight rate: a buy markup (for long positions) and a sell markup (for short positions).

These markups are stored in `Maintenance.Feature` as text values under two fixed feature IDs:
- **FeatureID 100050** -> BuyMarkup (applied to long positions held overnight)
- **FeatureID 100051** -> SellMarkup (applied to short positions held overnight)

The procedure returns a single row with both markups as decimal values, ready for use in fee calculations. It is used by the rollover fee calculation service to determine the current markup rates before computing the final fee for each position.

`Maintenance.Feature` is a general-purpose key-value configuration table used across multiple eToro services. Using it for markup values allows operations to adjust rates without a code deploy.

---

## 2. Business Logic

### 2.1 Feature Flag Lookup for Markup Values

**What**: Reads two specific feature IDs and converts their text values to decimal(16,8) for use in fee calculations.

**Columns/Parameters Involved**: `Maintenance.Feature.FeatureID`, `Maintenance.Feature.Value`, `@BuyMarkup`, `@SellMarkup`

**Rules**:
- FeatureID=100050 -> BuyMarkup: markup applied to long (buy) positions held overnight
- FeatureID=100051 -> SellMarkup: markup applied to short (sell) positions held overnight
- `SELECT TOP 1` is used as a safety guard in case the Feature table has multiple rows for the same FeatureID (should not happen, but defensive)
- `CONVERT(decimal(16,8), Value)` converts the text Value column to a numeric markup
- If either FeatureID does not exist in Maintenance.Feature, the corresponding markup variable remains NULL (declared but not assigned), and the output returns NULL for that column

**Diagram**:
```
Maintenance.Feature
  FeatureID=100050, Value='0.00123' -> @BuyMarkup = 0.00123000
  FeatureID=100051, Value='0.00456' -> @SellMarkup = 0.00456000

Output: { BuyMarkup: 0.00123000, SellMarkup: 0.00456000 }

Rollover fee calculation (in calling service):
  Long position: fee += position_value * BuyMarkup * nights_held
  Short position: fee += position_value * SellMarkup * nights_held
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BuyMarkup | DECIMAL(16,8) | YES | NULL | CODE-BACKED | Rollover fee markup rate for long (buy) positions held overnight. Read from Maintenance.Feature FeatureID=100050. NULL if not configured. |
| 2 | SellMarkup | DECIMAL(16,8) | YES | NULL | CODE-BACKED | Rollover fee markup rate for short (sell) positions held overnight. Read from Maintenance.Feature FeatureID=100051. NULL if not configured. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BuyMarkup, SellMarkup | Maintenance.Feature | Reader (cross-schema) | Reads FeatureID 100050 (BuyMarkup) and 100051 (SellMarkup) configuration values |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Rollover fee calculation service | (none) | Application call | Reads current markup rates before computing overnight fees for all open positions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetRolloverFeeMarkups (procedure)
+-- Maintenance.Feature (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table (Maintenance schema) | SELECT TOP 1 Value WHERE FeatureID IN (100050, 100051); one query per markup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Rollover fee calculation service | External application | Reads markup rates for overnight fee calculations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| SELECT TOP 1 | Safety guard | Prevents errors if Feature table has duplicate rows for same FeatureID |
| CONVERT(decimal(16,8), Value) | Type conversion | Maintenance.Feature.Value is NVARCHAR; converted to high-precision decimal for fee math |
| Two separate SELECT statements | Design | One query per markup; simpler than a pivot or conditional aggregate |

---

## 8. Sample Queries

### 8.1 Get current rollover fee markups

```sql
EXEC Trade.GetRolloverFeeMarkups;
```

### 8.2 Equivalent inline query

```sql
SELECT
    CONVERT(decimal(16,8), (SELECT TOP 1 Value FROM Maintenance.Feature WHERE FeatureID = 100050)) AS BuyMarkup,
    CONVERT(decimal(16,8), (SELECT TOP 1 Value FROM Maintenance.Feature WHERE FeatureID = 100051)) AS SellMarkup;
```

### 8.3 View raw feature values for markup feature IDs

```sql
SELECT FeatureID, Value, FeatureName
FROM Maintenance.Feature WITH (NOLOCK)
WHERE FeatureID IN (100050, 100051)
ORDER BY FeatureID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetRolloverFeeMarkups | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetRolloverFeeMarkups.sql*
