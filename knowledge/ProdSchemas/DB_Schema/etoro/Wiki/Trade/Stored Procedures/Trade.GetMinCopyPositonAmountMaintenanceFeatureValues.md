# Trade.GetMinCopyPositonAmountMaintenanceFeatureValues

> Retrieves minimum position amount thresholds for copy trading, fund copies, and airdrops from Maintenance.Feature.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | OUTPUT parameters: MinCopyPositionAmountInCents, FundMinCopyPositionAmountInCents, AirDropMinPositionAmountInCents |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns configuration values that define the minimum position amounts allowed for copy trading operations. These thresholds prevent micro-investments that would be operationally costly or create noise in the system. Different thresholds apply for regular copy positions, fund copy positions, and airdrop positions.

Without this procedure, execution services would lack the configuration values needed to validate copy requests. Pre-execution validation depends on these thresholds to reject or allow position creation. The procedure name contains a typo ("Positon" instead of "Position") that is maintained for backward compatibility.

Data flows when Execution Services (MinCopyPositionAmountRepository) or pre-execution validation logic calls this procedure at runtime. Callers include Trade.GetEstimatedTreeUnitsByCID and Trade.GetEstimatedClosingTreeUnitsByPositionID, which use these values to compute tree units and validate copy amounts before execution.

---

## 2. Business Logic

### 2.1 Feature ID to Output Parameter Mapping

**What**: Each FeatureID in Maintenance.Feature maps to a specific OUTPUT parameter.

**Columns/Parameters Involved**: `FeatureID`, `Value`, `@MinCopyPositionAmountInCents`, `@FundMinCopyPositionAmountInCents`, `@AirDropMinPositionAmountInCents`

**Rules**:
- FeatureID 100 populates MinCopyPositionAmountInCents (minimum copy position amount in cents)
- FeatureID 101 populates FundMinCopyPositionAmountInCents (minimum fund copy position amount in cents)
- FeatureID 110 populates AirDropMinPositionAmountInCents (minimum airdrop position amount in cents)
- IIF returns Value when FeatureID matches, else 0; MAX aggregates across the three rows to produce one value per parameter

**Diagram**:
```
Maintenance.Feature (FeatureID, Value)
     |
     |  WHERE FeatureID IN (100, 101, 110)
     v
MAX(IIF(100)) -> @MinCopyPositionAmountInCents
MAX(IIF(101)) -> @FundMinCopyPositionAmountInCents
MAX(IIF(110)) -> @AirDropMinPositionAmountInCents
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MinCopyPositionAmountInCents | int | OUTPUT | - | CODE-BACKED | Minimum copy position amount in cents. From Maintenance.Feature FeatureID 100. Used by pre-execution validation to reject micro-investments. |
| 2 | @FundMinCopyPositionAmountInCents | int | OUTPUT | - | CODE-BACKED | Minimum fund copy position amount in cents. From Maintenance.Feature FeatureID 101. Different threshold for fund-based copy operations. |
| 3 | @AirDropMinPositionAmountInCents | int | OUTPUT | NULL | CODE-BACKED | Minimum airdrop position amount in cents. From Maintenance.Feature FeatureID 110. Optional; may be NULL if FeatureID 110 is not configured. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM clause | Maintenance.Feature | Implicit | Reads FeatureID and Value to populate OUTPUT parameters |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetEstimatedTreeUnitsByCID | EXEC | Procedure call | Uses minimum amounts for tree unit estimation |
| Trade.GetEstimatedClosingTreeUnitsByPositionID | EXEC | Procedure call | Uses minimum amounts for closing tree unit validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMinCopyPositonAmountMaintenanceFeatureValues (procedure)
└── Maintenance.Feature (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | SELECT FeatureID, Value for FeatureID IN (100, 101, 110) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetEstimatedTreeUnitsByCID | Procedure | Calls to obtain min copy amounts for validation |
| Trade.GetEstimatedClosingTreeUnitsByPositionID | Procedure | Calls to obtain min copy amounts for closing validation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Call procedure to retrieve all three thresholds
```sql
DECLARE @MinCopyPositionAmountInCents INT;
DECLARE @FundMinCopyPositionAmountInCents INT;
DECLARE @AirDropMinPositionAmountInCents INT = NULL;

EXEC Trade.GetMinCopyPositonAmountMaintenanceFeatureValues
    @MinCopyPositionAmountInCents = @MinCopyPositionAmountInCents OUTPUT,
    @FundMinCopyPositionAmountInCents = @FundMinCopyPositionAmountInCents OUTPUT,
    @AirDropMinPositionAmountInCents = @AirDropMinPositionAmountInCents OUTPUT;

SELECT @MinCopyPositionAmountInCents AS MinCopy, @FundMinCopyPositionAmountInCents AS FundMinCopy, @AirDropMinPositionAmountInCents AS AirDropMin;
```

### 8.2 Inspect source Maintenance.Feature rows
```sql
SELECT FeatureID, Value
FROM Maintenance.Feature WITH (NOLOCK)
WHERE FeatureID IN (100, 101, 110);
```

### 8.3 Validate thresholds before copy operation
```sql
DECLARE @MinCopy INT, @FundMin INT, @AirDrop INT;
EXEC Trade.GetMinCopyPositonAmountMaintenanceFeatureValues @MinCopy OUTPUT, @FundMin OUTPUT, @AirDrop OUTPUT;
-- Use @MinCopy, @FundMin, @AirDrop to validate amount >= threshold before executing copy
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trade.GetMinCopyPositonAmountMaintenanceFeatureValues](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/13795622973) | Confluence | Business purpose, parameter descriptions, FeatureID mappings (100, 101, 110), and calling services (Execution Services MinCopyPositionAmountRepository, pre-execution validation) |

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMinCopyPositonAmountMaintenanceFeatureValues | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMinCopyPositonAmountMaintenanceFeatureValues.sql*
