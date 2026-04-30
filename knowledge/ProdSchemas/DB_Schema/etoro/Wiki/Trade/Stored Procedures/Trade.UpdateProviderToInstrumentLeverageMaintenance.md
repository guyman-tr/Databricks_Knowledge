# Trade.UpdateProviderToInstrumentLeverageMaintenance

> Updates the Leverage1MaintenanceMargin value on Trade.ProviderToInstrument for a batch of provider-instrument pairs, setting the minimum equity percentage required to maintain a 1x leveraged position.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @LeverageMaintenanceMarginUpdates (TVP with ProviderID + InstrumentID + value) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Maintenance margin is the minimum equity a customer must hold to keep a leveraged position open. When this threshold is breached, positions are subject to automatic liquidation (stop out). This procedure updates the maintenance margin percentage for the 1x leverage tier on the ProviderToInstrument table, which is the instrument configuration table that governs all trading parameters for each instrument-provider combination.

The Leverage1MaintenanceMargin field specifically covers the base (1x) leverage scenario. In futures and margin trading, different leverage levels can have different maintenance margin requirements. This procedure is focused on the baseline tier.

This procedure is called by Trade.UpdateFuturesTradingConfigurations as part of the periodic futures instrument configuration refresh, where maintenance margin values are pushed from an upstream data source (typically a futures exchange or risk management system) to the trading database.

---

## 2. Business Logic

### 2.1 Precise Provider-Instrument Targeting

**What**: Updates are keyed on both ProviderID and InstrumentID, allowing different liquidity providers to have different maintenance margin requirements for the same instrument.

**Columns/Parameters Involved**: `@LeverageMaintenanceMarginUpdates.ProviderID`, `@LeverageMaintenanceMarginUpdates.InstrumentID`

**Rules**:
- JOIN uses both ProviderID AND InstrumentID as the composite key (same as ProviderToInstrument's PK structure)
- If a ProviderID + InstrumentID combination from the TVP does not exist in ProviderToInstrument, no row is updated (silent no-op)
- Different providers can maintain different Leverage1MaintenanceMargin values for the same instrument

**Diagram**:
```
@LeverageMaintenanceMarginUpdates (TVP)
  ProviderID = 100, InstrumentID = 1234, Leverage1MaintenanceMargin = 5.00
  ProviderID = 101, InstrumentID = 1234, Leverage1MaintenanceMargin = 4.50
    |
    INNER JOIN Trade.ProviderToInstrument ON ProviderID AND InstrumentID
    |
    UPDATE Leverage1MaintenanceMargin for each matched row
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LeverageMaintenanceMarginUpdates | Trade.Leverage1MaintenanceMarginUpdate (TVP, READONLY) | NO | - | CODE-BACKED | Input batch of maintenance margin updates. Each row contains ProviderID (liquidity provider), InstrumentID (instrument being traded), and Leverage1MaintenanceMargin (new margin value as a percentage with 2 decimal places, e.g., 5.00 = 5%). Rows are matched to ProviderToInstrument using the ProviderID + InstrumentID composite key. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID + InstrumentID | Trade.ProviderToInstrument | Implicit JOIN | Leverage1MaintenanceMargin column updated for matching provider-instrument combinations |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateFuturesTradingConfigurations | EXEC call | Caller | Calls this procedure as part of the futures instrument configuration update to refresh maintenance margin values |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateProviderToInstrumentLeverageMaintenance (procedure)
└── Trade.ProviderToInstrument (table) [UPDATE - Leverage1MaintenanceMargin column]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | UPDATEd: Leverage1MaintenanceMargin column updated for matched ProviderID + InstrumentID rows |
| Trade.Leverage1MaintenanceMarginUpdate | User Defined Type | TVP type for input parameter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateFuturesTradingConfigurations | Procedure | Calls this procedure to update maintenance margin values during futures configuration refresh |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No transaction | Logic | No explicit BEGIN TRAN / COMMIT. Single UPDATE statement runs in implicit auto-commit. No CATCH block - errors propagate to caller. |
| Silent no-op on miss | Logic | INNER JOIN means unmatched rows in TVP are silently skipped (no error if ProviderID + InstrumentID not found). |

---

## 8. Sample Queries

### 8.1 Update maintenance margin for a specific provider-instrument

```sql
DECLARE @Updates [Trade].[Leverage1MaintenanceMarginUpdate]
INSERT INTO @Updates (ProviderID, InstrumentID, Leverage1MaintenanceMargin)
VALUES (100, 1234, 5.00)

EXEC Trade.UpdateProviderToInstrumentLeverageMaintenance
    @LeverageMaintenanceMarginUpdates = @Updates
```

### 8.2 Batch update maintenance margins for multiple instruments

```sql
DECLARE @Updates [Trade].[Leverage1MaintenanceMarginUpdate]
INSERT INTO @Updates (ProviderID, InstrumentID, Leverage1MaintenanceMargin)
VALUES
    (100, 1234, 5.00),
    (100, 5678, 4.50),
    (101, 1234, 5.25)

EXEC Trade.UpdateProviderToInstrumentLeverageMaintenance
    @LeverageMaintenanceMarginUpdates = @Updates
```

### 8.3 Check current maintenance margin values before and after update

```sql
SELECT
    tpti.ProviderID,
    tpti.InstrumentID,
    tpti.Leverage1MaintenanceMargin,
    ti.InstrumentID AS VerifyInstrument
FROM Trade.ProviderToInstrument tpti WITH (NOLOCK)
JOIN Trade.Instrument ti WITH (NOLOCK) ON ti.InstrumentID = tpti.InstrumentID
WHERE tpti.InstrumentID IN (1234, 5678)
ORDER BY tpti.ProviderID, tpti.InstrumentID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trade.ProviderToInstrument](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/13795000352/Trade.ProviderToInstrument) | Confluence | Main instrument configuration table documentation; Leverage1MaintenanceMargin is one of the trading rule fields defining minimum equity requirements for leveraged positions |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateProviderToInstrumentLeverageMaintenance | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateProviderToInstrumentLeverageMaintenance.sql*
