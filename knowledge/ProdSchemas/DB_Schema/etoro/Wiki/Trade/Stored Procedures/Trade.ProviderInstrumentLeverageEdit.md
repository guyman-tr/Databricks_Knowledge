# Trade.ProviderInstrumentLeverageEdit

> Edits an existing leverage tier for a provider-instrument pair by updating IsDefault and Percentage on Trade.ProviderInstrumentToLeverage, enforcing the single-default constraint across all tiers, and immediately queuing a default-leverage sync event to downstream consumers.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ProviderID + @InstrumentID + @LeverageID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ProviderInstrumentLeverageEdit modifies an existing leverage tier for a specific provider-instrument pair. It updates two attributes: IsDefault (whether this leverage is the default when a customer opens a position) and Percentage (the spread or fee percentage associated with this leverage tier). When IsDefault is set to 1, it simultaneously clears IsDefault=0 on all sibling rows for the same provider+instrument pair, enforcing a single-default constraint. After the update, it queues a ConfigType=3 (default leverage) sync event to Trade.SyncConfiguration via Trade.SyncConfigurationAdd.

This procedure exists to manage the lifecycle of leverage tiers in the trading configuration system. Leverages are the multipliers customers can choose when opening positions (e.g., x2, x5, x10). Each instrument may have several leverage tiers available, and one must be designated as the default. When the default changes, the trading engine and UI must be notified via the sync queue so that new sessions present the correct default leverage. The Percentage field controls spread adjustments per leverage tier.

