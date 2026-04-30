# Trade.GetAllFixPerLotConfigurations

> Returns all fixed per-lot fee configurations for instruments and groups.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Full dump of Trade.FixPerLotConfigurations |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the complete fee configuration for fixed per-lot trading fees. Each row defines a fixed monetary fee charged per lot traded for a specific combination of instrument (or instrument type), customer group, settlement type, and fee operation type.

Fixed per-lot fees are charged as a flat amount per unit/lot traded, regardless of position value. This contrasts with percentage-based fees returned by Trade.GetAllFeeInPercentageConfigurations. Together, these two configuration tables define the platform's complete fee schedule.

The table schema is identical to FeeInPercentageConfigurations, with FeeValue representing a fixed monetary amount rather than a percentage.

---

## 2. Business Logic

### 2.1 Full Table Read

**What**: Returns all fixed per-lot fee configurations.

**Columns/Parameters Involved**: All columns from `Trade.FixPerLotConfigurations`

**Rules**:
- No filtering - returns all rows
- No ordering specified
- Typically loaded at application startup or on configuration refresh

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

None.

### Output Columns

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | ID | INT | CODE-BACKED | Primary key of the configuration row. |
| 2 | InstrumentID | INT | CODE-BACKED | Specific instrument this fee applies to (NULL for type-level rules). |
| 3 | GroupID | INT | CODE-BACKED | Customer group/tier for differentiated pricing. |
| 4 | InstrumentTypeID | INT | CODE-BACKED | Instrument type category (e.g., stocks, crypto, CFDs). |
| 5 | IsSettled | BIT | CODE-BACKED | Whether this fee applies to settled (real stock) or non-settled (CFD) positions. |
| 6 | FeeValue | DECIMAL | CODE-BACKED | Fixed fee amount per lot traded (in the instrument's currency). |
| 7 | FeeOperationTypeID | INT | CODE-BACKED | Type of operation this fee applies to (e.g., open, close, overnight). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.FixPerLotConfigurations | Direct Read | Fee configuration table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAllFixPerLotConfigurations (procedure)
└── Trade.FixPerLotConfigurations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FixPerLotConfigurations | Table | Fee configuration source |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all fixed per-lot fee configurations

```sql
EXEC Trade.GetAllFixPerLotConfigurations;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAllFixPerLotConfigurations | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAllFixPerLotConfigurations.sql*
