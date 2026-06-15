# Trade.InstrumentGroups

> Junction table mapping trading instruments to classification groups, enabling the platform to control which instruments are restricted to real stock only, blocked from copy trading, CFD-only, US-restricted, or subject to Net Open Position (NOP) exposure limits.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | Composite PK (InstrumentID, GroupID) CLUSTERED |
| **Partition** | DICTIONARY filegroup |
| **Row Count** | 341 (MCP verified) |
| **Indexes** | 1 active (PK only) |
| **Temporal** | Yes - SYSTEM_VERSIONING ON, history: History.TradeInstrumentGroups |

---

## 1. Business Meaning

Trade.InstrumentGroups is a many-to-many junction table that classifies trading instruments into behavioral groups. Each group defines a specific characteristic or restriction that applies to all instruments assigned to it. For example, an instrument in the "RealOnly" group (GroupID=1) can only be traded as a real stock purchase, while an instrument in "CopyBlock" (GroupID=2) cannot be opened via copy trading. An instrument can belong to multiple groups simultaneously (e.g., both RealOnly and US_Restricted).

Without this table, the platform would have no centralized mechanism to enforce instrument-level trading restrictions. Fee calculations (Trade.FnGetCloseFixPerLot, Trade.FnGetCloseFeeInPercentage), copy-trade restrictions (Trade.GetSmartCopyRestrictions), and regulatory compliance (US_Restricted group) all depend on group membership lookups.

Group assignments are managed by back-office operations through Trade.InsertInstrumentGroup and Trade.DeleteInstrumentGroup, both accepting TVP (Trade.InstrumentGroupsTbl) for bulk operations. The AppLoginName parameter is stored in CONTEXT_INFO for temporal audit trail. The INSERT trigger (TRG_InstrumentGroups_INSERT) forces a dummy UPDATE immediately after INSERT to ensure the temporal system captures the initial row version with the correct CONTEXT_INFO.

---

## 2. Business Logic

### 2.1 Instrument Group Membership

**What**: Determines whether a specific instrument belongs to a specific group, controlling trading behavior and restrictions.

**Columns/Parameters Involved**: `InstrumentID`, `GroupID`, `ProviderID`

**Rules**:
- An instrument can belong to zero or more groups simultaneously
- Group membership is checked by Trade.IsInstrumentInGroup(InstrumentID, GroupID) which returns BIT (1=in group, 0=not)
- Key business groups (by active instrument count):
  - GroupID 49: Most instruments (88) - used in fee calculations
  - GroupID 1 "RealOnly" (76 instruments): Instrument can only be traded as real stock, not CFD
  - GroupID 2 "CopyBlock" (73 instruments): Instrument cannot be opened via CopyTrader
  - GroupID 4 "US_Restricted" (68 instruments): Instrument restricted for US-regulated customers
  - GroupID 3 "CFDOnly": Instrument can only be traded as CFD, not real stock
- MaxNOP groups (33-52): Net Open Position exposure limits per tier (A=$80M, B=$40M, C=$20M, D=$12M, E=$10M)

**Diagram**:
```
Instrument (e.g., Apple stock)
    |
    +-- Group 1: RealOnly      --> Can buy real shares
    +-- Group 2: CopyBlock     --> Cannot be copy-traded
    +-- Group 4: US_Restricted  --> Restricted for US clients
    +-- Group 49: (fee group)   --> Specific fee schedule applies

Trade.IsInstrumentInGroup(@InstrumentID, @GroupID) = 1/0
    |
    +-- Used by: Fee calculations, copy-trade validation, regulatory checks
```

### 2.2 Temporal Audit via INSERT Trigger

**What**: Ensures every INSERT operation is captured in the temporal history with the correct application context.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- TRG_InstrumentGroups_INSERT fires after each INSERT and performs a no-op UPDATE (sets columns to their own values)
- This forces SQL Server temporal system to record a "before" snapshot in History.TradeInstrumentGroups
- The computed AppLoginName column captures the CONTEXT_INFO set by the calling procedure, identifying the back-office user who made the change
- CONTEXT_INFO is set by Trade.InsertInstrumentGroup / Trade.DeleteInstrumentGroup from the @AppLoginName parameter

---

## 3. Data Overview

| ProviderID | InstrumentID | GroupID | GroupName | Meaning |
|---|---|---|---|---|
| 1 | 1 | 1 | RealOnly | This instrument (ID 1) with provider 1 is restricted to real stock purchases only - customers cannot trade it as a CFD |
| 1 | 1 | 2 | CopyBlock | Same instrument is also blocked from being opened via CopyTrader - customers can only trade it independently |
| 1 | 1 | 4 | US_Restricted | Also restricted for US-regulated accounts - US customers cannot trade this instrument |
| 1 | 1 | 38 | MaxNOPLimit_C_OLD_$1.25M | Subject to an older $1.25M net open position limit in tier C |
| 1 | 5 | 26 | QaAutomation01 | QA automation test group assignment - used for automated testing of group membership logic |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | - | VERIFIED | Liquidity provider/broker identifier. Part of composite FK to Trade.ProviderToInstrument(ProviderID, InstrumentID). All current rows use ProviderID=1 (primary provider). Determines which provider's instrument listing this group membership applies to. |
| 2 | InstrumentID | int | NO | - | VERIFIED | Trading instrument identifier. Part of composite PK (InstrumentID, GroupID) and composite FK to Trade.ProviderToInstrument. References the instrument being classified. An instrument can appear in multiple rows with different GroupIDs. |
| 3 | GroupID | int | NO | - | VERIFIED | Group classification identifier. Part of composite PK. FK to Dictionary.TradingInstrumentGroups(GroupID). Key values: 1=RealOnly (real stock only), 2=CopyBlock (no copy-trading), 3=CFDOnly, 4=US_Restricted. 315 total groups exist including MaxNOP limits and QA automation groups. Checked by Trade.IsInstrumentInGroup and used in fee calculations. |
| 4 | SysStartTime | datetime2(7) | NO | getutcdate() | VERIFIED | System-versioned temporal column (GENERATED ALWAYS AS ROW START). Records when this group assignment became effective. Default is current UTC time at INSERT. Part of PERIOD FOR SYSTEM_TIME. |
| 5 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | VERIFIED | System-versioned temporal column (GENERATED ALWAYS AS ROW END). Records when this group assignment was removed or changed. Value of 9999-12-31 indicates the assignment is current. Part of PERIOD FOR SYSTEM_TIME. |
| 6 | DbLoginName | computed | NO | - | VERIFIED | Computed audit column: `suser_name()`. Captures the SQL Server login name of the session that last modified this row. Used for auditing which database account performed the change. |
| 7 | AppLoginName | computed | NO | - | CODE-BACKED | Computed audit column: `CONVERT(varchar(500), context_info())`. Captures the application-level user identity from CONTEXT_INFO, which is set by Trade.InsertInstrumentGroup and Trade.DeleteInstrumentGroup from the @AppLoginName parameter. Identifies the back-office operator who made the group assignment change. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GroupID | Dictionary.TradingInstrumentGroups | Explicit FK (FK_Group) | Maps to the group definition (name, description). 315 possible groups covering trading restrictions, NOP limits, and test groups. |
| (ProviderID, InstrumentID) | Trade.ProviderToInstrument | Explicit FK (FK_ProviderToInstrument) | Validates that the instrument-provider combination exists. Ensures group assignments only apply to active provider-instrument pairs. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.TradeInstrumentGroups | - | Temporal History | System-versioned history of all group assignment changes |
| Trade.IsInstrumentInGroup | InstrumentID, GroupID | SELECT EXISTS | Scalar function returning BIT - primary lookup for group membership checks |
| Trade.FnGetCloseFixPerLot | - | JOIN | Uses group membership for close-fee-per-lot calculations |
| Trade.FnGetCloseFeeInPercentage | - | JOIN | Uses group membership for percentage-based close fee calculations |
| Trade.InsertInstrumentGroup | ProviderID, InstrumentID, GroupID | INSERT | Bulk inserts group assignments from TVP (Trade.InstrumentGroupsTbl) |
| Trade.DeleteInstrumentGroup | ProviderID, InstrumentID, GroupID | DELETE | Bulk removes group assignments from TVP |
| Trade.GetSmartCopyRestrictions | - | Reader | Reads group membership for copy-trade restriction validation |
| Trade.GetInstrumentsAndInstrumentsGroups | - | Reader | Returns instruments with their group assignments |
| Trade.GetInstrumentDataForAPI | - | Reader | Includes group data in API instrument responses |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentGroups (table)
+-- Dictionary.TradingInstrumentGroups (table) [FK target]
+-- Trade.ProviderToInstrument (table) [FK target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.TradingInstrumentGroups | Table | FK target - GroupID references GroupID |
| Trade.ProviderToInstrument | Table | FK target - (ProviderID, InstrumentID) composite FK |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.TradeInstrumentGroups | Table | Temporal history table |
| Trade.IsInstrumentInGroup | Function | Checks group membership (SELECT EXISTS) |
| Trade.FnGetCloseFixPerLot | Function | JOINs for fee calculation |
| Trade.FnGetCloseFeeInPercentage | Function | JOINs for percentage fee calculation |
| Trade.InsertInstrumentGroup | Stored Procedure | Writer - bulk INSERT from TVP |
| Trade.DeleteInstrumentGroup | Stored Procedure | Deleter - bulk DELETE via TVP |
| Trade.GetSmartCopyRestrictions | Stored Procedure | Reader - copy-trade restriction checks |
| Trade.GetInstrumentsAndInstrumentsGroups | Stored Procedure | Reader - returns group assignments |
| Trade.GetInstrumentDataForAPI | Stored Procedure | Reader - API instrument data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (PK) | CLUSTERED PK | InstrumentID ASC, GroupID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (PK) | PRIMARY KEY | Composite (InstrumentID, GroupID) - ensures each instrument can appear in each group at most once |
| FK_Group | FOREIGN KEY | GroupID -> Dictionary.TradingInstrumentGroups(GroupID). WITH CHECK |
| FK_ProviderToInstrument | FOREIGN KEY | (ProviderID, InstrumentID) -> Trade.ProviderToInstrument(ProviderID, InstrumentID). WITH CHECK |

---

## 8. Sample Queries

### 8.1 List all group assignments for a specific instrument
```sql
SELECT  ig.InstrumentID,
        ig.ProviderID,
        tig.GroupName,
        ig.GroupID
FROM    Trade.InstrumentGroups ig WITH (NOLOCK)
JOIN    Dictionary.TradingInstrumentGroups tig WITH (NOLOCK)
        ON ig.GroupID = tig.GroupID
WHERE   ig.InstrumentID = 1
ORDER BY tig.GroupName;
```

### 8.2 Check if an instrument is in a specific group
```sql
SELECT  Trade.IsInstrumentInGroup(1, 2) AS IsInCopyBlockGroup;
```

### 8.3 View group assignment change history for an instrument
```sql
SELECT  InstrumentID,
        GroupID,
        DbLoginName,
        AppLoginName,
        SysStartTime,
        SysEndTime
FROM    Trade.InstrumentGroups
FOR SYSTEM_TIME ALL
WHERE   InstrumentID = 1
ORDER BY GroupID, SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from DDL analysis, live data sampling (341 rows across 22 groups), and procedure logic analysis (Trade.InsertInstrumentGroup, Trade.DeleteInstrumentGroup, Trade.IsInstrumentInGroup).

---

*Generated: 2026-03-15 | Quality: 8.7/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentGroups | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.InstrumentGroups.sql*
