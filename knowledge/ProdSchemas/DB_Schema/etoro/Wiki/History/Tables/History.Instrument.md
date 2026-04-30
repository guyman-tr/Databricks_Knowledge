# History.Instrument

> SQL Server system-versioned temporal history table for Trade.Instrument, automatically recording every configuration change to trading instrument records with precise row-validity timestamps (SysStartTime/SysEndTime) to enable point-in-time reconstruction of any instrument's configuration state.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentID, SysStartTime, SysEndTime) - no formal PK; temporal history semantics |
| **Partition** | No |
| **Indexes** | 1 (CLUSTERED on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

This table is the automatically maintained historical version store for `Trade.Instrument`. SQL Server's system-versioning feature manages this table transparently: whenever a row in `Trade.Instrument` is inserted, updated, or deleted, SQL Server writes the previous row state here with SysStartTime/SysEndTime stamped to record the exact validity window. No application code writes directly to this table.

`Trade.Instrument` defines every tradeable instrument on eToro's platform - the currency pair composition (BuyCurrencyID, SellCurrencyID), trading parameters (TradeRange, DollarRatio), routing details (PriceServerID, ShardID), and operational status (OperationMode). Changes to these configurations - adding new instruments, changing price server assignments, modifying trading ranges - must be auditable, especially for compliance investigations of why certain trades were priced or routed differently on a specific date.

Additionally, `Trade.Instrument` has three DML triggers (AuditDelete, AuditInsert, AuditUpdate) that write changes to three columns (PipDifferenceThreshold, PriceServerID, ShardID) into `History.AuditHistory` as a separate column-level change log. The temporal versioning here provides full-row snapshots, while the trigger-based History.AuditHistory provides column-level change tracking for those three specific fields.

Data flows automatically: any UPDATE or DELETE on `Trade.Instrument` causes SQL Server to move the current row (with original SysStartTime and the change timestamp as SysEndTime) into this history table. To access history, use `Trade.Instrument FOR SYSTEM_TIME AS OF '...'` or `FOR SYSTEM_TIME ALL` - never query this table directly in production code.

---

## 2. Business Logic

### 2.1 SQL Server System-Versioned Temporal Table Pattern

**What**: SQL Server automatically manages row versioning between Trade.Instrument (current) and History.Instrument (historical versions), enabling point-in-time reconstruction of any instrument's configuration.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `InstrumentID`

**Rules**:
- SysStartTime = the UTC timestamp when this row version became active in Trade.Instrument
- SysEndTime = the UTC timestamp when this row version was superseded; current rows in Trade.Instrument have SysEndTime = '9999-12-31 23:59:59.9999999'
- A single InstrumentID may appear many times in this table (one entry per configuration change event)
- The CLUSTERED index on (SysEndTime ASC, SysStartTime ASC) is the standard SQL Server temporal history index pattern
- DbLoginName = suser_name() and AppLoginName = context_info() are computed columns in Trade.Instrument, materialized here at version creation, capturing WHO made the change

**Diagram**:
```
Trade.Instrument (current state):
  InstrumentID=100000, PriceServerID=5, OperationMode=0, SysEndTime='9999-12-31'

UPDATE Trade.Instrument SET PriceServerID=6 WHERE InstrumentID=100000:

History.Instrument receives (previous version):
  InstrumentID=100000, PriceServerID=5, SysStartTime='2026-03-05', SysEndTime='2026-03-13'

Trade.Instrument updated (new current):
  InstrumentID=100000, PriceServerID=6, SysStartTime='2026-03-13', SysEndTime='9999-12-31'
```

### 2.2 Dual Audit System - Temporal Versioning and Column-Level Triggers

**What**: Trade.Instrument employs two complementary audit mechanisms for a complete change history.

**Columns/Parameters Involved**: `PipDifferenceThreshold`, `PriceServerID`, `ShardID`, `SysStartTime`, `SysEndTime`

**Rules**:
- **Temporal versioning (this table)**: Full-row snapshots for every change to ANY column. Enables point-in-time reconstruction of the entire instrument configuration.
- **Trigger-based column log (History.AuditHistory)**: Three DML triggers (AuditDelete_Trade_Instrument, AuditInsert_Trade_Instrument, AuditUpdate_Trade_Instrument) track changes to exactly 3 columns: PipDifferenceThreshold, PriceServerID, ShardID. Writes old/new values individually to History.AuditHistory with UserName, AppName, Operation ('I'/'U'/'D').
- The 3 trigger-tracked columns are the most operationally sensitive: PipDifferenceThreshold controls volatility behavior, PriceServerID determines rate source routing, ShardID controls data partitioning.
- Both systems record together; for the 3 sensitive columns, History.AuditHistory provides compact before/after diffs while History.Instrument provides the full row context.

---

## 3. Data Overview

| InstrumentID | BuyCurrencyID | SellCurrencyID | SysStartTime | SysEndTime | OperationMode | DbLoginName | Meaning |
|---|---|---|---|---|---|---|---|
| 100000 | 100000 | 1 (USD) | 2026-03-05 | 2026-03-13 | 0 | TRAD\igorve | InstrumentID=BuyCurrencyID=100000 is a stock/asset instrument. Configuration was active for 8 days before being updated by igorve on 2026-03-13. |
| 1016 | 1016 | 1 (USD) | 2026-03-05 19:39 | 2026-03-05 21:45 | 0 | TRAD\gittysa | Short 2-hour window: InstrumentID=1016 was updated twice in the same day by gittysa, indicating a configuration adjustment that was corrected or refined on the same day. |
| 1053988 | 1053988 | 1 (USD) | 2026-02-17 | 2026-03-05 | 1 | TRAD\gittysa | OperationMode=1 (non-standard) version for a newer instrument (high ID). OMEID=NULL suggests no OMS entity assigned yet. PriceServerID=100 indicates a specific provider. |
| 1016586 | 1016586 | 2 (EUR) | 2026-02-17 | 2026-03-05 | 1 | TRAD\gittysa | SellCurrencyID=2 (EUR) - one of the few EUR-denominated instruments in the recent changes. OperationMode=1, no OMEID, PriceServerID=100. |
| 1050127 | 1050127 | 1 (USD) | 2026-02-12 | 2026-03-05 | 1 | TRAD\gittysa | One of many OperationMode=1 instruments added in Feb 2026. The batch of changes by gittysa suggests a coordinated instrument configuration rollout on 2026-02-17 and 2026-03-05. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Trading instrument identifier. Matches Trade.Instrument.InstrumentID (PK_TISR). Multiple rows with the same InstrumentID represent successive configuration versions. For stock/asset instruments, InstrumentID typically equals BuyCurrencyID. |
| 2 | BuyCurrencyID | int | NO | - | CODE-BACKED | The "buy" side currency of this instrument pair. FK to `Dictionary.Currency.CurrencyID` in Trade.Instrument (WITH CHECK). DEFAULT 0. For most instruments in live data, BuyCurrencyID equals InstrumentID - the instrument represents trading that currency/asset. For forex pairs, BuyCurrencyID is the base currency (e.g., EUR in EUR/USD). |
| 3 | SellCurrencyID | int | NO | - | CODE-BACKED | The "sell" side currency of this instrument pair. FK to `Dictionary.Currency.CurrencyID` in Trade.Instrument (WITH CHECK). DEFAULT 0. In live data, SellCurrencyID=1 (USD) for most instruments, SellCurrencyID=2 (EUR) for EUR-denominated pairs. Defines the quote currency. |
| 4 | TradeRange | smallint | NO | - | NAME-INFERRED | Maximum pip/tick movement range permitted for trade execution on this instrument. Observed values: 100 (most instruments) and 500 (older/major instruments). Controls how far from the current rate a fill can be accepted. |
| 5 | DollarRatio | decimal(8,2) | NO | - | NAME-INFERRED | Conversion ratio relating this instrument's unit value to USD. Value 1.0 observed for all recent data, suggesting most instruments are already USD-denominated or the ratio is managed elsewhere. May be used to normalize PnL calculations across different currency-denominated instruments. |
| 6 | Passport | timestamp | NO | - | CODE-BACKED | SQL Server `timestamp` (rowversion) - an automatically incrementing binary counter that changes with every row modification in Trade.Instrument. Not a date/time. Used for optimistic concurrency control: applications compare Passport values to detect if a row was modified since last read. Materialized from Trade.Instrument at version capture time. |
| 7 | PipDifferenceThreshold | bigint | YES | - | CODE-BACKED | Maximum allowable pip difference threshold for volatility/price discrepancy checks. Tracked by the AuditUpdate/Insert/Delete triggers on Trade.Instrument - changes to this column are individually logged to History.AuditHistory. NULL means no threshold is enforced. Value 32767 (max smallint) observed for one instrument, suggesting "unlimited" sentinel. 0 means strict no-gap enforcement. |
| 8 | IsMajor | bit | NO | - | CODE-BACKED | Whether this is a major instrument (1) or not (0). DEFAULT 0 in Trade.Instrument. IsMajor=1 instruments may receive preferential treatment in hedging (see Trade.HedgeServer.AllowMajor) and UI presentation. |
| 9 | PriceServerID | int | YES | - | CODE-BACKED | Which price server instance provides rate quotes for this instrument. Tracked by the AuditUpdate/Insert/Delete triggers - changes logged individually to History.AuditHistory. Values observed: 1, 5, 100. NULL means unassigned. PriceServerID routing changes are among the most operationally significant configuration events. |
| 10 | ShardID | int | NO | - | CODE-BACKED | Database sharding partition key for this instrument. Tracked by the AuditUpdate/Insert/Delete triggers - changes logged individually to History.AuditHistory. Values observed: 1 and 2. Controls which shard handles trading data for this instrument. |
| 11 | OMEID | int | YES | - | NAME-INFERRED | Order Management System entity identifier. Links this instrument to its counterpart entity in the OMS layer. Values observed: 2, 4, or NULL. NULL for newer instruments that may not yet have OMS entity assignments. |
| 12 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login name (suser_name()) of the session that made the configuration change captured in this version. Computed column in Trade.Instrument, materialized at version creation. Example: "TRAD\gittysa" or "TRAD\igorve" - identifies the operator who changed this instrument configuration. |
| 13 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application-level login from SQL Server context_info() at time of change. Populated by services that set context_info before modifying Trade.Instrument. NULL in all observed live data (applications did not set context_info). |
| 14 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version became active in Trade.Instrument. GENERATED ALWAYS AS ROW START on the source table. The instrument had this configuration from SysStartTime until SysEndTime. Precision to 100-nanosecond intervals. |
| 15 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version was superseded. GENERATED ALWAYS AS ROW END. CLUSTERED index leading column for efficient temporal range scans. SysStartTime=SysEndTime indicates a zero-duration version (INSERT immediately followed by UPDATE in the same transaction). |
| 16 | OperationMode | tinyint | YES | - | CODE-BACKED | Operational mode of the instrument. DEFAULT 0 in Trade.Instrument. Values observed: 0 (standard operation, most instruments) and 1 (alternative/restricted mode, seen in newer high-ID instruments added in Feb 2026). Exact semantics defined in the trading application configuration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. As a temporal history table, all FK constraints reside on `Trade.Instrument`. Temporal history tables intentionally have no FK constraints to avoid blocking historical row insertion.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.Instrument | SYSTEM_VERSIONING | Temporal history source | Trade.Instrument is configured with `SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[Instrument])`. All historical versions are automatically routed here by SQL Server. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Instrument (table)
- no code-level dependencies (leaf table, temporal history)
```

This object has no code-level dependencies. As a SQL Server-managed temporal history table, it is populated automatically by the database engine.

### 6.1 Objects This Depends On

No dependencies. Temporal history tables have no FK constraints or references.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | Source temporal table - SQL Server automatically writes previous row versions here on UPDATE/DELETE |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_Instrument | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (DATA_COMPRESSION=PAGE) |

No primary key constraint. The CLUSTERED index on (SysEndTime, SysStartTime) is the standard SQL Server temporal history index pattern. Table is on [PRIMARY] filegroup.

### 7.2 Constraints

None. Temporal history tables intentionally have no CHECK, UNIQUE, DEFAULT, or FOREIGN KEY constraints.

---

## 8. Sample Queries

### 8.1 What was an instrument's configuration on a specific date?

```sql
-- Use FOR SYSTEM_TIME on the source table, not this history table directly
SELECT
    i.InstrumentID,
    i.BuyCurrencyID,
    i.SellCurrencyID,
    i.PriceServerID,
    i.ShardID,
    i.OperationMode,
    i.IsMajor,
    i.SysStartTime,
    i.SysEndTime
FROM Trade.Instrument FOR SYSTEM_TIME AS OF '2024-01-15T00:00:00' i WITH (NOLOCK)
WHERE i.InstrumentID = @InstrumentID;
```

### 8.2 All configuration changes for a specific instrument

```sql
SELECT
    h.InstrumentID,
    h.SysStartTime AS ValidFrom,
    h.SysEndTime AS ValidUntil,
    h.PriceServerID,
    h.ShardID,
    h.OperationMode,
    h.PipDifferenceThreshold,
    h.DbLoginName AS ChangedBy,
    DATEDIFF(SECOND, h.SysStartTime, h.SysEndTime) AS VersionDurationSeconds
FROM History.Instrument h WITH (NOLOCK)
WHERE h.InstrumentID = @InstrumentID
ORDER BY h.SysStartTime ASC;
```

### 8.3 Find all instruments that changed price server assignment in a time window

```sql
SELECT
    h.InstrumentID,
    h.PriceServerID AS OldPriceServerID,
    curr.PriceServerID AS NewPriceServerID,
    h.SysEndTime AS ChangeTime,
    h.DbLoginName AS ChangedBy
FROM History.Instrument h WITH (NOLOCK)
JOIN Trade.Instrument curr WITH (NOLOCK) ON h.InstrumentID = curr.InstrumentID
WHERE h.SysEndTime >= @StartDate
  AND h.SysEndTime <  @EndDate
  AND h.PriceServerID <> curr.PriceServerID
ORDER BY h.SysEndTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 7.3/10 (Elements: 7.6/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Instrument | Type: Table | Source: etoro/etoro/History/Tables/History.Instrument.sql*
