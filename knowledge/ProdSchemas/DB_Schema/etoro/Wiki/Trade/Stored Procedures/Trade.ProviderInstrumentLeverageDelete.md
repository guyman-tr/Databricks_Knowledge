# Trade.ProviderInstrumentLeverageDelete

> Removes a leverage tier for a provider-instrument pair from Trade.ProviderInstrumentToLeverage, blocks deletion of the default tier with error code 60025, and queues the updated full leverages list and default leverage sync events via Trade.SyncLeveragesList.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ProviderID + @InstrumentID + @LeverageID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ProviderInstrumentLeverageDelete removes a leverage tier option from the set available to customers for a given provider-instrument pair. For example, if x2, x5, and x10 are available, this procedure removes x2, leaving only x5 and x10. A critical business guard prevents deleting the default tier: if the target row has IsDefault=1, the procedure raises error 60025 ("Cannot remove link marked as default") and rolls back. This forces operators to assign a new default before removing the current one, preventing a state where an instrument has no default leverage.

After deletion, Trade.SyncLeveragesList is called to queue both ConfigType=2 (updated full list without the removed tier) and ConfigType=3 (unchanged default) to Trade.SyncConfiguration, notifying the trading engine and UI.

Data flow: Called by back-office leverage management tools. Deletes one row from Trade.ProviderInstrumentToLeverage using OUTPUT to capture the IsDefault flag for the guard check. If the deleted row was default, RAISERROR(60025) triggers the CATCH block which rolls back. Error handling uses THROW (re-raises original exception) in the CATCH - unlike ProviderInstrumentLeverageAdd which uses RAISERROR(60000).

---

## 2. Business Logic

### 2.1 Delete with Output-Based Default Guard

**What**: Deletes the row but captures the IsDefault flag to enforce the no-delete-if-default rule.

**Columns/Parameters Involved**: `IsDefault`, `@Info` (table variable)

**Rules**:
- DELETE FROM ProviderInstrumentToLeverage ... OUTPUT DELETED.IsDefault INTO @Info(IsDefault BIT).
- The DELETE happens FIRST, then the guard check runs.
- IF EXISTS(SELECT * FROM @Info WHERE IsDefault = 1): RAISERROR(60025,16,1,'Cannot remove link marked as default').
- Error 60025 fires inside the TRY block, triggering the CATCH which rolls back the transaction (undoing the delete).
- This OUTPUT-then-check pattern means the row is tentatively deleted and only rolled back if it was default - a common SQL Server pattern when OUTPUT with a guard check is needed.
- If the row doesn't exist (PK not found), DELETE succeeds with 0 rows affected; @Info will be empty; guard check passes; SyncLeveragesList is called with no effect.

### 2.2 Full Sync After Delete

**What**: Queues both ConfigType=2 (list) and ConfigType=3 (default) via SyncLeveragesList after deletion.

**Rules**:
- EXECUTE Trade.SyncLeveragesList @ProviderID, @InstrumentID.
- The sync list will reflect the remaining tiers after the deletion (the deleted tier is already gone from ProviderInstrumentToLeverage).
- Both list and default events are queued - same as Add. Delete changes the available options set, so the full list must be re-synced.

**Diagram**:
```
Trade.ProviderInstrumentLeverageDelete(@ProviderID, @InstrumentID, @LeverageID)
    |
    v
DELETE FROM ProviderInstrumentToLeverage WHERE PK
OUTPUT DELETED.IsDefault INTO @Info
    |
    v
IF @Info.IsDefault = 1:
    RAISERROR(60025) -> CATCH -> ROLLBACK -> THROW
    |
    v (if not default)
EXEC Trade.SyncLeveragesList(@ProviderID, @InstrumentID)
    |- SyncConfigurationAdd(@InstrumentID, 2, "1, 2, 5")  -- list without removed tier
    \- SyncConfigurationAdd(@InstrumentID, 3, "5")  -- unchanged default
    |
    v
COMMIT / RETURN 0
```

### 2.3 Error Handling: THROW in CATCH

**What**: Uses THROW (not RAISERROR 60000) for error propagation, unlike ProviderInstrumentLeverageAdd.

