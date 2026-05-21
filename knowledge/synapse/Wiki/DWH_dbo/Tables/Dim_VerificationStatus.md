# DWH_dbo.Dim_VerificationStatus

> Lookup dimension for customer identity verification status values from the UserApiDB system. 3-row table classifying verification workflow states. Sourced daily from UserApiDB.Dictionary.VerificationStatus via SP_Dictionaries_DL_To_Synapse.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | UserApiDB.Dictionary.VerificationStatus |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED (VerificationStatusID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationstatus` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`DWH_dbo.Dim_VerificationStatus` is a 3-row reference table holding verification status values from the UserApiDB system — a separate verification workflow database distinct from the main etoroDB. While `Dim_VerificationLevel` (etoro.Dictionary) tracks the KYC tier (Level 0-3), this table tracks the verification *workflow state* within UserApiDB's verification pipeline.

Source: `UserApiDB.Dictionary.VerificationStatus`. The Generic Pipeline exports this daily to Bronze, staged into `DWH_staging.UserApiDB_Dictionary_VerificationStatus`, and SP_Dictionaries_DL_To_Synapse loads with TRUNCATE + INSERT. No upstream wiki exists for this table (UserApiDB schema not yet documented).

The exact business meaning of each status value (VerificationStatusID) is derived from SP code and live data sampling only. With 3 rows observed at Phase 2, this is a compact classification table for verification workflow states.

---

## 2. Business Logic

### 2.1 Verification Workflow States

**What**: Classifies verification workflow states from the UserApiDB verification system.

**Columns Involved**: `VerificationStatusID`, `Name`

**Rules**:
- Exactly 3 status values present (observed in live sample)
- Source is UserApiDB, a separate system from the main etoroDB — this represents a different verification workflow concept than `Dim_VerificationLevel`
- Specific ID-to-name mapping requires domain expert review (no upstream wiki available — Tier 3)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE is optimal for this 3-row table. Clustered index on `VerificationStatusID` for point lookups.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve VerificationStatusID | JOIN DWH fact/dim table ON VerificationStatusID = Dim_VerificationStatus.VerificationStatusID |

### 3.3 Gotchas

- **Different from Dim_VerificationLevel**: This table comes from UserApiDB (not etoro.Dictionary). The two "verification" dimensions represent different concepts — tier vs. workflow state
- **No upstream wiki**: Value descriptions are Tier 3 (inferred from name column only); domain expert validation recommended

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 2 — SP ETL code | (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| Tier 3 — live data sampling | (Tier 3 — Phase 2 live sample) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | VerificationStatusID | int | YES | Nullable integer identifier for the verification status, sourced from UserApiDB_Dictionary_VerificationStatus. Not declared as a primary key or indexed in the DDL. |
| 2 | Name | varchar(20) | YES | Human-readable label for the verification status. The name values observed (3 rows) describe verification workflow states from the UserApiDB system. Truncated to varchar(20) — longer names may be clipped. (Tier 3 — Phase 2 live sample) |
| 3 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Not a production change timestamp. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| VerificationStatusID | UserApiDB.Dictionary.VerificationStatus | VerificationStatusID | Passthrough |
| Name | UserApiDB.Dictionary.VerificationStatus | Name | Passthrough |
| UpdateDate | — | — | ETL-computed: GETDATE() at load time |

### 5.2 ETL Pipeline

```
UserApiDB.Dictionary.VerificationStatus (UserApiDB, 3 rows)
  |
  v [Generic Pipeline — daily, Override, parquet]
Bronze/UserApiDB/Dictionary/VerificationStatus/
  |
  v [staging]
DWH_staging.UserApiDB_Dictionary_VerificationStatus
  |
  v [SP_Dictionaries_DL_To_Synapse — TRUNCATE + INSERT]
DWH_dbo.Dim_VerificationStatus (3 rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | UserApiDB.Dictionary.VerificationStatus | 3-row verification workflow status table (UserApiDB) |
| Lake | Bronze/UserApiDB/Dictionary/VerificationStatus/ | Daily full export (Override, parquet) |
| Staging | DWH_staging.UserApiDB_Dictionary_VerificationStatus | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; UpdateDate=GETDATE() |
| Target | DWH_dbo.Dim_VerificationStatus | 3 rows |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| VerificationStatusID | UserApiDB.Dictionary.VerificationStatus | Production source (no upstream wiki) |

### 6.2 Referenced By (other objects point to this)

No known DWH consumers identified at documentation time. Domain expert review recommended to identify fact/dim tables that reference `VerificationStatusID`.

---

## 7. Sample Queries

### 7.1 List all verification statuses

```sql
SELECT VerificationStatusID, Name, UpdateDate
FROM [DWH_dbo].[Dim_VerificationStatus]
ORDER BY VerificationStatusID
```

### 7.2 ETL freshness check

```sql
SELECT VerificationStatusID, Name, UpdateDate
FROM [DWH_dbo].[Dim_VerificationStatus]
ORDER BY VerificationStatusID
-- UpdateDate should equal today's date if ETL ran successfully
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|-------------------------|
| [Customer Statuses in BO](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/11844354213/Customer+Statuses+in+BO) | Confluence | Customer status is driven by verification, risk, and moderation parameters—how “verification” gates what a client can do on-platform. |
| [Verification](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/11680940206/Verification) | Confluence | FTD window and verification deadlines; failing verification can move accounts to **Pending Verification**—workflow context for verification state dimensions. |
| [Phone Verification](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/11673403756/Phone+Verification) | Confluence | Phone verification as part of mandatory account verification—additional verification channel beyond document-based checks. |

---

*Generated: 2026-03-19 | Quality: 7.2/10 | Phases: 7/14 (simple-dict fast-path: P3/P5/P6/P7/P9B/P10 skipped)*
*Tiers: 0 T1, 2 T2, 1 T3, 0 T4-Inferred | Elements: 7.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 9.0/10*
*Object: DWH_dbo.Dim_VerificationStatus | Type: Table | Production Source: UserApiDB.Dictionary.VerificationStatus*
