# Trade.MaxLeverageByInstrumentForExposure

## 1. Business Meaning

Defines the maximum allowed leverage for a given exposure (position size) per instrument. As a customer's position size increases, the maximum permitted leverage decreases. InstrumentID = 0 acts as a default rule when no instrument-specific rule exists. Used to prevent over-exposure risk by enforcing tiered leverage limits.

## 2. Business Logic

- **Exposure tiers**: For each instrument, multiple rows define (MaxPositionUnits, MaxLeverage) pairs. Smaller positions allow higher leverage; larger positions require lower leverage.
- **Default fallback**: When no rule exists for an instrument, rules for InstrumentID = 0 apply.
- **Lookup algorithm**: `GetMaxLeverageByInstrumentForExposureForCID` finds the smallest MaxPositionUnits ≥ (existing exposure + new position) and returns its MaxLeverage.
- **Over-exposure**: If no row satisfies the condition, the procedure raises "Over exposure" error—the customer cannot open the requested position.
- **System versioning**: Historical changes are tracked in `History.MaxLeverageByInstrumentForExposure`.

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Row count | ~237 |
| Partitioning | None |
| System versioning | Yes (History.MaxLeverageByInstrumentForExposure) |
| Filegroup | PRIMARY, DICTIONARY for NonLiquidatablePositionRules |

**Sample distributions** (InstrumentID = 0 default rules):
- MaxPositionUnits: 10,000 → MaxLeverage 10
- MaxPositionUnits: 25,000 → MaxLeverage 5
- MaxPositionUnits: 100,000 → MaxLeverage 1
- MaxPositionUnits: 1,000,000,000 → MaxLeverage 0 (unlimited-size cap)

## 4. Elements

| # | Column | Type | Nullable | Default | Description |
|---|--------|------|----------|---------|-------------|
| 1 | InstrumentID | int | NO | - | Instrument (0 = default rule). FK to Trade.Instrument. |
| 2 | MaxPositionUnits | decimal(18,4) | NO | - | Upper bound of position size (units) for this leverage tier. |
| 3 | MaxLeverage | int | NO | - | Maximum allowed leverage for positions up to MaxPositionUnits. |
| 4 | DbLoginName | nvarchar(128) | - | suser_name() | Computed: current SQL login. |
| 5 | AppLoginName | varchar(500) | - | context_info() | Computed: application login from context. |
| 6 | SysStartTime | datetime2(7) | NO | getutcdate() | Temporal period start. |
| 7 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | Temporal period end. |

## 5. Relationships

| From | To | Type | Join |
|------|-----|------|------|
| InstrumentID | Trade.Instrument | Implicit FK | Lookup instrument metadata |
| InstrumentID = 0 | - | Default | Special sentinel for fallback rules |
| History table | History.MaxLeverageByInstrumentForExposure | System versioning | Auto-populated |

## 6. Dependencies

**Referenced by procedures:**
- `Trade.GetMaxLeverageByInstrumentForExposureForCID` – Main consumer: validates leverage before opening positions.

**Related tables:**
- `Trade.PositionTbl` – Used to compute existing user exposure (AmountInUnitsDecimal).
- `History.MaxLeverageByInstrumentForExposure` – History table.

## 7. Technical Details

- **Primary key**: (InstrumentID, MaxPositionUnits)
- **System-versioned temporal table**: SysStartTime, SysEndTime; history in History schema.
- **Trigger**: `Tr_T_MaxLeverageByInstrumentForExposure_INSERT` – no-op update for side effect (pattern used with temporal).
- **Constraints**: DF_MaxLeverageByInstrumentForExposure_SysStart, DF_MaxLeverageByInstrumentForExposure_SysEnd.
- **Filegroup**: PRIMARY.

## 8. Sample Queries

```sql
-- Default rules (InstrumentID = 0)
SELECT InstrumentID, MaxPositionUnits, MaxLeverage
FROM Trade.MaxLeverageByInstrumentForExposure
WHERE InstrumentID = 0
ORDER BY MaxPositionUnits;

-- Rules for a specific instrument
SELECT InstrumentID, MaxPositionUnits, MaxLeverage
FROM Trade.MaxLeverageByInstrumentForExposure
WHERE InstrumentID = 1
ORDER BY MaxPositionUnits;

-- Leverage lookup (mirrors proc logic)
DECLARE @InstrumentID INT = 1, @CID INT = 12345, @PositionUnits DECIMAL(18,4) = 5000;
SELECT TOP 1 InstrumentID, MaxPositionUnits, MaxLeverage
FROM Trade.MaxLeverageByInstrumentForExposure
WHERE InstrumentID IN (@InstrumentID, 0)
  AND MaxPositionUnits >= (
    SELECT ISNULL(SUM(AmountInUnitsDecimal), 0) + @PositionUnits
    FROM Trade.PositionTbl WHERE CID = @CID AND InstrumentID = @InstrumentID
  )
ORDER BY MaxPositionUnits;
```

## 9. Atlassian Knowledge Sources

- Jira/Confluence: Search for "max leverage", "exposure leverage", "over exposure" for product requirements.
- No direct Confluence/Jira references found in codebase.

---

*Generated: 2026-03-14 | Quality: 8.2/10*
