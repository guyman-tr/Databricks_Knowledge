# Dictionary.TradingInstrumentGroups

> System-versioned configuration table defining named instrument groupings used for trading rules, risk limits, regulatory restrictions, and cross-border settings.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table (System-Versioned / Temporal) |
| **Key Identifier** | GroupID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **History Table** | History.DictionaryTradingInstrumentGroups |
| **Indexes** | 2 active (PK clustered + unique NC on GroupName) |

---

## 1. Business Meaning

Dictionary.TradingInstrumentGroups defines named categories that instruments can be assigned to for applying shared trading rules, risk limits, and regulatory restrictions. Instead of configuring rules per-instrument, the system groups instruments into categories and applies rules at the group level — reducing configuration complexity for 10,000+ instruments.

Key business groups include: **RealOnly** (instruments that can only be traded as real stock, not CFD), **CFDOnly** (CFD-only instruments), **CopyBlock** (instruments blocked from copy-trading), **US_Restricted** (instruments not allowed under US regulation), and **MaxNOPLimit** tiers (A through K) that set maximum Net Open Position dollar limits per group — from $80M for tier A down to $50K for tier L. Newer groups include **Crypto Futures**, **Crypto UCITS ETFs**, and **SQFs** (Special Qualifying Funds).

Being system-versioned with temporal tracking, all group changes are audited. The INSERT trigger captures audit context (DbLoginName, AppLoginName) for every new group creation. The table also contains many QA automation groups created by automated testing — these are test artifacts, not production business groups.

---

## 2. Business Logic

### 2.1 Risk Limit Tiers (MaxNOPLimit)

**What**: Net Open Position (NOP) limits are configured per instrument group, creating tiered risk exposure caps.

**Columns/Parameters Involved**: `GroupID`, `GroupName`, `Description`

**Rules**:
- **MaxNOPLimit_A_$80M**: Highest limit tier — large-cap, highly liquid instruments (major forex, S&P 500 stocks)
- **MaxNOPLimit_B_$40M**: Second tier — moderately liquid instruments
- **Through to MaxNOPLimit_L_$50K**: Lowest tier — illiquid or high-risk instruments (small-cap, exotic crypto)
- NOP limits prevent excessive concentration risk in any single instrument group
- "_OLD_" suffix groups are deprecated tiers with lower limits from before limit expansion

### 2.2 Regulatory & Product Restrictions

**What**: Some groups enforce regulatory constraints or product-level trading restrictions.

**Columns/Parameters Involved**: `GroupName`

**Rules**:
- **RealOnly (1)**: Instruments restricted to real stock ownership — CFD trading disabled. Used for instruments where the platform wants to offer only physical shares.
- **CFDOnly (3)**: Instruments available only as CFDs — no real stock ownership option. Typically for instruments where custody is complex.
- **CopyBlock (2)**: Instruments blocked from CopyTrader — copied portfolios cannot include these instruments. Used for illiquid or restricted assets.
- **US_Restricted (4)**: Instruments not available to US-regulated customers. Regulatory compliance for eToro USA.

---

## 3. Data Overview

| GroupID | GroupName | Description | Meaning |
|---|---|---|---|
| 1 | RealOnly | - | Instruments restricted to real stock ownership only — no CFD trading. Ensures customer actually owns the shares, not a derivative contract. |
| 2 | CopyBlock | - | Instruments excluded from CopyTrader copying. Prevents illiquid or restricted instruments from being auto-copied when a leader trades them. |
| 3 | CFDOnly | - | Instruments available exclusively as CFDs — no real stock ownership. Typically for instruments where custody arrangements are unavailable. |
| 4 | US_Restricted | Instruments Not allowed in US | Instruments blocked for US-regulated customers. Regulatory compliance — some instruments require specific SEC registrations not available for eToro USA. |
| 33 | MaxNOPLimit_A_$80M | MaxNOPLimit | Highest risk limit tier — platform can hold up to $80M in net open positions across all instruments in this group. Reserved for the most liquid instruments. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GroupID | int (IDENTITY) | NO | - | CODE-BACKED | Auto-incrementing group identifier. Business groups: 1=RealOnly, 2=CopyBlock, 3=CFDOnly, 4=US_Restricted, 33-52=MaxNOPLimit tiers, 59=SQFs, 99=Crypto Futures, 183=Crypto UCITS ETFs, 450=stockmargin, 480=Experimental_Crypto, 780=Crypto US ETFs, 801=Futures. Many QA automation groups also exist. |
| 2 | GroupName | varchar(50) | NO | - | CODE-BACKED | Unique group name used as technical identifier. Business groups use descriptive names; QA groups use "QaAutomation" prefix with timestamps. |
| 3 | Description | varchar(200) | YES | - | CODE-BACKED | Optional description providing business context. Some groups have descriptions (e.g., "Instruments Not allowed in US"), others are NULL. |
| 4 | DbLoginName | computed | NO | - | CODE-BACKED | Computed: `suser_name()`. SQL Server login that last modified the row. |
| 5 | AppLoginName | computed | NO | - | CODE-BACKED | Computed: `CONVERT(varchar(500), context_info())`. Application-level identity from CONTEXT_INFO. |
| 6 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | Temporal row start — GENERATED ALWAYS AS ROW START. |
| 7 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | Temporal row end — GENERATED ALWAYS AS ROW END. Active rows: 9999-12-31. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Instrument-to-group mapping tables | GroupID | Implicit | Links instruments to their assigned groups for rule application |
| Trading engine configuration | GroupID | Read | Loads group memberships to enforce NOP limits and restrictions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.TradingInstrumentGroups (table)
```

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.DictionaryTradingInstrumentGroups | Table | Temporal history of group changes |
| Instrument configuration procedures | Stored Procedures | Assign instruments to groups |
| Trading engine | Service | Loads group NOP limits and restrictions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (PK) | CLUSTERED PK | GroupID | - | - | Active |
| UIX_GroupName | NONCLUSTERED UNIQUE | GroupName | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK | PRIMARY KEY | Auto-incrementing group ID, DICTIONARY filegroup |
| UIX_GroupName | UNIQUE | Ensures no duplicate group names |
| SYSTEM_TIME PERIOD | TEMPORAL | SysStartTime to SysEndTime — automatic versioning |
| TRG_DictionaryTradingInstrumentGroups_INSERT | TRIGGER (FOR INSERT) | Self-update on INSERT to capture audit computed columns |

---

## 8. Sample Queries

### 8.1 List all business-relevant groups (exclude QA automation)
```sql
SELECT  GroupID, GroupName, Description
FROM    Dictionary.TradingInstrumentGroups WITH (NOLOCK)
WHERE   GroupName NOT LIKE 'QaAutomation%'
        AND GroupName NOT LIKE '%Test%'
ORDER BY GroupID;
```

### 8.2 List all MaxNOPLimit tier groups
```sql
SELECT  GroupID, GroupName, Description
FROM    Dictionary.TradingInstrumentGroups WITH (NOLOCK)
WHERE   GroupName LIKE 'MaxNOPLimit%'
ORDER BY GroupName;
```

### 8.3 View group creation history
```sql
SELECT  GroupID, GroupName, Description,
        SysStartTime AS CreatedAt
FROM    Dictionary.TradingInstrumentGroups WITH (NOLOCK)
WHERE   GroupName NOT LIKE 'QaAutomation%'
ORDER BY SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.TradingInstrumentGroups | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.TradingInstrumentGroups.sql*
