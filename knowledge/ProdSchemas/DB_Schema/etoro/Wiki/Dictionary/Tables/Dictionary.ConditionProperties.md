# Dictionary.ConditionProperties

> Temporal lookup table defining the 27 tradeable properties that can be evaluated in CEP (Complex Event Processing) rule conditions — covering instrument attributes, customer attributes, position details, and hedge parameters.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PropertyID (int, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Dictionary.ConditionProperties enumerates the data properties (fields) that can be used as the left-hand side of a comparison in CEP (Complex Event Processing) rule conditions. When building a CEP rule like "if Leverage >= 100 for Crypto instruments," the "Leverage" and "InstrumentType" parts come from this table — they define WHAT is being evaluated. The HOW (comparison operator) comes from `Dictionary.ConditionOperators`.

The 27 properties span multiple data domains: instrument characteristics (type, ID, exchange), customer attributes (CID, country, club level, affiliate, label), position details (leverage, lot count, buy/sell direction, settlement type, ratio), and hedge system parameters (parent/root hedge server, execution ID). This breadth allows the CEP engine to create highly specific rules that target particular combinations of customer, instrument, and trading conditions.

This is a system-versioned temporal table with history in `History.ConditionProperties`. The table has grown over time — recent additions include AccountType (2025-04-02) and SettlementType (2025-08-19), reflecting evolving business needs for more granular rule conditions. Changes are tracked via `TRG_T_ConditionProperties` INSERT trigger.

Referenced by `CEP.Conditions`, `CEP.PropertyToRuleType`, `CEP.GetConditions` view, and `CEP.UpdateCondition` procedure. Access controlled via `PROD_CEP_UI_USER` role.

---

## 2. Business Logic

### 2.1 Property Categories

**What**: Five domains of properties available for CEP rule conditions.

**Columns/Parameters Involved**: `PropertyID`, `Name`

**Rules**:
- **Instrument Properties (IDs 1-2, 25)**: InstrumentType, InstrumentID, ExchangeID — identify WHAT is being traded. Used in rules targeting specific asset classes or exchanges.
- **Trade Parameters (IDs 4-5, 16-20, 24, 27)**: Leverage, LotCount, PositionRatio, OrderType, IsBuy, TreeUnitSize, TreeSizeUSD, IsSettled, SettlementType — describe HOW the trade is structured. Used in rules that limit position sizes, leverage, or settlement methods.
- **Customer Attributes (IDs 7, 9-10, 15, 22-23, 26)**: CID, CustomerLabelID, CustomerIsCupon, PlayerLevelID, CountryID, AffiliateID, AccountType — identify WHO is trading. Used in rules targeting specific customer segments, countries, or VIP tiers.
- **Hedge Parameters (IDs 8, 11-12, 14)**: ParentHedgeServerID, ExecutionID, RootHedgeServerID, ParentPositionID — identify hedge system routing. Used in rules that control hedge execution paths.
- **Copy Trading (IDs 13, 21)**: IsOpenOpen, HasCopiers — identify social trading context. Used in rules that apply different logic for copied trades or popular investors with copiers.
- **Sell Currency (ID 6)**: SellCurrency — the currency being sold in a forex trade. Used in currency-specific rules.

---

## 3. Data Overview

| PropertyID | Name | Meaning |
|---|---|---|
| 1 | InstrumentType | Asset class classification (e.g., Forex, Stocks, Crypto, Commodities). Used in rules like "if InstrumentType = Crypto then apply stricter leverage limits." |
| 4 | Leverage | The leverage multiplier on a position (e.g., 1x, 2x, 5x, 30x). Used in rules limiting maximum leverage per instrument type or customer segment. |
| 7 | CID | Customer ID — the unique identifier for a specific user. Used in rules targeting individual customers (e.g., VIP exceptions, flagged accounts). |
| 15 | PlayerLevelID | eToro Club tier (Bronze through Diamond+). Used in rules that vary behavior by customer loyalty level (e.g., premium customers get different hedge routing). |
| 27 | SettlementType | Position settlement model (CFD vs Real Stock). Most recently added property (2025-08-19) — enables rules that differentiate between derivative and ownership positions. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PropertyID | int | NO | - | VERIFIED | Primary key identifying the condition property. Values 1-27 (not contiguous — ID 3 is missing). Referenced by `CEP.Conditions` and `CEP.PropertyToRuleType` to define which data field a rule condition evaluates. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Property name matching a field in the trading data model (e.g., 'InstrumentType', 'Leverage', 'CID', 'SettlementType'). Used by the CEP engine to dynamically resolve which data field to evaluate at runtime. |
| 3 | DbLoginName | computed | - | suser_name() | CODE-BACKED | Computed column — returns the current SQL Server login name at query time. Audit trail for data access tracking. |
| 4 | AppLoginName | computed | - | CONVERT(varchar(500), context_info()) | CODE-BACKED | Computed column — returns the application-layer context info. Identifies which service is accessing the data. Returns NULL when no context info is set. |
| 5 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System-versioned temporal start timestamp. Most original properties show 2021-09-13 (initial population). Recent additions: AccountType (2025-04-02), SettlementType (2025-08-19). |
| 6 | SysEndTime | datetime2(7) | NO | '9999-12-31 23:59:59.9999999' | CODE-BACKED | System-versioned temporal end timestamp. '9999-12-31' = currently active. Historical versions stored in History.ConditionProperties. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CEP.Conditions | PropertyID | Implicit FK | Each rule condition specifies which property to evaluate |
| CEP.PropertyToRuleType | PropertyID | Implicit FK | Maps which properties are available for each rule type |
| CEP.GetConditions | PropertyID | View | Exposes conditions with resolved property names |
| CEP.UpdateCondition | PropertyID | Procedure | Updates condition definitions including property assignment |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CEP.Conditions | Table | References property ID in rule conditions |
| CEP.PropertyToRuleType | Table | Maps properties to rule types |
| CEP.GetConditions | View | Resolves property names for display |
| CEP.UpdateCondition | Procedure | Updates condition property assignments |
| History.ConditionProperties | Table | Temporal history table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CepProperties | CLUSTERED PK | PropertyID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_ConditionProperties_SysStart | DEFAULT | SysStartTime defaults to getutcdate() |
| DF_ConditionProperties_SysEnd | DEFAULT | SysEndTime defaults to '9999-12-31 23:59:59.9999999' |
| SYSTEM_VERSIONING | Temporal | History tracked in History.ConditionProperties |
| TRG_T_ConditionProperties | Trigger (FOR INSERT) | Forces temporal history capture on INSERT |

---

## 8. Sample Queries

### 8.1 List all current condition properties
```sql
SELECT  PropertyID,
        Name,
        SysStartTime AS AddedDate
FROM    Dictionary.ConditionProperties WITH (NOLOCK)
ORDER BY PropertyID;
```

### 8.2 Show CEP conditions with resolved property and operator names
```sql
SELECT  C.ConditionID,
        CP.Name AS PropertyName,
        CO.Name AS OperatorName,
        C.*
FROM    CEP.Conditions C WITH (NOLOCK)
INNER JOIN Dictionary.ConditionProperties CP WITH (NOLOCK)
        ON CP.PropertyID = C.PropertyID
INNER JOIN Dictionary.ConditionOperators CO WITH (NOLOCK)
        ON CO.OperatorID = C.OperatorID;
```

### 8.3 Find recently added properties
```sql
SELECT  PropertyID,
        Name,
        SysStartTime
FROM    Dictionary.ConditionProperties WITH (NOLOCK)
WHERE   SysStartTime > '2025-01-01'
ORDER BY SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ConditionProperties | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ConditionProperties.sql*
