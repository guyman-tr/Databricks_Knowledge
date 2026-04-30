# History.DictionaryTradingInstrumentGroups

> Temporal system-versioned history table storing all past versions of trading instrument group definitions - recording every change to the named groups that classify instruments by trading rules (RealOnly, CopyBlock, CFDOnly, US_Restricted, MaxNOPLimit tiers, etc.).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; rows identified by (GroupID) + SysStartTime + SysEndTime |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

This table is the **SQL Server temporal history store** for `Dictionary.TradingInstrumentGroups`. SQL Server automatically moves rows here whenever an instrument group definition is updated or deleted.

`Dictionary.TradingInstrumentGroups` defines **named groupings of trading instruments** used to apply special trading rules across a set of instruments. A group has a name and optional description; instruments are linked to groups via `Trade.InstrumentGroups`. The business groups define:

| GroupName | Description |
|-----------|-------------|
| RealOnly (1) | Instruments that can only be traded as real ownership, not as CFDs |
| CopyBlock (2) | Instruments blocked from CopyTrading (cannot be copied) |
| CFDOnly (3) | Instruments that can only be traded as CFDs |
| US_Restricted (4) | Instruments not allowed for US customers |
| MaxNOPLimit_A_$80M through MaxNOPLimit_L_$50K (33-52) | Net Open Position limit tiers - instruments grouped by their maximum allowed NOP per tier |
| Lowtouchinstruments (49) | Low-touch instruments (reduced manual handling required) |
| SQFs (59) | UI configuration group for SQF (Structured Quote Facility) instruments |
| Crypto Futures (99) | Cryptocurrency futures instruments |
| Crypto UCITS ETFs (183) | Crypto UCITS ETF instruments |
| stockmargin (450) | Stock margin instruments |
| Experimental_Crypto (480) | Experimental cryptocurrency instruments |
| Crypto US ETFs (780) | Crypto US ETF instruments / cross-border settings |
| Futures (849) | Futures instruments |

With 1,713 historical rows spanning from October 2025, this history captures changes to the source table which has 849 GroupIDs currently active - the majority being QaAutomation test groups created by the automated test suite in this staging environment.

---

## 2. Business Logic

### 2.1 Temporal Versioning - How History Is Recorded

**What**: SQL Server automatically populates this table via system-versioning whenever a group row is modified or deleted.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `GroupID`

**Rules**:
- When a row is **updated**: SQL Server moves the old version here with `SysEndTime` = the moment of update, `SysStartTime` = when that version was first active.
- When a row is **deleted**: SQL Server moves the row here with `SysEndTime` = deletion timestamp.
- The CLUSTERED index on `(SysEndTime, SysStartTime)` enables efficient `FOR SYSTEM_TIME AS OF` queries.

### 2.2 INSERT Trigger Creates Zero-Duration History Rows

**What**: `TRG_DictionaryTradingInstrumentGroups_INSERT` on the source table fires a no-op UPDATE after every INSERT, generating a zero-duration history row for each new group.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `GroupName`

**Rules**:
- After INSERT, the trigger executes: `UPDATE A SET A.GroupName = A.GroupName` (no-op self-update).
- SQL Server's temporal mechanism treats this as an UPDATE, moving the just-inserted row to history with `SysStartTime = SysEndTime = T` (zero duration, because both timestamps are within the same transaction).
- This creates a permanent audit record even for records that are later deleted without any UPDATE, ensuring the history table always has an entry for every group that was ever created.
- Zero-duration rows (SysStartTime = SysEndTime) are INSERT artifacts; rows with SysStartTime < SysEndTime represent actual time periods the row was the "current" version.
- Visible in data: GroupID=849 has SysStartTime=SysEndTime=2026-03-18T19:37:58.836 (zero-duration INSERT artifact).

**Diagram**:
```
INSERT GroupID=849, GroupName="Futures"
  -> Row enters Dictionary.TradingInstrumentGroups (SysStartTime=T1=19:37:58.836)
  -> INSERT trigger fires: UPDATE GroupName=GroupName
     -> Old row moved to History: SysStartTime=T1, SysEndTime=T1 (zero-duration)
     -> New row in source: SysStartTime=T1+epsilon

DELETE GroupID=848 (previous "Futures"):
  -> Row moved to History: SysStartTime=T_insert, SysEndTime=T_delete
     (SysStartTime < SysEndTime: represents actual active lifetime of 5 seconds)
```

