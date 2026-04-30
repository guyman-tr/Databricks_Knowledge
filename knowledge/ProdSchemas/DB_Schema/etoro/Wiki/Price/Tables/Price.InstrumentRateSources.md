# Price.InstrumentRateSources

> Configuration table that maps each trading instrument to one or more price data sources with a priority order, defining which market data feeds the pricing engine queries first, second, and so on for each instrument.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | InstrumentRateSourceID (int IDENTITY, CLUSTERED PK) |
| **Partition** | Yes - MAIN partition scheme on InstrumentRateSourceID |
| **Indexes** | 2 (PK clustered + NC on InstrumentID) |

---

## 1. Business Meaning

InstrumentRateSources defines the price feed routing for every instrument in the system. Each row assigns a specific rate source (Price.AccountRateSource) to a specific instrument (Trade.Instrument) at a specific priority level. When the pricing engine needs a price for an instrument, it queries the primary source (Priority=10) first; if unavailable, falls back to the secondary (Priority=20), then tertiary (Priority=30), then quaternary (Priority=40). This multi-source design provides resilience against feed outages and enables instrument-level control over data providers.

With 656 rows spanning all active instruments and 2-4 sources per instrument, this table is the central routing table of the Price schema. It is consumed by multiple views (GetInstrumentRateSources, GetInstrumentAllocationData, GetTopRateSourceAllocations) that the pricing engine and allocation systems rely on.

Data lifecycle: the table supports two write patterns. Incremental updates are handled by `Price.InstrumentRateSourceAdd` (upsert: inserts new mappings or updates priority of existing ones) and `Price.InstrumentRateSourceEdit` (priority-only update). Bulk refresh is performed by `Price.UpdateInstrumentRateSources` which completely truncates the table and repopulates from `Price.GetInstrumentPriceSources` - this enables automated reconfiguration when the base view's source logic changes. System versioning tracks all changes in History.InstrumentRateSources.

---

## 2. Business Logic

### 2.1 Priority-Based Rate Source Routing

**What**: Each instrument can have up to 4 rate sources assigned at different priority tiers, enabling fallback routing when a primary source is unavailable.

**Columns/Parameters Involved**: `InstrumentID`, `AccountRateSourceID`, `Priority`

**Rules**:
- Priority=10: primary source (75% of all rows - queried first)
- Priority=20: secondary fallback (18% of rows)
- Priority=30: tertiary fallback (6% of rows)
- Priority=40: quaternary fallback (< 1% of rows - used for most critical instruments only)
- The combination (InstrumentID, AccountRateSourceID) is logically unique - InstrumentRateSourceAdd enforces this via upsert logic
- `Price.GetTopRateSourceAllocations` uses ROW_NUMBER() PARTITION BY InstrumentID ORDER BY Priority ASC WHERE Row=1 to isolate the primary source per instrument
- Lower Priority value = higher precedence (10 ranks before 20)

**Diagram**:
```
InstrumentID -> [Priority 10 source] -> primary price feed query
             -> [Priority 20 source] -> fallback if primary unavailable
             -> [Priority 30 source] -> second fallback
             -> [Priority 40 source] -> last resort (rare)

GetTopRateSourceAllocations: only returns Row=1 (lowest priority value per instrument)
GetInstrumentRateSources:    returns all rows with IsBenchmark flag and Quality
GetInstrumentAllocationData: returns all rows with liquidity account mapping + IsBenchmark
```

### 2.2 Upsert Pattern via InstrumentRateSourceAdd

**What**: The add procedure enforces a logical uniqueness constraint: each (instrument, source) combination can only exist once, with priority being the only mutable attribute.

**Columns/Parameters Involved**: `InstrumentID`, `AccountRateSourceID`, `Priority`

**Rules**:
- INSERT only if (InstrumentID, AccountRateSourceID) does not already exist in the table
- If already exists: call InstrumentRateSourceEdit to update Priority to the new value
- This means "adding" a source that already exists silently becomes a priority update
- Error 60000 is raised on any DML failure

### 2.3 Bulk Refresh via UpdateInstrumentRateSources

**What**: The complete table can be wiped and rebuilt from the Price.GetInstrumentPriceSources view in a single atomic transaction.

**Columns/Parameters Involved**: `InstrumentID`, `AccountRateSourceID`, `Priority`

**Rules**:
- `Price.UpdateInstrumentRateSources` executes DELETE FROM followed by INSERT INTO ... SELECT from GetInstrumentPriceSources
- This resets ALL instrument-source mappings in one operation - used for schema-wide reconfiguration
- Wrapped in a TRY/CATCH with ROLLBACK on failure, ensuring atomicity
- PriceServerID is NOT populated by this bulk refresh (set by IDENTITY only as NULL)
- After a bulk refresh, all InstrumentRateSourceIDs change (IDENTITY increments)

---

## 3. Data Overview

