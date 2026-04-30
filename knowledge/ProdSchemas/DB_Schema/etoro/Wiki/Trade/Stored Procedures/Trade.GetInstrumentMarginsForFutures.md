# Trade.GetInstrumentMarginsForFutures

> Retrieves initial margin and stop-loss margin amounts in asset currency for a batch of futures instruments from their primary provider configuration.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns InstrumentID + margin columns from Trade.ProviderToInstrument |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentMarginsForFutures is a bulk-read procedure that returns the futures margin requirements - initial margin and stop-loss margin - for a set of instruments from the primary provider (ProviderID=1, Tradonomi). Futures instruments require margin deposits before trading; the initial margin is the amount required to open a position, and the stop-loss margin is the minimum equity threshold below which the position is force-closed.

This procedure exists because the Trading Ops Tool and OpsFlow API need to display and validate margin configurations for futures instruments in bulk. Without it, each instrument's margin data would have to be fetched individually from Trade.ProviderToInstrument. It is the read-side counterpart of Trade.SetInstrumentMarginsForFutures, which updates these same columns.

The procedure is called by ops tools (trading-opstool-api, OpsFlowAPI) to retrieve current margin settings. The caller populates a Trade.InstrumentIDsTbl TVP with the target instrument IDs. The procedure first validates that ALL requested instruments exist in Trade.ProviderToInstrument for ProviderID=1; if any are missing, it raises error 60127. On success, it returns one row per instrument with the two margin amounts.

---

## 2. Business Logic

### 2.1 Instrument Existence Validation

**What**: Pre-flight check ensuring every requested instrument has a provider-to-instrument configuration for the primary provider.

**Columns/Parameters Involved**: `@instrumentid_list`, `Trade.ProviderToInstrument.InstrumentID`, `Trade.ProviderToInstrument.ProviderID`

**Rules**:
- A LEFT JOIN between the input TVP and ProviderToInstrument (ProviderID=1) checks for NULLs on the PTI side
- If ANY InstrumentID from the input has no matching row in ProviderToInstrument for ProviderID=1, RAISERROR(60127) fires and the procedure returns immediately
- Error 60127 means "One or more InstrumentIDs were not found in Trade.ProviderToInstrument" - this same error code is used by Trade.CheckValidInstruments and Trade.GetInstrumentSlippage for the same validation pattern

**Diagram**:
```
@instrumentid_list        ProviderToInstrument (ProviderID=1)
+---------------+        +---------------+
| InstrumentID  |  LEFT  | InstrumentID  |
|     1001      | -----> |     1001      |  Match -> OK
|     1002      | -----> |     (NULL)    |  No match -> RAISERROR(60127)
|     1003      | -----> |     1003      |  Match -> OK
+---------------+        +---------------+
```

### 2.2 Primary Provider Hardcoded Filter

**What**: The procedure exclusively reads from ProviderID=1 (Tradonomi), the primary execution provider.

**Columns/Parameters Involved**: `Trade.ProviderToInstrument.ProviderID`

