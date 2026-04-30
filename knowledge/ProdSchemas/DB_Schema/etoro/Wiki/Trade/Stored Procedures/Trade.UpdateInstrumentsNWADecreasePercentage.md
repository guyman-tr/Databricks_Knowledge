# Trade.UpdateInstrumentsNWADecreasePercentage

> Batch-updates BonusCreditUsePercent in Trade.ProviderToInstrument for a set of instruments. The SyncConfiguration queue entry was intentionally removed in 2016 (FB:37894) as the procedure became single-operation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentNewConfigTable (TVP - Trade.InstrumentNWADecreasePercentageConfigTable) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateInstrumentsNWADecreasePercentage sets `BonusCreditUsePercent` for each instrument in `Trade.ProviderToInstrument`. This field controls what percentage of the instrument's position exposure is drawn from bonus credit (as opposed to real cash). "NWA Decrease Percentage" refers to how much the Net Worth Allocation (NWA) decreases per unit of trading on this instrument - instruments with higher BonusCreditUsePercent consume bonus credit faster per dollar traded.

The procedure was modified by developer "Adi" on 2016-08-01 (Facebook ticket FB:37894) to remove the SyncConfiguration INSERT and the explicit transaction, as the procedure was reduced to a single UPDATE statement. The original design included ConfigurationUpdateTypeID sync queue like the sibling procedures (MaxPositionUnits, MinPositionAmount, MaxStopLoss, MaxRateDiff), but this was dropped as no longer needed. The current version is a minimal single-statement UPDATE.

---

## 2. Business Logic

### 2.1 BonusCreditUsePercent Update

**What**: Updates BonusCreditUsePercent for all InstrumentIDs present in the TVP.

**Columns/Parameters Involved**: `@InstrumentNewConfigTable.InstrumentID`, `.ConfigurationValue`, `Trade.ProviderToInstrument.BonusCreditUsePercent`

**Rules**:
- `UPDATE Trade.ProviderToInstrument SET BonusCreditUsePercent=f.ConfigurationValue INNER JOIN @InstrumentNewConfigTable f ON f.InstrumentID=TI.InstrumentID`
- Single-statement UPDATE, no explicit transaction (single operation does not require one)
- No SyncConfiguration INSERT (intentionally removed in 2016 per FB:37894)
- No existence check; silent no-op for unmatched InstrumentIDs

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentNewConfigTable | Trade.InstrumentNWADecreasePercentageConfigTable READONLY | NO | - | CODE-BACKED | TVP with the new BonusCreditUsePercent values. Each row: InstrumentID (JOIN key to ProviderToInstrument), ConfigurationValue (the new NWA decrease percentage - the percentage of bonus credit consumed per unit of position exposure on this instrument). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentNewConfigTable | Trade.InstrumentNWADecreasePercentageConfigTable | TVP | Input parameter type |
| UPDATE target | Trade.ProviderToInstrument | Modifier | Updates BonusCreditUsePercent per InstrumentID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. PROD_BIadmins has VIEW DEFINITION. Invoked by configuration tooling.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInstrumentsNWADecreasePercentage (procedure)
+-- Trade.InstrumentNWADecreasePercentageConfigTable (TVP type)
+-- Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentNWADecreasePercentageConfigTable | User Defined Type (TVP) | Input parameter type (InstrumentID, ConfigurationValue) |
| Trade.ProviderToInstrument | Table | UPDATE target for BonusCreditUsePercent |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (configuration tooling) | - | Called when adjusting bonus credit usage rates per instrument |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Uses SET NOCOUNT ON. TRY/CATCH with THROW. No transaction (single operation). SyncConfiguration INSERT was deliberately removed in 2016 (FB:37894 by Adi).

---

## 8. Sample Queries

### 8.1 Update BonusCreditUsePercent for a batch of instruments
```sql
DECLARE @Config Trade.InstrumentNWADecreasePercentageConfigTable;

INSERT INTO @Config (InstrumentID, ConfigurationValue)
VALUES
  (1001, 0.20),
  (1002, 0.15);

EXEC Trade.UpdateInstrumentsNWADecreasePercentage @InstrumentNewConfigTable = @Config;
```

### 8.2 Check current BonusCreditUsePercent settings
```sql
SELECT InstrumentID, BonusCreditUsePercent
FROM   Trade.ProviderToInstrument WITH (NOLOCK)
WHERE  InstrumentID IN (1001, 1002);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInstrumentsNWADecreasePercentage | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInstrumentsNWADecreasePercentage.sql*