### 2.3 Audit Attribution via DbLoginName and AppLoginName

**What**: Two computed columns on the source table capture who made each change.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`

**Rules**:
- `DbLoginName = suser_name()` - the SQL Server login at time of DML. Examples: `TRAD\eladav` (developer), `DevTradingSTG` (service account), `trading-opstool-api` (operations tool API).
- `AppLoginName = CONVERT(varchar(500), context_info())` - set by the application before executing DML via `SET CONTEXT_INFO`. Carries the end-user email address (e.g., `opstest01@etoro.com`) padded with null characters to 128 bytes (the size of context_info varbinary), then cast to varchar(500).
- NULL `AppLoginName` = change made directly via SSMS or a process that doesn't set `context_info`.
- `AppLoginName` values contain trailing null characters (`\u0000`) due to the binary padding - must be trimmed in queries.

### 2.4 Instrument Group Business Applications

**What**: Groups are referenced by multiple systems to apply rules to sets of instruments.

**Rules** (from dependent SPs):
- `Trade.GetSmartCopyRestrictions` reads `Dictionary.TradingInstrumentGroups` joined to `Trade.InstrumentGroups` to determine SmartCopy (CopyTrading) restrictions per instrument.
- `Trade.GetSmartCopyRestrictions_TRDOPS` - Operations Tool version of the same.
- The MaxNOPLimit groups define exposure limit tiers - instruments in `MaxNOPLimit_A_$80M` have a maximum NOP of $80M, while `MaxNOPLimit_K_$50K` instruments are highly restricted.
- `CopyBlock` instruments cannot appear in any CopyTrading portfolio.
- `RealOnly` / `CFDOnly` restrict which settlement types are available.

---

## 3. Data Overview

| GroupID | GroupName | DbLoginName | SysStartTime | SysEndTime | Meaning |
|---|---|---|---|---|---|
| 1 | QaAutomation01 | TRAD\eladav | 2025-10-19 11:30 | 2025-10-19 11:33 | The first GroupID in history was a QA test group created by developer eladav during initial staging setup - active for ~3 minutes before being replaced. |
| 5 | Futures | TRAD\eladav | 2025-10-19 11:33 | 2025-10-19 11:34 | GroupID=5 was named "Futures" during the Oct 2025 initial staging load, then superseded ~40s later. |
| 849 | Futures | DevTradingSTG | 2026-03-18 19:37:58 | 2026-03-18 19:37:58 | Zero-duration row created by the INSERT trigger for the latest "Futures" group creation. |
| 846 | QaAutomation_20260318182111611_2cfc5d | trading-opstool-api | 2026-03-18 18:21:14 | 2026-03-18 18:21:14 | QA automation test group created via Operations Tool API (opstest01@etoro.com), immediately deleted in same transaction. |

**Environment note**: This is a staging environment. The 849 currently active GroupIDs and 1,713 history rows are dominated by QaAutomation test groups. Production would have a much smaller set of active groups (the business groups listed in Section 1) with a longer history timeline.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GroupID | int | NO | - | CODE-BACKED | Surrogate primary key from the source table (IDENTITY in Dictionary.TradingInstrumentGroups). Identifies the group across all its historical versions. Meaningful business IDs: 1=RealOnly, 2=CopyBlock, 3=CFDOnly, 4=US_Restricted. IDs above ~25 are dominated by QaAutomation test groups in staging. |
| 2 | GroupName | varchar(50) | NO | - | VERIFIED | The group's unique name (UNIQUE constraint on source table). Business names: "RealOnly", "CopyBlock", "CFDOnly", "US_Restricted", "MaxNOPLimit_A_$80M" through "MaxNOPLimit_L_$50K", "Crypto Futures", "Futures", "Lowtouchinstruments", "SQFs", "stockmargin", "Experimental_Crypto", "Crypto US ETFs", "Crypto UCITS ETFs". Modified by Trade.UpdateTradingInstrumentGroupName. |
| 3 | Description | varchar(200) | YES | - | VERIFIED | Optional free-text description of the group's purpose. NULL for many groups. Examples: "Instruments Not allowed in US", "MaxNOPLimit", "Crypto Futures", "UI Configurations for SQFs", "'Cross border Settings". |
| 4 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | SQL Server login that performed the DML, captured via `suser_name()` computed column on source. Examples: `TRAD\eladav` (domain developer account), `DevTradingSTG` (service account), `trading-opstool-api` (Operations Tool API service account). NULL if suser_name() was unavailable. |
| 5 | AppLoginName | varchar(500) | YES | - | VERIFIED | Application-level user identity, captured via `CONVERT(varchar(500), context_info())` computed column. Set by the application using `SET CONTEXT_INFO` before executing DML. Contains the end-user's email address padded with null bytes (e.g., "opstest01@etoro.com\0\0\0..."). NULL when context_info not set (direct SSMS access or scripts). Must be trimmed with REPLACE/RTRIM to remove null padding. |
| 6 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this version of the group became active in Dictionary.TradingInstrumentGroups. Equal to SysEndTime for INSERT-triggered zero-duration rows. Managed by SQL Server temporal system-versioning. |
| 7 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this version was superseded (updated or deleted). Clustered index leading column. Equal to SysStartTime for INSERT-triggered zero-duration rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | Dictionary.TradingInstrumentGroups | Temporal | This row is a historical version of the source table row with matching GroupID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.TradingInstrumentGroups | (all columns) | Temporal (SYSTEM_VERSIONING) | Source table - SQL Server automatically writes superseded rows here |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.DictionaryTradingInstrumentGroups (table)
- Temporal history leaf node - no code-level dependencies
- Populated automatically from Dictionary.TradingInstrumentGroups (table)
- INSERT trigger on source creates additional zero-duration history rows
```