| InstrumentRateSourceID | InstrumentID | AccountRateSourceID | Priority | Meaning |
|---|---|---|---|---|
| 605008 | 1 (EUR/USD) | 21 (FD/EtoroAll) | 10 | EUR/USD primary price source is FD (EtoroAll broker). The lowest priority number = first queried. |
| 605009 | 1 (EUR/USD) | 301 (QuantHouse NDF) | 30 | EUR/USD tertiary fallback source is QuantHouse NDF feed. Only used if FD and secondary unavailable. |
| 604418 | 3 | 21 (FD) | 10 | Instrument 3 primary source is FD - same pattern as most forex instruments. |
| 604419 | 3 | 300 (QuantHouse MBL) | 20 | Instrument 3 secondary source is QuantHouse MBL, providing a different feed technology as backup. |
| 605083 | 5 | 102 (QuantHouse MBO) | 20 | Instrument 5 secondary is QuantHouse MBO - different QuantHouse feed variant as fallback. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentRateSourceID | int IDENTITY(1,1) | NOT NULL | auto | VERIFIED | Surrogate primary key. Auto-incremented integer assigned at INSERT. After a bulk refresh via UpdateInstrumentRateSources, all IDs are reassigned (DELETE + re-INSERT). Not semantically meaningful - use (InstrumentID, AccountRateSourceID) as the logical key. |
| 2 | PriceServerID | int | YES | - | CODE-BACKED | Deprecated/unused column. All 656 rows have NULL. Originally may have designated which price server instance was responsible for this source mapping. No procedures currently write to this column; UpdateInstrumentRateSources bulk refresh does not populate it. Can be ignored in queries. |
| 3 | InstrumentID | int | NOT NULL | - | VERIFIED | FK to Trade.Instrument. The instrument for which this rate source applies. Indexed (IX_InstrumentID) for fast lookup. One instrument typically has 2-4 rows in this table - one per source tier. (Trade.Instrument) |
| 4 | AccountRateSourceID | int | NOT NULL | - | VERIFIED | FK to Price.AccountRateSource. Identifies the specific market data provider assigned to this instrument at this priority. The Name in AccountRateSource (e.g., "FD/EtoroAll", "QuantHouse MBL", "Bloomberg RAW") describes the actual feed. (Price.AccountRateSource) |
| 5 | Priority | int | YES | - | VERIFIED | Feed priority ordering within an instrument's source list. Lower value = higher precedence: 10=primary (75% of rows), 20=secondary (18%), 30=tertiary (6%), 40=quaternary (<1%). The pricing engine queries in ascending priority order. Only Priority is mutable after INSERT (via InstrumentRateSourceEdit). |
| 6 | DbLoginName | varchar (computed) | NOT NULL | suser_name() | CODE-BACKED | Computed: SQL Server login of last row modifier. Auto-set on every DML. Used for DB-level audit tracking. |
| 7 | AppLoginName | varchar(500) (computed) | YES | context_info() | CODE-BACKED | Computed: application identity from SQL Server context_info(). Populated when calling service sets context_info before DML. NULL when not set. |
| 8 | SysStartTime | datetime2(7) | NOT NULL | getutcdate() | CODE-BACKED | Temporal period start. Auto-managed by SQL Server system versioning. Use FOR SYSTEM_TIME AS OF to query historical configurations. |
| 9 | SysEndTime | datetime2(7) | NOT NULL | '9999-12-31 23:59:59.9999999' | CODE-BACKED | Temporal period end. Active rows = '9999-12-31...'. Historical row versions in History.InstrumentRateSources. |
| 10 | HostName | varchar (computed) | NOT NULL | host_name() | CODE-BACKED | Computed: hostname of the SQL Server connection that performed the last DML. Complements DbLoginName and AppLoginName for audit tracking. Not present in AccountRateSource - unique to this table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK (FK_TRIN_PIRS) | The instrument being configured with a price source |
| AccountRateSourceID | Price.AccountRateSource | FK (FK_PARS_PIRS) | The rate source assigned to this instrument at this priority. See AccountRateSource for the full list of providers. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.GetInstrumentRateSources | InstrumentID, AccountRateSourceID | JOIN | Returns all source mappings with names, IsBenchmark flag, and Quality score |
| Price.GetInstrumentAllocationData | InstrumentID, AccountRateSourceID | JOIN via CTE | Returns source mapping with liquidity account and IsBenchmark flag; used for allocation analysis |
| Price.GetTopRateSourceAllocations | InstrumentID, Priority | JOIN via CTE | Returns only the primary (lowest priority) source per instrument with its liquidity account |
| Price.InstrumentRateSourceAdd | InstrumentID, AccountRateSourceID | WRITER (UPSERT) | Inserts new instrument-source mapping or updates existing one's priority |
| Price.InstrumentRateSourceEdit | InstrumentRateSourceID | MODIFIER | Updates Priority only for an existing mapping |
| Price.UpdateInstrumentRateSources | InstrumentID, AccountRateSourceID, Priority | DELETER + WRITER | Bulk refresh: deletes all rows and repopulates from GetInstrumentPriceSources |
| Price.CleanUnmappedInstrumentRateSources | InstrumentID, AccountRateSourceID | DELETER | Removes stale mappings for instruments no longer active |
| Price.DelistInstrument | InstrumentID | DELETER | Removes all source mappings for a delisted instrument |
| Price.GetPriceAllocationDiscrepancy | InstrumentID, AccountRateSourceID | READER | Compares configured sources against actual allocation for discrepancy detection |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.InstrumentRateSources (table)
|- Trade.Instrument (table, FK target - leaf)
|- Price.AccountRateSource (table, FK target - leaf)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK target - InstrumentID must reference a valid instrument |
| Price.AccountRateSource | Table | FK target - AccountRateSourceID must reference a valid rate source |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.GetInstrumentRateSources | View | Base table - provides all instrument-source mappings with enriched display data |
| Price.GetInstrumentAllocationData | View | CTE source - provides instrument-source-priority for allocation analysis |
| Price.GetTopRateSourceAllocations | View | CTE source - provides primary source per instrument (WHERE Row=1) |
| Price.InstrumentRateSourceAdd | Stored Procedure | UPSERT writer - inserts or priority-updates mappings |
| Price.InstrumentRateSourceEdit | Stored Procedure | Priority modifier - only updates Priority column |
| Price.UpdateInstrumentRateSources | Stored Procedure | Bulk refresh writer - DELETE all + INSERT from GetInstrumentPriceSources |
| Price.CleanUnmappedInstrumentRateSources | Stored Procedure | Cleanup deleter - removes stale mappings |
| Price.DelistInstrument | Stored Procedure | Cascade deleter - removes mappings when instrument is delisted |
| Price.GetPriceAllocationDiscrepancy | Stored Procedure | Reader - compares configured vs actual source allocations |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TIRSID | CLUSTERED PK | InstrumentRateSourceID ASC | - | - | Active |
| IX_InstrumentID | NONCLUSTERED | InstrumentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TIRSID | PRIMARY KEY | Surrogate PK on IDENTITY column |
| FK_TRIN_PIRS | FK | InstrumentID -> Trade.Instrument(InstrumentID) |
| FK_PARS_PIRS | FK | AccountRateSourceID -> Price.AccountRateSource(AccountRateSourceID) |
| DF_InstrumentRateSources_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_InstrumentRateSources_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| SYSTEM_VERSIONING = ON | Temporal | Full history in History.InstrumentRateSources |
| TRG_T_InstrumentRateSources | TRIGGER (INSERT) | ASM no-op: self-update on InstrumentID after insert |

