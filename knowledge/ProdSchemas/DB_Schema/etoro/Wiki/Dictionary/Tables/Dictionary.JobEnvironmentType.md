# Dictionary.JobEnvironmentType

> Lookup table defining three job execution environments — Israel, Cyprus, and Amsterdam — representing the geographic data center locations where scheduled BackOffice jobs run.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | JobEnvironmentTypeID (INT, CLUSTERED PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.JobEnvironmentType defines the geographic execution environments for eToro's scheduled BackOffice jobs. eToro operates data centers in multiple locations — Israel, Cyprus, and Amsterdam — and certain scheduled jobs must run in specific environments due to data residency requirements, regulatory constraints, or proximity to dependent systems.

This table exists because job scheduling must be environment-aware. A compliance reporting job may need to run in Cyprus (where the EU-regulated entity is based), while a market data processing job may need to run in Amsterdam (closer to European exchange feeds). The environment type ensures jobs are dispatched to the correct data center.

The JobEnvironmentTypeID is stored in BackOffice.ScheduledJob and consumed by BackOffice.ScheduledJobAdd, BackOffice.ScheduledJobEdit, and BackOffice.ScheduledJobsGet for job management operations.

---

## 2. Business Logic

### 2.1 Geographic Execution Routing

**What**: Three environments correspond to eToro's primary data center locations.

**Columns/Parameters Involved**: `JobEnvironmentTypeID`, `JobEnvironmentType`

**Rules**:
- **Israel (1)**: Primary development and operations center. Jobs handling core trading operations, customer management, and internal tooling typically run here.
- **Cyprus (2)**: EU-regulated entity location (eToro Europe Ltd). Jobs related to EU regulatory compliance, European customer data processing, and CySEC reporting run here.
- **Amsterdam (3)**: European data center for market data and low-latency operations. Jobs requiring proximity to European exchanges or that benefit from Amsterdam's network connectivity run here.
- Each scheduled job is assigned exactly one environment, determining which data center's job scheduler picks it up.

---

## 3. Data Overview

| JobEnvironmentTypeID | JobEnvironmentType | Meaning |
|---|---|---|
| 1 | Israel | Primary operations environment. Core trading, customer management, and internal operations jobs execute here. Home of eToro's main engineering and operations teams. |
| 2 | Cyprus | EU regulatory environment. Jobs related to CySEC compliance, EU customer data processing, GDPR obligations, and European regulatory reporting run in this environment. |
| 3 | Amsterdam | European infrastructure environment. Market data processing, low-latency trading operations, and jobs requiring proximity to European exchange venues execute here. Note: trailing space in the stored value. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | JobEnvironmentTypeID | int | NO | - | VERIFIED | Primary key identifying the execution environment. 1=Israel, 2=Cyprus, 3=Amsterdam. Stored in BackOffice.ScheduledJob to route jobs to the correct data center. |
| 2 | JobEnvironmentType | varchar(50) | YES | - | VERIFIED | Geographic name of the execution environment. Displayed in BackOffice job scheduling UI for operators to select the target environment. Note: "Amsterdam" value has trailing whitespace. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.ScheduledJob | JobEnvironmentTypeID | Implicit FK | Each scheduled job is assigned to an execution environment |
| BackOffice.ScheduledJobAdd | JobEnvironmentTypeID | Parameter | Used when creating new scheduled jobs |
| BackOffice.ScheduledJobEdit | JobEnvironmentTypeID | Parameter | Used when modifying scheduled job environment |
| BackOffice.ScheduledJobsGet | JobEnvironmentTypeID | Lookup | Resolves environment name in job listing queries |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.ScheduledJob | Table | References environment type per scheduled job |
| BackOffice.ScheduledJobAdd | Stored Procedure | Writes — accepts environment for new jobs |
| BackOffice.ScheduledJobEdit | Stored Procedure | Writes — updates job environment |
| BackOffice.ScheduledJobsGet | Stored Procedure | Reads — resolves environment names |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | CLUSTERED PK | JobEnvironmentTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PRIMARY KEY | PRIMARY KEY | Unique environment type identifier |

---

## 8. Sample Queries

### 8.1 List all execution environments
```sql
SELECT  JobEnvironmentTypeID,
        LTRIM(RTRIM(JobEnvironmentType)) AS JobEnvironmentType
FROM    [Dictionary].[JobEnvironmentType] WITH (NOLOCK)
ORDER BY JobEnvironmentTypeID;
```

### 8.2 Join to scheduled jobs
```sql
SELECT  sj.JobName,
        LTRIM(RTRIM(jet.JobEnvironmentType)) AS Environment,
        sj.IsEnabled
FROM    [BackOffice].[ScheduledJob] sj WITH (NOLOCK)
JOIN    [Dictionary].[JobEnvironmentType] jet WITH (NOLOCK)
        ON sj.JobEnvironmentTypeID = jet.JobEnvironmentTypeID
ORDER BY jet.JobEnvironmentTypeID, sj.JobName;
```

### 8.3 Count jobs per environment
```sql
SELECT  LTRIM(RTRIM(jet.JobEnvironmentType)) AS Environment,
        COUNT(*) AS JobCount
FROM    [BackOffice].[ScheduledJob] sj WITH (NOLOCK)
JOIN    [Dictionary].[JobEnvironmentType] jet WITH (NOLOCK)
        ON sj.JobEnvironmentTypeID = jet.JobEnvironmentTypeID
GROUP BY jet.JobEnvironmentType
ORDER BY JobCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.JobEnvironmentType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.JobEnvironmentType.sql*
