# Customer.ClientSetting

> Per-customer UI settings override table, currently empty — all customers use the default settings from Dictionary.ClientSetting (SettingID=1).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | CID (int, PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 (clustered PK only) |

---

## 1. Business Meaning

Customer.ClientSetting is designed to store per-customer overrides for UI/trading settings such as watchlist configurations, responsible trading leverage/risk limits, sound preferences, OTC (Over-The-Counter) trading defaults, instrument view type, and stop-loss/take-profit edit modes.

The table is currently empty (0 rows). All customers use the global defaults defined in Dictionary.ClientSetting (SettingID=1), which stores a single row representing the platform-wide default settings. The architecture supports the pattern where: (1) Dictionary.ClientSetting holds system-wide defaults, and (2) Customer.ClientSetting would hold per-CID overrides when a customer deviates from the default. Since no customer has customized settings, no override rows exist.

The settings cover UI configuration (instrument view type, sound on/off), trading risk controls (ResponsibleTradingLeverage, ResponsibleTradingRisk set to 100 = no cap applied), and default order parameters (OTC leverage=50, amount=$500 default order size). The `SL_EditType` and `TP_EditType` values (1) control whether stop-loss and take-profit are set by percentage (0) or by amount (1) in the trading UI.

---

## 2. Business Logic

### 2.1 Default-Override Settings Pattern

**What**: Two-tier settings system: Dictionary.ClientSetting provides the global default; Customer.ClientSetting provides per-customer overrides. Currently all customers use the default.

**Columns/Parameters Involved**: All columns

**Rules**:
- If a CID exists in Customer.ClientSetting -> use Customer.ClientSetting values for that customer
- If a CID has no row in Customer.ClientSetting (currently ALL customers) -> fall back to Dictionary.ClientSetting SettingID=1 defaults
- Default values (from Dictionary.ClientSetting SettingID=1): ForexWatchList="1;2;3;4;5;6;7;", StocksWatchList="1005;", ResponsibleTradingLeverage=100, ResponsibleTradingRisk=100, Sound=0 (off), OCT_IsOn=false, OTC_Leverage=50, OTC_Amount=500.00, InstrumentViewType=0, SL_EditType=1 (amount), TP_EditType=1 (amount)

### 2.2 Watchlist Format

**What**: ForexWatchList and StocksWatchList store instrument IDs as semicolon-delimited strings.

**Columns/Parameters Involved**: `ForexWatchList`, `StocksWatchList`

**Rules**:
- IDs are semicolon-delimited: "1;2;3;4;5;6;7;" represents 7 default forex instruments in the watchlist
- StocksWatchList default = "1005;" (a single default stock instrument)
- The format allows client-side parsing without a separate watchlist table per customer

---

## 3. Data Overview

*Customer.ClientSetting is currently empty (0 rows). All customers use Dictionary.ClientSetting defaults.*

Dictionary.ClientSetting defaults (the reference values for all customers):

| SettingID | ForexWatchList | ResponsibleTradingLeverage | OCT_IsOn | OTC_Leverage | SL_EditType | Meaning |
|---|---|---|---|---|---|---|
| 1 | 1;2;3;4;5;6;7; | 100 | false | 50 | 1 | Global default — 7 forex instruments in watchlist, responsible trading leverage at 100 (no cap), OTC disabled, OTC leverage 50x default, stop-loss edit by amount (1) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID - primary key. Identifies the customer whose settings are overridden. Currently no rows exist, so all customers use Dictionary.ClientSetting defaults. |
| 2 | ForexWatchList | varchar(200) | YES | - | CODE-BACKED | Semicolon-delimited list of forex instrument IDs to show in the customer's forex watchlist. Default (from Dictionary): "1;2;3;4;5;6;7;" (7 default forex instruments). NULL = use default. |
| 3 | StocksWatchList | varchar(500) | YES | - | CODE-BACKED | Semicolon-delimited list of stock instrument IDs for the customer's stocks watchlist. Default: "1005;" (1 default stock). NULL = use default. |
| 4 | ResponsibleTradingLeverage | int | YES | - | CODE-BACKED | Maximum leverage limit for responsible trading: 100 = no additional cap beyond regulatory limits. Lower values would cap the customer's available leverage below the platform maximum. |
| 5 | ResponsibleTradingRisk | int | YES | - | CODE-BACKED | Maximum risk exposure limit for responsible trading: 100 = no additional cap. Works alongside ResponsibleTradingLeverage to enforce voluntary or compliance-required risk limits. |
| 6 | Sound | smallint | YES | - | CODE-BACKED | Sound notification preference: 0=off (default), non-zero=on. Controls whether the platform plays audio notifications for trade events. |
| 7 | OCT_IsOn | bit | YES | - | CODE-BACKED | OCT (One-Click Trading) enabled flag: 0=disabled (default). When enabled, trades execute immediately without a confirmation dialog. |
| 8 | OTC_Leverage | int | YES | - | CODE-BACKED | Default leverage setting for OTC (Over-The-Counter) orders. Default: 50 (50x leverage). Stored as customer preference for pre-filling the OTC order form. |
| 9 | OTC_Amount | decimal(10,2) | YES | - | CODE-BACKED | Default order amount in USD for OTC orders. Default: 500.00. Pre-fills the OTC order amount input. |
| 10 | InstrumentViewType | smallint | YES | - | CODE-BACKED | How instruments are displayed in the trading UI: 0=default view. Controls chart type, list layout, or other display preferences. Name-inferred from context; exact values require UI documentation. |
| 11 | SL_EditType | smallint | YES | - | CODE-BACKED | Stop-loss edit mode: 1=edit by amount ($ value), 0=edit by percentage. Controls how the stop-loss input appears in the position editor. Default=1 (amount). |
| 12 | TP_EditType | smallint | YES | - | CODE-BACKED | Take-profit edit mode: 1=edit by amount ($ value), 0=edit by percentage. Controls how the take-profit input appears in the position editor. Default=1 (amount). Mirrors SL_EditType in design. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Given the table is currently empty and has no procedure consumers found in the codebase scan, this table may be consumed directly by application-layer code (not via stored procedures) or may be a legacy structure pending activation.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ClientSetting | Table | Default settings counterpart - same column structure; provides values when CID has no row in Customer.ClientSetting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ClientSetting | CLUSTERED | CID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ClientSetting | PRIMARY KEY | CID must be unique - one settings row per customer |

---

## 8. Sample Queries

### 8.1 Get effective settings for a customer (with fallback to default)

```sql
SELECT
    ISNULL(cs.ForexWatchList, ds.ForexWatchList) AS ForexWatchList,
    ISNULL(cs.StocksWatchList, ds.StocksWatchList) AS StocksWatchList,
    ISNULL(cs.ResponsibleTradingLeverage, ds.ResponsibleTradingLeverage) AS RespLeverage,
    ISNULL(cs.OCT_IsOn, ds.OCT_IsOn) AS OCT_IsOn,
    ISNULL(cs.SL_EditType, ds.SL_EditType) AS SL_EditType,
    ISNULL(cs.TP_EditType, ds.TP_EditType) AS TP_EditType
FROM Dictionary.ClientSetting ds WITH (NOLOCK)
LEFT JOIN Customer.ClientSetting cs WITH (NOLOCK) ON cs.CID = 1001
WHERE ds.SettingID = 1
```

### 8.2 Check if any customers have custom settings

```sql
SELECT
    COUNT(*) AS CustomSettingsCount
FROM Customer.ClientSetting WITH (NOLOCK)
-- Returns 0 currently - all customers use Dictionary.ClientSetting defaults
```

### 8.3 View the global default settings

```sql
SELECT
    SettingID,
    ForexWatchList,
    StocksWatchList,
    ResponsibleTradingLeverage,
    ResponsibleTradingRisk,
    Sound,
    OCT_IsOn,
    OTC_Leverage,
    OTC_Amount,
    InstrumentViewType,
    SL_EditType,
    TP_EditType
FROM Dictionary.ClientSetting WITH (NOLOCK)
WHERE SettingID = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 4/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.ClientSetting | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.ClientSetting.sql*