**Rules**:
- ProviderID=1 is hardcoded in both the validation check and the main SELECT
- This means margin data is always from the primary provider's configuration, regardless of whether the instrument exists under other providers
- The returned margin values are denominated in the instrument's asset currency (as indicated by the column names StopLossMarginInAssetCurrency and InitialMarginInAssetCurrency)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @instrumentid_list | Trade.InstrumentIDsTbl (READONLY) | NO | - | CODE-BACKED | Table-valued parameter containing the set of instrument IDs to look up. Each InstrumentID must exist in Trade.ProviderToInstrument for ProviderID=1 or the procedure raises error 60127. Callers populate this from Trade.Instrument filtered by InstrumentTypeID=14 (futures) or other criteria. See [Trade.InstrumentIDsTbl](../User Defined Types/Trade.InstrumentIDsTbl.md). |

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | InstrumentID | int | Trade.ProviderToInstrument.InstrumentID | CODE-BACKED | The instrument identifier, returned to correlate each row with the caller's input. FK to Trade.Instrument. |
| R2 | StopLossMarginInAssetCurrency | (from PTI) | Trade.ProviderToInstrument.StopLossMarginInAssetCurrency | CODE-BACKED | The stop-loss margin amount in the instrument's asset currency. This is the minimum equity a futures position must maintain; falling below triggers forced liquidation. Updated by Trade.SetInstrumentMarginsForFutures. Used in the Leverage1MaintenanceMargin calculation: `(1 - StopLossMargin / InitialMargin) * 100`. |
| R3 | InitialMarginInAssetCurrency | (from PTI) | Trade.ProviderToInstrument.InitialMarginInAssetCurrency | CODE-BACKED | The initial margin deposit required in the instrument's asset currency to open a futures position. Must be > 0 (enforced by Trade.SetInstrumentMarginsForFutures via error 60202). Updated by Trade.SetInstrumentMarginsForFutures. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @instrumentid_list | Trade.InstrumentIDsTbl | TVP Type | Table-valued parameter type defining the input schema (single InstrumentID column) |
| FROM/JOIN | Trade.ProviderToInstrument | Read (SELECT) | Source of margin data; joined on InstrumentID with ProviderID=1 filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SetInstrumentMarginsForFutures | (counterpart) | Writer counterpart | Updates the same StopLossMarginInAssetCurrency, InitialMarginInAssetCurrency, and Leverage1MaintenanceMargin columns this procedure reads |
| Trade.UpdateFuturesTradingConfigurations | (related) | Related procedure | Also manages futures trading configuration in ProviderToInstrument |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentMarginsForFutures (procedure)
+-- Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | Read via INNER JOIN - source of InstrumentID, StopLossMarginInAssetCurrency, InitialMarginInAssetCurrency |
| Trade.InstrumentIDsTbl | User Defined Type | TVP type for @instrumentid_list parameter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| trading-opstool-api | DB User | EXECUTE permission granted - ops tool for managing instrument configurations |
| OpsFlowAPI | DB User | EXECUTE permission granted - operations flow API |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RAISERROR(60127) | Runtime validation | Raised when any input InstrumentID does not exist in Trade.ProviderToInstrument for ProviderID=1. Prevents returning incomplete margin data. |

---

## 8. Sample Queries

### 8.1 Retrieve futures margins for specific instruments

```sql
DECLARE @Instruments Trade.InstrumentIDsTbl;
INSERT INTO @Instruments (InstrumentID) VALUES (1001), (1002), (1003);
EXEC Trade.GetInstrumentMarginsForFutures @instrumentid_list = @Instruments;
```

### 8.2 Retrieve margins for all futures instruments

```sql
DECLARE @FuturesInstruments Trade.InstrumentIDsTbl;
INSERT INTO @FuturesInstruments (InstrumentID)
SELECT  InstrumentID
FROM    Trade.Instrument WITH (NOLOCK)
WHERE   InstrumentTypeID = 14;

EXEC Trade.GetInstrumentMarginsForFutures @instrumentid_list = @FuturesInstruments;
```

### 8.3 Compare margins with current ProviderToInstrument data directly

```sql
SELECT  PTI.InstrumentID,
        I.SymbolFull,
        PTI.StopLossMarginInAssetCurrency,
        PTI.InitialMarginInAssetCurrency,
        PTI.Leverage1MaintenanceMargin
FROM    Trade.ProviderToInstrument PTI WITH (NOLOCK)
        INNER JOIN Trade.Instrument I WITH (NOLOCK) ON PTI.InstrumentID = I.InstrumentID
WHERE   PTI.ProviderID = 1
        AND I.InstrumentTypeID = 14
ORDER BY I.SymbolFull;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trading Opstool API TDD](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/12817367145) | Confluence | Procedure is listed as part of the Trading Ops Tool API surface for instrument management |

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentMarginsForFutures | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentMarginsForFutures.sql*
