# Trade.ProviderInstrumentLeverageAdd

> Adds a new leverage tier for a provider-instrument pair to Trade.ProviderInstrumentToLeverage, enforces the single-default constraint, and queues BOTH the full leverages list and the default leverage sync events via Trade.SyncLeveragesList.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ProviderID + @InstrumentID + @LeverageID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ProviderInstrumentLeverageAdd inserts a new leverage tier into the Trade.ProviderInstrumentToLeverage table, making an additional leverage option available to customers trading a specific instrument through a specific execution provider. For example, if instrument 1 currently offers x2 and x5, this procedure adds x10 as a new option. If the new tier is designated as default (@IsDefault=1), it clears the default flag on all existing tiers. After the insert, it calls Trade.SyncLeveragesList to queue BOTH sync events: ConfigType=2 (the full sorted leverages list) and ConfigType=3 (the current default leverage).

This procedure exists as the creation step in the leverage tier lifecycle, alongside Trade.ProviderInstrumentLeverageEdit (modify) and Trade.ProviderInstrumentLeverageDelete (remove). The full sync (both list and default) via SyncLeveragesList is essential after adding a tier because the downstream trading system needs the updated available-options list, not just the default. This distinguishes Add from Edit (which only syncs the default).

Data flow: Called by back-office leverage management tools. Inserts one row into Trade.ProviderInstrumentToLeverage. If @IsDefault=1, bulk-updates sibling rows. Calls Trade.SyncLeveragesList which calls Trade.SyncConfigurationAdd twice (ConfigType=2 and ConfigType=3) within a nested transaction. Both operations commit as a single unit.

---

## 2. Business Logic

### 2.1 Insert and Single-Default Enforcement

**What**: Inserts the new leverage tier and ensures only one tier is the default.

**Columns/Parameters Involved**: `ProviderID`, `InstrumentID`, `LeverageID`, `IsDefault`, `Percentage`

**Rules**:
- INSERT INTO Trade.ProviderInstrumentToLeverage all 5 columns from parameters.
- IF @IsDefault = 1: UPDATE ProviderInstrumentToLeverage SET IsDefault=0 WHERE ProviderID=@ProviderID AND InstrumentID=@InstrumentID AND LeverageID != @LeverageID.
- This clears all existing defaults, leaving only the newly inserted row as default.
- If @IsDefault=0: siblings are untouched; multiple non-default tiers remain valid.
- Note: Inserting a duplicate PK (ProviderID+InstrumentID+LeverageID) will fail with a constraint violation caught by the TRY/CATCH.

### 2.2 Full Sync vs. Default-Only Sync

**What**: Add queues a two-event sync (list + default) via SyncLeveragesList, unlike Edit which only queues the default.

**Columns/Parameters Involved**: ConfigurationUpdateTypeID=2 (list), ConfigurationUpdateTypeID=3 (default)

**Rules**:
- EXECUTE Trade.SyncLeveragesList @ProviderID, @InstrumentID.
- SyncLeveragesList internally calls SyncConfigurationAdd twice: once for ConfigType=2 (full sorted CSV list of all leverage values), once for ConfigType=3 (the default leverage value).
- The full list sync is necessary because the new tier changes the set of available options, not just the default.
- Trade.ProviderInstrumentLeverageEdit calls SyncConfigurationAdd directly for ConfigType=3 only (not SyncLeveragesList) because editing does not add/remove options.

**Diagram**:
```
Trade.ProviderInstrumentLeverageAdd(@ProviderID, @InstrumentID, @LeverageID, @IsDefault, @Percentage)
    |
    v
INSERT INTO Trade.ProviderInstrumentToLeverage (all 5 columns)
    |
    v
IF @IsDefault = 1:
    UPDATE ProviderInstrumentToLeverage SET IsDefault=0 WHERE ProviderID+InstrumentID AND LeverageID != @LeverageID
    |
    v
EXEC Trade.SyncLeveragesList(@ProviderID, @InstrumentID)
    |- SyncConfigurationAdd(@InstrumentID, 2, "1, 2, 5, 10")  -- full list with new tier
    \- SyncConfigurationAdd(@InstrumentID, 3, "5")  -- default leverage
    |
    v
COMMIT / RETURN 0 or RAISERROR 60000
```

### 2.3 Transaction and Error Handling

**What**: Full transaction with TRY/CATCH and RAISERROR-based error code.

