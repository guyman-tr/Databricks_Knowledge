# History.PortfolioConversionConfiguration

> Superseded temporal history table (singular name, no HostName column) from the original version of the portfolio conversion configuration source table, before the source was renamed to Hedge.PortfolioConversionConfigurations and HostName audit capture was added. Currently empty.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No (PAGE compression) |
| **Indexes** | 1 (clustered on temporal system columns) |

---

## 1. Business Meaning

History.PortfolioConversionConfiguration (singular) is the predecessor temporal history table to History.PortfolioConversionConfigurations (plural). The two tables differ in one column: History.PortfolioConversionConfiguration lacks the `HostName` column that was added when the source table was updated and renamed.

The domain: Hedge.PortfolioConversionConfigurations maps a source instrument (InstrumentID) to a hedge instrument (InstrumentIDToHedge) with a conversion multiplier, enabling the hedging engine to calculate equivalent exposure for portfolio hedging operations. When the hedging engine needs to hedge exposure in one instrument using another (e.g., hedging an ETF using its underlying), this table provides the instrument pair and scaling factor.

This older history table is currently empty - it was either never populated or its data was migrated when the source table was renamed. The active history table is History.PortfolioConversionConfigurations (plural).

---

## 2. Business Logic

### 2.1 Temporal History Pattern

**What**: This table was intended to capture prior versions of the portfolio conversion configuration source table before the HostName column was added.

**Columns/Parameters Involved**: `InstrumentID`, `InstrumentIDToHedge`, `Multiplier`, `SysStartTime`, `SysEndTime`

**Rules**:
- Composite PK in the source table: (InstrumentID, InstrumentIDToHedge) - each instrument pair has one configuration row.
- Multiplier: scaling factor for the hedge exposure calculation (e.g., 1.0 = full hedge, 0 = not in use).
- SysStartTime=SysEndTime: INSERT-capture records from the TRG_T_PortfolioConversionConfigurations trigger.
- DbLoginName/AppLoginName: captured from SUSER_NAME()/CONTEXT_INFO() at write time in the source table. HostName is absent (added in the later version).

---

## 3. Data Overview

Table is currently empty - 0 rows in the live database. Superseded by History.PortfolioConversionConfigurations (plural) which is the active history table for Hedge.PortfolioConversionConfigurations.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The source trading instrument being converted for hedging. Part of the composite key from source table. FK to Trade.Instrument. |
| 2 | InstrumentIDToHedge | int | NO | - | CODE-BACKED | The target instrument used to hedge exposure from InstrumentID. Part of the composite key. FK to Trade.Instrument. |
| 3 | Multiplier | decimal(16,8) | NO | - | CODE-BACKED | Scaling factor applied when converting InstrumentID exposure to InstrumentIDToHedge hedge quantity. 1.0 = full 1:1 hedge; 0 = inactive/disabled mapping. |
| 4 | SysStartTime | datetime2(2) | NO | - | CODE-BACKED | UTC timestamp when this configuration version became active. SQL Server temporal period start column. datetime2(2) precision (10ms). |
| 5 | SysEndTime | datetime2(2) | NO | - | CODE-BACKED | UTC timestamp when this configuration version was superseded. SysStartTime=SysEndTime indicates INSERT-capture record. |
| 6 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login at write time, from SUSER_NAME() in the source table. Typically "TRAD\{username}" format. |
| 7 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application context at write time, from CONTEXT_INFO() in source. Set by ConfigurationManager before write. Padded with null bytes to 500 chars. Note: unlike the newer History.PortfolioConversionConfigurations, this table has NO HostName column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | Source instrument for portfolio conversion. FK enforced in source table. |
| InstrumentIDToHedge | Trade.Instrument | Implicit | Target hedge instrument. FK enforced in source table. |

### 5.2 Referenced By (other objects point to this)

No active source table writes to this history table. It was superseded when the source was renamed and HostName was added.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.PortfolioConversionConfigurations | Table | Successor - the active history table for the renamed/updated source table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_PortfolioConversionConfiguration | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

None. Temporal history tables have no PK or FK constraints.

### 7.3 Storage

| Property | Value |
|----------|-------|
| Filegroup | PRIMARY |
| Data Compression | PAGE |

---

## 8. Sample Queries

### 8.1 Check if legacy history table has any rows

```sql
SELECT COUNT(*) AS RowCount
FROM History.PortfolioConversionConfiguration WITH (NOLOCK);
```

### 8.2 Compare schema difference from newer version (HostName missing)

```sql
-- Old table: no HostName column
SELECT InstrumentID, InstrumentIDToHedge, Multiplier, DbLoginName, SysStartTime, SysEndTime
FROM History.PortfolioConversionConfiguration WITH (NOLOCK)
ORDER BY SysStartTime DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;

-- New table: has HostName column
SELECT InstrumentID, InstrumentIDToHedge, Multiplier, DbLoginName, HostName, SysStartTime, SysEndTime
FROM History.PortfolioConversionConfigurations WITH (NOLOCK)
ORDER BY SysStartTime DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PortfolioConversionConfiguration | Type: Table | Source: etoro/etoro/History/Tables/History.PortfolioConversionConfiguration.sql*
