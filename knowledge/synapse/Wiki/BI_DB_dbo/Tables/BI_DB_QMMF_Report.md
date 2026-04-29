# BI_DB_dbo.BI_DB_QMMF_Report

> ~1.19B-row daily compliance interaction table tracking QMMF (Qualifying Money Market Funds) customer responses from ComplianceStateDB. Populated by `SP_QMMF_Report` via DELETE+INSERT per date. Contains 898K distinct GCIDs from 2023-08-06 to present, capturing interaction clicks, answers (Yes/No), club tier, and interest opt-in status.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ComplianceStateDB.Compliance (external tables) via `SP_QMMF_Report` |
| **Refresh** | Daily (DELETE+INSERT per LastInteractionDate) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Row Count** | ~1,191,268,551 (daily snapshots, 2023-08-06 to 2026-04-12) |

---

## 1. Business Meaning

`BI_DB_QMMF_Report` tracks customer interactions with the QMMF (Qualifying Money Market Funds) compliance flow. Each row represents one customer (GCID) at one interaction date, recording the number of clicks, the type of interaction action, the customer's answer (Yes/No via StateAdditionalData), their club tier at the time, and whether they opted into interest on balance.

The QMMF flow is triggered by UserInteractionId=39 in ComplianceStateDB, filtered to UserInteractionActionId IN (1=open, 14=accept, 15=decline). The SP enriches the raw interaction data with the customer's club tier (from Dim_PlayerLevel via Fact_SnapshotCustomer at the LastInteractionDate) and their Interest consent status (latest ConsentStatusID=1 from External_Interest_Trade_InterestConsent).

With ~1.19B rows across 898K distinct GCIDs, the table grows daily as each date's snapshot is appended. The companion `BI_DB_QMMF_Report_Finance` table provides financial metrics (unrealized CFD equity and credit) for the subset of customers who accepted (UserInteractionActionId=14).

---

## 2. Business Logic

### 2.1 Interaction Action Types

**What**: QMMF compliance interaction action classification.
**Columns Involved**: `UserInteractionActionId`
**Rules**:
- 1 = Open (customer opened the QMMF interaction)
- 14 = Accept (customer accepted/completed the QMMF flow)
- 15 = Decline (customer declined the QMMF flow)

### 2.2 Club Tier Enrichment

**What**: Customer's eToro Club tier at the time of the last interaction.
**Columns Involved**: `Club`
**Rules**:
- Resolved via Dim_Customer (GCID→RealCID) → Fact_SnapshotCustomer → Dim_Range (date match on LastInteractionDateID) → Dim_PlayerLevel.Name
- Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond

### 2.3 Interest on Balance Opt-In

**What**: Whether the customer has opted into interest on balance.
**Columns Involved**: `InterestOnBalance_Opt_In`
**Rules**:
- Joins to External_Interest_Trade_InterestConsent, takes latest record by ValidFrom (ROW_NUMBER DESC)
- 1 if latest ConsentStatusID = 1
- 0 otherwise (no consent record or ConsentStatusID <> 1)

### 2.4 State Additional Data

**What**: Customer's QMMF questionnaire answer.
**Columns Involved**: `StateAdditionalData`
**Rules**:
- 'Answer-Yes' = customer answered yes to the QMMF question
- 'Answer-No' = customer answered no
- Empty string = no answer recorded

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no preferred join key. ~1.19B rows. **This is a very large table** — always filter on `LastInteractionDate` or `UpdateDate` to avoid full scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Latest snapshot | `WHERE UpdateDate = (SELECT MAX(UpdateDate) FROM BI_DB_QMMF_Report)` |
| QMMF acceptance rate | `SELECT UpdateDate, AVG(CASE WHEN UserInteractionActionId=14 THEN 1.0 ELSE 0.0 END) FROM ... GROUP BY UpdateDate` |
| Club tier breakdown | `SELECT Club, COUNT(DISTINCT GCID) FROM ... WHERE UpdateDate = @latest GROUP BY Club` |
| Interest opt-in rate | `SELECT AVG(CAST(InterestOnBalance_Opt_In AS FLOAT)) FROM ... WHERE UpdateDate = @latest` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_QMMF_Report_Finance | `GCID = GCID AND UpdateDate = Date` | Financial metrics for accepted customers |
| DWH_dbo.Dim_Customer | `GCID = GCID` | Full customer profile |

