# BI_DB_dbo.BI_DB_AMLComment_Risk_Score_Report_Ext

> Minimal 2-column AML compliance parameter table holding CID and AuditDate pairs — likely a control/parameter set fed by an external AML compliance tool to drive AML comment risk score reporting. Currently **empty (0 rows as of 2026-04-23)**. No writer SP exists in the SSDT repo; no downstream consumers identified. The "Ext" suffix indicates population by an external system rather than an internal ETL process.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table — external system parameter/control table |
| **Production Source** | Unknown external AML compliance tool (system pushes data) |
| **Refresh** | Unknown — external system feed; currently empty |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Row Count** | 0 (as of 2026-04-23) |

---

## 1. Business Meaning

`BI_DB_AMLComment_Risk_Score_Report_Ext` is a two-column stub table holding **CID** (customer ID) and **AuditDate** pairs for AML (Anti-Money Laundering) comment risk score reporting. The "Ext" suffix strongly indicates this table is populated by an **external AML compliance system** (such as an AML case management tool or compliance platform) rather than an internal Synapse stored procedure.

Based on the table name structure — "AMLComment" + "Risk_Score_Report" + "Ext" — the most likely purpose is:
- The external AML tool pushes a list of customer IDs and audit dates into this table
- A downstream report or process reads these CID+AuditDate pairs to generate an AML risk score commentary report for those specific customers at those audit points
- The report itself is likely generated externally (Excel, Power BI, or a compliance dashboard)

The table is currently empty (0 rows). No references to this table were found in any other SSDT stored procedure or view, which is consistent with it being a pure input/parameter table.

---

## 2. Business Logic

### 2.1 External Parameter Feed

**What**: External AML tool populates CID + AuditDate pairs to drive report generation.
**Columns Involved**: CID, AuditDate
**Rules**:
- `CID` identifies the customer being assessed in the AML risk score report
- `AuditDate` captures the specific audit event date for the risk score assessment
- HEAP distribution (no ordering) — typical for control/parameter tables used via JOIN or cursor
- No uniqueness constraint — multiple audit dates per CID are possible

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HEAP with ROUND_ROBIN — appropriate for a small parameter table. No join key constraint. Table is currently empty.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Which CIDs have been audited? | `SELECT DISTINCT CID FROM [BI_DB_dbo].[BI_DB_AMLComment_Risk_Score_Report_Ext]` |
| Audit history for a customer | `SELECT * FROM ... WHERE CID = 12345 ORDER BY AuditDate` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Dim_Customer | `ON ext.CID = dc.RealCID` | Enrich with customer profile for AML reporting |
| BI_DB_AML_Documents_Dashboard | `ON ext.CID = aml.CID` | Cross-reference AML document status |

### 3.4 Gotchas

- **Table is empty**: 0 rows as of 2026-04-23. External system has not populated data.
- **HEAP**: No ordering guarantee on reads; parameter tables should always include explicit ORDER BY.
- **No uniqueness**: Multiple rows per CID possible (one per audit event date).
- **External writer**: Changes to the source AML tool may alter the feed format without SSDT DDL updates.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production source wiki |
| Tier 2 | Derived from writer SP code (source-to-target mapping) |
| Tier 3 | Inferred from DDL, column name patterns, sibling table docs, or live data |
| Tier 4 | Best-guess — no definitive source found |
| Tier 5 | Propagation constant (ETL metadata — UpdateDate, InsertDate) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NOT NULL | Customer ID — identifies the eToro customer whose AML comment risk score is being reported. FK to DWH Dim_Customer.RealCID. Populated by external AML compliance tool. (Tier 4 — unknown external AML system) |
| 2 | AuditDate | date | NULL | Date of the AML comment audit event for this customer. Used to scope the AML risk score report to a specific point in time. (Tier 4 — unknown external AML system) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | Unknown external AML compliance tool | customer_id / CID | Passthrough — external system populates |
| AuditDate | Unknown external AML compliance tool | audit_date | Passthrough — external system populates |

### 5.2 ETL Pipeline

```
Unknown external AML compliance tool (case management / compliance platform)
  |-- External system direct write to Synapse (mechanism unknown) ---|
  v
BI_DB_dbo.BI_DB_AMLComment_Risk_Score_Report_Ext (0 rows, decommissioned or inactive)
  |-- No downstream ETL SP identified ---|
  v
No UC Gold target (_Not_Migrated)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer identity reference (RealCID) |

### 6.2 Referenced By

No downstream consumers identified in SSDT repo.

---

## 7. Sample Queries

### List all audited customers with dates

```sql
SELECT 
    ext.CID,
    ext.AuditDate,
    dc.UserName,
    dc.Country
FROM [BI_DB_dbo].[BI_DB_AMLComment_Risk_Score_Report_Ext] ext
LEFT JOIN [DWH_dbo].[Dim_Customer] dc ON ext.CID = dc.RealCID
ORDER BY ext.AuditDate DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found. The external AML compliance tool feeding this table is unidentified. Documentation would reside in the AML/Compliance team's internal tooling documentation.

---

*Generated: 2026-04-23 | Quality: 5.0/10 | Phases: 4/14*
*Tiers: 0 T1, 0 T2, 0 T3, 2 T4, 0 T5 | Elements: 2/2, Logic: 4/10, Data Evidence: 2/10*
*Object: BI_DB_dbo.BI_DB_AMLComment_Risk_Score_Report_Ext | Type: Table | Production Source: Unknown external AML system*