---

## 8. Sample Queries

### 8.1 View all rate sources for a specific instrument with priority order

```sql
SELECT
    IRS.InstrumentRateSourceID,
    IRS.InstrumentID,
    IRS.AccountRateSourceID,
    ARS.Name AS SourceName,
    IRS.Priority,
    IRS.SysStartTime AS ConfiguredSince
FROM Price.InstrumentRateSources IRS WITH (NOLOCK)
JOIN Price.AccountRateSource ARS WITH (NOLOCK)
    ON ARS.AccountRateSourceID = IRS.AccountRateSourceID
WHERE IRS.InstrumentID = 1  -- replace with specific InstrumentID
ORDER BY IRS.Priority;
```

### 8.2 Find all instruments that use a specific rate source

```sql
SELECT
    IRS.InstrumentID,
    IRS.Priority,
    ARS.Name AS SourceName
FROM Price.InstrumentRateSources IRS WITH (NOLOCK)
JOIN Price.AccountRateSource ARS WITH (NOLOCK)
    ON ARS.AccountRateSourceID = IRS.AccountRateSourceID
WHERE IRS.AccountRateSourceID = 21  -- replace with specific AccountRateSourceID
ORDER BY IRS.Priority, IRS.InstrumentID;
```

### 8.3 Get primary rate source per instrument (simulate GetTopRateSourceAllocations)

```sql
WITH IRS AS (
    SELECT
        InstrumentID,
        AccountRateSourceID,
        Priority,
        ROW_NUMBER() OVER (PARTITION BY InstrumentID ORDER BY Priority ASC) AS RowNum
    FROM Price.InstrumentRateSources WITH (NOLOCK)
)
SELECT
    IRS.InstrumentID,
    IRS.AccountRateSourceID,
    ARS.Name AS PrimarySourceName,
    IRS.Priority
FROM IRS
JOIN Price.AccountRateSource ARS WITH (NOLOCK)
    ON ARS.AccountRateSourceID = IRS.AccountRateSourceID
WHERE IRS.RowNum = 1
ORDER BY IRS.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 3, 4, 5, 7, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.InstrumentRateSources | Type: Table | Source: etoro/etoro/Price/Tables/Price.InstrumentRateSources.sql*
