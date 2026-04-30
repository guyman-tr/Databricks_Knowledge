# History.CEP_LOG_CompoundProperties

> Trigger-based audit log capturing previous versions of CEP compound property definitions whenever they are updated or deleted; records the name and validity period of each changed compound property.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (CompoundPropertyID, ValidFrom, ValidTo) - composite PK CLUSTERED |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.CEP_LOG_CompoundProperties is one of seven interrelated audit log tables that together capture the complete version history of the CEP (Complex Event Processing) rules engine configuration. A compound property in the CEP system is a named logical grouping that combines multiple conditions (via AND/OR semantics) to form a reusable sub-expression within rules.

CEP.CompoundProperties stores the live compound property definitions. Whenever a compound property is renamed or deleted, the DELETE and UPDATE triggers on CEP.CompoundProperties copy the prior row here. This is a pre-temporal audit mechanism that predates SQL Server SYSTEM_VERSIONING (CEP.CompoundProperties also has a separate SQL Server temporal history table: History.CompoundProperties via SYSTEM_VERSIONING).

With 4,812 rows this is an actively maintained audit trail reflecting significant configuration churn in the CEP rules engine over time.

---

## 2. Business Logic

### 2.1 Trigger-Based Change Capture

**What**: Each row is a snapshot of one compound property definition at the moment it was superseded.

**Columns/Parameters Involved**: `CompoundPropertyID`, `Name`, `ValidFrom`, `ValidTo`

**Rules**:
- UPDATE trigger (CEPCompoundPropertiesUpdate): before updating, refreshes ValidFrom on the live row to now, then copies the OLD row (pre-update) here
- DELETE trigger (CEPCompoundPropertiesDelete): copies the deleted row here
- ValidTo defaults to getutcdate() at INSERT time - captures when the change occurred
- ValidFrom copied from the parent row - captures when that version became active
- PK = (CompoundPropertyID, ValidFrom, ValidTo) allows multiple historical versions per compound property

**Note**: CEP.CompoundProperties also has SQL Server SYSTEM_VERSIONING pointing to History.CompoundProperties. The CEP_LOG tables are an older, parallel audit mechanism.

---

## 3. Data Overview

4,812 rows of compound property change events, reflecting active configuration management of the CEP rules engine.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CompoundPropertyID | int | NO | - | CODE-BACKED | Identifies the compound property that was changed. PK in CEP.CompoundProperties. Part of composite PK here. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | The name of the compound property as it existed before this change. A compound property groups conditions into a reusable logical expression (e.g., "HighRiskInstrument", "LargeBuyPosition"). |
| 3 | ValidFrom | datetime | NO | - | CODE-BACKED | Timestamp when this version of the compound property became active. Copied from the parent row's ValidFrom column. Part of composite PK. |
| 4 | ValidTo | datetime | NO | getutcdate() | CODE-BACKED | Timestamp when this version was superseded (when the UPDATE or DELETE triggered). Defaults to getutcdate() at INSERT time. Part of composite PK. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CompoundPropertyID | CEP.CompoundProperties | Trigger audit | This row is a past version of a parent table row |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CEP.CompoundProperties | CEPCompoundPropertiesDelete trigger | Writer | Copies deleted rows here |
| CEP.CompoundProperties | CEPCompoundPropertiesUpdate trigger | Writer | Copies pre-update rows here |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CEP_LOG_CompoundProperties (table)
```

---

### 6.1 Objects This Depends On

No hard dependencies (no FK constraints in DDL).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CEP.CompoundProperties | Table | Trigger writer - copies changed rows here |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CompoundProperties | CLUSTERED PK | CompoundPropertyID ASC, ValidFrom ASC, ValidTo ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CompoundProperties | PRIMARY KEY | (CompoundPropertyID, ValidFrom, ValidTo) |
| (DEFAULT) | DEFAULT | ValidTo = getutcdate() |

Storage: ON [PRIMARY] filegroup.

---

## 8. Sample Queries

### 8.1 View all versions of a specific compound property
```sql
SELECT CompoundPropertyID, Name, ValidFrom, ValidTo,
       DATEDIFF(DAY, ValidFrom, ValidTo) AS DaysActive
FROM [History].[CEP_LOG_CompoundProperties]
WHERE CompoundPropertyID = @CompoundPropertyID
ORDER BY ValidFrom DESC
```

### 8.2 Find compound properties changed in a date range
```sql
SELECT CompoundPropertyID, Name, ValidFrom, ValidTo
FROM [History].[CEP_LOG_CompoundProperties]
WHERE ValidTo BETWEEN @StartDate AND @EndDate
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (written by triggers) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CEP_LOG_CompoundProperties | Type: Table | Source: etoro/etoro/History/Tables/History.CEP_LOG_CompoundProperties.sql*
