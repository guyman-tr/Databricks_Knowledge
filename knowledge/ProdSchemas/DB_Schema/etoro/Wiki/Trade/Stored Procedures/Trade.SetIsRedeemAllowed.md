# Trade.SetIsRedeemAllowed

> Toggles the global "redeem allowed" feature flag, updating both the feature configuration table and publishing a sync notification to the trading engine.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @IsRedeemAllowed (0 or 1) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure controls whether the "redeem" operation is globally enabled or disabled across the trading platform. Redeem allows real-stock position holders to redeem (take delivery of) their actual shares. When redeem is disabled, no customer can initiate a redeem operation regardless of their individual eligibility.

The procedure exists as a global kill-switch that operations teams can use to suspend all redeem activity - for example, during system maintenance, settlement processing windows, or regulatory events. It is granted to the TAPIUser (Trading API user), meaning it is exposed through the trading administrative API.

The procedure performs two writes in sequence: (1) updates the feature flag in Maintenance.Feature (FeatureID=52) to enable/disable at the feature-control level, and (2) inserts a sync record in Trade.SyncConfiguration with ConfigurationUpdateTypeID=40 (UPDATE_GENERAL_ALLOW_REDEEM) and InstrumentID=-999 (a sentinel meaning "all instruments / global"), so the trading engine's in-memory configuration is refreshed.

---

## 2. Business Logic

### 2.1 Two-Write Synchronization Pattern

**What**: The procedure must update two systems - the feature flag store and the trading engine sync queue - to ensure the change propagates to both persistent config and live runtime state.

**Columns/Parameters Involved**: `@IsRedeemAllowed`, `Maintenance.Feature.FeatureID=52`, `Trade.SyncConfiguration.ConfigurationUpdateTypeID=40`

**Rules**:
- Step 1: UPDATE Maintenance.Feature SET Value = @IsRedeemAllowed WHERE FeatureID = 52 (the "is redeem allowed" feature)
- Step 2: INSERT INTO Trade.SyncConfiguration with InstrumentID = -999 (global sentinel), ConfigurationUpdateTypeID = 40 (UPDATE_GENERAL_ALLOW_REDEEM), Value = @IsRedeemAllowed
- Both writes happen in the same TRY/CATCH block; if either fails, THROW propagates the exception
- The SyncConfiguration insert triggers the trading engine (SBR - presumably "Server-Based Routing" or sync bus) to reload its allow-redeem setting

**Diagram**:
```
@IsRedeemAllowed (0 or 1)
  |
  +--> UPDATE Maintenance.Feature WHERE FeatureID=52
  |        (persistent config store)
  |
  +--> INSERT Trade.SyncConfiguration
           InstrumentID = -999 (global)
           ConfigurationUpdateTypeID = 40 (UPDATE_GENERAL_ALLOW_REDEEM)
           Value = @IsRedeemAllowed
           (triggers trading engine config reload via SBR sync)
```

### 2.2 Input Validation

**What**: Rejects values other than 0 or 1 with an informative error message.

**Columns/Parameters Involved**: `@IsRedeemAllowed`

**Rules**:
- IF @IsRedeemAllowed IS NULL OR @IsRedeemAllowed > 1 OR @IsRedeemAllowed < 0 -> RAISERROR with message "The parameter IsRedeemAllowed can only get the values 1 or 0"
- Only values 0 (disabled) and 1 (enabled) are accepted - no intermediate states

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IsRedeemAllowed | TINYINT | NO | - | CODE-BACKED | The desired state for the global redeem feature: 1 = redeem is enabled (customers can initiate redeems), 0 = redeem is disabled (all redeem requests blocked). Any other value (NULL, >1, <0) raises an error. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeatureID = 52 | Maintenance.Feature | Modifier | Updates the Value column to @IsRedeemAllowed for the "is redeem allowed" feature flag row |
| InstrumentID = -999, ConfigurationUpdateTypeID = 40 | Trade.SyncConfiguration | Writer | Inserts a sync record to trigger trading engine config reload for the global redeem setting |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| TAPIUser (Trading API user) | - | EXECUTE permission | Granted execute on this procedure - exposed via Trading administrative API |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SetIsRedeemAllowed (procedure)
├── Maintenance.Feature (table) [updates FeatureID=52 value]
└── Trade.SyncConfiguration (table) [inserts ConfigurationUpdateTypeID=40 sync record]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | Updated: SET Value = @IsRedeemAllowed WHERE FeatureID = 52 |
| Trade.SyncConfiguration | Table | Inserted into with InstrumentID=-999 and ConfigurationUpdateTypeID=40 (UPDATE_GENERAL_ALLOW_REDEEM) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trading Administrative API (via TAPIUser) | External | Calls this procedure to toggle global redeem on/off |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @IsRedeemAllowed range check | Business validation | Only 0 or 1 accepted; NULL or out-of-range raises RAISERROR |
| FeatureID = 52 | Hardcoded constant | "Allow Redeem" feature identifier in Maintenance.Feature |
| ConfigurationUpdateTypeID = 40 | Hardcoded constant | "UPDATE_GENERAL_ALLOW_REDEEM" sync operation type (per inline code comment) |
| InstrumentID = -999 | Hardcoded sentinel | Represents a global (all-instruments) scope for the sync record |

---

## 8. Sample Queries

### 8.1 Enable redeem globally

```sql
EXEC Trade.SetIsRedeemAllowed @IsRedeemAllowed = 1;
```

### 8.2 Disable redeem globally

```sql
EXEC Trade.SetIsRedeemAllowed @IsRedeemAllowed = 0;
```

### 8.3 Check current redeem feature state

```sql
SELECT FeatureID, Value, Description
FROM Maintenance.Feature WITH (NOLOCK)
WHERE FeatureID = 52;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found in SP folder | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SetIsRedeemAllowed | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SetIsRedeemAllowed.sql*
