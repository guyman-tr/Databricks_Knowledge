# Price.BenchmarkFeedConfiguration

> Configuration table that designates a specific rate source as the "benchmark" feed for each instrument type (CurrencyType), used by the pricing engine to flag benchmark vs. non-benchmark sources in instrument allocation views.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | (BenchmarkAccountRateSourceID, CurrencyTypeID) - composite CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 (PK clustered composite) |

---

## 1. Business Meaning

BenchmarkFeedConfiguration defines which rate source serves as the authoritative "benchmark" feed for a given instrument type. For each combination of a rate source (Price.AccountRateSource) and an instrument category (Dictionary.CurrencyType), a row in this table indicates that the source is designated as the benchmark for that category. This allows the pricing engine to distinguish between regular price sources and the single reference source for each category.

Without this table, all rate sources would appear equal in the instrument allocation views. The benchmark designation enables downstream systems to compare prices from secondary feeds against the benchmark, detect discrepancies, and apply quality weighting logic. The `Quality` column provides a numeric quality score for the designated benchmark source.

Data flows: rows are expected to be inserted via tooling or manual configuration when a rate source is promoted to benchmark status for an instrument type. Currently the table holds 0 rows (no benchmark designations configured). Views `Price.GetInstrumentRateSources` and `Price.GetInstrumentAllocationData` LEFT JOIN to this table to compute the `IsBenchmark` flag (0 or 1) and `Quality` (-1 when no benchmark configured) for each instrument-source combination. System versioning tracks all changes in `History.BenchmarkFeedConfiguration`.

---

## 2. Business Logic

### 2.1 Benchmark Designation Pattern

**What**: Each row marks one rate source as the benchmark for one instrument type. A source not in this table for a given type is a non-benchmark source.

**Columns/Parameters Involved**: `BenchmarkAccountRateSourceID`, `CurrencyTypeID`

**Rules**:
- The composite PK guarantees at most one Quality score per (source, type) combination
- Views derive `IsBenchmark = iif(BenchmarkAccountRateSourceID IS NULL, 0, 1)` via LEFT JOIN - NULL means no benchmark row matched (the source is not a benchmark for that type)
- A rate source can be benchmark for multiple CurrencyTypes (multiple rows with same BenchmarkAccountRateSourceID but different CurrencyTypeID)
- A CurrencyType can theoretically have multiple benchmark sources (no UNIQUE constraint on CurrencyTypeID alone), though business intent implies one per type

**Diagram**:
```
Price.InstrumentRateSources  <-- JOIN on AccountRateSourceID + InstrumentTypeID=CurrencyTypeID
         |
         | LEFT JOIN to Price.BenchmarkFeedConfiguration
         v
IsBenchmark = 1 (row found)   --> source IS the benchmark for this instrument type
IsBenchmark = 0 (no row)      --> source is NOT a benchmark for this instrument type
Quality = row.Quality          --> benchmark quality score
Quality = -1 (no row matched)  --> no benchmark configured, default fallback
```

### 2.2 Temporal Auditing via System Versioning

**What**: Every INSERT, UPDATE, and DELETE is tracked automatically in the history table and audit log.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- SysStartTime / SysEndTime are SQL Server temporal period columns - managed automatically
- SysEndTime = '9999-12-31...' = currently active row; rows in History.BenchmarkFeedConfiguration hold retired versions
- DbLoginName (computed: suser_name()) captures the SQL login at time of DML - cannot be overridden
- AppLoginName (computed: context_info()) captures the calling application identity when set via `SET CONTEXT_INFO`
- Audit triggers additionally write per-column change records to History.AuditHistory for application-level auditing

---

## 3. Data Overview

The table is currently empty (0 rows). No benchmark feed designations are active. Views that LEFT JOIN to this table will return IsBenchmark=0 and Quality=-1 for all instrument-source pairs until rows are inserted.

*When populated, rows would appear as:*

