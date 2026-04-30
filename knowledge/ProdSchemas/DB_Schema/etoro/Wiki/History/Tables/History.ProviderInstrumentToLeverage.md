# History.ProviderInstrumentToLeverage

> Versioned historical log of leverage option availability per provider and instrument, using application-managed ValidFrom/ValidTo intervals to track which leverage tiers were available and at what margin percentages over time.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | VersionID (INT IDENTITY, clustered PK) |
| **Partition** | No (ON [HISTORY] filegroup) |
| **Indexes** | 5 (1 clustered PK + 4 nonclustered) |

---

## 1. Business Meaning

`History.ProviderInstrumentToLeverage` is a standalone versioned history log that tracks the leverage options available for each provider-instrument combination over time. Unlike SQL Server temporal tables (which are automatically maintained), this table uses application-managed `ValidFrom`/`ValidTo` date intervals to represent the historical validity period of each leverage configuration.

Each row represents one leverage tier (`LeverageID`) for a specific provider (`ProviderID`) and instrument (`InstrumentID`), along with whether it was the default leverage option and the associated margin percentage. When leverage configurations change (e.g., a new leverage tier is added or a tier is removed for regulatory compliance), new rows are inserted with updated ValidFrom/ValidTo values.

With 205,431 rows spanning active trading history (most recent rows showing ValidTo = 3000-01-01 for currently active configurations), this table provides a comprehensive audit trail of how leverage availability evolved across instruments. Leverage availability is critical for compliance (regulators often impose maximum leverage limits) and for customer experience (the system needs to know which leverage options to display).

---

## 2. Business Logic

### 2.1 Application-Managed Validity Intervals

**What**: ValidFrom and ValidTo define when a leverage configuration was/is active. NOT a SQL Server temporal table.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo`

**Rules**:
- `ValidTo = '3000-01-01 00:00:00.000'` sentinel = this leverage tier is currently active
- Multiple rows can be active simultaneously for the same (ProviderID, InstrumentID) pair - one per available leverage tier
- When a leverage tier is deactivated: existing row's ValidTo is set to the deactivation timestamp
- ValidFrom/ValidTo are datetime (not datetime2) - local server time

### 2.2 Default Leverage and Margin

**What**: For each provider-instrument pair, one leverage tier is marked as the default, and each tier has an associated margin percentage.

**Columns/Parameters Involved**: `ProviderID`, `InstrumentID`, `LeverageID`, `IsDefault`, `Percentage`

**Rules**:
- `IsDefault=true`: this leverage tier is the default for the instrument (pre-selected in the UI)
- `IsDefault=false`: available tier but not default
- Multiple leverage tiers can coexist for the same provider-instrument at the same time (each with different LeverageID)
- `Percentage`: margin percentage associated with this leverage tier. From live data: Percentage=0 observed - this may store an override or the margin is defined elsewhere
- Indexes HPIL_PROVIDERINSTRUMENT and HPIL_PROVIDERINSTRUMENTLEVERAGE support efficient lookup of current active leverage options for a given position

---

## 3. Data Overview

205,431 rows. Active leverage configurations have ValidTo = 3000-01-01. Multiple active rows per (ProviderID, InstrumentID) for different leverage tiers.

| VersionID | ProviderID | InstrumentID | LeverageID | IsDefault | Percentage | ValidFrom | ValidTo |
|---|---|---|---|---|---|---|---|
| (latest) | 1 | 2 | 10 | true | 0 | 2026-03-17 08:22:54 | 3000-01-01 (active) |
| (latest) | 1 | 2 | 5 | false | 0 | 2026-03-17 08:22:54 | 3000-01-01 (active) |
| (latest) | 1 | 2 | 6 | false | 0 | 2026-03-17 08:22:54 | 3000-01-01 (active) |

*ProviderID=1, InstrumentID=2 has 3 active leverage tiers (IDs 5, 6, 10) with LeverageID=10 as default.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | VersionID | int IDENTITY(1,1) NOT FOR REPLICATION | NO | auto | VERIFIED | Auto-incrementing row version identifier. Clustered PK. NOT FOR REPLICATION prevents identity gaps on replication targets. Provides a stable row key for joining. |
| 2 | ProviderID | int | NO | - | VERIFIED | The price/execution provider for which this leverage option applies. Implicit FK to provider lookup (same as Trade.ProviderToInstrument.ProviderID). |
| 3 | InstrumentID | int | NO | - | VERIFIED | The financial instrument for which this leverage tier is available. Implicit FK to instrument lookup. HPIL_INSTRUMENT index supports per-instrument queries. |
| 4 | LeverageID | int | NO | - | VERIFIED | Identifies the leverage tier (e.g., 1:5, 1:10, 1:100). Implicit FK to leverage lookup (Dictionary.Leverage or Trade.Leverage). HPIL_LEVERAGE index supports per-leverage-tier queries. |
| 5 | IsDefault | bit | NO | - | VERIFIED | 1 = this is the default leverage tier presented to customers for this instrument. Only one tier per active (ProviderID, InstrumentID) pair should be IsDefault=1 at any time. |
| 6 | Percentage | int | NO | - | CODE-BACKED | Margin percentage associated with this leverage tier. Observed value: 0. May represent a margin override percentage (0 = use system default) or may be populated differently in older rows. |
| 7 | ValidFrom | datetime | NO | - | VERIFIED | Application-set timestamp when this leverage tier became available for this provider-instrument pair. Not UTC-guaranteed - local server datetime. Written by the application when adding a leverage tier. |
| 8 | ValidTo | datetime | NO | - | VERIFIED | Application-set timestamp when this leverage tier was deactivated. Sentinel '3000-01-01 00:00:00.000' = currently active. Set to current timestamp when a tier is removed. HPIL_PROVIDERINSTRUMENTLEVERAGE index supports active-tier queries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID | Provider lookup | Implicit | The provider these leverage options belong to |
| InstrumentID | Instrument lookup | Implicit | The instrument these leverage tiers apply to |
| LeverageID | Leverage lookup | Implicit | The leverage tier definition |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (External application or Trade SPs) | INSERT/UPDATE | WRITER | Application-managed versioning - new rows inserted when leverage options change |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ProviderInstrumentToLeverage (table)
(leaf - no code-level dependencies)
```

