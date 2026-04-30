# Trade.GetMaxLeverageByInstrumentForExposureForCID

> Determines the maximum allowed leverage for a customer's new position on a specific instrument, based on their current total exposure and the instrument's tiered exposure-to-leverage rules.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: InstrumentID, MaxPositionUnits, MaxLeverage, UserExposureInUnits, NumberOfOpenedPositions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMaxLeverageByInstrumentForExposureForCID enforces exposure-based leverage limits. As a customer accumulates more units on a given instrument, their maximum allowed leverage decreases - this is a risk management mechanism to prevent excessive concentration. The procedure calculates the customer's current exposure in units, adds the proposed new position's units, and finds the appropriate leverage tier.

This procedure exists because regulators and eToro's risk policy require that leverage scales down as exposure grows. For example, a customer might get 400x leverage on their first 10,000 units of EUR/USD, but only 200x after 50,000 units. The tiered rules are stored in Trade.MaxLeverageByInstrumentForExposure. If no instrument-specific rules exist, default rules (InstrumentID=0) apply.

Called by PROD_BIadmins. If the customer's total exposure (existing + proposed) exceeds ALL tiers, the procedure raises an "Over exposure" error to block the trade.

---

## 2. Business Logic

### 2.1 Tiered Exposure-to-Leverage Lookup

**What**: Finds the maximum leverage tier that can accommodate the customer's total exposure after the proposed position.

**Columns/Parameters Involved**: `@InstrumentID`, `@CID`, `@PositionUnits`, `Trade.MaxLeverageByInstrumentForExposure`, `Trade.PositionTbl`

**Rules**:
- Calculates UserExposureInUnits = SUM(AmountInUnitsDecimal) for the customer's open positions on this instrument
- Finds the FIRST tier in Trade.MaxLeverageByInstrumentForExposure where MaxPositionUnits >= UserExposureInUnits + @PositionUnits (ordered by MaxPositionUnits ascending)
- If no instrument-specific tiers exist (InstrumentID not in table), falls back to InstrumentID=0 (default tiers)
- If no tier can accommodate the total exposure -> RAISERROR 'Over exposure' (severity 16)

**Diagram**:
```
@InstrumentID, @CID, @PositionUnits
     |
     +--> Does Trade.MaxLeverageByInstrumentForExposure have rows for @InstrumentID?
     |        YES -> use @InstrumentID
     |        NO  -> use InstrumentID=0 (defaults)
     |
     v
Trade.PositionTbl -> SUM(AmountInUnitsDecimal) for @CID + @InstrumentID = UserExposureInUnits
     |
     v
SELECT TOP 1 FROM MaxLeverageByInstrumentForExposure
WHERE MaxPositionUnits >= UserExposureInUnits + @PositionUnits
ORDER BY MaxPositionUnits ASC
     |
     +--> Found tier -> return (InstrumentID, MaxPositionUnits, MaxLeverage, UserExposure, PositionCount)
     +--> No tier fits -> RAISERROR 'Over exposure'
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @InstrumentID | int | IN | - | CODE-BACKED | Instrument the customer wants to open a new position on. Used to look up exposure tiers and sum existing exposure. |
| 2 | @CID | int | IN | - | CODE-BACKED | Customer ID. Used to calculate current exposure on this instrument. |
| 3 | @PositionUnits | decimal(18,4) | IN | - | CODE-BACKED | Number of units the customer wants to add in the new position. Combined with existing exposure to check against tiers. |

### 4.2 Result Set

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | InstrumentID | int | NO | CODE-BACKED | The instrument ID used for tier lookup (may be 0 if default rules applied). |
| 2 | MaxPositionUnits | decimal | NO | CODE-BACKED | The ceiling of the matching tier - maximum total units allowed at this leverage level. |
| 3 | MaxLeverage | int | NO | CODE-BACKED | The maximum leverage multiplier allowed at this exposure level. |
| 4 | UserExposureInUnits | decimal | NO | CODE-BACKED | The customer's current total open units on this instrument (before the new position). |
| 5 | NumberOfOpenedPositions | int | NO | CODE-BACKED | Count of the customer's open positions on this instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.MaxLeverageByInstrumentForExposure | SELECT (READER) | Reads tiered exposure-to-leverage rules |
| FROM | Trade.PositionTbl | SELECT (READER) | Reads open positions to calculate current exposure |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | GRANT EXECUTE | Application User | BI analytics on leverage exposure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMaxLeverageByInstrumentForExposureForCID (procedure)
+-- Trade.MaxLeverageByInstrumentForExposure (table)
+-- Trade.PositionTbl (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.MaxLeverageByInstrumentForExposure | Table | SELECT to find matching exposure-leverage tier |
| Trade.PositionTbl | Table | SELECT to calculate current customer exposure on instrument |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins | Application User | Analytics |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Raises 'Over exposure' error (severity 16, state 1) if no tier accommodates the proposed total exposure.

---

## 8. Sample Queries

### 8.1 Check max leverage for a customer adding 100 units

```sql
EXEC Trade.GetMaxLeverageByInstrumentForExposureForCID
    @InstrumentID = 1001,
    @CID = 12345,
    @PositionUnits = 100.0000;
```

### 8.2 View exposure tiers for an instrument

```sql
SELECT  InstrumentID,
        MaxPositionUnits,
        MaxLeverage
FROM    Trade.MaxLeverageByInstrumentForExposure WITH (NOLOCK)
WHERE   InstrumentID IN (1001, 0)
ORDER BY InstrumentID, MaxPositionUnits;
```

### 8.3 Check current customer exposure per instrument

```sql
SELECT  InstrumentID,
        SUM(AmountInUnitsDecimal) AS TotalUnits,
        COUNT(*) AS PositionCount
FROM    Trade.PositionTbl WITH (NOLOCK)
WHERE   CID = 12345
        AND StatusID = 1
GROUP BY InstrumentID
ORDER BY TotalUnits DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMaxLeverageByInstrumentForExposureForCID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMaxLeverageByInstrumentForExposureForCID.sql*