Data flow: Called by leverage management tools in back-office. Companion to Trade.ProviderInstrumentLeverageAdd (creates new tiers) and Trade.ProviderInstrumentLeverageDelete (removes tiers). After editing, Trade.SyncConfigurationAdd queues ConfigType=3 with the default leverage value. Trade.SyncLeveragesList (batch item #17) queues BOTH ConfigType=2 (full list) and ConfigType=3 (default) - LeverageEdit only queues the default.

---

## 2. Business Logic

### 2.1 Single-Default Enforcement

**What**: Only one leverage tier per provider-instrument pair can be the default at any time.

**Columns/Parameters Involved**: `IsDefault`, `@IsDefault`

**Rules**:
- Main UPDATE: Sets IsDefault=@IsDefault and Percentage=@Percentage WHERE ProviderID=@ProviderID AND InstrumentID=@InstrumentID AND LeverageID=@LeverageID.
- Secondary UPDATE (conditional): IF @IsDefault = 1 -> UPDATE ProviderInstrumentToLeverage SET IsDefault=0 WHERE ProviderID=@ProviderID AND InstrumentID=@InstrumentID AND LeverageID != @LeverageID.
- This guarantees that setting one tier as default automatically demotes all sibling tiers.
- If @IsDefault=0, the secondary UPDATE is skipped - multiple non-default tiers can coexist.
- Note: There is no guard against setting ALL tiers to IsDefault=0 (caller's responsibility).

### 2.2 Default Leverage Sync

**What**: After editing, queues the current default leverage value to downstream sync consumers.

**Columns/Parameters Involved**: `ConfigurationUpdateTypeID=3`, `@LeverageValue`

**Rules**:
- Reads the Dictionary.Leverage.Value for the edited LeverageID (the integer multiplier, e.g., 5 for x5).
- Calls Trade.SyncConfigurationAdd(@InstrumentID, 3, CAST(@LeverageValue AS VARCHAR)).
- ConfigType=3 = default leverage. ConfigType=2 (full leverages list) is NOT queued by this procedure - use Trade.SyncLeveragesList for that.
- Only syncs the default leverage, not the full list. This is intentional - editing a non-default tier (IsDefault=0) still syncs the default because the default may have changed.

**Diagram**:
```
Trade.ProviderInstrumentLeverageEdit(@ProviderID, @InstrumentID, @LeverageID, @IsDefault, @Percentage)
    |
    v
UPDATE ProviderInstrumentToLeverage SET IsDefault=@IsDefault, Percentage=@Percentage WHERE PK
    |
    v
IF @IsDefault = 1:
    UPDATE ProviderInstrumentToLeverage SET IsDefault=0 WHERE ProviderID+InstrumentID AND LeverageID != @LeverageID
    |
    v
GET @LeverageValue = Dictionary.Leverage.Value WHERE LeverageID=@LeverageID
    |
    v
EXEC Trade.SyncConfigurationAdd(@InstrumentID, 3, @LeverageValue)  -- default leverage sync
    |
    v
COMMIT / RETURN 0 or RAISERROR 60000
```

### 2.3 Transaction and Error Handling

**What**: Wraps updates in a transaction with TRY/CATCH and standardized error codes.

**Rules**:
- BEGIN TRANSACTION / COMMIT TRANSACTION wraps the full operation.
- On error: ROLLBACK, RAISERROR with severity/state, RETURN 60000 (standard Trade error code).
- RETURN 0 on success.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderID | INTEGER | NO | - | CODE-BACKED | Execution provider identifier. Combined with @InstrumentID + @LeverageID to uniquely identify the row in Trade.ProviderInstrumentToLeverage. |
| 2 | @InstrumentID | INTEGER | NO | - | CODE-BACKED | Instrument identifier. Used in the PK filter and as the InstrumentID for Trade.SyncConfigurationAdd. |
| 3 | @LeverageID | INTEGER | NO | - | CODE-BACKED | The specific leverage tier to edit. FK to Dictionary.Leverage. Used to resolve the integer multiplier value for the sync event. |
| 4 | @IsDefault | BIT | NO | - | CODE-BACKED | Whether this leverage tier becomes the default for new positions. 1=set as default (clears all siblings). 0=non-default (siblings unchanged). |
| 5 | @Percentage | INTEGER | NO | - | CODE-BACKED | Spread/fee percentage associated with this leverage tier. Stored directly in ProviderInstrumentToLeverage.Percentage. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProviderID + @InstrumentID + @LeverageID | Trade.ProviderInstrumentToLeverage | Modifier (UPDATE) | Updates IsDefault and Percentage on the target leverage tier. Also clears IsDefault=0 on sibling tiers if @IsDefault=1. |
| @LeverageID | Dictionary.Leverage | Reader (SELECT) | Resolves LeverageID to integer Value for the sync event payload. |
| (call) | Trade.SyncConfigurationAdd | Callee | Called once with ConfigType=3 and the default leverage integer value to notify downstream consumers. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Back-office leverage management tools | - | Caller | Called when an operator edits a leverage tier's default flag or percentage in the admin console. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ProviderInstrumentLeverageEdit (procedure)
├── Trade.ProviderInstrumentToLeverage (table)
├── Dictionary.Leverage (table)
└── Trade.SyncConfigurationAdd (procedure)
      └── Trade.SyncConfiguration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderInstrumentToLeverage | Table | UPDATE target: sets IsDefault and Percentage on the PK row; clears IsDefault on siblings when @IsDefault=1. |
| Dictionary.Leverage | Table | SELECT Value WHERE LeverageID=@LeverageID to get the integer multiplier for the sync event. |
| Trade.SyncConfigurationAdd | Procedure | Called once to queue ConfigType=3 (default leverage value) to Trade.SyncConfiguration. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Back-office leverage management | External callers | Calls this when editing leverage tier configuration. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Note: Unlike Trade.SyncLeveragesList which queues BOTH ConfigType=2 (full list) and ConfigType=3 (default), this procedure only queues ConfigType=3. If callers need to sync the full leverage list after an edit, they must additionally call Trade.SyncLeveragesList.

---

## 8. Sample Queries

### 8.1 Set leverage x5 as default for provider 1, instrument 1 (assuming LeverageID=5 maps to x5)

```sql
EXEC Trade.ProviderInstrumentLeverageEdit
    @ProviderID = 1,
    @InstrumentID = 1,
    @LeverageID = 5,
    @IsDefault = 1,
    @Percentage = 0;
-- Updates IsDefault=1 on LeverageID=5, clears IsDefault on all siblings
-- Queues ConfigType=3 (default leverage=5) to Trade.SyncConfiguration
```

### 8.2 Update percentage on non-default tier

```sql
EXEC Trade.ProviderInstrumentLeverageEdit
    @ProviderID = 1,
    @InstrumentID = 1,
    @LeverageID = 10,
    @IsDefault = 0,
    @Percentage = 5;
-- Updates Percentage=5 on LeverageID=10, does NOT clear siblings
-- Still queues ConfigType=3 sync
```

### 8.3 View current leverage configuration for an instrument

```sql
SELECT TPI.LeverageID, DL.Value AS Multiplier, TPI.IsDefault, TPI.Percentage
FROM Trade.ProviderInstrumentToLeverage TPI WITH (NOLOCK)
JOIN Dictionary.Leverage DL WITH (NOLOCK) ON TPI.LeverageID = DL.LeverageID
WHERE TPI.ProviderID = 1 AND TPI.InstrumentID = 1
ORDER BY DL.Value;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ProviderInstrumentLeverageEdit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ProviderInstrumentLeverageEdit.sql*
