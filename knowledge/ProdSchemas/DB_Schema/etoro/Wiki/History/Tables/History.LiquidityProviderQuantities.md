# History.LiquidityProviderQuantities

> SQL Server temporal history table automatically maintained by the database engine, recording every past configuration state of Price.LiquidityProviderQuantities - the quantity limit configuration table that defines maximum order/position quantities per instrument per liquidity provider type.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite: (SysEndTime, SysStartTime) - temporal history clustered index |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime ASC, SysStartTime ASC) |

---

## 1. Business Meaning

History.LiquidityProviderQuantities is the temporal history backing table for Price.LiquidityProviderQuantities. It is automatically populated by SQL Server's SYSTEM_VERSIONING mechanism whenever rows in Price.LiquidityProviderQuantities are updated or deleted.

Price.LiquidityProviderQuantities defines the maximum quantity (lot size / position size) that eToro's Price Control System (PCS) will route to a specific liquidity provider type for a specific instrument. Each row specifies one (LiquidityProviderTypeID, InstrumentID) combination and the Quantity limit that governs routing decisions. When the price engine evaluates how much of an order to route to a given LP type, it consults this table.

With 0 rows in the test environment, this table is only active in production where live LP quantity configurations are maintained. Changes are infrequent (LP routing limits are stable configurations) but tracked via temporal history for audit and troubleshooting of routing behavior changes.

The INSERT trigger `TRG_T_LiquidityProviderQuantities` (FOR INSERT: no-op UPDATE SET InstrumentID=InstrumentID) ensures that every new quantity configuration is captured in History at the moment of creation, not only subsequent changes.

---

## 2. Business Logic

### 2.1 Quantity Limit Per LP Type Per Instrument

**What**: Price.LiquidityProviderQuantities defines how much volume the PCS can route to each LP type for each instrument. This caps the exposure sent to any single LP type.

**Columns/Parameters Involved**: `LiquidityProviderTypeID`, `InstrumentID`, `Quantity`

**Rules**:
- One row per (InstrumentID, LiquidityProviderTypeID) combination - composite PK on live table
- Quantity (decimal(16,4)): the maximum number of units/lots that can be sent to this LP type for this instrument
- The PCS uses these limits when distributing orders across multiple LP types for the same instrument
- FK to Trade.LiquidityProviderType (enforced on live table): only recognized LP type IDs are valid
- FK to Trade.Instrument (enforced on live table): only valid instruments can have quantity limits configured
- Changes to quantity limits generate temporal history rows capturing the prior configuration

### 2.2 INSERT Trigger - Capturing Initial Configuration in History

**What**: The `TRG_T_LiquidityProviderQuantities` trigger fires on every INSERT to Price.LiquidityProviderQuantities and performs a no-op UPDATE (SET InstrumentID=InstrumentID), forcing the newly inserted configuration to appear in temporal history.

**Rules**:
- Without the trigger: pure INSERTs would not generate history rows (SYSTEM_VERSIONING only archives on UPDATE/DELETE)
- With the trigger: every new (InstrumentID, LiquidityProviderTypeID) quantity configuration is immediately archived
- Pattern: the same INSERT trigger technique used across CEP.ListCIDMappings, CEP.NamedLists, Trade.MaxLeverageByInstrumentForExposure
- History rows from this trigger have SysStartTime = SysEndTime (ValidForSec=0) - the row existed for zero duration before the UPDATE superseded it

### 2.3 Computed Identity Capture

**What**: DbLoginName and AppLoginName are computed columns on Price.LiquidityProviderQuantities that capture who made each configuration change.

**Rules**:
- DbLoginName = suser_name() on live table - identifies the database login (e.g., Configuration Manager operator or service account)
- AppLoginName = CONVERT(varchar(500), context_info()) - application-level identity. May be NULL if context_info was not set before the DML
- Both values are stored as snapshots in the temporal history rows at the time of each change

---

## 3. Data Overview

0 rows in test environment. In production, rows represent superseded quantity configurations: each time a quantity limit is adjusted for an instrument-LP type pair, the prior value is archived here.