### 3.4 Gotchas

- **Extremely large table**: ~1.19B rows. Always filter by date to avoid performance issues.
- **Daily snapshots accumulate**: Each day's DELETE+INSERT adds the full population — row count grows linearly with days.
- **GCID not CID**: This table uses Global CID (GCID), not RealCID. Join to Dim_Customer.GCID for RealCID resolution.
- **UserInteractionId always 39**: Hardcoded filter in SP. All rows are QMMF interactions.
- **StateAdditionalData can be empty**: Not NULL but empty string when no answer recorded.
- **Club reflects interaction date**: Club tier is resolved at the LastInteractionDate, not at query time.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | Propagation column (ETL infrastructure) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | NO | Global Customer ID from ComplianceStateDB.Compliance.CustomerInteractions. Identifies the customer across compliance interaction flows. (Tier 2 — SP_QMMF_Report, ComplianceStateDB) |
| 2 | Count_Clicks | int | NO | Number of interaction action counts for this GCID on this interaction. Sourced from CustomerInteractionActionCounts.Count. (Tier 2 — SP_QMMF_Report, ComplianceStateDB) |
| 3 | FirstInteractionDate | date | NO | Date of the first interaction action for this customer-interaction pair. (Tier 2 — SP_QMMF_Report, ComplianceStateDB) |
| 4 | LastInteractionDate | date | NO | Date of the most recent interaction action for this customer-interaction pair. Used as the partition key for DELETE+INSERT. (Tier 2 — SP_QMMF_Report, ComplianceStateDB) |
| 5 | UserInteractionActionId | int | NO | Interaction action type: 1=Open, 14=Accept, 15=Decline. Filtered from ComplianceStateDB UserInteractionDetails. (Tier 2 — SP_QMMF_Report, ComplianceStateDB) |
| 6 | UserInteractionTypeId | int | NO | Interaction type identifier. Always 7 in observed data. From ComplianceStateDB UserInteractionDetails. (Tier 2 — SP_QMMF_Report, ComplianceStateDB) |
| 7 | UserInteractionId | int | NO | User interaction definition ID. Always 39 (QMMF flow) due to SP filter. From ComplianceStateDB UserInteractionDetails. (Tier 2 — SP_QMMF_Report, ComplianceStateDB) |
| 8 | CustomerInteractionId | int | NO | Unique customer interaction instance ID. FK to ComplianceStateDB CustomerInteractionActionCounts. (Tier 2 — SP_QMMF_Report, ComplianceStateDB) |
| 9 | StateAdditionalData | varchar(max) | YES | Customer's QMMF answer: 'Answer-Yes', 'Answer-No', or empty string. From ComplianceStateDB CustomerInteractions.StateAdditionalData. (Tier 2 — SP_QMMF_Report, ComplianceStateDB) |
| 10 | UpdateDate | date | YES | SP execution date (@Date parameter). All rows for a given LastInteractionDate share the same UpdateDate. (Tier 5 — ETL metadata) |
| 11 | Club | varchar(20) | YES | eToro Club tier at the time of LastInteractionDate: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. Resolved via Dim_Customer → Fact_SnapshotCustomer → Dim_PlayerLevel.Name at the interaction date. (Tier 2 — SP_QMMF_Report, Dim_PlayerLevel) |
| 12 | InterestOnBalance_Opt_In | int | YES | Interest on balance consent flag. 1 if latest ConsentStatusID=1 in External_Interest_Trade_InterestConsent (partitioned by CID, ordered by ValidFrom DESC), else 0. (Tier 2 — SP_QMMF_Report, Interest.InterestConsent) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| GCID | ComplianceStateDB.Compliance.CustomerInteractions | GCID | passthrough |
| Count_Clicks | ComplianceStateDB.Compliance.CustomerInteractionActionCounts | Count | rename |
| FirstInteractionDate | ComplianceStateDB.Compliance.CustomerInteractionActionCounts | FirstInteractionDate | passthrough |
| LastInteractionDate | ComplianceStateDB.Compliance.CustomerInteractionActionCounts | LastInteractionDate | passthrough |
| UserInteractionActionId | ComplianceStateDB.Compliance.CustomerInteractionActionCounts | UserInteractionActionId | passthrough (filtered) |
| UserInteractionTypeId | ComplianceStateDB.Compliance.UserInteractionDetails | UserInteractionTypeId | passthrough |
| UserInteractionId | ComplianceStateDB.Compliance.UserInteractionDetails | UserInteractionId | passthrough (always 39) |
| CustomerInteractionId | ComplianceStateDB.Compliance.CustomerInteractionActionCounts | CustomerInteractionId | passthrough |
| StateAdditionalData | ComplianceStateDB.Compliance.CustomerInteractions | StateAdditionalData | passthrough |
| UpdateDate | (computed) | — | @Date parameter |
| Club | DWH_dbo.Dim_PlayerLevel | Name | dim-lookup via Fact_SnapshotCustomer at LastInteractionDate |
| InterestOnBalance_Opt_In | Interest.InterestConsent | ConsentStatusID | CASE: latest=1 → 1, else 0 |

### 5.2 ETL Pipeline

```
ComplianceStateDB.Compliance.CustomerInteractionActionCounts
ComplianceStateDB.Compliance.CustomerInteractions
ComplianceStateDB.Compliance.UserInteractionDetails
  |-- External tables in BI_DB_dbo (lake ingestion) --|
  v
BI_DB_dbo.External_ComplianceStateDB_Compliance_* (3 external tables)
  |
  |-- SP_QMMF_Report (daily DELETE+INSERT by LastInteractionDate)
  |   Step 1: JOIN 3 ComplianceStateDB external tables
  |           Filter: UserInteractionId=39, UserInteractionActionId IN (1,14,15)
  |   Step 2: Enrich with Club tier (Dim_Customer → Fact_SnapshotCustomer → Dim_PlayerLevel)
  |   Step 3: Enrich with Interest opt-in (External_Interest_Trade_InterestConsent, latest by ValidFrom)
  |   Step 4: DELETE + INSERT by LastInteractionDate
  v
BI_DB_dbo.BI_DB_QMMF_Report (~1.19B rows, ROUND_ROBIN HEAP)
  |-- No UC target (Not_Migrated) --|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID | DWH_dbo.Dim_Customer (GCID) | Customer dimension |
| Club | DWH_dbo.Dim_PlayerLevel (Name) | Club tier lookup |
| InterestOnBalance_Opt_In | BI_DB_dbo.External_Interest_Trade_InterestConsent | Interest consent |

### 6.2 Referenced By (other objects point to this)

| Consuming Object | Relationship |
|-----------------|-------------|
| BI_DB_dbo.BI_DB_QMMF_Report_Finance | Sibling table — same SP, financial metrics for accepted customers |

---

## 7. Sample Queries

### 7.1 QMMF Acceptance Rate by Date

```sql
SELECT
    UpdateDate,
    COUNT(*) AS Total_Interactions,
    SUM(CASE WHEN UserInteractionActionId = 14 THEN 1 ELSE 0 END) AS Accepted,
    SUM(CASE WHEN UserInteractionActionId = 15 THEN 1 ELSE 0 END) AS Declined
FROM BI_DB_dbo.BI_DB_QMMF_Report
WHERE UpdateDate >= '2026-01-01'
GROUP BY UpdateDate
ORDER BY UpdateDate
```

### 7.2 Club Tier Distribution of QMMF Respondents

```sql
SELECT
    Club,
    COUNT(DISTINCT GCID) AS Unique_Customers,
    AVG(CAST(InterestOnBalance_Opt_In AS FLOAT)) AS Interest_OptIn_Rate
FROM BI_DB_dbo.BI_DB_QMMF_Report
WHERE UpdateDate = (SELECT MAX(UpdateDate) FROM BI_DB_dbo.BI_DB_QMMF_Report)
GROUP BY Club
ORDER BY Unique_Customers DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found specific to this table. QMMF compliance interactions are managed through ComplianceStateDB.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 11 T2, 0 T3, 0 T4, 1 T5 | Elements: 12/12, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_QMMF_Report | Type: Table | Production Source: ComplianceStateDB.Compliance via SP_QMMF_Report*