### 6.1 Objects This Depends On

No dependencies. Temporal history table populated automatically by SQL Server.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.TradingInstrumentGroups | Table | Source table - SQL Server writes old row versions here automatically on UPDATE/DELETE; INSERT trigger also generates zero-duration rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_DictionaryTradingInstrumentGroups | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

**Filegroup**: [DICTIONARY] - matching source table, consistent with reference data classification.
**Storage**: DATA_COMPRESSION = PAGE (table-level and index-level).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| None | - | Temporal history tables cannot have PK, UNIQUE, FK, or CHECK constraints in SQL Server |

---

## 8. Sample Queries

### 8.1 What groups were active on a specific date
```sql
-- Groups active as of 2025-11-01
SELECT GroupID, GroupName, Description, SysStartTime, SysEndTime
FROM [History].[DictionaryTradingInstrumentGroups] WITH (NOLOCK)
WHERE '2025-11-01' BETWEEN SysStartTime AND SysEndTime
  AND SysStartTime < SysEndTime  -- exclude zero-duration INSERT artifacts
ORDER BY GroupID
```

### 8.2 Full change history for a specific group
```sql
-- All versions of GroupID=4 (US_Restricted)
SELECT GroupID, GroupName, Description, DbLoginName,
       REPLACE(RTRIM(AppLoginName), CHAR(0), '') AS AppLoginName_Clean,
       SysStartTime, SysEndTime,
       DATEDIFF(SECOND, SysStartTime, SysEndTime) AS DurationSeconds
FROM [History].[DictionaryTradingInstrumentGroups] WITH (NOLOCK)
WHERE GroupID = 4
ORDER BY SysStartTime
UNION ALL
-- Current version
SELECT GroupID, GroupName, Description, DbLoginName,
       REPLACE(RTRIM(CONVERT(varchar(500), context_info())), CHAR(0), '') AS AppLoginName_Clean,
       SysStartTime, SysEndTime,
       NULL AS DurationSeconds
FROM [Dictionary].[TradingInstrumentGroups] WITH (NOLOCK)
WHERE GroupID = 4
```

### 8.3 Audit - which users made changes and when (excluding QA automation)
```sql
SELECT DbLoginName,
       REPLACE(RTRIM(AppLoginName), CHAR(0), '') AS AppLoginName_Clean,
       COUNT(*) AS ChangeCount,
       MIN(SysStartTime) AS FirstChange, MAX(SysEndTime) AS LastChange
FROM [History].[DictionaryTradingInstrumentGroups] WITH (NOLOCK)
WHERE SysStartTime < SysEndTime  -- exclude zero-duration INSERT artifacts
  AND GroupName NOT LIKE 'QaAutomation%'
GROUP BY DbLoginName, REPLACE(RTRIM(AppLoginName), CHAR(0), '')
ORDER BY ChangeCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.DictionaryTradingInstrumentGroups | Type: Table | Source: etoro/etoro/History/Tables/History.DictionaryTradingInstrumentGroups.sql*
