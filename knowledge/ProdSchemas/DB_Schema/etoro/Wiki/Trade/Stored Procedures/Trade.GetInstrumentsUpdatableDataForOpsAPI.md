# Trade.GetInstrumentsUpdatableDataForOpsAPI

> Retrieves updatable trading parameters (margins, SL/TP defaults, rate diff tolerances) for a batch of instruments from the primary provider, powering the Ops Tool instrument configuration screens.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 8 updatable config columns from Trade.ProviderToInstrument for ProviderID=1 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentsUpdatableDataForOpsAPI returns the subset of Trade.ProviderToInstrument columns that operators can modify through the Ops Tool API: margin settings, stop-loss/take-profit defaults, and allowed rate difference percentages. These are the "tunable knobs" for instrument risk management.

This procedure exists because the Ops Tool needs to display current values before operators edit them. It uses the same validation pattern as GetInstrumentMarginsForFutures (error 60127 if any instrument is missing from ProviderToInstrument for ProviderID=1).

Called by trading-opstool-api.

---

## 2. Business Logic

### 2.1 Instrument Existence Validation (ProviderID=1)

**What**: Same validation pattern as GetInstrumentMarginsForFutures - ensures all instruments exist for the primary provider.

**Columns/Parameters Involved**: `@instrumentid_list`, `ProviderToInstrument.InstrumentID`, `ProviderToInstrument.ProviderID`

**Rules**:
- LEFT JOIN validation, RAISERROR(60127) on missing instruments
- ProviderID=1 filter in both validation and main query
- Ordered by InstrumentID for consistent display

### 2.2 Updatable Configuration Parameters

**What**: Returns the risk and trading parameters that ops can modify for each instrument.

**Columns/Parameters Involved**: All return columns

**Rules**:
- Leverage1MaintenanceMargin: maintenance margin percentage at 1x leverage
- StopLossMarginInAssetCurrency / InitialMarginInAssetCurrency: futures margin settings
- MaxStopLossPercentage / DefaultStopLossPercentage / DefaultTakeProfitPercentage: SL/TP configuration
- AllowedRateDiffPercentage / AllowedRateDiffPercentageUpside: acceptable price deviation before alerts

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @instrumentid_list | Trade.InstrumentIDsTbl (READONLY) | NO | - | CODE-BACKED | TVP of instrument IDs. All must exist in ProviderToInstrument for ProviderID=1. See [Trade.InstrumentIDsTbl](../User Defined Types/Trade.InstrumentIDsTbl.md). |

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | InstrumentID | int | PTI.InstrumentID | CODE-BACKED | Instrument identifier. |
| R2 | Leverage1MaintenanceMargin | decimal | PTI | CODE-BACKED | Maintenance margin percentage at 1x leverage. Derived from StopLossMargin/InitialMargin ratio. |
| R3 | MaxStopLossPercentage | decimal | PTI | CODE-BACKED | Maximum SL percentage allowed for this instrument. |
| R4 | StopLossMarginInAssetCurrency | decimal | PTI | CODE-BACKED | Futures SL margin in asset currency. |
| R5 | InitialMarginInAssetCurrency | decimal | PTI | CODE-BACKED | Futures initial margin in asset currency. |
| R6 | DefaultStopLossPercentage | decimal | PTI | CODE-BACKED | Default SL percentage when opening positions without explicit SL. |
| R7 | DefaultTakeProfitPercentage | decimal | PTI | CODE-BACKED | Default TP percentage when opening positions without explicit TP. |
| R8 | AllowedRateDiffPercentage | decimal | PTI | CODE-BACKED | Maximum allowed downside price deviation percentage before alert. |
| R9 | AllowedRateDiffPercentageUpside | decimal | PTI | CODE-BACKED | Maximum allowed upside price deviation percentage before alert. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @instrumentid_list | Trade.InstrumentIDsTbl | TVP Type | Input parameter type |
| FROM/JOIN | Trade.ProviderToInstrument | Read (SELECT) | Source of all updatable configuration data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| trading-opstool-api | EXECUTE | Permission | Ops Tool API for instrument configuration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentsUpdatableDataForOpsAPI (procedure)
+-- Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | INNER JOIN - source of updatable configuration columns |
| Trade.InstrumentIDsTbl | User Defined Type | TVP type for @instrumentid_list |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| trading-opstool-api | DB User | EXECUTE permission |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RAISERROR(60127) | Runtime validation | Raised if any InstrumentID not found in ProviderToInstrument for ProviderID=1 |

---

## 8. Sample Queries

### 8.1 Get updatable data for specific instruments

```sql
DECLARE @Instruments Trade.InstrumentIDsTbl;
INSERT INTO @Instruments (InstrumentID) VALUES (1), (5), (10);
EXEC Trade.GetInstrumentsUpdatableDataForOpsAPI @instrumentid_list = @Instruments;
```

### 8.2 View all instruments with their margin and SL/TP configuration

```sql
SELECT  InstrumentID, Leverage1MaintenanceMargin, MaxStopLossPercentage,
        DefaultStopLossPercentage, DefaultTakeProfitPercentage
FROM    Trade.ProviderToInstrument WITH (NOLOCK)
WHERE   ProviderID = 1
ORDER BY InstrumentID;
```

### 8.3 Find instruments with custom rate diff tolerances

```sql
SELECT  PTI.InstrumentID, IMD.InstrumentDisplayName,
        PTI.AllowedRateDiffPercentage, PTI.AllowedRateDiffPercentageUpside
FROM    Trade.ProviderToInstrument PTI WITH (NOLOCK)
        INNER JOIN Trade.InstrumentMetaData IMD WITH (NOLOCK) ON PTI.InstrumentID = IMD.InstrumentID
WHERE   PTI.ProviderID = 1
ORDER BY PTI.AllowedRateDiffPercentage DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trading Opstool API TDD](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/12817367145) | Confluence | Procedure listed as part of Ops Tool API instrument management surface |

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentsUpdatableDataForOpsAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentsUpdatableDataForOpsAPI.sql*
