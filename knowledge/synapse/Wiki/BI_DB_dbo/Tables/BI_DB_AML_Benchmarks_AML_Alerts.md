# BI_DB_dbo.BI_DB_AML_Benchmarks_AML_Alerts

> AML benchmarking table tracking AML alert-driven customer status change events — each row records a CID whose PlayerStatus was changed as a result of an AML alert, with the status code, reason, sub-reason, and precise change timestamp. Currently **empty (0 rows as of 2026-04-23)**. No writer SP found in the SSDT repo; table is likely populated by an external AML compliance tool or was decommissioned. Companion to `BI_DB_AML_Benchmarks_Risk_Classification` (tracks risk classification changes). Distribution: ROUND_ROBIN, CLUSTERED on CID.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table — AML benchmarking: alert-driven status change log |
| **Production Source** | Unknown — no SSDT writer SP; likely external AML compliance tool |
| **Refresh** | Unknown — table is empty; no active ETL |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Row Count** | 0 (as of 2026-04-23) |
| **Related Tables** | BI_DB_AML_Benchmarks_Risk_Classification (companion table for risk class changes), DWH_dbo.Dim_PlayerStatus (PlayerStatusID lookup) |

---

## 1. Business Meaning

`BI_DB_AML_Benchmarks_AML_Alerts` is part of an **AML benchmarking dataset** that tracks the history of customer status changes driven by AML alert triggers. Each row represents one AML alert event that resulted in a change to a customer's `PlayerStatus` — the eToro account standing that controls trading, depositing, and withdrawal permissions.

The table captures:
- **Who**: CID and GCID of the customer affected
- **What changed**: PlayerStatus before/after (implied by the stored status code and reason)
- **Why**: PlayerStatusReason and sub-reason codes explaining the AML basis for the change
- **When**: Precise datetime of the AML alert status change

**"Benchmarks" context**: In the eToro AML function, benchmarking measures the AML team's effectiveness — how many customers were correctly flagged, how quickly status changes were applied, and what proportion of alerts led to blocking vs. warning vs. normal reversion. This table provides the event log needed for such calculations alongside its companion table `BI_DB_AML_Benchmarks_Risk_Classification`.

**Current status**: Empty (0 rows as of 2026-04-23). The table is either decommissioned or waiting to be populated by an external AML compliance tool.

---

## 2. Business Logic

### 2.1 AML Alert Status Change Tracking

**What**: Each row records one AML alert-driven change to a customer's PlayerStatus.
**Columns Involved**: CID, GCID, PlayerStatusID, PlayerStatusName, PlayerStatusReasonID, PlayerStatusReason, AMLAlert_ChangeDateTime
**Rules**:
- `PlayerStatusID` reflects the status **resulting** from the AML alert action (not the prior status)
- AML-relevant statuses include: 2=Blocked, 5=Warning, 6=Blocked-Under Investigation
- `AMLAlert_ChangeDateTime` is the precise timestamp of the status change
- `AMLAlert_ChangeDate` is the date portion (derived from ChangeDateTime)
- Clustered on CID for efficient per-customer lookup of alert history

### 2.2 Sub-Reason Hierarchy

**What**: Status changes can have three levels of classification: status, reason, and sub-reason.
**Columns Involved**: PlayerStatusID, PlayerStatusReasonID, PlayerStatusSubReasonID
**Rules**:
- A 3-level hierarchy provides granular categorization: (Status → Reason → Sub-Reason)
- Denormalized descriptions stored alongside ID codes for reporting convenience
- Sub-reason values depend on the reason chosen and may be NULL for simple cases

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on CID. Efficient for per-customer lookups; cross-customer aggregations require broadcast join. Table is currently empty.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| How many AML alert-driven status changes occurred per day? | `SELECT AMLAlert_ChangeDate, COUNT(*) FROM ... GROUP BY AMLAlert_ChangeDate ORDER BY AMLAlert_ChangeDate` |
| Which status changes were most common? | `SELECT PlayerStatusName, PlayerStatusReason, COUNT(*) FROM ... GROUP BY PlayerStatusName, PlayerStatusReason ORDER BY 3 DESC` |
| Alert history for a specific customer | `SELECT * FROM ... WHERE CID = 12345 ORDER BY AMLAlert_ChangeDateTime` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `ON CID = dc.RealCID` | Add customer profile (country, regulation, etc.) |
| BI_DB_AML_Benchmarks_Risk_Classification | `ON CID = rc.CID` | Cross-reference with risk classification changes for same customers |

### 3.4 Gotchas

- **Table is empty**: 0 rows as of 2026-04-23 — no historical data available.
- **AMLAlert_ChangeDateTime vs AMLAlert_ChangeDate**: Both store the same event point; use ChangeDate for date-level aggregation, ChangeDateTime for precise ordering.
- **No prior status**: Table records the resulting status only, not the prior status. For before/after analysis, cross-reference with Fact_SnapshotCustomer for the prior day's PlayerStatusID.
- **Denormalized**: PlayerStatusName, PlayerStatusReason, PlayerStatusSubReason are denormalized copies — may diverge from Dim tables if descriptions were updated after population.

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
| 1 | CID | int | NOT NULL | Customer ID — eToro customer whose PlayerStatus was changed due to an AML alert. FK to DWH_dbo.Dim_Customer.RealCID. (Tier 4 — unknown external AML tool) |
| 2 | GCID | int | NULL | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 4 — unknown external AML tool) |
| 3 | PlayerStatusID | int | NOT NULL | AML-driven PlayerStatus code applied to the customer. 0=N/A, 1=Normal, 2=Blocked, 3=Chat Blocked, 4=Blocked Upon Request, 5=Warning, 6=Blocked-Under Investigation, 7=Scalpers Block, 8=Blocked-PayPal Investigation, 9=Trade & MIMO Blocked, 10=Deposit Blocked, 11=Social Index, 12=Copy Block, 13=Pending Verification, 14=Blocked–Failed Verification, 15=Block Deposit & Trading (FK to Dim_PlayerStatus). (Tier 3 — DWH_dbo.Dim_PlayerStatus) |
| 4 | PlayerStatusName | varchar(50) | NULL | Denormalized name for PlayerStatusID (e.g., 'Blocked', 'Warning'). See PlayerStatusID for full value mapping. (Tier 3 — DWH_dbo.Dim_PlayerStatus) |
| 5 | PlayerStatusReasonID | int | NULL | Reason code explaining why the AML alert triggered the PlayerStatus change. FK to Dim_PlayerStatusReason. (Tier 3 — DWH_dbo.Dim_PlayerStatusReason) |
| 6 | PlayerStatusReason | varchar(50) | NULL | Denormalized reason description for PlayerStatusReasonID (e.g., 'AML Screening Match', 'Suspicious Activity'). (Tier 3 — DWH_dbo.Dim_PlayerStatusReason) |
| 7 | PlayerStatusSubReasonID | int | NULL | Sub-reason code providing additional granularity below PlayerStatusReasonID. FK to Dim_PlayerStatusSubReason. NULL for cases without sub-reason classification. (Tier 3 — DWH_dbo.Dim_PlayerStatusSubReason) |
| 8 | PlayerStatusSubReason | varchar(50) | NULL | Denormalized sub-reason description for PlayerStatusSubReasonID. NULL when no sub-reason applies. (Tier 3 — DWH_dbo.Dim_PlayerStatusSubReason) |
| 9 | AMLAlert_ChangeDateTime | datetime | NOT NULL | Precise datetime when the AML alert-driven status change was applied to the customer account. (Tier 4 — unknown external AML tool) |
| 10 | AMLAlert_ChangeDate | date | NULL | Calendar date of the AML alert status change. Date portion of AMLAlert_ChangeDateTime, stored for efficient date-level aggregation. (Tier 3 — derived from AMLAlert_ChangeDateTime) |
| 11 | UpdateDate | datetime | NOT NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID, GCID | Unknown external AML tool | customer_id | External system population |
| PlayerStatusID–SubReason | DWH_dbo.Dim_PlayerStatus/Reason/SubReason | ID + Name | Denormalized lookup at population time |
| AMLAlert_ChangeDateTime | Unknown external AML tool | change_datetime | Passthrough |
| AMLAlert_ChangeDate | Derived | AMLAlert_ChangeDateTime | Date truncation |
| UpdateDate | ETL metadata | GETDATE() | Pipeline run timestamp |

### 5.2 ETL Pipeline

```
Unknown external AML compliance tool / case management system
  |-- External population mechanism (unknown) ---|
  v
BI_DB_dbo.BI_DB_AML_Benchmarks_AML_Alerts (0 rows, inactive)
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
| PlayerStatusID | DWH_dbo.Dim_PlayerStatus | Status lookup (16 distinct values) |
| PlayerStatusReasonID | DWH_dbo.Dim_PlayerStatusReason | Reason classification lookup |
| PlayerStatusSubReasonID | DWH_dbo.Dim_PlayerStatusSubReason | Sub-reason classification lookup |

### 6.2 Referenced By

No downstream consumers identified.

---

## 7. Sample Queries

### AML alert status change distribution by status type

```sql
SELECT 
    PlayerStatusName,
    PlayerStatusReason,
    COUNT(*) AS AlertCount,
    MIN(AMLAlert_ChangeDate) AS FirstAlert,
    MAX(AMLAlert_ChangeDate) AS LastAlert
FROM [BI_DB_dbo].[BI_DB_AML_Benchmarks_AML_Alerts]
GROUP BY PlayerStatusName, PlayerStatusReason
ORDER BY AlertCount DESC;
```

### Cross-reference AML alerts with risk classification changes for the same customers

```sql
SELECT 
    a.CID,
    a.PlayerStatusName,
    a.AMLAlert_ChangeDate,
    r.RiskClassDesc,
    r.RiskClassChangeDate
FROM [BI_DB_dbo].[BI_DB_AML_Benchmarks_AML_Alerts] a
LEFT JOIN [BI_DB_dbo].[BI_DB_AML_Benchmarks_Risk_Classification] r
    ON a.CID = r.CID
WHERE ABS(DATEDIFF(DAY, a.AMLAlert_ChangeDate, r.RiskClassChangeDate)) <= 7
ORDER BY a.AMLAlert_ChangeDate;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. AML benchmarking documentation, if available, would reside in the AML/Compliance team's operational documentation.

---

*Generated: 2026-04-23 | Quality: 7.0/10 | Phases: 6/14*
*Tiers: 0 T1, 0 T2, 6 T3, 4 T4, 1 T5 | Elements: 11/11, Logic: 7/10, Data Evidence: 2/10*
*Object: BI_DB_dbo.BI_DB_AML_Benchmarks_AML_Alerts | Type: Table | Production Source: Unknown external AML tool*