**Rules**:
- BEGIN TRANSACTION / COMMIT TRANSACTION wraps insert, default-clear, and SyncLeveragesList call.
- On error: ROLLBACK (or COMMIT TRAN if @@TRANCOUNT != 1 due to nested transactions), RAISERROR(60000,16,1), RETURN 60000.
- RETURN 0 on success.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderID | INTEGER | NO | - | CODE-BACKED | Execution provider identifier. Part of the PK for the new ProviderInstrumentToLeverage row. |
| 2 | @InstrumentID | INTEGER | NO | - | CODE-BACKED | Instrument identifier. Part of the PK for the new row, and passed to Trade.SyncLeveragesList for sync event scoping. |
| 3 | @LeverageID | INTEGER | NO | - | CODE-BACKED | FK to Dictionary.Leverage. Identifies the leverage multiplier tier being added (e.g., LeverageID=5 -> x5 leverage). |
| 4 | @IsDefault | BIT | NO | - | CODE-BACKED | Whether the new tier is the default leverage for this provider-instrument. 1=set as default (clears siblings). 0=add as non-default. |
| 5 | @Percentage | INTEGER | NO | - | CODE-BACKED | Spread/fee percentage for this leverage tier. Stored directly in ProviderInstrumentToLeverage.Percentage. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProviderID + @InstrumentID + @LeverageID | Trade.ProviderInstrumentToLeverage | Writer (INSERT) | Inserts the new leverage tier row. Also UPDATE sibling rows to clear IsDefault when @IsDefault=1. |
| (call) | Trade.SyncLeveragesList | Callee | Called to queue both ConfigType=2 (full list) and ConfigType=3 (default) sync events after the insert. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Back-office leverage management tools | - | Caller | Called when operators add a new leverage tier to an instrument's available options. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ProviderInstrumentLeverageAdd (procedure)
├── Trade.ProviderInstrumentToLeverage (table)
└── Trade.SyncLeveragesList (procedure)
      ├── Trade.ProviderInstrumentToLeverage (table) [re-read for sync list]
      ├── Dictionary.Leverage (table)
      └── Trade.SyncConfigurationAdd (procedure)
            └── Trade.SyncConfiguration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderInstrumentToLeverage | Table | INSERT new leverage tier; UPDATE siblings IsDefault=0 when @IsDefault=1. |
| Trade.SyncLeveragesList | Procedure | Called after INSERT to propagate both sync events (ConfigType=2 and ConfigType=3). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Back-office leverage management | External callers | Calls this when adding new leverage options for instruments. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Sibling comparison**: Add vs. Edit vs. Delete
| Aspect | ProviderInstrumentLeverageAdd | ProviderInstrumentLeverageEdit | ProviderInstrumentLeverageDelete |
|--------|------------------------------|-------------------------------|----------------------------------|
| Sync scope | Full (list + default) via SyncLeveragesList | Default only (ConfigType=3) via SyncConfigurationAdd | Full (list + default) via SyncLeveragesList |
| Error handling | RAISERROR + RETURN 60000 | RAISERROR + RETURN 60000 | THROW (re-raises original) |
| Default guard | Clears siblings | Clears siblings | Blocks delete of default row |

---

## 8. Sample Queries

### 8.1 Add x10 leverage as non-default for provider 1, instrument 1

```sql
EXEC Trade.ProviderInstrumentLeverageAdd
    @ProviderID = 1,
    @InstrumentID = 1,
    @LeverageID = 10,    -- FK to Dictionary.Leverage; x10
    @IsDefault = 0,
    @Percentage = 0;
-- Inserts row; queues ConfigType=2 (new list "1, 2, 5, 10") and ConfigType=3 (unchanged default)
```

### 8.2 Add x20 leverage and make it the default

```sql
EXEC Trade.ProviderInstrumentLeverageAdd
    @ProviderID = 1,
    @InstrumentID = 1,
    @LeverageID = 20,
    @IsDefault = 1,
    @Percentage = 0;
-- Inserts row with IsDefault=1; clears IsDefault on all siblings; queues full sync
```

### 8.3 View leverage dictionary to find LeverageID for a multiplier

```sql
SELECT LeverageID, Value AS Multiplier
FROM Dictionary.Leverage WITH (NOLOCK)
ORDER BY Value;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ProviderInstrumentLeverageAdd | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ProviderInstrumentLeverageAdd.sql*