| BenchmarkAccountRateSourceID | CurrencyTypeID | Quality | Meaning |
|---|---|---|---|
| 196 | 5 | 90 | Bloomberg RAW designated as benchmark for Stocks (CurrencyTypeID=5); all Stocks instruments joining via GetInstrumentRateSources will show IsBenchmark=1, Quality=90 |
| 54 | 10 | 85 | GDAX/Coinbase designated as benchmark for Crypto (CurrencyTypeID=10); crypto instrument allocations will flag this source as the reference feed |
| 20 | 1 | 80 | Goldman Sachs designated as benchmark for Forex (CurrencyTypeID=1) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BenchmarkAccountRateSourceID | int | NOT NULL | - | VERIFIED | Part 1 of composite PK. References the rate source (Price.AccountRateSource) that is designated as the benchmark feed. Joined against Price.InstrumentRateSources.AccountRateSourceID in views to flag whether a given source is the benchmark for its instrument type. |
| 2 | CurrencyTypeID | int | NOT NULL | - | VERIFIED | Part 2 of composite PK. Identifies the instrument category for which this source is the benchmark: 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. Matched against Trade.Instrument.InstrumentTypeID in views (via `InstrumentTypeID = CurrencyTypeID`). (Source: Dictionary.CurrencyType) |
| 3 | Quality | int | NOT NULL | - | CODE-BACKED | Numeric quality score for the benchmark feed. Surfaced in Price.GetInstrumentRateSources as `isnull(BFC.Quality, -1) as Quality` - when no benchmark row exists the view returns -1 as the fallback. Higher values indicate a higher-quality benchmark source. Scale not defined in DDL; interpretation depends on pricing engine configuration. |
| 4 | DbLoginName | varchar (computed) | NOT NULL | suser_name() | CODE-BACKED | Computed column: SQL Server login name of the user/service account that last modified this row. Set automatically on every DML; cannot be overridden. Used for DB-level audit tracking alongside the AuditHistory trigger. |
| 5 | AppLoginName | varchar(500) (computed) | YES | context_info() | CODE-BACKED | Computed column: application-level identity captured from SQL Server context_info(). Populated when the calling service sets context_info before executing DML. NULL when context_info is not set. Pairs with DbLoginName for complete audit attribution. |
| 6 | SysStartTime | datetime2(7) | NOT NULL | getutcdate() | CODE-BACKED | Temporal period start: timestamp when this version of the row became current. Auto-managed by SQL Server temporal table. Use `FOR SYSTEM_TIME AS OF` to query point-in-time state. |
| 7 | SysEndTime | datetime2(7) | NOT NULL | '9999-12-31 23:59:59.9999999' | CODE-BACKED | Temporal period end: '9999-12-31...' = currently active row. Historical versions of changed rows are stored in History.BenchmarkFeedConfiguration with actual end timestamps. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BenchmarkAccountRateSourceID | Price.AccountRateSource | FK (FK_PriceBenchmark_BenchmarkARSID) | The rate source designated as benchmark. Must exist in the master rate source registry. |
| CurrencyTypeID | Dictionary.CurrencyType | FK (FK_PriceBenchmark_CurrencyTypeID) | The instrument category for which this is the benchmark source: 1=Forex ... 10=Crypto. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.GetInstrumentAllocationData | BenchmarkAccountRateSourceID | LEFT JOIN | Computes IsBenchmark flag per instrument-source pair in allocation data |
| Price.GetInstrumentRateSources | BenchmarkAccountRateSourceID | LEFT JOIN | Computes IsBenchmark flag and Quality score per instrument rate source |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.BenchmarkFeedConfiguration (table)
|- Price.AccountRateSource (table, FK target - leaf)
|- Dictionary.CurrencyType (table, FK target - leaf)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.AccountRateSource | Table | FK target - BenchmarkAccountRateSourceID must reference a valid rate source |
| Dictionary.CurrencyType | Table | FK target - CurrencyTypeID must reference a valid currency/instrument type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.GetInstrumentAllocationData | View | LEFT JOIN to derive IsBenchmark flag per instrument-source combination |
| Price.GetInstrumentRateSources | View | LEFT JOIN to derive IsBenchmark flag and Quality score per instrument rate source |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BenchmarkFeedConfiguration | CLUSTERED PK | BenchmarkAccountRateSourceID ASC, CurrencyTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BenchmarkFeedConfiguration | PRIMARY KEY | Composite PK on (BenchmarkAccountRateSourceID, CurrencyTypeID) - one quality score per source-type pair |
| FK_PriceBenchmark_BenchmarkARSID | FK | BenchmarkAccountRateSourceID -> Price.AccountRateSource(AccountRateSourceID) |
| FK_PriceBenchmark_CurrencyTypeID | FK | CurrencyTypeID -> Dictionary.CurrencyType(CurrencyTypeID) |
| DF_BenchmarkFeedConfiguration_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_BenchmarkFeedConfiguration_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| SYSTEM_VERSIONING = ON | Temporal | Full row history in History.BenchmarkFeedConfiguration |
| AuditDelete_Price_BenchmarkFeedConfiguration | TRIGGER (DELETE) | Writes per-column D-operation to History.AuditHistory |
| AuditInsert_Price_BenchmarkFeedConfiguration | TRIGGER (INSERT) | Writes per-column I-operation to History.AuditHistory |
| AuditUpdate_Price_BenchmarkFeedConfiguration | TRIGGER (UPDATE) | Writes per-column U-operation to History.AuditHistory for changed columns |
| TRG_T_BenchmarkFeedConfiguration | TRIGGER (INSERT) | ASM-generated no-op self-update; do not alter manually |

