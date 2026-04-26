# BI_DB_dbo.BI_DB_AML_Benchmarks_Risk_Classification

> AML benchmarking table tracking AML-driven risk classification change events — each row records a customer (CID/GCID) whose risk classification was changed as a result of AML review, capturing the new and previous risk class, the change date, and a row ordering number. Currently **empty (0 rows as of 2026-04-23)**. No writer SP found in the SSDT repo; table is likely populated by an external AML compliance tool or was decommissioned. Companion to `BI_DB_AML_Benchmarks_AML_Alerts` (tracks PlayerStatus changes). Distribution: ROUND_ROBIN, CLUSTERED on CID. **Key anomaly**: CID is nullable while GCID is NOT NULL — reversed from typical eToro table convention.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table — AML benchmarking: risk classification change log |
| **Production Source** | Unknown — no SSDT writer SP; likely external AML compliance tool |
| **Refresh** | Unknown — table is empty; no active ETL |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Row Count** | 0 (as of 2026-04-23) |
| **Related Tables** | BI_DB_AML_Benchmarks_AML_Alerts (companion table for AML alert status changes), DWH_dbo.Dim_RiskClassification (RiskClassID lookup) |

---

## 1. Business Meaning

`BI_DB_AML_Benchmarks_Risk_Classification` is part of an **AML benchmarking dataset** that tracks the history of customer risk classification changes driven by AML review processes. Each row represents one risk classification change event for a customer — recording the new risk class assigned after the AML review and the prior risk class that was replaced.

The table captures:
- **Who**: CID and GCID of the customer whose risk classification changed
- **What changed**: New risk class (RiskClassID / RiskClassDesc) and prior risk class (PreviousRiskClassID / PreviousRiskClassDesc)
- **When**: Calendar date of the risk class change (RiskClassChangeDate) and a date key (RiskClassChangeDateID)
- **Ordering**: RowNumber — likely for deduplication or identifying the most-recent change per customer

**"Benchmarks" context**: In the eToro AML function, benchmarking measures the effectiveness and timeliness of AML-driven customer risk re-assessments. This table provides the change history needed for calculating re-classification rates, time-to-action metrics, and risk escalation patterns. It operates alongside its companion table `BI_DB_AML_Benchmarks_AML_Alerts` which tracks AML alert-driven PlayerStatus changes.

**Current status**: Empty (0 rows as of 2026-04-23). The table is either decommissioned or awaiting population from an external AML compliance tool.

---

## 2. Business Logic

### 2.1 Risk Classification Change Tracking

**What**: Each row records one AML-driven change to a customer's risk classification.
**Columns Involved**: CID, GCID, RiskClassID, RiskClassDesc, PreviousRiskClassID, PreviousRiskClassDesc, RiskClassChangeDate, RiskClassChangeDateID
**Rules**:
- `RiskClassID` reflects the **resulting** (new) risk class after the AML review action
- `PreviousRiskClassID` reflects the risk class **before** the change event
- Risk class values confirmed from `DWH_dbo.Dim_RiskClassification`: 0=High(RiskScore=100), 1=Medium(50), 2=Low(0), 3=Unacceptable(200), 4=Medium High(75), 5=Medium Low(25)
- `RiskClassChangeDateID` is the date key (YYYYMMDD integer format) for joining to Dim_Date
- Clustered on CID for efficient per-customer lookup of classification history

### 2.2 Row Ordering / Deduplication

**What**: RowNumber provides ordering within the change history for each customer.
**Columns Involved**: RowNumber
**Rules**:
- Likely a `ROW_NUMBER() OVER (PARTITION BY CID ORDER BY RiskClassChangeDate [DESC|ASC])` expression
- If ordered descending, RowNumber=1 identifies the **most-recent** classification change per CID (useful for current-state queries)
- If ordered ascending, RowNumber=1 identifies the **earliest** change (useful for onboarding / first-classification queries)
- Actual partition and ordering direction unconfirmed — no writer SP available

### 2.3 GCID as Grain Key

