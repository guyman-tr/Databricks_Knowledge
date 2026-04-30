# History.CopyTradeSettlementRestrictions

> Temporal system-versioned history table that stores the full audit trail of all changes (inserts, updates, deletes) made to copy-trade settlement restriction rules in Trade.CopyTradeSettlementRestrictions.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; rows identified by ID + SysStartTime + SysEndTime |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

This table is the **SQL Server temporal history store** for `Trade.CopyTradeSettlementRestrictions`. SQL Server automatically moves rows here whenever a restriction rule is updated or deleted in the source table. Each row in this table represents the state of a restriction rule during a specific time interval defined by `SysStartTime` (when that version became active) and `SysEndTime` (when it was superseded or deleted).

`Trade.CopyTradeSettlementRestrictions` is a configuration table that controls which copy-trade settlement types (real stock ownership vs CFD contracts) are allowed for specific combinations of country, regulation, account type, instrument type, exchange, instrument, or trading group. These rules are used by the SmartCopy and CopyTrader systems to enforce regulatory compliance - for example, restricting real-stock copy-trading for users in certain jurisdictions.

This history table enables compliance audit trails and point-in-time queries: regulators or risk teams can determine what restriction rules were in effect at any past date, who changed them, and when. The `DbLoginName` and `AppLoginName` columns capture the SQL and application-level identity of whoever modified each rule.

---

## 2. Business Logic

### 2.1 Temporal Versioning - How History Is Recorded

**What**: SQL Server automatically populates this table via system-versioning whenever a row in `Trade.CopyTradeSettlementRestrictions` is modified or deleted.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `ID`

**Rules**:
- When a restriction row is **updated**: SQL Server moves the old version to this history table with `SysEndTime` = the moment of update, and `SysStartTime` = when that version was first created.
- When a restriction row is **deleted**: SQL Server moves the row here with `SysEndTime` = the deletion timestamp. These rows represent restriction rules that no longer exist.
- When a restriction row is **inserted**: No history row is created (the current row in `Trade.CopyTradeSettlementRestrictions` IS the first version, with `SysEndTime = '9999-12-31'`).
- The clustered index on `(SysEndTime, SysStartTime)` optimizes temporal range queries (`FOR SYSTEM_TIME AS OF`, `BETWEEN`, `FROM ... TO`).

**Diagram**:
```
INSERT restriction rule
  -> Row enters Trade.CopyTradeSettlementRestrictions
     SysStart=NOW, SysEnd=9999-12-31

UPDATE restriction rule (e.g., change RestrictionTypeID)
  -> OLD row moves to History.CopyTradeSettlementRestrictions
     SysStart=original_insert_time, SysEnd=NOW
  -> NEW row stays in Trade.CopyTradeSettlementRestrictions
     SysStart=NOW, SysEnd=9999-12-31

DELETE restriction rule
  -> Row moves to History.CopyTradeSettlementRestrictions
     SysStart=original_insert_time, SysEnd=NOW
     (no current row remains in Trade table)
```

### 2.2 Restriction Scope - What Gets Restricted

**What**: Each restriction rule targets a specific asset scope defined by a combination of nullable dimension columns.

**Columns/Parameters Involved**: `InstrumentTypeID`, `ExchangeID`, `InstrumentID`, `GroupID`, `CountryID`, `RegulationID`, `AccountTypeID`, `RegistrationDate`

**Rules**:
- At least one of `InstrumentTypeID`, `ExchangeID`, `InstrumentID`, or `GroupID` must be NOT NULL (enforced by `CK_CopyTradeSettlementRestriction_Asset` on the source table).
- `CountryID`, `RegulationID`, `AccountTypeID`, and `RegistrationDate` are optional scoping dimensions - when NULL, the restriction applies regardless of that dimension.
- The unique constraint on the source table enforces that no two rules cover the exact same combination of all nine dimension columns.
- `RestrictionTypeID` determines what is blocked: 0=AllowedAll (whitelist), 1=RestrictedReal (block real stock copy-trades), 2=RestrictedCfd (block CFD copy-trades), 3=RestrictedAll (block all copy-trades).

**Diagram**:
```
Restriction rule targeting a specific instrument in a country:
  CountryID=55 (e.g., US), InstrumentID=1234, RestrictionTypeID=1 (RestrictedReal)
  -> US users cannot copy-trade real shares of instrument 1234

Restriction rule targeting all stocks on an exchange for a regulation:
  RegulationID=3, ExchangeID=7, InstrumentTypeID=NULL, RestrictionTypeID=3 (RestrictedAll)
  -> Users under regulation 3 cannot copy-trade any asset on exchange 7
```

### 2.3 Audit Identity Capture

**What**: The source table captures who made each change via computed columns that persist into history.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`

**Rules**:
- `DbLoginName` = `suser_name()` - the SQL Server login executing the change (computed on source table, stored as static value in history).
- `AppLoginName` = `CONVERT(varchar(500), context_info())` - the application-level username, set via `SET CONTEXT_INFO` by callers (e.g., `Trade.InsertCopyTradeSettlementRestrictions` accepts `@AppLoginName` and sets it).
- The INSERT trigger `TRG_T_CopyTradeSettlementRestrictions` on the source table performs a self-update (`SET CountryID=CountryID`) after every INSERT - this forces SQL Server temporal to generate a history record capturing the initial state with correct `DbLoginName`/`AppLoginName` values at insert time.

---

## 3. Data Overview

The table currently contains 0 rows (no historical changes have been recorded in this environment). Rows are populated automatically by SQL Server as restriction rules in `Trade.CopyTradeSettlementRestrictions` are modified over time. A representative row would look like:

| ID | RestrictionTypeID | InstrumentID | CountryID | SysStartTime | SysEndTime | Meaning |
|----|------------------|-------------|-----------|-------------|------------|---------|
| 42 | 1 | 1234 | 55 | 2024-01-15 10:30:00 | 2024-06-20 14:00:00 | A rule restricting real-stock copy-trading for instrument 1234 in country 55, which was active from Jan 2024 until it was modified or deleted in June 2024. |
| 42 | 3 | 1234 | 55 | 2024-06-20 14:00:00 | 9999-12-31... | The updated version of the same rule (now RestrictedAll), still currently active. This version would be in Trade.CopyTradeSettlementRestrictions, NOT in this history table. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | YES | - | CODE-BACKED | Scoping dimension: restricts this rule to users from a specific country. FK to Dictionary.Country. NULL = rule applies regardless of country. Used as a join key in Trade.GetSmartCopyRestrictions -> Dictionary.Country. |
| 2 | RegulationID | int | YES | - | CODE-BACKED | Scoping dimension: restricts this rule to users under a specific regulatory regime. FK to Dictionary.Regulation (ID column). NULL = rule applies regardless of regulation. Used as a join key in Trade.GetSmartCopyRestrictions -> Dictionary.Regulation. |
| 3 | InstrumentTypeID | int | YES | - | CODE-BACKED | Scoping dimension: restricts this rule to a specific instrument type (e.g., stocks, crypto, forex). FK to Dictionary.CurrencyType (CurrencyTypeID column). NULL = rule applies to all instrument types within other scope constraints. |
| 4 | ExchangeID | int | YES | - | CODE-BACKED | Scoping dimension: restricts this rule to instruments listed on a specific exchange. FK to Dictionary.ExchangeInfo (ExchangeID column). NULL = rule applies regardless of exchange. |
| 5 | InstrumentID | int | YES | - | CODE-BACKED | Scoping dimension: restricts this rule to a single specific instrument. FK to Trade.InstrumentMetaData (InstrumentID column). NULL = rule applies to all instruments within other scope constraints. |
| 6 | RestrictionTypeID | tinyint | NO | - | VERIFIED | The type of copy-trade settlement restriction being applied: 0=AllowedAll (no restriction - used as whitelist override), 1=RestrictedReal (block real stock copy-trades only), 2=RestrictedCfd (block CFD copy-trades only), 3=RestrictedAll (block all copy-trades). FK to Dictionary.RestrictionType. Validated on insert by Trade.InsertCopyTradeSettlementRestrictions. |
| 7 | ID | int | NO | - | CODE-BACKED | Surrogate primary key of the restriction rule in Trade.CopyTradeSettlementRestrictions. Carried into history to identify which rule this historical version belongs to. IDENTITY on source table. |
| 8 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | The SQL Server login name that performed the insert/update/delete on the source table. Computed on source table as suser_name() - captures the database-level identity. Stored as a static value when the row moves to history. |
| 9 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | The application-level username that performed the change. Computed on source table as CONVERT(varchar(500), context_info()). Set by callers via SET CONTEXT_INFO before executing Trade.InsertCopyTradeSettlementRestrictions (via @AppLoginName parameter). Empty string if not set by caller. |
| 10 | SysStartTime | datetime2(7) | NO | - | VERIFIED | The UTC timestamp when this version of the restriction rule became active (i.e., when the row was inserted or last updated in Trade.CopyTradeSettlementRestrictions). Managed by SQL Server temporal system-versioning. Used as lower bound in FOR SYSTEM_TIME queries. |
| 11 | SysEndTime | datetime2(7) | NO | - | VERIFIED | The UTC timestamp when this version of the restriction rule was superseded (modified or deleted). Managed by SQL Server temporal system-versioning. Rows with SysEndTime = '9999-12-31...' are current (still in Trade table). Clustered index leading column for efficient temporal range lookups. |
| 12 | UnblockReasonId | int | YES | - | CODE-BACKED | The reason code explaining why this restriction was (or could be) removed. FK to Dictionary.BlockUnBlockReason (ID column). Values include: 1=Requested by BO Admin, 2=High Risk Score, 3=Employee Account, 4=OPT OUT, 5=OPT IN, 6=Not Verified, 7=Verified, 8=Requested by KYC, 9=Liquidation, 10=Liquidation Remove. NULL = no specific unblock reason recorded. |
| 13 | GroupID | int | YES | - | CODE-BACKED | Scoping dimension: restricts this rule to instruments in a specific trading group (e.g., a custom portfolio group). FK to Dictionary.TradingInstrumentGroups (GroupID column). NULL = rule applies regardless of trading group. |
| 14 | RegistrationDate | datetime | YES | - | NAME-INFERRED | Scoping dimension: restricts this rule to users with a specific registration date. Exact matching semantics (not a range). NULL = rule applies regardless of registration date. Not populated by Trade.InsertCopyTradeSettlementRestrictions - may be set via direct insert or a different path. |
| 15 | AccountTypeID | int | YES | - | CODE-BACKED | Scoping dimension: restricts this rule to users of a specific account type. FK to Dictionary.AccountType. Sample values: 2=Corporate, 6=Affiliate Private Account, 13=Analyst, 15=Affiliate Corporate Account, 16=Administrated Account. NULL = rule applies regardless of account type. Added after initial table creation (not in INSERT SP). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Implicit | Country scoping for the restriction rule |
| RegulationID | Dictionary.Regulation | Implicit | Regulatory jurisdiction scoping |
| InstrumentTypeID | Dictionary.CurrencyType | Implicit | Instrument type scoping (uses CurrencyTypeID column) |
| ExchangeID | Dictionary.ExchangeInfo | Implicit | Exchange scoping |
| InstrumentID | Trade.InstrumentMetaData | Implicit | Single-instrument scoping |
| RestrictionTypeID | Dictionary.RestrictionType | Implicit | Type of copy-trade settlement restriction |
| UnblockReasonId | Dictionary.BlockUnBlockReason | Implicit | Reason for removing the restriction |
| GroupID | Dictionary.TradingInstrumentGroups | Implicit | Trading group scoping |
| AccountTypeID | Dictionary.AccountType | Implicit | Account type scoping |
| ID | Trade.CopyTradeSettlementRestrictions | Temporal | This row is a historical version of the source table row with this ID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CopyTradeSettlementRestrictions | (all columns) | Temporal (SYSTEM_VERSIONING) | Source table - SQL Server automatically writes superseded rows here |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CopyTradeSettlementRestrictions (table)
- This is a temporal history table. It is a leaf node with no code-level dependencies.
- Populated automatically by SQL Server from Trade.CopyTradeSettlementRestrictions (table)
```

### 6.1 Objects This Depends On

No dependencies. This is a temporal history table populated automatically by SQL Server's system-versioning mechanism - no CREATE TABLE dependencies on other objects within History schema.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CopyTradeSettlementRestrictions | Table | Source table - SQL Server writes old row versions here automatically on UPDATE/DELETE |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_CopyTradeSettlementRestrictions | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| None | - | Temporal history tables cannot have PK, UNIQUE, FK, or CHECK constraints in SQL Server |

**Storage**: DATA_COMPRESSION = PAGE (matches source table compression setting)

---

## 8. Sample Queries

### 8.1 View current restriction rules with human-readable labels
```sql
SELECT
    r.ID,
    r.RestrictionTypeID,
    rt.RestrictionTypeName,
    r.InstrumentID,
    r.CountryID,
    c.Name AS Country,
    r.RegulationID,
    reg.Name AS Regulation,
    r.SysStartTime,
    r.SysEndTime
FROM [Trade].[CopyTradeSettlementRestrictions] r WITH (NOLOCK)
INNER JOIN [Dictionary].[RestrictionType] rt WITH (NOLOCK)
    ON r.RestrictionTypeID = rt.RestrictionTypeID
LEFT JOIN [Dictionary].[Country] c WITH (NOLOCK)
    ON r.CountryID = c.CountryID
LEFT JOIN [Dictionary].[Regulation] reg WITH (NOLOCK)
    ON r.RegulationID = reg.ID
```

### 8.2 Point-in-time query - what restrictions were active on a specific date
```sql
SELECT *
FROM [Trade].[CopyTradeSettlementRestrictions]
FOR SYSTEM_TIME AS OF '2024-06-01 00:00:00'
WHERE InstrumentID = 1234
```

### 8.3 Full audit trail for a specific restriction rule
```sql
-- Show all versions of rule ID=42 (current + history combined)
SELECT ID, RestrictionTypeID, CountryID, InstrumentID,
       DbLoginName, AppLoginName,
       SysStartTime, SysEndTime,
       'History' AS Source
FROM [History].[CopyTradeSettlementRestrictions] WITH (NOLOCK)
WHERE ID = 42
UNION ALL
SELECT ID, RestrictionTypeID, CountryID, InstrumentID,
       DbLoginName, AppLoginName,
       SysStartTime, SysEndTime,
       'Current' AS Source
FROM [Trade].[CopyTradeSettlementRestrictions] WITH (NOLOCK)
WHERE ID = 42
ORDER BY SysStartTime
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.9/10 (Elements: 9.3/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CopyTradeSettlementRestrictions | Type: Table | Source: etoro/etoro/History/Tables/History.CopyTradeSettlementRestrictions.sql*
