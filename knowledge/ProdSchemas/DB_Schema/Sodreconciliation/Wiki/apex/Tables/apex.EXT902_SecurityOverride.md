# apex.EXT902_SecurityOverride

> Margin requirement overrides per security from Apex Clearing EXT902 extract: maintenance, initial, and day-trade requirements.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (1 PK + 1 NC) |

---

## 1. Business Meaning

This table stores security-level margin requirement overrides from Apex Clearing's EXT902 extract. Each row represents a custom margin requirement for a specific security that differs from the standard Reg T or exchange margin rates. These overrides are applied by Apex's risk management team for securities deemed to have elevated risk profiles.

The EXT902 data is important for understanding why certain positions have higher margin requirements than standard rates. When an account receives a margin call (EXT250), the security override data can help explain whether the call was driven by non-standard margin requirements on specific holdings.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT902 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

### 2.1 Long vs. Short Margin Requirements

**What**: Different margin requirements apply to long and short positions.

**Columns Involved**: `MaintenanceLong`, `MaintenanceShort`, `InitialLong`, `InitialShort`, `DayTradeRequirementLong`, `DayTradeRequirementShort`

**Rules**:
- Maintenance requirements are the minimum equity needed to hold the position overnight
- Initial requirements are the equity needed to open a new position
- Day trade requirements apply to positions opened and closed within the same day
- Long and short positions typically have different requirement levels
- Values are expressed as decimal percentages (e.g., 0.5000 = 50%)

### 2.2 Option-Related Overrides

**What**: Additional fields apply to option margin calculations.

**Columns Involved**: `UnderlierLessOOMPercent`, `UnderlierPercent`, `UncoveredOptionMin`

**Rules**:
- UnderlierPercent is the percentage of the underlying security value used in margin calculation
- UnderlierLessOOMPercent adjusts for out-of-the-money options
- UncoveredOptionMin sets the minimum margin for uncovered (naked) options

---

## 3. Data Overview

N/A - Apex Clearing daily extract data. Rows are bulk-loaded per SodFiles import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT902 file import. CASCADE DELETE. |
| 3 | Symbol | varchar(35) | YES | - | CODE-BACKED | Trading symbol of the security with overridden margin requirements. |
| 4 | MaintenanceLong | decimal(9,4) | YES | - | CODE-BACKED | Maintenance margin requirement for long positions (as decimal percent). |
| 5 | MaintenanceShort | decimal(9,4) | YES | - | CODE-BACKED | Maintenance margin requirement for short positions (as decimal percent). |
| 6 | InitialLong | decimal(9,4) | YES | - | CODE-BACKED | Initial margin requirement for opening new long positions (as decimal percent). |
| 7 | InitialShort | decimal(9,4) | YES | - | CODE-BACKED | Initial margin requirement for opening new short positions (as decimal percent). |
| 8 | DayTradeRequirementLong | decimal(9,4) | YES | - | CODE-BACKED | Day trade margin requirement for long positions (as decimal percent). |
| 9 | DayTradeRequirementShort | decimal(9,4) | YES | - | CODE-BACKED | Day trade margin requirement for short positions (as decimal percent). |
| 10 | UnderlierLessOOMPercent | decimal(9,4) | YES | - | NAME-INFERRED | Percentage of underlying value minus out-of-the-money amount for option margin. |
| 11 | UnderlierPercent | decimal(9,4) | YES | - | NAME-INFERRED | Percentage of underlying security value used in option margin calculation. |
| 12 | UncoveredOptionMin | decimal(9,4) | YES | - | NAME-INFERRED | Minimum margin requirement for uncovered (naked) option positions. |
| 13 | Qualifier | int | YES | - | NAME-INFERRED | Qualifier code that modifies how the override is applied. |
| 14 | Value | varchar(8) | YES | - | NAME-INFERRED | Additional value associated with the qualifier. |
| 15 | DateModified | smalldatetime | YES | - | CODE-BACKED | Date the override was last modified by Apex risk management. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SodFileId | apex.SodFiles | FK (ON DELETE CASCADE) | Links to source file import |

### 5.2 Referenced By (other objects point to this)

No known consumers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
apex.EXT902_SecurityOverride (table)
  └── apex.SodFiles (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| apex.SodFiles | Table | FK from SodFileId |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EXT902_SecurityOverride | CLUSTERED PK | Id | - | - | Active |
| IX_EXT902_SecurityOverride_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT902_SecurityOverride | PRIMARY KEY | Unique Id per row |
| FK_EXT902_SecurityOverride_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get current security overrides

```sql
SELECT Symbol, MaintenanceLong, MaintenanceShort, InitialLong, InitialShort, DateModified
FROM apex.EXT902_SecurityOverride WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 902 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY Symbol;
```

### 8.2 Find securities with high margin requirements

```sql
SELECT Symbol, MaintenanceLong, MaintenanceShort, InitialLong, InitialShort,
       DayTradeRequirementLong, DayTradeRequirementShort
FROM apex.EXT902_SecurityOverride WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 902 AND Status = 2 ORDER BY ProcessDate DESC)
  AND MaintenanceLong > 0.5
ORDER BY MaintenanceLong DESC;
```

### 8.3 Find recently modified overrides

```sql
SELECT Symbol, MaintenanceLong, MaintenanceShort, Qualifier, Value, DateModified
FROM apex.EXT902_SecurityOverride WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 902 AND Status = 2 ORDER BY ProcessDate DESC)
  AND DateModified >= DATEADD(DAY, -7, GETDATE())
ORDER BY DateModified DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 5 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT902_SecurityOverride | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT902_SecurityOverride.sql*