**What**: GCID is NOT NULL while CID is nullable — atypical for BI_DB_dbo tables where CID is usually the primary key.
**Columns Involved**: CID (nullable), GCID (NOT NULL)
**Rules**:
- GCID (Group Customer ID) is the cross-product identity key linking the same person across eToro products/entities
- The NOT NULL constraint on GCID suggests GCID may be the **effective grain** of this table (not CID)
- CID may be NULL for customers who exist in the AML system but whose eToro CID was not resolved at population time, or for accounts originating from non-standard product lines
- Cross-reference: GCID can be used to join to `DWH_dbo.Dim_Customer` via the GCID column on that table

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on CID. Efficient for per-customer lookups; cross-customer aggregations require full scan. Table is currently empty.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| How many risk class changes occurred per day? | `SELECT RiskClassChangeDate, COUNT(*) FROM ... GROUP BY RiskClassChangeDate ORDER BY RiskClassChangeDate` |
| Most common risk class transitions (from → to)? | `SELECT PreviousRiskClassDesc, RiskClassDesc, COUNT(*) FROM ... GROUP BY PreviousRiskClassDesc, RiskClassDesc ORDER BY 3 DESC` |
| Current risk class per customer (most recent change)? | `SELECT CID, RiskClassDesc FROM ... WHERE RowNumber = 1` (if RowNumber partitions by CID desc) |
| Risk classification history for a specific customer | `SELECT * FROM ... WHERE CID = 12345 ORDER BY RiskClassChangeDate` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `ON CID = dc.RealCID` | Add customer profile (country, regulation, etc.) |
| DWH_dbo.Dim_RiskClassification | `ON RiskClassID = rc.RiskClassificationID` | Resolve risk class name/score from normalized table |
| BI_DB_AML_Benchmarks_AML_Alerts | `ON CID = a.CID` | Cross-reference with AML alert-driven PlayerStatus changes for same customers |
| DWH_dbo.Dim_Date | `ON RiskClassChangeDateID = d.DateKey` | Add calendar attributes to change date |

### 3.4 Gotchas

- **Table is empty**: 0 rows as of 2026-04-23 — no historical data available for analysis.
- **CID nullable / GCID NOT NULL**: Reversed from typical eToro convention — use GCID as the reliable join key; filter `WHERE CID IS NOT NULL` before joining on CID.
- **Denormalized descriptions**: RiskClassDesc and PreviousRiskClassDesc are denormalized copies — may diverge from `Dim_RiskClassification` if descriptions were updated after population.
- **RowNumber semantics unknown**: Without a writer SP, the partition and ordering direction of RowNumber cannot be confirmed. Treat with caution for deduplication logic until the source mechanism is known.
- **RiskClassChangeDateID format**: Integer date key in YYYYMMDD format — join to Dim_Date on DateKey, not direct date comparison.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production source wiki |
| Tier 2 | Derived from writer SP code (source-to-target mapping) |
| Tier 3 | Inferred from DDL, column name patterns, live Dim table data, or sibling table docs |
| Tier 4 | Best-guess — no definitive source found |
| Tier 5 | Propagation constant (ETL metadata — UpdateDate) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NULL | Customer ID — eToro customer whose risk classification changed. FK to DWH_dbo.Dim_Customer.RealCID. **Nullable** — atypical for BI_DB_dbo; GCID is the NOT NULL key here. (Tier 4 — unknown external AML tool) |
| 2 | GCID | int | NOT NULL | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NOT NULL — acts as the effective grain key of this table (reversed from typical BI_DB_dbo convention where CID is NOT NULL). (Tier 4 — unknown external AML tool) |
| 3 | RiskClassID | int | NULL | New/current risk classification ID after the AML-driven change. Values from DWH_dbo.Dim_RiskClassification: 0=High(RiskScore=100), 1=Medium(50), 2=Low(0), 3=Unacceptable(200), 4=Medium High(75), 5=Medium Low(25). FK to Dim_RiskClassification. (Tier 3 — DWH_dbo.Dim_RiskClassification) |
| 4 | RiskClassDesc | nvarchar | NULL | Denormalized description of the new risk class (e.g., 'High', 'Medium', 'Unacceptable'). See RiskClassID for full value mapping. (Tier 3 — DWH_dbo.Dim_RiskClassification) |
| 5 | PreviousRiskClassID | int | NULL | Prior risk classification ID before this change event. Same value domain as RiskClassID: 0=High, 1=Medium, 2=Low, 3=Unacceptable, 4=Medium High, 5=Medium Low. (Tier 3 — DWH_dbo.Dim_RiskClassification) |
| 6 | PreviousRiskClassDesc | nvarchar | NULL | Denormalized description of the prior risk class before the change. (Tier 3 — DWH_dbo.Dim_RiskClassification) |
| 7 | RiskClassChangeDateID | int | NULL | Date key (YYYYMMDD integer format) for the risk classification change date. Join to DWH_dbo.Dim_Date.DateKey for calendar attributes. (Tier 3 — derived from RiskClassChangeDate) |
| 8 | RiskClassChangeDate | date | NULL | Calendar date when the customer's risk classification was changed. (Tier 4 — unknown external AML tool) |
| 9 | RowNumber | bigint | NULL | Row ordering number — likely ROW_NUMBER() OVER (PARTITION BY CID ORDER BY RiskClassChangeDate) for identifying the most-recent change per customer or deduplication. Exact partition/ordering unconfirmed — no writer SP available. (Tier 3 — derived) |
| 10 | UpdateDate | datetime | NOT NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID, GCID | Unknown external AML tool | customer_id | External system population |
| RiskClassID, RiskClassDesc | DWH_dbo.Dim_RiskClassification | RiskClassificationID, RiskClassificationName | Denormalized lookup at population time |
| PreviousRiskClassID, PreviousRiskClassDesc | DWH_dbo.Dim_RiskClassification | RiskClassificationID (prior), RiskClassificationName (prior) | Denormalized lookup at population time |
| RiskClassChangeDateID | Derived | RiskClassChangeDate | CONVERT(int, CONVERT(varchar, RiskClassChangeDate, 112)) — YYYYMMDD |
| RiskClassChangeDate | Unknown external AML tool | change_date | Passthrough |
| RowNumber | Derived | ROW_NUMBER() | Window function — partition/order unconfirmed |
| UpdateDate | ETL metadata | GETDATE() | Pipeline run timestamp |

