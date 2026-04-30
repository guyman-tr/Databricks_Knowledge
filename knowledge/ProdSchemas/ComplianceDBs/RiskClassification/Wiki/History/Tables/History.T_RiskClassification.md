# History.T_RiskClassification

> Temporal history table preserving all superseded versions of customer risk classification records from dbo.T_RiskClassification, enabling point-in-time risk score lookback and compliance auditing across the full customer lifecycle.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | GCID + BeginTime (clustered index) |
| **Partition** | No (PAGE compression) |
| **Indexes** | 1 active (clustered) |

---

## 1. Business Meaning

This is the temporal history table for `dbo.T_RiskClassification` - the main customer risk classification table. It stores all superseded versions of customer risk records. Every time a customer's risk score changes (via the `P_RiskClassification` procedure's DELETE+INSERT pattern), the previous version moves here automatically via SQL Server system-versioning.

This table is critical for compliance and regulatory purposes. Regulators can require lookback to determine what a customer's risk classification was on any historical date. The table is directly consumed by `dbo.V_RiskClassification` (to compute PreviousRisk and PreviousRiskUpdateDate), `dbo.V_RiskClassification_4_SynapseExport3`, and `dbo.V_RiskClassification_History` for historical data export.

With ~8.5M rows compared to ~5M current rows in dbo.T_RiskClassification, the average customer has had about 1.7 historical risk versions beyond their current state.

---

## 2. Business Logic

### 2.1 Temporal History Pattern

**What**: System-managed archive of every superseded customer risk classification.

**Columns/Parameters Involved**: All columns mirror dbo.T_RiskClassification exactly

**Rules**:
- Rows appear here when P_RiskClassification DELETEs and re-INSERTs a customer's row in dbo.T_RiskClassification
- The deleted version (with its BeginTime and the current timestamp as EndTime) is preserved here
- Multiple historical versions per GCID are normal - each represents a different risk state
- BeginTime/EndTime define the validity window: the risk score was in effect during [BeginTime, EndTime)
- The V_RiskClassification view's CTE excludes the 2021-03-07 to 2021-03-10 window from "previous risk" lookups (mass re-scoring event)

### 2.2 Risk Score Evolution Tracking

**What**: Enables tracing a customer's complete risk classification journey.

**Columns/Parameters Involved**: `GCID`, `RiskScore`, `BeginTime`, `EndTime`

**Rules**:
- Combining this table with dbo.T_RiskClassification (current) gives the complete timeline
- Example GCID 91: was at 200 (Unacceptable) from 2021-06 to 2023-04, then 50 (Medium) from 2023-04 to 2023-11, now 100 (High)
- Risk downgrades and upgrades are both visible in the history

---

## 3. Data Overview

| GCID | RiskScore | RiskScore_Value | RegulationID | BeginTime | EndTime | Meaning |
|------|-----------|----------------|-------------|-----------|---------|---------|
| 91 | 50 | 3*50 | 1 (CySEC) | 2023-04-23 | 2023-11-26 | Previous state: Medium risk with 3 parameters at 50. Lasted 7 months before being upgraded to High (100). |
| 91 | 200 | 2*200 | 1 (CySEC) | 2021-06-17 | 2023-04-23 | Earlier state: Unacceptable risk (200) with 2 parameters at 200. Lasted nearly 2 years before being downgraded to Medium. |

Total: ~8.5M historical risk versions.

---

## 4. Elements

All columns mirror `dbo.T_RiskClassification` exactly (same ~100 columns). See [dbo.T_RiskClassification](../../dbo/Tables/dbo.T_RiskClassification.md) for full element descriptions.

Key structural differences from the parent table:
- No PK constraint (history tables use clustered index instead)
- No temporal PERIOD definition (this IS the history table)
- BeginTime/EndTime are plain columns, not GENERATED ALWAYS

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | INT | NO | - | VERIFIED | Global Customer ID. Part of clustered index with BeginTime. |
| 2 | CID | INT | YES | - | CODE-BACKED | Customer ID. |
| 3 | RegulationID | INT | YES | - | VERIFIED | Regulation ID. See [Regulation](../_glossary.md#regulation). |
| 4 | RiskScore | INT | YES | - | VERIFIED | Final risk score that was in effect during [BeginTime, EndTime). |
| 5 | RiskScore_Value | VARCHAR(50) | YES | - | CODE-BACKED | Score formula (N*Score format) during this period. |
| 6 | BeginTime | DATETIME2(7) | NO | - | VERIFIED | When this historical version became effective. |
| 7 | EndTime | DATETIME2(7) | NO | - | VERIFIED | When this version was superseded by a newer classification. |
| 8-100 | *_RiskScore / *_Value | INT/VARCHAR(50) | YES | - | CODE-BACKED | All individual parameter score/value columns. Same as dbo.T_RiskClassification. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (parent) | dbo.T_RiskClassification | Temporal history | System-versioned history table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.V_RiskClassification | CTE (historyDate, history) | Reader | Computes PreviousRisk and PreviousRiskUpdateDate |
| dbo.V_RiskClassificationDataLake | CTE | Reader | Same previous risk logic |
| dbo.V_RiskClassification_4_SynapseExport3 | FROM | Reader | Direct history export for Synapse |
| dbo.V_RiskClassification_History | FROM | Reader | Direct history access view |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.V_RiskClassification | View | CTE reads MAX(BeginTime) per GCID for previous risk |
| dbo.V_RiskClassificationDataLake | View | Same CTE pattern |
| dbo.V_RiskClassification_4_SynapseExport3 | View | Direct FROM for history export |
| dbo.V_RiskClassification_History | View | Direct FROM for history access |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| Idx_History_T_RiskClassification | CLUSTERED | GCID ASC, BeginTime ASC | - | - | Active (FILLFACTOR 90, PAGE compression) |

### 7.2 Constraints

None. Temporal history tables do not carry PK constraints.

---

## 8. Sample Queries

### 8.1 Complete risk history timeline for a customer
```sql
SELECT GCID, RiskScore, RiskScore_Value, RegulationID, BeginTime, EndTime
FROM History.T_RiskClassification WITH (NOLOCK)
WHERE GCID = 91
ORDER BY BeginTime DESC
```

### 8.2 Point-in-time risk classification lookup
```sql
SELECT GCID, RiskScore, RegulationID
FROM History.T_RiskClassification WITH (NOLOCK)
WHERE GCID = 91
  AND BeginTime <= '2022-01-01' AND EndTime > '2022-01-01'
```

### 8.3 Find customers whose risk was downgraded
```sql
SELECT h1.GCID, h1.RiskScore AS OlderScore, h2.RiskScore AS NewerScore,
       h1.BeginTime AS OlderBegin, h2.BeginTime AS NewerBegin
FROM History.T_RiskClassification h1 WITH (NOLOCK)
JOIN History.T_RiskClassification h2 WITH (NOLOCK)
    ON h1.GCID = h2.GCID AND h1.EndTime = h2.BeginTime
WHERE h2.RiskScore < h1.RiskScore
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 95 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.T_RiskClassification | Type: Table | Source: RiskClassification/History/Tables/History.T_RiskClassification.sql*
