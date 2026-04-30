# History.T_RiskClassification20200122

> Temporal history table for the archived dbo.T_RiskClassification20200122 snapshot, preserving superseded versions of the legacy risk classification records that included SubValue columns.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | GCID + BeginTime (clustered index) |
| **Partition** | No (PAGE compression) |
| **Indexes** | 1 active (clustered) |

---

## 1. Business Meaning

This is the temporal history table for `dbo.T_RiskClassification20200122` - the archived risk classification snapshot from January 2020. It preserves superseded versions of records in that archive table. Since the parent table itself is an archive, this is a "history of an archive" - tracking changes made to the 2020 snapshot after it was created.

Currently contains 0 rows, indicating the archive table has not been modified since its initial creation - all original data remains as-is in the parent table.

---

## 2. Business Logic

### 2.1 Empty History

**What**: No historical versions exist because the parent archive table has never been modified after creation.

**Rules**:
- 0 rows indicates the archive data has been stable since the 2020 snapshot was taken
- If compliance were to correct any values in the archive, the original versions would be preserved here

---

## 3. Data Overview

Empty table (0 rows). No modifications have been made to the parent archive.

---

## 4. Elements

All columns mirror `dbo.T_RiskClassification20200122` exactly (~140 columns including SubValue triplets). See [dbo.T_RiskClassification20200122](../../dbo/Tables/dbo.T_RiskClassification20200122.md) for full element descriptions.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | INT | NO | - | VERIFIED | Global Customer ID. Part of clustered index. |
| 2-5 | CID, RegulationID, RiskScore, RiskScore_Value | Various | YES | - | CODE-BACKED | Core classification fields. |
| 6-7 | BeginTime, EndTime | DATETIME2(7) | NO | - | VERIFIED | Temporal validity period. |
| 8-140 | *_RiskScore, *_Value, *_SubValue | INT/VARCHAR(50) | YES | - | CODE-BACKED | All parameter score/value/subvalue triplets. Legacy schema with SubValue. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (parent) | dbo.T_RiskClassification20200122 | Temporal history | History for the 2020 archive snapshot |

### 5.2 Referenced By (other objects point to this)

No other objects reference this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| Idx_History_T_RiskClassification20200122 | CLUSTERED | GCID ASC, BeginTime ASC | - | - | Active (FILLFACTOR 90, PAGE compression) |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check if any archive modifications exist
```sql
SELECT COUNT(*) AS HistoricalVersions
FROM History.T_RiskClassification20200122 WITH (NOLOCK)
```

### 8.2 Find modifications to a specific customer's archive record
```sql
SELECT GCID, RiskScore, BeginTime, EndTime
FROM History.T_RiskClassification20200122 WITH (NOLOCK)
WHERE GCID = @GCID
ORDER BY BeginTime DESC
```

### 8.3 Audit trail of archive changes
```sql
SELECT TOP 10 GCID, RiskScore, BeginTime, EndTime
FROM History.T_RiskClassification20200122 WITH (NOLOCK)
ORDER BY EndTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 137 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.T_RiskClassification20200122 | Type: Table | Source: RiskClassification/History/Tables/History.T_RiskClassification20200122.sql*
