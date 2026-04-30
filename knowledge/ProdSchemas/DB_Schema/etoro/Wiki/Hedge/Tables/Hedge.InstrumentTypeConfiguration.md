# Hedge.InstrumentTypeConfiguration

> Configuration table defining the default hedge server assignment for each instrument type (asset class), enabling the hedge engine to route orders to a type-appropriate server when no more specific server assignment exists.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | InstrumentTypeID (int, FK to Dictionary.CurrencyType, PK CLUSTERED) |
| **Partition** | No (on [PRIMARY] filegroup, FILLFACTOR=95) |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

`Hedge.InstrumentTypeConfiguration` maps each instrument type (asset class) to a default hedge server. The design intent is to provide a type-level fallback routing rule: when the hedge engine needs to assign a hedge server for an instrument and no more specific per-instrument or per-group configuration exists, it can look up the instrument's asset class (via `Dictionary.CurrencyType`) and find the default server configured here.

This table is referenced by `Hedge.GetDefaultHedgeServers`, which returns both the type-to-server mapping and a feature flag from `Maintenance.Feature` (FeatureID=102). The feature flag connection suggests the type-based default routing capability is controlled by a feature toggle - it can be enabled or disabled at the platform level.

**Current state**: The table has 0 rows (both current and history tables are empty). The designed routing logic has either never been activated or was previously active with data that has since been fully removed. The table and its consuming procedure remain in the schema, suggesting the capability may be reactivated.

---

## 2. Business Logic

### 2.1 Asset Class Default Server Routing

**What**: Maps each `Dictionary.CurrencyType` (Forex, Stocks, Crypto, etc.) to a `Trade.HedgeServer`, providing a type-level fallback for hedge server assignment.

**Columns/Parameters Involved**: `InstrumentTypeID`, `DefaultHedgeServerID`

**Rules**:
- `InstrumentTypeID` references `Dictionary.CurrencyType.CurrencyTypeID` - each row covers one asset class (1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto)
- `DefaultHedgeServerID` references `Trade.HedgeServer.HedgeServerID` - the hedge server to which all instruments of this type default
- PK on InstrumentTypeID: one default server per asset class, no duplicates
- This provides coarser routing granularity than `Hedge.InstrumentConfiguration` (per-instrument) or `Hedge.InstrumentGroupsMapping` (per-group)

### 2.2 Feature Flag Integration

**What**: `Hedge.GetDefaultHedgeServers` returns this table's data alongside a feature flag from `Maintenance.Feature` (FeatureID=102), indicating the routing behavior is conditionally active.

**Columns/Parameters Involved**: `InstrumentTypeID`, `DefaultHedgeServerID`

**Rules**:
- The hedge engine reads both the type-server mapping AND feature flag FeatureID=102 from `Maintenance.Feature` in a single procedure call
- If the feature flag is disabled, the type-based defaults may be ignored by the engine even if rows exist in this table
- Table currently empty (0 rows in current and history tables) - feature has no active assignments

---

## 3. Data Overview

| InstrumentTypeID | DefaultHedgeServerID | Meaning |
|---|---|---|
| (no rows) | (no rows) | Table is currently empty - no default hedge server assignments by instrument type are configured |

