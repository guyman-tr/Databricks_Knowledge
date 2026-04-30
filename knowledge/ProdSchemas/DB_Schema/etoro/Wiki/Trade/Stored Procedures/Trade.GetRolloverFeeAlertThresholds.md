# Trade.GetRolloverFeeAlertThresholds

> Returns the current rollover fee alert thresholds for all instrument types, enriched with the instrument type name from Dictionary.CurrencyType. No parameters.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (no parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the read endpoint for the rollover fee alert configuration. It returns the full threshold configuration table - one row per instrument type - with the instrument type name resolved from Dictionary.CurrencyType. The output is used by the trading operations UI and monitoring tools to display the current thresholds and confirm who last updated each one.

Rollover fees are charged when positions are held overnight. Trade.RolloverFeeAlertThreshold defines the maximum acceptable rollover fee percentage per instrument type (e.g., Stocks threshold=6.09%, Crypto threshold=20%). When a calculated rollover fee exceeds the threshold, `Trade.RolloverFeesAlertIfNeeded` fires an alert for the ops team.

This procedure is the counterpart to `Trade.UpdateRolloverFeeThreshold` (which writes new thresholds). Together, they form the read/write pair for rollover fee alert configuration management.

Note on Dictionary.CurrencyType: The JOIN uses `Dictionary.CurrencyType ON InstrumentTypeID = DI.CurrencyTypeID`. Dictionary.CurrencyType and Dictionary.InstrumentType use the same ID space - CurrencyTypeID = InstrumentTypeID. The Name column from Dictionary.CurrencyType provides the human-readable instrument type name (e.g., "Stocks", "Currencies", "Crypto").

---

## 2. Business Logic

### 2.1 Threshold Configuration Readout

**What**: Returns all thresholds with their instrument type names. No filtering.

**Columns/Parameters Involved**: `InstrumentTypeID`, `Name`, `RolloverFeeThreshold`, `UpdatedByUser`

**Rules**:
- INNER JOIN to Dictionary.CurrencyType ON InstrumentTypeID = CurrencyTypeID -> gets Name for each instrument type
- No WHERE clause -> returns all configured instrument types
- No NOLOCK hint in this procedure (reads temporal table; NOLOCK is avoided for temporal tables)
- No pagination -> small table (6 rows, one per instrument type)

**Current threshold values** (from Trade.RolloverFeeAlertThreshold live data):
```
InstrumentTypeID | Name        | RolloverFeeThreshold | UpdatedByUser
-----------------|-------------|---------------------|-------------------
1                | Stocks       | 6.09%               | opstest01@etoro.com
2                | Currencies   | 3.00%               | rachelsa@etoro.com
4                | Commodities  | 0.50%               | rachelsa@etoro.com
5                | Indices      | 10.00%              | initial script
6                | ETFs         | 11.00%              | igorve@etoro.com
10               | Crypto       | 20.00%              | yevgenymi@etoro.com
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
| 1 | InstrumentTypeID | INT | NO | - | CODE-BACKED | Instrument type identifier. Maps to Dictionary.CurrencyType.CurrencyTypeID (same ID space as InstrumentTypeID). Values: 1=Stocks, 2=Currencies, 4=Commodities, 5=Indices, 6=ETFs, 10=Crypto. PK of Trade.RolloverFeeAlertThreshold. |
| 2 | Name | VARCHAR | NO | - | CODE-BACKED | Human-readable instrument type name from Dictionary.CurrencyType. E.g., "Stocks", "Currencies", "Crypto". |
| 3 | RolloverFeeThreshold | DECIMAL(16,8) | NO | - | CODE-BACKED | Maximum acceptable rollover fee percentage for this instrument type. Positions with overnight fees exceeding this trigger an alert via Trade.RolloverFeesAlertIfNeeded. |
| 4 | UpdatedByUser | VARCHAR(50) | NO | - | CODE-BACKED | Email or username of the person who last updated this threshold. Provides audit trail for configuration changes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentTypeID, RolloverFeeThreshold, UpdatedByUser | Trade.RolloverFeeAlertThreshold | Reader | Complete source of threshold configuration; temporal table (system-versioned) |
| Name | Dictionary.CurrencyType | Reader (cross-schema) | Resolves CurrencyTypeID -> Name for instrument type labels |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trading ops UI / monitoring | (none) | Application call | Displays current rollover fee alert thresholds for configuration review |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetRolloverFeeAlertThresholds (procedure)
+-- Trade.RolloverFeeAlertThreshold (table - temporal)
+-- Dictionary.CurrencyType (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.RolloverFeeAlertThreshold | Table (temporal) | Source of InstrumentTypeID, RolloverFeeThreshold, UpdatedByUser |
| Dictionary.CurrencyType | Table (Dictionary schema) | INNER JOIN on CurrencyTypeID = InstrumentTypeID for Name column |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trading operations service | External application | Configuration read for rollover fee alert threshold display |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| INNER JOIN Dictionary.CurrencyType | Design | Excludes any RolloverFeeAlertThreshold rows with InstrumentTypeID not in Dictionary.CurrencyType (safe: table is small and well-controlled) |
| No NOLOCK | Design | Trade.RolloverFeeAlertThreshold is a temporal (system-versioned) table; NOLOCK is avoided to prevent reading inconsistent temporal history metadata |

---

## 8. Sample Queries

### 8.1 Get all rollover fee alert thresholds

```sql
EXEC Trade.GetRolloverFeeAlertThresholds;
```

### 8.2 Equivalent inline query

```sql
SELECT IR.InstrumentTypeID, DI.Name, IR.RolloverFeeThreshold, IR.UpdatedByUser
FROM Trade.RolloverFeeAlertThreshold IR
INNER JOIN Dictionary.CurrencyType DI ON IR.InstrumentTypeID = DI.CurrencyTypeID;
```

### 8.3 Check if a specific instrument type has a threshold configured

```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM Trade.RolloverFeeAlertThreshold WHERE InstrumentTypeID = 1
) THEN 'Configured' ELSE 'Not configured' END AS Status;
-- InstrumentTypeID=1 = Stocks
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetRolloverFeeAlertThresholds | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetRolloverFeeAlertThresholds.sql*
