# History.PriceAlgoSkewConditions

> Temporal history table storing all past versions of Price.PriceAlgoSkewConditions - the volume and customer count thresholds that activate price skewing for an instrument.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - clustered on (SysEndTime, SysStartTime) |
| **Partition** | No (ON [PRIMARY] filegroup) |
| **Indexes** | 1 (1 clustered) |

---

## 1. Business Meaning

`History.PriceAlgoSkewConditions` is the **temporal history backing table** for `Price.PriceAlgoSkewConditions`. SQL Server's system-versioned temporal tables automatically move old rows here whenever the live table is updated or deleted. This table is never written to directly - it is maintained entirely by the SQL Server temporal table mechanism.

The live table `Price.PriceAlgoSkewConditions` defines per-instrument activation conditions for the price skewing algorithm: a minimum number of customers (`MinCIDCount`) and a minimum trading volume in USD (`MinVolumeUSD`) that must be met before price skewing is applied. When these thresholds are changed, the old configuration is automatically versioned into this history table, preserving the full audit trail of when and by whom the conditions were modified (`DbLoginName`, `AppLoginName`).

This history table enables point-in-time queries such as "what were the skew activation thresholds for instrument X on date Y?" - critical for investigating past pricing decisions and ensuring regulatory compliance.

---

## 2. Business Logic

### 2.1 SQL Server Temporal Table - Automatic Versioning

**What**: Every change to Price.PriceAlgoSkewConditions automatically writes the previous version here.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- `SysStartTime` = when this row became the active version in Price.PriceAlgoSkewConditions
- `SysEndTime` = when this row was superseded (updated or deleted) - set by SQL Server automatically
- Rows with `SysEndTime = '9999-12-31'` are the current active rows (still in the live table, not here)
- This table only contains EXPIRED rows (past versions)
- The live table Price.PriceAlgoSkewConditions has `SYSTEM_VERSIONING = ON (HISTORY_TABLE = History.PriceAlgoSkewConditions)`

**Diagram**:
```
Price.PriceAlgoSkewConditions (live - current versions)
    System Versioning (SQL Server auto-manages)
    |
    v
History.PriceAlgoSkewConditions (this table - expired versions)
    SysStartTime = when row became active
    SysEndTime   = when row was changed/deleted
```

### 2.2 Price Skew Activation Conditions

**What**: Defines per-instrument conditions that must be met before price skewing is activated.

**Columns/Parameters Involved**: `InstrumentID`, `MinCIDCount`, `MinVolumeUSD`

**Rules**:
- `MinCIDCount`: minimum number of unique customers required before skew is applied for this instrument
- `MinVolumeUSD`: minimum total trading volume in USD required before skew is applied
- Both conditions must typically be met simultaneously to activate skewing
- Price skewing adjusts bid/ask spread to manage eToro's net position risk exposure

---

## 3. Data Overview

Table is empty (0 rows) in current environment. This means either Price.PriceAlgoSkewConditions has never been modified since system-versioning was enabled, or versioning was enabled recently with no prior modifications. A typical historical row would look like:

| InstrumentID | MinCIDCount | MinVolumeUSD | DbLoginName | AppLoginName | SysStartTime | SysEndTime | Meaning |
|---|---|---|---|---|---|---|---|
| 50 | 100 | 500000.00 | etoro\trader_ops | PricingService v2.1 | 2024-01-15 09:00:00 | 2024-06-01 14:30:00 | Old skew conditions for instrument 50, active for ~5 months before being updated |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Financial instrument this skew condition applies to. Implicit FK to instrument lookup. Inherited from Price.PriceAlgoSkewConditions. |
| 2 | MinCIDCount | int | NO | - | CODE-BACKED | Minimum number of unique customers with open positions in this instrument required to activate price skewing. If the actual count is below this threshold, no skewing is applied. Inherited from Price.PriceAlgoSkewConditions. |
| 3 | MinVolumeUSD | money | NO | - | CODE-BACKED | Minimum total open volume in USD for this instrument required to activate price skewing. Acts as a size filter - low volume instruments do not get skewed regardless of customer count. Inherited from Price.PriceAlgoSkewConditions. |
| 4 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL login name of the user who made the change that caused this row to be versioned. Captured by a trigger on Price.PriceAlgoSkewConditions (Price.Tr_T_PriceAlgoSkewConditions_INSERT per dependency data). Audit field. |
| 5 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application-level login or service identity that made the change. May contain service account names or application identifiers. Complements DbLoginName for full audit context. |
| 6 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this row version became active in Price.PriceAlgoSkewConditions. Set by SQL Server temporal table engine. Enables point-in-time reconstruction of the skew conditions. |
| 7 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this row was superseded (another UPDATE or DELETE happened in Price.PriceAlgoSkewConditions). Set by SQL Server temporal table engine. The validity period for this row version is [SysStartTime, SysEndTime). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Instrument lookup | Implicit | The financial instrument these skew conditions apply to |
| (all columns) | Price.PriceAlgoSkewConditions | Temporal | This is the history backing table for the live Price table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Server temporal engine | (auto) | System | Rows moved here automatically when Price.PriceAlgoSkewConditions is updated/deleted |
| Price.Tr_T_PriceAlgoSkewConditions_INSERT | Trigger | Related | Trigger on live table captures audit fields (DbLoginName, AppLoginName) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PriceAlgoSkewConditions (table)
(temporal history backing table - no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No dependencies. Written entirely by SQL Server temporal table engine.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.PriceAlgoSkewConditions | Table | Live table - SQL Server moves expired rows here automatically |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_PriceAlgoSkewConditions | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

*DATA_COMPRESSION=PAGE. Clustered on (SysEndTime, SysStartTime) - standard pattern for temporal history tables to optimize FOR SYSTEM_TIME AS OF queries.*

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Point-in-time skew conditions for all instruments (requires live table join)

```sql
-- Use SQL Server temporal syntax on the LIVE table (Price.PriceAlgoSkewConditions)
-- The database engine automatically reads from this history table as needed
SELECT InstrumentID, MinCIDCount, MinVolumeUSD, DbLoginName, SysStartTime, SysEndTime
FROM Price.PriceAlgoSkewConditions
FOR SYSTEM_TIME AS OF '2025-01-01 00:00:00'
```

### 8.2 Full version history for a specific instrument

```sql
SELECT InstrumentID, MinCIDCount, MinVolumeUSD, DbLoginName, AppLoginName, SysStartTime, SysEndTime
FROM History.PriceAlgoSkewConditions WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
ORDER BY SysStartTime ASC
```

### 8.3 All changes made in a date range

```sql
SELECT InstrumentID, MinCIDCount, MinVolumeUSD, DbLoginName, AppLoginName, SysStartTime, SysEndTime
FROM History.PriceAlgoSkewConditions WITH (NOLOCK)
WHERE SysEndTime >= @StartDate
  AND SysStartTime < @EndDate
ORDER BY SysEndTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 9.3/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PriceAlgoSkewConditions | Type: Table | Source: etoro/etoro/History/Tables/History.PriceAlgoSkewConditions.sql*