**Expected production data patterns**:
- One history row per (InstrumentID, LiquidityProviderTypeID) change
- High-frequency instruments (FX majors, popular stocks) may have more frequent quantity rebalancing
- Batch configuration changes during LP onboarding/decommissioning generate clusters of history rows with similar SysEndTime

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityProviderTypeID | int | NO | - | CODE-BACKED | The liquidity provider technology type this quantity limit applies to. FK to Trade.LiquidityProviderType enforced on live table (not in history). Part of the composite PK on Price.LiquidityProviderQuantities (InstrumentID, LiquidityProviderTypeID). Identifies which LP technology class is being quantity-limited for this instrument. See History.LiquidityProviderType for type definitions and history. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | The financial instrument for which this quantity limit is configured. FK to Trade.Instrument enforced on live table (not in history). Part of the composite PK. Each instrument-LP type pair has exactly one current quantity limit on the live table; multiple history rows represent changes over time. |
| 3 | Quantity | decimal(16,4) | NO | - | CODE-BACKED | The maximum quantity (units/lots) that the Price Control System can route to this LP type for this instrument. decimal(16,4) provides precision for both whole-lot instruments (integer values) and fractional instruments. Changes to this value generate the temporal history rows stored here. |
| 4 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login name that changed this quantity configuration. Computed column on Price.LiquidityProviderQuantities (= suser_name()); stored as snapshot in history. Identifies the database operator who made the configuration change (domain\username format for TRAD accounts, or service account names). |
| 5 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application-level identity from context_info(). Computed column on live table; stored as snapshot in history. Format: "username;ConfigurationManager" null-padded to 128 bytes (context_info buffer) when changed via Config Manager tool. NULL for direct SQL changes. varchar(500) accommodates the padded format. |
| 6 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this quantity configuration became current in Price.LiquidityProviderQuantities. Set automatically by SQL Server SYSTEM_VERSIONING. The clustered index (SysEndTime ASC, SysStartTime ASC) supports efficient temporal range scans. |
| 7 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this quantity configuration was superseded. When SysEndTime = SysStartTime (from the INSERT trigger's no-op UPDATE), the row represents the initial creation snapshot - the configuration was updated immediately after insertion. The clustered index leading column supports "configurations active before date X" queries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityProviderTypeID | Trade.LiquidityProviderType | Implicit | FK enforced on Price.LiquidityProviderQuantities; not in history. History in History.LiquidityProviderType. |
| InstrumentID | Trade.Instrument | Implicit | FK enforced on Price.LiquidityProviderQuantities; not in history. References the instrument being configured. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.LiquidityProviderQuantities | SYSTEM_VERSIONING | Writer (automatic) | Live temporal table - SQL Server archives old configurations here on UPDATE/DELETE |
| TRG_T_LiquidityProviderQuantities | (no-op UPDATE) | Writer (forced) | INSERT trigger forces new configurations into temporal history |

---

## 6. Dependencies

```
History.LiquidityProviderQuantities (table)
  - No code-level dependencies (temporal history leaf table)
  - Source: Price.LiquidityProviderQuantities (live temporal table, SYSTEM_VERSIONING = ON)
    - FK dependencies on live table: Trade.Instrument, Trade.LiquidityProviderType
    - Modified by: Configuration Manager tool (TRAD domain accounts)
    - INSERT trigger: TRG_T_LiquidityProviderQuantities (forces INSERTs into history)
```

### 6.1 Objects This Depends On

No dependencies. Populated automatically by temporal versioning.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.LiquidityProviderQuantities | Table | Live temporal table - this is its HISTORY_TABLE |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_LiquidityProviderQuantities | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

PAGE compression applied. ON [PRIMARY] filegroup.

### 7.2 Constraints

No constraints on history table. Price.LiquidityProviderQuantities live table: CLUSTERED PK on (InstrumentID ASC, LiquidityProviderTypeID ASC), FILLFACTOR=95; FK_PriceLiquidityProviderQuantities_InstrumentID (InstrumentID -> Trade.Instrument); FK_PriceLiquidityProviderQuantities_LiquidityProviderTypeID (LiquidityProviderTypeID -> Trade.LiquidityProviderType).

---

## 8. Sample Queries

### 8.1 Full quantity configuration history for a specific instrument-LP type pair

```sql
SELECT LiquidityProviderTypeID, InstrumentID, Quantity,
       DbLoginName, AppLoginName, SysStartTime, SysEndTime,
       DATEDIFF(SECOND, SysStartTime, SysEndTime) AS ValidForSec
FROM [History].[LiquidityProviderQuantities] WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
  AND LiquidityProviderTypeID = @LiquidityProviderTypeID
UNION ALL
SELECT LiquidityProviderTypeID, InstrumentID, Quantity,
       DbLoginName, AppLoginName, SysStartTime, SysEndTime, NULL
FROM [Price].[LiquidityProviderQuantities] WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
  AND LiquidityProviderTypeID = @LiquidityProviderTypeID
ORDER BY SysStartTime ASC
```

### 8.2 Quantity limits at a specific point in time

```sql
SELECT LiquidityProviderTypeID, InstrumentID, Quantity
FROM [Price].[LiquidityProviderQuantities]
FOR SYSTEM_TIME AS OF '2025-01-01 00:00:00'
ORDER BY InstrumentID, LiquidityProviderTypeID
```

### 8.3 Most frequently changed quantity configurations

```sql
SELECT InstrumentID, LiquidityProviderTypeID,
       COUNT(*) AS ChangeCount,
       MIN(Quantity) AS MinQty, MAX(Quantity) AS MaxQty
FROM [History].[LiquidityProviderQuantities] WITH (NOLOCK)
GROUP BY InstrumentID, LiquidityProviderTypeID
ORDER BY ChangeCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (temporal history - written by Config Manager tool) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.LiquidityProviderQuantities | Type: Table | Source: etoro/etoro/History/Tables/History.LiquidityProviderQuantities.sql*
