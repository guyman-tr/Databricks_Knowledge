# Dictionary.ConfigurationUpdateType

> Lookup table defining the 29 types of instrument configuration changes — covering leverage, fees, position limits, visibility, SL/TP settings, and redemption rules — tracked by the instrument sync and audit system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ConfigurationUpdateTypeID (int, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Dictionary.ConfigurationUpdateType classifies the types of configuration changes that can be made to trading instruments. When an administrator updates an instrument's settings (leverage, fees, position limits, visibility, etc.), the change is logged with a ConfigurationUpdateTypeID so that audit trails and sync systems can identify exactly what was modified.

This is a heavily referenced table — consumed by more than 15 stored procedures across the Trade schema. Major consumers include `Trade.UpdateInstrumentsTradingConfigurations`, `Trade.UpdateInstrumentsMaxPositionUnits`, `Trade.UpdateInstrumentsMinPositionAmount`, and `Trade.SyncConfigurationAdd`. The `Trade.SyncConfiguration` table stores pending configuration changes with this type ID, enabling a publish-subscribe pattern where configuration changes are queued and then applied by the trading engine.

The table covers the full range of tradeable instrument settings: from basic parameters (leverage, unit margin, fees) through trading controls (allow buy/sell, tradeable flag) to advanced settings (redeem eligibility, SL/TP defaults, guaranteed SL/TP).

---

## 2. Business Logic

### 2.1 Configuration Change Categories

**What**: Five functional categories of instrument configuration updates.

**Columns/Parameters Involved**: `ConfigurationUpdateTypeID`, `Name`

**Rules**:
- **Pricing & Margins (IDs 1, 4-6)**: UnitMargin, MaxPositionUnits, FeeValues, MinPositionAmount — fundamental pricing and size parameters that determine trading economics.
- **Leverage (IDs 2-3, 46-47)**: Leverages, DefaultLeverage, DefaultStopLossPercentageLeveraged/NonLeveraged — leverage multipliers and associated default risk controls.
- **Trading Controls (IDs 10-14, 19-20)**: AllowBuy, AllowSell, AllowPendingOrders, AllowEntryOrders, IsTradable, AllowClosePosition, AllowExitOrders — binary flags that enable/disable specific trading operations per instrument.
- **Visibility & Display (IDs 15-18)**: IsVisible, IsVisibleInternallyOnly, DisplayName, IndustryID — controls whether instruments appear in the platform UI and how they are categorized.
- **SL/TP & Redemption (IDs 7-8, 21-27)**: MaxStopLoss, MaxRateDiff, MaxTakeProfit, GuaranteeSLTP, AllowEditSLTP, GeneralAllowRedeem, AllowRedeem, MinPositionUnitsForRedeem, MaxPositionUnitsForRedeem — risk management and CopyTrading redemption settings.

---

## 3. Data Overview

| ConfigurationUpdateTypeID | Name | Meaning |
|---|---|---|
| 1 | Update_UnitMargin | Change to the margin required per unit of the instrument — directly affects how much capital is locked per position. Core pricing parameter. |
| 5 | Update_FeeValues | Change to spread, overnight, or transaction fees for the instrument — impacts trading costs for customers. Processed by `Trade.UpdateInstrumentToFeeConfigurations_TRDOPS`. |
| 14 | Update_IsTradble | Toggle whether the instrument is tradeable — setting to false effectively suspends all trading on that instrument. Used during delistings, corporate actions, or market emergencies. |
| 24 | Update_GeneralAllowRedeem | Toggle whether CopyTrading redemption is globally allowed for this instrument — controls whether copy-trade positions can be partially redeemed. |
| 46 | Update_DefaultStopLossPercentageLeveraged | Change to the default stop-loss percentage for leveraged positions — the pre-filled SL value shown to customers trading with leverage. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ConfigurationUpdateTypeID | int | NO | - | VERIFIED | Primary key identifying the configuration change type. Values 1-47 (non-contiguous — gaps between 27 and 46). Referenced by `Trade.SyncConfiguration.ConfigurationUpdateTypeID` and numerous Trade update procedures. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | PascalCase name of the configuration change using `Update_` prefix convention (e.g., 'Update_Leverages', 'Update_FeeValues', 'Update_IsTradble'). Used as a programmatic key in sync systems and audit logs. Read by `Trade.GetInstrumentConfigurationUpdate` and `Trade.BatchInsertEventsToSbrInstrumentsUpdates` for event classification. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SyncConfiguration | ConfigurationUpdateTypeID | Implicit FK | Queued configuration changes reference this type to identify what setting was modified |
| Trade.UpdateInstrumentsTradingConfigurations | Read | Procedure | Reads type IDs when processing trading config updates |
| Trade.UpdateInstrumentsMaxPositionUnits | Read | Procedure | References type ID for max position unit changes |
| Trade.UpdateInstrumentsMinPositionAmount | Read | Procedure | References type ID for min position amount changes |
| Trade.SyncConfigurationAdd | Read | Procedure | Inserts sync records with configuration update type |
| Trade.DelistStock | Read | Procedure | Uses multiple type IDs when delisting instruments |
| Trade.BatchInsertEventsToSbrInstrumentsUpdates | Read | Procedure | Publishes SBR events classified by update type |
| Trade.GetInstrumentConfigurationUpdate | Read | Procedure | Retrieves config updates by type for processing |
| dbo.P_UpdateUnitMargin | Read | Procedure | Legacy procedure for unit margin updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.SyncConfiguration | Table | Stores pending config changes by type |
| Trade.UpdateInstrumentsTradingConfigurations | Procedure | Processes trading config updates |
| Trade.SyncConfigurationAdd | Procedure | Creates sync records |
| Trade.DelistStock | Procedure | Uses during instrument delisting |
| Trade.BatchInsertEventsToSbrInstrumentsUpdates | Procedure | Event classification |
| Trade.GetInstrumentConfigurationUpdate | Procedure | Retrieves updates by type |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DCUPT | CLUSTERED PK | ConfigurationUpdateTypeID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all configuration update types
```sql
SELECT  ConfigurationUpdateTypeID,
        Name
FROM    Dictionary.ConfigurationUpdateType WITH (NOLOCK)
ORDER BY ConfigurationUpdateTypeID;
```

### 8.2 Find trading control update types
```sql
SELECT  ConfigurationUpdateTypeID,
        Name
FROM    Dictionary.ConfigurationUpdateType WITH (NOLOCK)
WHERE   Name LIKE '%Allow%'
     OR Name LIKE '%Tradble%'
ORDER BY ConfigurationUpdateTypeID;
```

### 8.3 Show pending sync records with resolved update type names
```sql
SELECT  SC.ConfigurationUpdateTypeID,
        CUT.Name AS UpdateType,
        SC.*
FROM    Trade.SyncConfiguration SC WITH (NOLOCK)
INNER JOIN Dictionary.ConfigurationUpdateType CUT WITH (NOLOCK)
        ON CUT.ConfigurationUpdateTypeID = SC.ConfigurationUpdateTypeID
ORDER BY SC.ConfigurationUpdateTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ConfigurationUpdateType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ConfigurationUpdateType.sql*
