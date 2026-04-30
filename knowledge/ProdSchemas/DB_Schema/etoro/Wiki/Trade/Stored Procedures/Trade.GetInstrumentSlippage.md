# Trade.GetInstrumentSlippage

> Retrieves slippage tolerance and units quantity type for a batch of instruments from the primary provider configuration, enabling order execution engines to apply per-instrument slippage rules.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns InstrumentID + Slippage + UnitsQuantityType from Trade.ProviderToInstrument |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentSlippage is a bulk-read procedure that returns the slippage configuration and units quantity type for a set of instruments from Trade.ProviderToInstrument. Slippage defines the maximum allowed price deviation between the requested execution price and the actual fill price. UnitsQuantityType determines how position sizes are expressed (lots, units, etc.) for each instrument.

This procedure exists because order execution engines need per-instrument slippage tolerances to decide whether to fill, requote, or reject orders when market prices move between order submission and execution. Different instruments have different liquidity profiles requiring different slippage settings.

Like Trade.GetInstrumentMarginsForFutures, this procedure validates that all requested instruments exist in ProviderToInstrument (ProviderID is not filtered here, unlike the margins procedure) using the same error 60127 pattern. It uses the Trade.InstrumentIDsTbl TVP for batch input.

---

## 2. Business Logic

### 2.1 Instrument Existence Validation

**What**: Validates all requested instruments exist in ProviderToInstrument before returning data.

**Columns/Parameters Involved**: `@instrumentid_list`, `Trade.ProviderToInstrument.InstrumentID`

**Rules**:
- LEFT JOIN between input TVP and ProviderToInstrument checks for missing instruments
- RAISERROR(60127) if any InstrumentID has no ProviderToInstrument record
- Same validation pattern used by Trade.GetInstrumentMarginsForFutures and Trade.CheckValidInstruments

### 2.2 Slippage Tolerance Configuration

**What**: Per-instrument slippage tolerance defines acceptable price deviation during order execution.

**Columns/Parameters Involved**: `Slippage`, `UnitsQuantityType`

**Rules**:
- Slippage value determines maximum acceptable price movement between order request and execution
- UnitsQuantityType defines how the instrument measures position sizes
- No ProviderID filter - returns data across all providers (unlike GetInstrumentMarginsForFutures which filters to ProviderID=1)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @instrumentid_list | Trade.InstrumentIDsTbl (READONLY) | NO | - | CODE-BACKED | TVP containing instrument IDs to look up. All must exist in Trade.ProviderToInstrument or error 60127 is raised. See [Trade.InstrumentIDsTbl](../User Defined Types/Trade.InstrumentIDsTbl.md). |

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | InstrumentID | int | Trade.ProviderToInstrument.InstrumentID | CODE-BACKED | Instrument identifier. FK to Trade.Instrument. |
| R2 | Slippage | decimal | Trade.ProviderToInstrument.Slippage | CODE-BACKED | Maximum allowed price slippage for order execution. Defines how far the actual fill price can deviate from the requested price before an order is rejected or requoted. |
| R3 | UnitsQuantityType | int | Trade.ProviderToInstrument.UnitsQuantityType | CODE-BACKED | Defines how position sizes are measured for this instrument (e.g., units, lots). Determines the quantity system used in order and position calculations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @instrumentid_list | Trade.InstrumentIDsTbl | TVP Type | Input parameter type |
| FROM/JOIN | Trade.ProviderToInstrument | Read (SELECT) | Source of slippage and units quantity data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Order execution engines | (application) | Consumer | Uses slippage tolerances during order fill decisions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentSlippage (procedure)
+-- Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | INNER JOIN - source of Slippage and UnitsQuantityType |
| Trade.InstrumentIDsTbl | User Defined Type | TVP type for @instrumentid_list |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Order execution engines | Application | Read slippage config for order execution decisions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RAISERROR(60127) | Runtime validation | Raised if any input InstrumentID not found in Trade.ProviderToInstrument |

---

## 8. Sample Queries

### 8.1 Get slippage for specific instruments

```sql
DECLARE @Instruments Trade.InstrumentIDsTbl;
INSERT INTO @Instruments (InstrumentID) VALUES (1), (5), (10);
EXEC Trade.GetInstrumentSlippage @instrumentid_list = @Instruments;
```

### 8.2 View all instrument slippage settings

```sql
SELECT  InstrumentID, Slippage, UnitsQuantityType
FROM    Trade.ProviderToInstrument WITH (NOLOCK)
WHERE   ProviderID = 1
ORDER BY InstrumentID;
```

### 8.3 Find instruments with high slippage tolerance

```sql
SELECT  PTI.InstrumentID,
        IMD.InstrumentDisplayName,
        PTI.Slippage,
        PTI.UnitsQuantityType
FROM    Trade.ProviderToInstrument PTI WITH (NOLOCK)
        INNER JOIN Trade.InstrumentMetaData IMD WITH (NOLOCK) ON PTI.InstrumentID = IMD.InstrumentID
WHERE   PTI.Slippage > 10
ORDER BY PTI.Slippage DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentSlippage | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentSlippage.sql*
