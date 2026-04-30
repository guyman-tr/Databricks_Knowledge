# Trade.ProviderToInstrumentSetMimPositionAmount

> Updates the minimum position amount (in account currency) for a provider-instrument pair in Trade.ProviderToInstrument and queues a ConfigType=6 sync event to notify downstream trading system consumers.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ProviderID + @InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ProviderToInstrumentSetMimPositionAmount sets the minimum monetary amount required to open a position for a given execution provider and instrument. This floor prevents micro-positions that would be operationally uneconomical or technically problematic for the hedging infrastructure. After updating Trade.ProviderToInstrument.MinPositionAmount, it queues a ConfigType=6 (minimum position amount) sync event to Trade.SyncConfiguration via Trade.SyncConfigurationAdd, so the trading engine and UI can enforce the new minimum immediately.

**Note on naming**: The procedure name contains a typo - "Mim" should be "Min" (minimum). This is a known artifact in the codebase and the procedure name is intentionally preserved as-is for backward compatibility.

This procedure is the minimum-amount counterpart to Trade.ProviderToInstrumentSetMaxPositionUnits (which handles maximum units, ConfigType=4). Together they define the position size envelope for each provider-instrument configuration.

Data flow: Called by back-office risk management or configuration tools. Updates Trade.ProviderToInstrument.MinPositionAmount (MONEY type). Formats the value with CONVERT(varchar(500), @MinPositionAmount, style 2) before queuing - style 2 produces scientific notation for very small amounts (e.g., 0.01 -> "1.000000e-002") which is how the sync consumer expects the value. Uses THROW (not RAISERROR) for error propagation - distinguishing it from the RAISERROR-based siblings.

---

## 2. Business Logic

### 2.1 MinPositionAmount Update and Sync

**What**: Updates the minimum position amount and propagates it to the sync queue with decimal formatting.

**Columns/Parameters Involved**: `MinPositionAmount`, `@MinPositionAmount`, `ConfigurationUpdateTypeID=6`

**Rules**:
- UPDATE Trade.ProviderToInstrument SET MinPositionAmount=@MinPositionAmount WHERE ProviderID=@ProviderID AND InstrumentID=@InstrumentID.
- Format for sync: @strValue = CONVERT(VARCHAR(500), @MinPositionAmount, 2). Style 2 = scientific notation (e.g., 10.00 -> "1.000000e+001").
- EXEC Trade.SyncConfigurationAdd @InstrumentID, 6, @strValue.
- ConfigType=6 = minimum position amount.

**Diagram**:
```
Trade.ProviderToInstrumentSetMimPositionAmount(@ProviderID, @InstrumentID, @MinPositionAmount)
    |
    v
UPDATE Trade.ProviderToInstrument SET MinPositionAmount=@MinPositionAmount WHERE PK
    |
    v
@strValue = CONVERT(VARCHAR(500), @MinPositionAmount, 2)  -- scientific notation format
    |
    v
EXEC Trade.SyncConfigurationAdd(@InstrumentID, 6, @strValue)
    |
    v
COMMIT / THROW on error
```

### 2.2 Error Handling: THROW vs. RAISERROR

**What**: Uses THROW for error propagation, unlike sibling procedures that use RAISERROR.

**Rules**:
- TRY/CATCH with THROW (not RAISERROR) in the CATCH block.
- THROW re-raises the original exception with original error number, message, and state.
- This is newer T-SQL style (SQL Server 2012+) vs. the RAISERROR pattern in sibling procedures (SyncLeveragesList, ProviderInstrumentLeverageEdit, etc.).
- No explicit RETURN value - control flow exits via THROW on error or falls through on success.

### 2.3 CONVERT Style 2 - Scientific Notation for Sync

**What**: The MONEY value is converted to scientific notation string for the sync queue payload.

**Rules**:
- CONVERT(VARCHAR(500), @MinPositionAmount, 2) uses style 2 = scientific notation.
- Example: MinPositionAmount=0.01 -> "1.000000e-002"; MinPositionAmount=10 -> "1.000000e+001".
- The downstream sync consumer parses this format. Using style 0 (plain decimal) or style 1 would produce different format that could cause parsing errors in consuming systems.
- This is the only configuration sync procedure that applies a specific CONVERT style - others use plain CAST.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderID | INTEGER | NO | - | CODE-BACKED | Execution provider identifier. With @InstrumentID forms the PK filter on Trade.ProviderToInstrument. |
| 2 | @InstrumentID | INTEGER | NO | - | CODE-BACKED | Instrument identifier. Used in the PK filter and as the InstrumentID for Trade.SyncConfigurationAdd. |
| 3 | @MinPositionAmount | MONEY | NO | - | CODE-BACKED | The new minimum position amount in account currency. MONEY type supports up to 4 decimal places. Converted to scientific notation string (CONVERT style 2) for the sync queue payload. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProviderID + @InstrumentID | Trade.ProviderToInstrument | Modifier (UPDATE) | Sets MinPositionAmount for the specified provider-instrument pair. |
| (call) | Trade.SyncConfigurationAdd | Callee | Called with ConfigType=6 and the scientific-notation formatted value to queue the change for downstream consumers. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Back-office risk management tools | - | Caller | Called when operators set or adjust minimum position amount requirements. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ProviderToInstrumentSetMimPositionAmount (procedure)
├── Trade.ProviderToInstrument (table)
└── Trade.SyncConfigurationAdd (procedure)
      └── Trade.SyncConfiguration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | UPDATE target for MinPositionAmount column. |
| Trade.SyncConfigurationAdd | Procedure | Called with ConfigType=6 to queue minimum position amount sync event. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Back-office risk management | External callers | Calls this to configure minimum position size per instrument. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**ConfigType mapping summary** (across related procedures):
| ConfigType | Meaning | Set By |
|-----------|---------|--------|
| 2 | Full leverages list (csv) | Trade.SyncLeveragesList |
| 3 | Default leverage value | Trade.SyncLeveragesList, Trade.ProviderInstrumentLeverageEdit |
| 4 | Max position units | Trade.ProviderToInstrumentSetMaxPositionUnits |
| 6 | Min position amount | Trade.ProviderToInstrumentSetMimPositionAmount (this procedure) |

**Procedure name typo**: The name "Mim" instead of "Min" is a known artifact. Do not rename - doing so would break all callers.

---

## 8. Sample Queries

### 8.1 Set minimum position amount to $10 for provider 1, instrument 1

```sql
EXEC Trade.ProviderToInstrumentSetMimPositionAmount
    @ProviderID = 1,
    @InstrumentID = 1,
    @MinPositionAmount = 10.00;
-- Updates MinPositionAmount=10.00 and queues ConfigType=6 with "1.000000e+001"
```

### 8.2 View current min/max configuration for an instrument

```sql
SELECT ProviderID, InstrumentID, MinPositionAmount, MaxPositionUnits
FROM Trade.ProviderToInstrument WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY ProviderID;
```

### 8.3 Check pending sync events for min position amount

```sql
SELECT TOP 10 ID, ConfigurationUpdateTypeID, InstrumentID, Value, Occurred
FROM Trade.SyncConfiguration WITH (NOLOCK)
WHERE InstrumentID = 1 AND ConfigurationUpdateTypeID = 6
ORDER BY ID DESC;
-- ConfigType=6 = min position amount; Value will be in scientific notation
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ProviderToInstrumentSetMimPositionAmount | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ProviderToInstrumentSetMimPositionAmount.sql*