---

## 8. Sample Queries

### 8.1 View all configured benchmark feeds with source and type names

```sql
SELECT
    BFC.BenchmarkAccountRateSourceID,
    ARS.Name AS SourceName,
    BFC.CurrencyTypeID,
    CT.Name AS InstrumentTypeName,
    BFC.Quality,
    BFC.SysStartTime AS ConfiguredSince
FROM Price.BenchmarkFeedConfiguration BFC WITH (NOLOCK)
JOIN Price.AccountRateSource ARS WITH (NOLOCK)
    ON ARS.AccountRateSourceID = BFC.BenchmarkAccountRateSourceID
JOIN Dictionary.CurrencyType CT WITH (NOLOCK)
    ON CT.CurrencyTypeID = BFC.CurrencyTypeID
ORDER BY BFC.CurrencyTypeID, BFC.Quality DESC;
```

### 8.2 Check benchmark status for all rate sources on a specific instrument type

```sql
SELECT
    IRS.InstrumentID,
    IRS.AccountRateSourceID,
    ARS.Name AS SourceName,
    IRS.Priority,
    iif(BFC.BenchmarkAccountRateSourceID IS NULL, 0, 1) AS IsBenchmark,
    isnull(BFC.Quality, -1) AS Quality
FROM Price.InstrumentRateSources IRS WITH (NOLOCK)
JOIN Price.AccountRateSource ARS WITH (NOLOCK)
    ON ARS.AccountRateSourceID = IRS.AccountRateSourceID
LEFT JOIN Price.BenchmarkFeedConfiguration BFC WITH (NOLOCK)
    ON BFC.BenchmarkAccountRateSourceID = IRS.AccountRateSourceID
    AND BFC.CurrencyTypeID = 5  -- Stocks
WHERE IRS.InstrumentID = 1  -- replace with specific InstrumentID
ORDER BY IRS.Priority;
```

### 8.3 View change history for benchmark configurations (temporal query)

```sql
SELECT
    BenchmarkAccountRateSourceID,
    CurrencyTypeID,
    Quality,
    DbLoginName,
    AppLoginName,
    SysStartTime,
    SysEndTime
FROM Price.BenchmarkFeedConfiguration
FOR SYSTEM_TIME ALL
ORDER BY CurrencyTypeID, SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 4, 5, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.BenchmarkFeedConfiguration | Type: Table | Source: etoro/etoro/Price/Tables/Price.BenchmarkFeedConfiguration.sql*