---

### 6.1 Objects This Depends On

None.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Trade platform) | External/Procedures | READER/WRITER - leverage option history for compliance and UI |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HPIL | CLUSTERED PK | VersionID ASC | - | - | Active |
| HPIL_INSTRUMENT | NONCLUSTERED | InstrumentID ASC | - | - | Active |
| HPIL_LEVERAGE | NONCLUSTERED | LeverageID ASC | - | - | Active |
| HPIL_PROVIDERINSTRUMENT | NONCLUSTERED | ProviderID ASC, InstrumentID ASC | - | - | Active |
| HPIL_PROVIDERINSTRUMENTLEVERAGE | NONCLUSTERED | ProviderID ASC, InstrumentID ASC, LeverageID ASC | - | - | Active |

*ON [HISTORY] filegroup, FILLFACTOR=90 on all indexes (with DATA_COMPRESSION=PAGE on clustered and nonclustered). The HPIL_PROVIDERINSTRUMENTLEVERAGE index directly supports the primary access pattern: "find the current leverage options for a given provider/instrument/leverage combination".*

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HPIL | PK | VersionID clustered PK |

---

## 8. Sample Queries

### 8.1 Current active leverage options for a specific instrument

```sql
SELECT ProviderID, InstrumentID, LeverageID, IsDefault, Percentage, ValidFrom
FROM History.ProviderInstrumentToLeverage WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
  AND ValidTo = '3000-01-01 00:00:00.000'
ORDER BY ProviderID, IsDefault DESC
```

### 8.2 Full leverage history for a provider-instrument pair

```sql
SELECT VersionID, LeverageID, IsDefault, Percentage, ValidFrom, ValidTo,
    CASE WHEN ValidTo = '3000-01-01' THEN 1 ELSE 0 END AS IsCurrentlyActive
FROM History.ProviderInstrumentToLeverage WITH (NOLOCK)
WHERE ProviderID = @ProviderID AND InstrumentID = @InstrumentID
ORDER BY ValidFrom ASC
```

### 8.3 Default leverage by instrument (currently active)

```sql
SELECT InstrumentID, ProviderID, LeverageID, ValidFrom
FROM History.ProviderInstrumentToLeverage WITH (NOLOCK)
WHERE IsDefault = 1
  AND ValidTo = '3000-01-01 00:00:00.000'
ORDER BY InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ProviderInstrumentToLeverage | Type: Table | Source: etoro/etoro/History/Tables/History.ProviderInstrumentToLeverage.sql*