### 5.2 ETL Pipeline

```
Unknown external AML compliance tool / case management system
  |-- External population mechanism (unknown) ---|
  v
BI_DB_dbo.BI_DB_AML_Benchmarks_Risk_Classification (0 rows, inactive)
  |-- No downstream SP identified ---|
  v
No UC Gold target (_Not_Migrated)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer identity reference |
| GCID | DWH_dbo.Dim_Customer | Cross-product customer identity reference |
| RiskClassID | DWH_dbo.Dim_RiskClassification | New risk class lookup (6 values: 0–5) |
| PreviousRiskClassID | DWH_dbo.Dim_RiskClassification | Prior risk class lookup (same 6 values) |
| RiskClassChangeDateID | DWH_dbo.Dim_Date | Date dimension key |

### 6.2 Referenced By

No downstream consumers identified.

---

## 7. Sample Queries

### Risk classification transition matrix

```sql
SELECT 
    PreviousRiskClassDesc,
    RiskClassDesc,
    COUNT(*) AS TransitionCount,
    MIN(RiskClassChangeDate) AS FirstOccurrence,
    MAX(RiskClassChangeDate) AS LastOccurrence
FROM [BI_DB_dbo].[BI_DB_AML_Benchmarks_Risk_Classification]
WHERE CID IS NOT NULL
GROUP BY PreviousRiskClassDesc, RiskClassDesc
ORDER BY TransitionCount DESC;
```

### Cross-reference risk classification changes with AML alert status changes for same customers

```sql
SELECT 
    r.CID,
    r.RiskClassChangeDate,
    r.PreviousRiskClassDesc AS FromRisk,
    r.RiskClassDesc AS ToRisk,
    a.PlayerStatusName,
    a.AMLAlert_ChangeDate
FROM [BI_DB_dbo].[BI_DB_AML_Benchmarks_Risk_Classification] r
LEFT JOIN [BI_DB_dbo].[BI_DB_AML_Benchmarks_AML_Alerts] a
    ON r.CID = a.CID
WHERE ABS(DATEDIFF(DAY, r.RiskClassChangeDate, a.AMLAlert_ChangeDate)) <= 7
ORDER BY r.RiskClassChangeDate;
```

### Most recent risk classification per customer

```sql
SELECT CID, GCID, RiskClassDesc, RiskClassChangeDate
FROM [BI_DB_dbo].[BI_DB_AML_Benchmarks_Risk_Classification]
WHERE RowNumber = 1  -- assumes RowNumber=1 is most recent per CID
  AND CID IS NOT NULL;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. AML benchmarking documentation, if available, would reside in the AML/Compliance team's operational documentation.

---

*Generated: 2026-04-23 | Quality: 7.0/10 | Phases: 6/14*
*Tiers: 0 T1, 0 T2, 6 T3, 4 T4, 1 T5 | Elements: 10/10, Logic: 7/10, Data Evidence: 2/10*
*Object: BI_DB_dbo.BI_DB_AML_Benchmarks_Risk_Classification | Type: Table | Production Source: Unknown external AML tool*
