# Trade.SetInstrumentsDataForOpsAPI

> Feature-flag-gated batch update of 8 risk parameters in Trade.ProviderToInstrument for a set of instruments, using SERIALIZABLE isolation and firing SBR instrument update events after the update commits.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Instruments_NewParams TVP - batch of InstrumentIDs with new risk parameter values |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the primary write interface for the Operations API to update instrument risk parameters in bulk. It allows the ops team to adjust up to 8 risk control parameters for multiple instruments in a single atomic transaction.

The procedure is protected by a **feature flag** (`Maintenance.Feature FeatureID=124`) - if the flag is off (value=0), the procedure refuses to execute. This allows risk management to disable the ops update capability without a code deployment.

After successfully updating `Trade.ProviderToInstrument`, the procedure fires an SBR (likely "Smart Balance Risk" or similar event streaming system) notification via `Trade.BatchInsertEventsToSbrInstrumentsUpdates` - this propagates the parameter changes to downstream services that need to re-evaluate positions based on the new risk parameters.

The **SERIALIZABLE isolation level** prevents phantom reads during the update, ensuring no concurrent modifications to the same instruments can interleave with this batch.

---

## 2. Business Logic

### 2.1 Feature Flag Guard

**What**: Prevents execution when the Ops API update feature is disabled.

**Columns/Parameters Involved**: `Maintenance.Feature.Value WHERE FeatureID=124`

**Rules**:
- SELECT CAST(Value AS INT) FROM Maintenance.Feature WHERE FeatureID=124
- If value = 0 -> RAISERROR: 'Feature Flag for [Trade].[SetInstrumentsDataForOpsAPI] is off', RETURN
- Value = 1 (or any non-zero) -> proceed

### 2.2 Context Info for Audit Trail

**What**: Embeds the ops user login into the session context for audit purposes.

**Rules**:
- If @AppLoginName != '' -> SET CONTEXT_INFO CAST(@AppLoginName AS VARBINARY(128))
- Readable by triggers or audit processes via CONTEXT_INFO() during the update

### 2.3 All-NULL Validation

**What**: Prevents no-op calls where all parameters are NULL (nothing to update).

**Columns/Parameters Involved**: All 8 TVP columns

**Rules**:
- RAISERROR(60202) if any instrument row has ALL 8 parameter columns as NULL
- RETURN after RAISERROR
- This ensures the caller always specifies at least one parameter to change

### 2.4 Batch Risk Parameter Update

**What**: Updates up to 8 ProviderToInstrument risk columns per instrument with ISNULL partial-update pattern.

**Columns/Parameters Involved**: 8 columns in `Trade.ProviderToInstrument`

**Rules**:
- TRANSACTION ISOLATION LEVEL SERIALIZABLE prevents phantom reads
- All 8 columns use ISNULL(src, dest) pattern - NULL TVP values preserve existing values
- Updated columns:

| Column | Business Meaning |
|--------|-----------------|
| Leverage1MaintenanceMargin | % of initial margin at which maintenance stop triggers (real-stock) |
| MaxStopLossPercentage | Maximum stop-loss percentage a customer can set |
| StopLossMarginInAssetCurrency | SL margin threshold in asset currency |
| InitialMarginInAssetCurrency | Required initial margin in asset currency |
| DefaultStopLossPercentage | Default SL% applied when customer opens without specifying SL |
| DefaultTakeProfitPercentage | Default TP% applied when customer opens without specifying TP |
| AllowedRateDiffPercentage | Maximum downside slippage % allowed from order price |
| AllowedRateDiffPercentageUpside | Maximum upside slippage % allowed from order price |

### 2.5 SBR Event Notification

**What**: Notifies downstream services of the parameter changes via event streaming.

**Columns/Parameters Involved**: `Trade.BatchInsertEventsToSbrInstrumentsUpdates`

**Rules**:
- Called AFTER the UPDATE, BEFORE COMMIT (within the same transaction)
- @InstrumentsToSendUpdates = @Instruments_NewParams (same TVP passed through)
- If this fails -> CATCH block ROLLBACK -> parameter update also rolled back (atomic)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Instruments_NewParams | Trade.InstrumentsIDListSetParamsTbl READONLY | NO | - | CODE-BACKED | TVP containing InstrumentIDs and the risk parameters to update. NULL for any column means "keep existing value". At least one non-NULL parameter required per row. |
| 2 | @AppLoginName | VARCHAR(50) | YES | '' | CODE-BACKED | The Ops API user login name. If provided, set into CONTEXT_INFO for audit trail. Empty string = no context info set. |

**Trade.InstrumentsIDListSetParamsTbl columns (UDT - inferred from SET clause):**

| Column | Type | Description |
|--------|------|-------------|
| InstrumentID | INT | Instrument to update |
| Leverage1MaintenanceMargin | DECIMAL | Maintenance margin % for real-stock (Leverage=1) positions |
| MaxStopLossPercentage | DECIMAL | Maximum allowed stop-loss percentage |
| StopLossMarginInAssetCurrency | DECIMAL | SL margin threshold in asset currency |
| InitialMarginInAssetCurrency | DECIMAL | Required opening margin in asset currency |
| DefaultStopLossPercentage | DECIMAL | Default SL% when customer doesn't specify |
| DefaultTakeProfitPercentage | DECIMAL | Default TP% when customer doesn't specify |
| AllowedRateDiffPercentage | DECIMAL | Max downside slippage % |
| AllowedRateDiffPercentageUpside | DECIMAL | Max upside slippage % |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Feature guard | Maintenance.Feature | Lookup | FeatureID=124: enables/disables this procedure's execution |
| Validation + UPDATE | Trade.ProviderToInstrument | Modifier | Validates (all-NULL check) and updates 8 risk parameter columns |
| TVP type | Trade.InstrumentsIDListSetParamsTbl | UDT | Input structure definition |
| Post-update event | Trade.BatchInsertEventsToSbrInstrumentsUpdates | Callee | Fires SBR update events for modified instruments |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - called by Ops API for instrument risk parameter management.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SetInstrumentsDataForOpsAPI (procedure)
|- Maintenance.Feature (table - FeatureID=124 feature flag)
|- Trade.InstrumentsIDListSetParamsTbl (UDT - TVP type)
|- Trade.ProviderToInstrument (table - validation + update target)
|- Trade.BatchInsertEventsToSbrInstrumentsUpdates (procedure - SBR event firing)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | FeatureID=124: gate - if 0, procedure refuses to run |
| Trade.InstrumentsIDListSetParamsTbl | User Defined Type | TVP type defining 8 risk parameter columns |
| Trade.ProviderToInstrument | Table | All-NULL validation and UPDATE target for 8 risk columns |
| Trade.BatchInsertEventsToSbrInstrumentsUpdates | Procedure | Called post-update to fire SBR events for changed instruments |

### 6.2 Objects That Depend On This

No dependents found - called by Ops API service.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Feature flag | Gate | FeatureID=124=0 -> RAISERROR + RETURN; allows disabling without code change |
| All-NULL validation | Validation | RAISERROR(60202) if all 8 params NULL for any instrument - prevents no-op updates |
| SERIALIZABLE isolation | Concurrency | Prevents phantom rows during batch update; highest isolation level |
| Atomic with SBR | Atomicity | SBR event INSERT and ProviderToInstrument UPDATE are in same transaction - both succeed or both rollback |
| Partial update | Logic | ISNULL(src, dest) for all 8 columns - NULL = keep existing |

---

## 8. Sample Queries

### 8.1 Update risk parameters for instruments

```sql
DECLARE @Params Trade.InstrumentsIDListSetParamsTbl
INSERT INTO @Params (InstrumentID, MaxStopLossPercentage, DefaultStopLossPercentage, AllowedRateDiffPercentage, AllowedRateDiffPercentageUpside)
VALUES
    (1234, 50.0, 10.0, 0.5, 0.5),
    (5678, 75.0, NULL, NULL, NULL)   -- Only MaxSL updated for 5678

EXEC Trade.SetInstrumentsDataForOpsAPI
    @Instruments_NewParams = @Params,
    @AppLoginName = 'ops_user@etoro.com'
```

### 8.2 Check feature flag status

```sql
SELECT FeatureID, Value,
    CASE CAST(Value AS INT) WHEN 1 THEN 'ENABLED' ELSE 'DISABLED' END AS Status
FROM Maintenance.Feature WITH (NOLOCK)
WHERE FeatureID = 124
```

### 8.3 Review current risk parameters for an instrument

```sql
SELECT InstrumentID, Leverage1MaintenanceMargin, MaxStopLossPercentage,
    DefaultStopLossPercentage, DefaultTakeProfitPercentage,
    AllowedRateDiffPercentage, AllowedRateDiffPercentageUpside,
    InitialMarginInAssetCurrency, StopLossMarginInAssetCurrency
FROM Trade.ProviderToInstrument WITH (NOLOCK)
WHERE InstrumentID = 1234
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SetInstrumentsDataForOpsAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SetInstrumentsDataForOpsAPI.sql*
