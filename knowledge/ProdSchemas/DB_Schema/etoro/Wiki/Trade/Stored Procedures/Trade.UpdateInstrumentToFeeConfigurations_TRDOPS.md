# Trade.UpdateInstrumentToFeeConfigurations_TRDOPS

> Direct MERGE-based upsert of overnight and end-of-week fee rates into Trade.InstrumentToFeeConfigV2 using a V2-native TVP that includes SettlementTypeID and FeeCalculationTypeID, bypassing the V1 adapter layer; used by the TRDOPS fee management tooling.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentToFeeConfigUpdates.(InstrumentID, SettlementTypeID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the TRDOPS (Trading Operations) tooling's direct path for updating instrument fee rates in Trade.InstrumentToFeeConfigV2. Unlike the legacy Trade.UpdateInstrumentToFeeConfigTable (which accepts a V1 TVP lacking SettlementTypeID and FeeCalculationTypeID and converts it before writing), this procedure accepts the V2-native TVP type (InstrumentToFeeConfigType_TRDOPS) that carries all fields required by the V2 schema. The caller is responsible for supplying correct SettlementTypeID and FeeCalculationTypeID values.

The procedure covers all eight fee rate fields: overnight (buy/sell) and end-of-week (buy/sell) for both leveraged and non-leveraged positions. These fees are applied by the rollover process at the end of each trading day and at the end of each trading week, charging customers for holding leveraged or non-leveraged overnight positions.

A fee change alert is sent after the update (via Trade.RolloverFeesAlertIfNeeded) unless the caller is the internal split process (@AppLoginName = 'split'). This suppression is intentional: split operations divide a position's fees as an internal accounting operation and do not represent a real rate change that requires downstream notification.

---

## 2. Business Logic

### 2.1 MERGE Upsert into InstrumentToFeeConfigV2

**What**: A MERGE statement handles both new and existing fee configurations for each (InstrumentID, SettlementTypeID) composite key.

**Columns/Parameters Involved**: `InstrumentID`, `SettlementTypeID`, all 8 fee rate fields, `FeeCalculationTypeID`, `UpdatedByUser`, `Occurred`

**Rules**:
- WHEN MATCHED (row exists): UPDATE all 8 fee fields + FeeCalculationTypeID + UpdatedByUser + Occurred
- WHEN NOT MATCHED (new combination): INSERT all fields including InstrumentID and SettlementTypeID
- Occurred timestamp is captured once at procedure start with GETUTCDATE() and applied to all rows in the batch
- UpdatedByUser is set to @AppLoginName for audit trail

**Diagram**:
```
(InstrumentID, SettlementTypeID) exists in InstrumentToFeeConfigV2?
  YES -> UPDATE 8 fee rates + FeeCalculationTypeID + UpdatedByUser + Occurred
  NO  -> INSERT full row with all 13 fields
```

### 2.2 Temp Table with Clustered Index for Performance

**What**: The input TVP is materialized into a temp table with a clustered index before the MERGE, improving join performance for large batches.

**Columns/Parameters Involved**: `#TempInstrumentToFeeConfigUpdates (InstrumentID, SettlementTypeID)`

**Rules**:
- `SELECT * INTO #TempInstrumentToFeeConfigUpdates FROM @InstrumentToFeeConfigUpdates`
- `CREATE CLUSTERED INDEX CIX ON #TempInstrumentToFeeConfigUpdates (InstrumentID, SettlementTypeID)` applied immediately after
- The MERGE reads from the temp table (not the TVP directly) to benefit from the index seek

### 2.3 SyncConfiguration XML Snapshot

**What**: After the MERGE, a sync event is inserted into Trade.SyncConfiguration for each updated instrument, carrying a full XML snapshot of the fee state for downstream consumers.

**Columns/Parameters Involved**: `Trade.SyncConfiguration.ConfigurationUpdateTypeID` (= 5), `InstrumentID`, `Value` (XML string)

**Rules**:
- ConfigurationUpdateTypeID = 5 (fee configuration update type)
- Value is a FOR XML PATH / ROOT XML fragment containing all 10 fields: InstrumentID, 8 fee rates, SettlementTypeID, FeeCalculationTypeID, UpdatedByUser
- Reads from the original @InstrumentToFeeConfigUpdates TVP (not the temp table) for the XML subquery
- One row inserted per instrument in the input batch

**XML snippet structure**:
```xml
<Root>
  <Instrument>
    <InstrumentID>1234</InstrumentID>
    <NonLeveragedSellEndOfWeekFee>0.00500000</NonLeveragedSellEndOfWeekFee>
    ...
    <SettlementTypeID>0</SettlementTypeID>
    <FeeCalculationTypeID>0</FeeCalculationTypeID>
    <UpdatedByUser>admin</UpdatedByUser>
  </Instrument>
</Root>
```

### 2.4 Split Process Suppression of Alert

**What**: The fee change alert is suppressed when the update comes from the split process.

**Columns/Parameters Involved**: `@AppLoginName`, `@IsAlertTriggered`

**Rules**:
- IF ISNULL(@AppLoginName, '') <> 'split': call Trade.RolloverFeesAlertIfNeeded
- If @AppLoginName = 'split': skip alert, @IsAlertTriggered remains 0
- Comment in code: "We don't need to trigger alert on a split process"
- The alert notifies operations teams when actual overnight/weekly fee rates change

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentToFeeConfigUpdates | Trade.InstrumentToFeeConfigType_TRDOPS (TVP, READONLY) | NO | - | CODE-BACKED | V2-native fee configuration TVP. Composite PK: (InstrumentID int NOT NULL, SettlementTypeID tinyint NOT NULL DEFAULT 0). Contains 8 fee rate fields (decimal(16,8) NOT NULL): NonLeveragedSellEndOfWeekFee, NonLeveragedBuyEndOfWeekFee, NonLeveragedBuyOverNightFee, NonLeveragedSellOverNightFee, LeveragedSellEndOfWeekFee, LeveragedBuyEndOfWeekFee, LeveragedBuyOverNightFee, LeveragedSellOverNightFee. Also contains FeeCalculationTypeID (tinyint NOT NULL DEFAULT 0). Unlike V1 types, caller must provide SettlementTypeID explicitly (e.g., 0 = CFD/standard, 4 = crypto TRS). |
| 2 | @AppLoginName | varchar(50) | YES | NULL | CODE-BACKED | Username or service name of the caller. Written to UpdatedByUser on InstrumentToFeeConfigV2 rows and embedded in the SyncConfiguration XML snapshot for audit. Special value 'split' suppresses the fee change alert - used by the split process which divides fee amounts as internal accounting rather than a real rate change. |
| 3 | @IsAlertTriggered | bit (OUTPUT) | NO | 0 | CODE-BACKED | Output indicating whether Trade.RolloverFeesAlertIfNeeded triggered a downstream fee change notification. Returns 1 if an alert was sent; 0 if suppressed (split process or no alertable changes). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (InstrumentID, SettlementTypeID) | Trade.InstrumentToFeeConfigV2 | MERGE (UPDATE/INSERT) | Primary target; fee rates and metadata upserted by composite key |
| All fee fields | Trade.SyncConfiguration | INSERT | Fee change sync event with full XML snapshot; ConfigurationUpdateTypeID = 5 |
| @IsAlertTriggered | Trade.RolloverFeesAlertIfNeeded | EXEC call | Triggered after commit unless caller is 'split' process |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| TRDOPS fee management tooling | Application call | Caller | No internal SP callers found; invoked from Trading Operations tooling that manages fee rates directly using V2 TVP format |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInstrumentToFeeConfigurations_TRDOPS (procedure)
|- Trade.InstrumentToFeeConfigV2 (table) [MERGE upsert - fee rates by InstrumentID+SettlementTypeID]
|- Trade.SyncConfiguration (table) [INSERT - fee change XML snapshot, ConfigurationUpdateTypeID=5]
+-- Trade.RolloverFeesAlertIfNeeded (procedure) [EXEC - fee change alert, skipped for 'split' caller]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentToFeeConfigV2 | Table | MERGE target: UPDATE on match, INSERT on not-match, keyed by (InstrumentID, SettlementTypeID) |
| Trade.SyncConfiguration | Table | INSERTed: ConfigurationUpdateTypeID=5 with XML snapshot of all fee fields per instrument |
| Trade.RolloverFeesAlertIfNeeded | Procedure | EXECuted post-commit to notify ops if fee rates changed (suppressed for 'split' caller) |
| Trade.InstrumentToFeeConfigType_TRDOPS | User Defined Type | V2-native TVP type for @InstrumentToFeeConfigUpdates; includes SettlementTypeID and FeeCalculationTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| TRDOPS fee management application | Application | Calls this procedure to upsert overnight/weekly fee rates using the V2 TVP format |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Composite key | TVP type | PK (InstrumentID, SettlementTypeID) with IGNORE_DUP_KEY = OFF in the TVP type definition |
| Temp table clustered index | Performance | CIX on (InstrumentID, SettlementTypeID) created before MERGE for efficient join |
| Split suppression | Logic | IF ISNULL(@AppLoginName, '') <> 'split' - alert skipped for internal split process |
| Atomic transaction | TRY/CATCH | MERGE + INSERT in single BEGIN TRAN / COMMIT; ROLLBACK + THROW on error |
| Occurred timestamp | Consistency | Single GETUTCDATE() captured before MERGE applied to all rows in batch |

---

## 8. Sample Queries

### 8.1 Update fee rates for a single instrument (CFD, standard settlement)

```sql
DECLARE @Fees [Trade].[InstrumentToFeeConfigType_TRDOPS]
INSERT INTO @Fees (InstrumentID, SettlementTypeID, FeeCalculationTypeID,
                   NonLeveragedBuyOverNightFee, NonLeveragedSellOverNightFee,
                   NonLeveragedBuyEndOfWeekFee, NonLeveragedSellEndOfWeekFee,
                   LeveragedBuyOverNightFee, LeveragedSellOverNightFee,
                   LeveragedBuyEndOfWeekFee, LeveragedSellEndOfWeekFee)
VALUES (1234, 0, 0,
        0.00250000, 0.00250000, 0.00750000, 0.00750000,
        0.00350000, 0.00350000, 0.01050000, 0.01050000)

DECLARE @IsAlert bit = 0
EXEC Trade.UpdateInstrumentToFeeConfigurations_TRDOPS
    @InstrumentToFeeConfigUpdates = @Fees,
    @AppLoginName = 'trdops_admin',
    @IsAlertTriggered = @IsAlert OUTPUT

SELECT @IsAlert AS AlertTriggered
```

### 8.2 Update fees for a crypto TRS instrument (SettlementTypeID = 4)

```sql
DECLARE @Fees [Trade].[InstrumentToFeeConfigType_TRDOPS]
INSERT INTO @Fees (InstrumentID, SettlementTypeID, FeeCalculationTypeID,
                   NonLeveragedBuyOverNightFee, NonLeveragedSellOverNightFee,
                   NonLeveragedBuyEndOfWeekFee, NonLeveragedSellEndOfWeekFee,
                   LeveragedBuyOverNightFee, LeveragedSellOverNightFee,
                   LeveragedBuyEndOfWeekFee, LeveragedSellEndOfWeekFee)
VALUES (5678, 4, 0,
        0.00100000, 0.00100000, 0.00300000, 0.00300000,
        0.00150000, 0.00150000, 0.00450000, 0.00450000)

DECLARE @IsAlert bit = 0
EXEC Trade.UpdateInstrumentToFeeConfigurations_TRDOPS
    @InstrumentToFeeConfigUpdates = @Fees,
    @AppLoginName = 'trdops_admin',
    @IsAlertTriggered = @IsAlert OUTPUT
```

### 8.3 Check current fee configuration for an instrument

```sql
SELECT
    fc.InstrumentID,
    fc.SettlementTypeID,
    fc.FeeCalculationTypeID,
    fc.NonLeveragedBuyOverNightFee,
    fc.NonLeveragedSellOverNightFee,
    fc.LeveragedBuyOverNightFee,
    fc.LeveragedSellOverNightFee,
    fc.UpdatedByUser,
    fc.Occurred
FROM Trade.InstrumentToFeeConfigV2 fc WITH (NOLOCK)
WHERE fc.InstrumentID = 1234
ORDER BY fc.SettlementTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInstrumentToFeeConfigurations_TRDOPS | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInstrumentToFeeConfigurations_TRDOPS.sql*