**Rules**:
- CATCH block: `SET @LocalError = ERROR_NUMBER(); THROW`.
- THROW re-raises the original exception (including the 60025 from the guard check).
- The caller receives the original error number and message, not the generic 60000 wrapper.
- No explicit RETURN in CATCH - THROW always terminates execution.
- This is inconsistent with ProviderInstrumentLeverageAdd (uses RAISERROR 60000 + RETURN 60000) but consistent with ProviderToInstrumentSetMimPositionAmount.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderID | INTEGER | NO | - | CODE-BACKED | Execution provider identifier. Part of the PK identifying the leverage tier to delete. |
| 2 | @InstrumentID | INTEGER | NO | - | CODE-BACKED | Instrument identifier. Part of the PK, and passed to Trade.SyncLeveragesList for sync scoping. |
| 3 | @LeverageID | INTEGER | NO | - | CODE-BACKED | FK to Dictionary.Leverage. Identifies the specific leverage tier to remove (e.g., LeverageID=2 -> x2 leverage). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProviderID + @InstrumentID + @LeverageID | Trade.ProviderInstrumentToLeverage | Modifier (DELETE) | Removes the leverage tier row; captures IsDefault via OUTPUT for default guard. |
| (call) | Trade.SyncLeveragesList | Callee | Called after deletion to queue both ConfigType=2 (updated list) and ConfigType=3 (default) sync events. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Back-office leverage management tools | - | Caller | Called when operators remove a leverage tier from an instrument's available options. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ProviderInstrumentLeverageDelete (procedure)
├── Trade.ProviderInstrumentToLeverage (table)
└── Trade.SyncLeveragesList (procedure)
      ├── Trade.ProviderInstrumentToLeverage (table)
      ├── Dictionary.Leverage (table)
      └── Trade.SyncConfigurationAdd (procedure)
            └── Trade.SyncConfiguration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderInstrumentToLeverage | Table | DELETE target; OUTPUT captures IsDefault for the guard check. |
| Trade.SyncLeveragesList | Procedure | Called after deletion to propagate updated list and default sync events. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Back-office leverage management | External callers | Calls this to remove a leverage option from an instrument. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Error code reference**:
- 60025: "Cannot remove link marked as default" - raised when attempting to delete a leverage tier that is currently the default. Callers must first designate another tier as default via Trade.ProviderInstrumentLeverageEdit (@IsDefault=1) before deleting the current default.
- Contrast with 60000: generic Trade schema error code used by Add/Edit; Delete uses THROW to propagate specific error codes.

**Lifecycle summary for leverage tiers**:
- Create: Trade.ProviderInstrumentLeverageAdd (INSERT + SyncLeveragesList)
- Edit: Trade.ProviderInstrumentLeverageEdit (UPDATE IsDefault/Percentage + SyncConfigurationAdd ConfigType=3)
- Delete: Trade.ProviderInstrumentLeverageDelete (DELETE + guard + SyncLeveragesList)
- Sync full: Trade.SyncLeveragesList (ConfigType=2 + ConfigType=3)

---

## 8. Sample Queries

### 8.1 Delete non-default leverage tier (x2) for provider 1, instrument 1

```sql
EXEC Trade.ProviderInstrumentLeverageDelete
    @ProviderID = 1,
    @InstrumentID = 1,
    @LeverageID = 2;    -- FK to Dictionary.Leverage; x2 multiplier
-- Deletes the tier; queues updated list (e.g., "5, 10") and default sync events
```

### 8.2 Attempt to delete the default tier (will fail with error 60025)

```sql
-- First: find the current default
SELECT LeverageID, IsDefault, DL.Value AS Multiplier
FROM Trade.ProviderInstrumentToLeverage TPI WITH (NOLOCK)
JOIN Dictionary.Leverage DL WITH (NOLOCK) ON TPI.LeverageID = DL.LeverageID
WHERE TPI.ProviderID = 1 AND TPI.InstrumentID = 1 AND TPI.IsDefault = 1;

-- Then: try to delete it (will raise error 60025)
EXEC Trade.ProviderInstrumentLeverageDelete
    @ProviderID = 1,
    @InstrumentID = 1,
    @LeverageID = 5;    -- if x5 is the default
-- ERROR: Msg 60025 - Cannot remove link marked as default
```

### 8.3 Safe delete flow: reassign default first, then delete old default

```sql
-- Step 1: Set x10 as new default
EXEC Trade.ProviderInstrumentLeverageEdit @ProviderID=1, @InstrumentID=1, @LeverageID=10, @IsDefault=1, @Percentage=0;

-- Step 2: Now x5 (old default) can be deleted
EXEC Trade.ProviderInstrumentLeverageDelete @ProviderID=1, @InstrumentID=1, @LeverageID=5;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ProviderInstrumentLeverageDelete | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ProviderInstrumentLeverageDelete.sql*
