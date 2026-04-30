# Trade.GetAllFeeInPercentageConfigurations

> Returns all percentage-based fee configurations for instruments and groups.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Full dump of Trade.FeeInPercentageConfigurations |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the complete fee configuration for percentage-based trading fees. Each row defines a fee percentage applied to a specific combination of instrument (or instrument type), customer group, settlement type, and fee operation type.

The fee engine uses this configuration to calculate percentage-based fees at trade time. The configuration supports both specific instrument overrides (by InstrumentID) and broader instrument-type-level rules (by InstrumentTypeID), with GroupID allowing different fee tiers for different customer segments.

This procedure is the percentage-fee counterpart to Trade.GetAllFixPerLotConfigurations, which handles fixed per-lot fees. Together they form the complete fee configuration loaded by the trading fee calculation engine.

---

## 2. Business Logic

### 2.1 Full Table Read

**What**: Returns all fee percentage configurations.

**Columns/Parameters Involved**: All columns from `Trade.FeeInPercentageConfigurations`

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
| 6 | FeeValue | DECIMAL | CODE-BACKED | Fee percentage value (e.g., 0.01 = 1%). |
| 7 | FeeOperationTypeID | INT | CODE-BACKED | Type of operation this fee applies to (e.g., open, close, overnight). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.FeeInPercentageConfigurations | Direct Read | Fee configuration table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAllFeeInPercentageConfigurations (procedure)
└── Trade.FeeInPercentageConfigurations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FeeInPercentageConfigurations | Table | Fee configuration source |

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

### 8.1 Get all percentage fee configurations

```sql
EXEC Trade.GetAllFeeInPercentageConfigurations;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAllFeeInPercentageConfigurations | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAllFeeInPercentageConfigurations.sql*
