# Dictionary.ClientSetting

> Configuration table storing default client trading UI settings — watchlists, leverage, risk, sound, OTC mode, and SL/TP edit preferences. Contains a single default-settings row.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | SettingID (int, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Dictionary.ClientSetting stores the default UI and trading configuration values that are applied to new client accounts at registration. This is a single-row configuration table (SettingID=1) that serves as the template for initial client preferences — what instruments appear on the default watchlist, what leverage and risk levels are preset, whether sound notifications are enabled, and how stop-loss/take-profit controls are displayed.

When a new customer registers, the system copies these default values into the customer's personalized settings. The customer can then modify their individual preferences. This table defines the "factory defaults" — the baseline experience for every new user before they customize anything.

No FK references or procedure consumers were found in the current SSDT project referencing `Dictionary.ClientSetting` specifically, suggesting it is consumed by application-layer registration code.

---

## 2. Business Logic

### 2.1 Default Trading UI Configuration

**What**: Factory default settings applied to every new customer account.

**Columns/Parameters Involved**: All columns

**Rules**:
- **Watchlists**: Default Forex watchlist shows instruments 1-7 (major currency pairs). Default Stocks watchlist shows instrument 1005 (likely a flagship stock).
- **Risk controls**: Default leverage=100 and risk=100 — represents the maximum "responsible trading" settings before a customer's risk profile is assessed.
- **OTC mode**: Disabled by default (OCT_IsOn=false), with leverage 50 and amount 500.00 if enabled. OTC (Over The Counter) is an alternative trading mode.
- **Display preferences**: Sound=0 (muted), InstrumentViewType=0 (default view), SL_EditType=1 and TP_EditType=1 (specific stop-loss/take-profit edit control styles).

---

## 3. Data Overview

| SettingID | ForexWatchList | ResponsibleTradingLeverage | OCT_IsOn | SL_EditType | Meaning |
|---|---|---|---|---|---|
| 1 | 1;2;3;4;5;6;7; | 100 | false | 1 | The single default settings row — defines baseline configuration for all new user accounts. Forex watchlist includes 7 major instruments, leverage defaults to maximum, OTC trading is off, and SL/TP controls use edit type 1. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SettingID | int | NO | - | CODE-BACKED | Primary key identifying the settings profile. Only value 1 exists — this is a single-row configuration table. |
| 2 | ForexWatchList | varchar(200) | YES | - | VERIFIED | Semicolon-delimited list of default Forex instrument IDs for new user watchlists. Value '1;2;3;4;5;6;7;' represents the 7 major currency pairs shown to new users. References instrument IDs from Dictionary.Currency. |
| 3 | StocksWatchList | varchar(500) | YES | - | VERIFIED | Semicolon-delimited list of default Stock instrument IDs for new user watchlists. Value '1005;' shows a single flagship stock. Larger capacity (500 chars vs 200) allows for more stock symbols. |
| 4 | ResponsibleTradingLeverage | int | YES | - | VERIFIED | Default leverage level (100) for the "responsible trading" configuration. Applied as the initial maximum leverage before the customer completes suitability assessment. Value of 100 represents 1:100 leverage ratio. |
| 5 | ResponsibleTradingRisk | int | YES | - | VERIFIED | Default risk level (100) for the "responsible trading" configuration. Represents the initial risk tolerance setting for new accounts. Higher values allow riskier trades. |
| 6 | Sound | smallint | YES | - | VERIFIED | Sound notification preference: 0=muted, other values may enable different sound profiles. Default is 0 (silent) to avoid unexpected audio on first login. |
| 7 | OCT_IsOn | bit | YES | - | CODE-BACKED | Whether OTC (Over The Counter) trading mode is enabled by default: 0=disabled, 1=enabled. Default is false — OTC mode is opt-in for customers who want alternative execution. |
| 8 | OTC_Leverage | int | YES | - | CODE-BACKED | Default leverage for OTC trades when OTC mode is enabled. Value 50 represents 1:50 leverage — lower than the standard trading leverage default, reflecting higher risk of OTC instruments. |
| 9 | OTC_Amount | decimal(10,2) | YES | - | CODE-BACKED | Default trade amount for OTC trades in account currency. Value 500.00 — the pre-filled amount when a customer opens an OTC position without specifying an amount. |
| 10 | InstrumentViewType | smallint | YES | - | NAME-INFERRED | Controls the default instrument display layout in the trading UI. Value 0 represents the default/standard view. Other values likely correspond to alternative layouts (grid, list, chart-focused). |
| 11 | SL_EditType | smallint | YES | - | NAME-INFERRED | Controls how the Stop Loss control is displayed in the trade ticket UI. Value 1 represents a specific edit control style (e.g., slider vs numeric input vs percentage). |
| 12 | TP_EditType | smallint | YES | - | NAME-INFERRED | Controls how the Take Profit control is displayed in the trade ticket UI. Value 1 represents a specific edit control style. Same concept as SL_EditType but for the take-profit input. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No FK references found in the SSDT project. Consumed by application-layer registration code.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in the SSDT project.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ClientSetting | CLUSTERED PK | SettingID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 Read the default client settings
```sql
SELECT  *
FROM    Dictionary.ClientSetting WITH (NOLOCK)
WHERE   SettingID = 1;
```

### 8.2 Parse default Forex watchlist instrument IDs
```sql
SELECT  SettingID,
        value AS InstrumentID
FROM    Dictionary.ClientSetting WITH (NOLOCK)
CROSS APPLY STRING_SPLIT(ForexWatchList, ';')
WHERE   value <> ''
  AND   SettingID = 1;
```

### 8.3 Show OTC default configuration
```sql
SELECT  OCT_IsOn AS OtcEnabled,
        OTC_Leverage AS OtcLeverage,
        OTC_Amount AS OtcDefaultAmount
FROM    Dictionary.ClientSetting WITH (NOLOCK)
WHERE   SettingID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 8/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 3 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ClientSetting | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ClientSetting.sql*