The table has 0 current rows and 0 historical rows, indicating this routing feature has never been used in this environment or all assignments have been deleted.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentTypeID | int | NO | - | VERIFIED | Primary key. FK to Dictionary.CurrencyType(CurrencyTypeID). Identifies the asset class being configured: 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. One row per asset class maximum. |
| 2 | DefaultHedgeServerID | int | NO | - | VERIFIED | FK to Trade.HedgeServer(HedgeServerID). The hedge server to which instruments of this type default when no more specific assignment exists. |
| 3 | DbLoginName | varchar(computed) | YES | suser_name() | CODE-BACKED | Computed audit column. SQL Server login executing the DML. |
| 4 | AppLoginName | varchar(computed) | YES | context_info() | CODE-BACKED | Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. |
| 5 | SysStartTime | datetime2(7) | NO | getutcdate() | VERIFIED | Temporal period start. UTC timestamp when this row version became active. |
| 6 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | VERIFIED | Temporal period end. 9999-12-31 for current rows. History in History.HedgeInstrumentTypeConfiguration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentTypeID | Dictionary.CurrencyType | FK (FK_HedgeInstrumentTypeConfiguration_InstrumentTypeID) | Each row configures the default server for one asset class defined in Dictionary.CurrencyType |
| DefaultHedgeServerID | Trade.HedgeServer | FK (FK_HedgeInstrumentTypeConfiguration_DefaultHedgeServerID) | The configured default hedge server must exist in Trade.HedgeServer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetDefaultHedgeServers | (table ref) | READER | SELECTs InstrumentTypeID + DefaultHedgeServerID; returns type-to-server mapping alongside Maintenance.Feature FeatureID=102 flag |
| History.HedgeInstrumentTypeConfiguration | (temporal) | Temporal History | Stores historical row versions via SYSTEM_VERSIONING |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.InstrumentTypeConfiguration (table)
  ├── Dictionary.CurrencyType (table) [FK - InstrumentTypeID]
  └── Trade.HedgeServer (table) [FK - DefaultHedgeServerID]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CurrencyType | Table | FK_HedgeInstrumentTypeConfiguration_InstrumentTypeID - each row must reference a valid asset class |
| Trade.HedgeServer | Table | FK_HedgeInstrumentTypeConfiguration_DefaultHedgeServerID - the assigned default server must exist |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetDefaultHedgeServers | Stored Procedure | READER - returns type-to-server mapping for hedge engine routing |
| History.HedgeInstrumentTypeConfiguration | Table | Temporal shadow table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgeInstrumentTypeConfiguration | CLUSTERED PK | InstrumentTypeID ASC | - | - | Active (FILLFACTOR=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HedgeInstrumentTypeConfiguration | PRIMARY KEY | InstrumentTypeID - one default server per asset class |
| FK_HedgeInstrumentTypeConfiguration_InstrumentTypeID | FOREIGN KEY | InstrumentTypeID must reference Dictionary.CurrencyType(CurrencyTypeID) |
| FK_HedgeInstrumentTypeConfiguration_DefaultHedgeServerID | FOREIGN KEY | DefaultHedgeServerID must reference Trade.HedgeServer(HedgeServerID) |
| DF_InstrumentTypeConfiguration_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_InstrumentTypeConfiguration_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime, SysEndTime |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.HedgeInstrumentTypeConfiguration |

### 7.3 Triggers

| Trigger Name | Event | Action |
|-------------|-------|--------|
| TRG_T_InstrumentTypeConfiguration | INSERT | No-op self-UPDATE (UPDATE A SET A.InstrumentTypeID = A.InstrumentTypeID) to force temporal history capture on INSERT |

---

## 8. Sample Queries

### 8.1 View all configured default hedge server assignments by instrument type

```sql
SELECT
    itc.InstrumentTypeID,
    ct.Name AS InstrumentTypeName,
    itc.DefaultHedgeServerID
FROM Hedge.InstrumentTypeConfiguration itc WITH (NOLOCK)
JOIN Dictionary.CurrencyType ct WITH (NOLOCK)
    ON itc.InstrumentTypeID = ct.CurrencyTypeID
ORDER BY itc.InstrumentTypeID
```

### 8.2 Check if the default hedge server routing feature is enabled

```sql
-- GetDefaultHedgeServers returns both the table data and this feature flag
SELECT Value FROM Maintenance.Feature WHERE FeatureID = 102
```

### 8.3 View historical assignments (if any were ever configured)

```sql
SELECT
    h.InstrumentTypeID,
    h.DefaultHedgeServerID,
    h.SysStartTime,
    h.SysEndTime
FROM History.HedgeInstrumentTypeConfiguration h WITH (NOLOCK)
ORDER BY h.SysStartTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9.5/10, Logic: 8.0/10, Relationships: 9.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 files | Corrections: 0 applied*
*Object: Hedge.InstrumentTypeConfiguration | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.InstrumentTypeConfiguration.sql*
