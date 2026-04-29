# BI_DB_dbo.BI_DB_US_Customer_Acount_Reconcilation

> 347M-row daily Apex-vs-eToro account reconciliation table for US FinCEN+FINRA regulation. FULL OUTER JOIN identifies accounts existing on one side but not the other. Daily DELETE @Date + INSERT via `SP_US_Customer_Acount_Reconcilation`. Covers dates 2021-01-29 to present.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | External_USABroker_Apex tables + DWH_dbo.Dim_Customer via `SP_US_Customer_Acount_Reconcilation` |
| **Refresh** | Daily (DELETE @Date + INSERT) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | — |
| **Row Count** | ~347,000,000 (as of 2026-04-12) |

---

## 1. Business Meaning

`BI_DB_US_Customer_Acount_Reconcilation` performs daily compliance reconciliation between the eToro platform and Apex Clearing for US-regulated accounts (FinCEN + FINRA, RegulationID=8). The SP builds two populations — Apex accounts (from External_USABroker tables) and eToro accounts (from Dim_Customer WHERE RegulationID=8) — then performs a FULL OUTER JOIN to detect mismatches.

Only mismatch records are persisted: accounts existing on Apex but not eToro ('Missing In eToro Side', ~372K on latest date), or on eToro but not Apex ('Missing In Apex Side', ~12.5K on latest date). The 'Check' status exists in logic but is never persisted — both-side matches are excluded. Historical rows accumulate daily (347M rows across ~5 years).

Primary purpose: compliance monitoring of brokerage account synchronization between eToro and Apex Clearing.

---

## 2. Business Logic

### 2.1 FULL OUTER JOIN Reconciliation

**What**: Detects accounts present on one side but absent on the other.
**Columns Involved**: `ReconStatus`, `ApexID`, `RealCID`
**Rules**:
- Step 1: Pull Apex data from 3 External_USABroker tables (ApexData, ApexStatus dictionary, UserData)
- Step 2: Pull eToro data from Dim_Customer WHERE RegulationID=8
- Step 3: FULL OUTER JOIN #apexdata ON CID = RealCID
- Filter: WHERE ApexID IS NULL OR RealCID IS NULL (only mismatches kept)
- ReconStatus = CASE: ApexID IS NULL → 'Missing In Apex Side', RealCID IS NULL → 'Missing In eToro Side', ELSE → 'Check'

### 2.2 Final Enrichment Join

**What**: Enriches mismatch records with customer dimensions.
**Columns Involved**: `VerificationLevelID`, `Regulation`, `EtoroAcountStatus`
**Rules**:
- Join back to Dim_Customer via COALESCE(RealCID, ApexCID)
- Dim_Regulation for regulation name, Dim_AccountStatus for status name

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — always filter on `Date` to avoid scanning 347M rows.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Latest day reconciliation summary | `WHERE Date = (SELECT MAX(Date) FROM ...) GROUP BY ReconStatus` |
| Missing-in-Apex trend over time | `WHERE ReconStatus = 'Missing In Apex Side' GROUP BY Date` |
| Specific customer reconciliation | `WHERE ApexCID = {cid} OR RealCID = {cid}` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `RealCID = RealCID` | Full customer profile |
| DWH_dbo.Dim_VerificationLevel | `VerificationLevelID = VerificationLevelID` | KYC level name |

### 3.4 Gotchas

- **Typo in table name**: "Acount" (not Account) and "Reconcilation" (not Reconciliation) — preserved from original SP
- **No 'Check' rows in live data**: Only mismatches are persisted; both-side matches are filtered out
- **347M rows**: Always filter on Date to avoid full scans
- **NULL ApexID or RealCID**: By design — NULL indicates the missing side of the reconciliation

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 5 | ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | NO | Reconciliation run date. The @Date parameter passed to the SP. (Tier 2 — SP_US_Customer_Acount_Reconcilation) |
| 2 | ApexID | varchar(20) | YES | The unique account identifier assigned by Apex Clearing. Format: '3' prefix + alphanumeric sequence. Maximum 8 characters. Immutably bound to one GCID. NULL for records missing on Apex side. (Tier 1 — USABroker.Apex.ApexData) |
| 3 | ApexCID | int | YES | Platform Customer ID. Links to the user management system. NULL for records created before CID tracking was added. (Tier 1 — USABroker.Apex.UserData) |
| 4 | ApexApprovedDate | date | YES | Timestamp of manual approval. NULL for auto-approved accounts. Renamed from ApprovedByDate. (Tier 1 — USABroker.Apex.UserData) |
| 5 | ApexStatus | varchar(100) | YES | UPPERCASE display name for the status. Values: COMPLETE, RESTRICTED, REJECTED, SUSPENDED, ACTION_REQUIRED, ERROR, BACK_OFFICE. (Tier 1 — USABroker.Dictionary.ApexStatus) |
| 6 | ReconStatus | varchar(40) | YES | ETL-computed reconciliation outcome. Values: 'Missing In Apex Side' (eToro-only account), 'Missing In eToro Side' (Apex-only account). 'Check' exists in logic but is never persisted. (Tier 2 — SP_US_Customer_Acount_Reconcilation) |
| 7 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Only populated for eToro-side matches. NULL for Apex-only records. (Tier 1 — Customer.CustomerStatic) |
| 8 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Joined via COALESCE(RealCID, ApexCID) to Dim_Customer. (Tier 1 — BackOffice.Customer) |
| 9 | Regulation | varchar(40) | YES | Short code for the regulation. Dim-lookup from Dim_Regulation via RegulationID. Expected value: US FinCEN+FINRA regulation. (Tier 1 — Dictionary.Regulation) |
| 10 | EtoroAcountStatus | varchar(20) | YES | Human-readable label for the account state: 'Open', 'Closed', or 'N/A'. Dim-lookup from Dim_AccountStatus. Note: column name has typo (Acount, not Account). (Tier 1 — Dictionary.AccountStatus) |
| 11 | UpdateDate | datetime | YES | ETL execution timestamp. GETDATE() at SP execution time. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| ApexID | USABroker.Apex.ApexData | ApexID | passthrough |
| ApexCID | USABroker.Apex.UserData | CID | passthrough |
| ApexApprovedDate | USABroker.Apex.UserData | ApprovedByDate | rename |
| ApexStatus | USABroker.Dictionary.ApexStatus | Name | dim-lookup |
| RealCID | Customer.CustomerStatic | CID | passthrough via Dim_Customer |
| VerificationLevelID | BackOffice.Customer | VerificationLevelID | passthrough via Dim_Customer |
| Regulation | Dictionary.Regulation | Name | dim-lookup |
| EtoroAcountStatus | Dictionary.AccountStatus | AccountStatusName | dim-lookup |

### 5.2 ETL Pipeline

```
External_USABroker_Apex_ApexData + External_USABroker_Apex_UserData + External_USABroker_Dictionary_ApexStatus
  → #apexdata (Apex-side population)
DWH_dbo.Dim_Customer WHERE RegulationID=8
  → #etorodata (eToro-side population)
  |
  |-- FULL OUTER JOIN ON CID = RealCID
  |   WHERE ApexID IS NULL OR RealCID IS NULL (mismatches only)
  |
  |-- Enrich via COALESCE(RealCID, ApexCID) → Dim_Customer → Dim_Regulation, Dim_AccountStatus
  |
  |-- SP_US_Customer_Acount_Reconcilation @Date
  |   DELETE WHERE Date=@Date, INSERT
  v
BI_DB_dbo.BI_DB_US_Customer_Acount_Reconcilation (347M rows, ROUND_ROBIN HEAP)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer (RealCID) | eToro customer record |
| ApexCID | DWH_dbo.Dim_Customer (RealCID) | Apex-side customer record (via CID mapping) |
| VerificationLevelID | DWH_dbo.Dim_VerificationLevel | KYC level |
| Regulation | DWH_dbo.Dim_Regulation | Regulation dimension |
| EtoroAcountStatus | DWH_dbo.Dim_AccountStatus | Account status dimension |

### 6.2 Referenced By (other objects point to this)

No known consumers in the current wiki inventory.

---

## 7. Sample Queries

### 7.1 Latest Day Reconciliation Summary

```sql
SELECT ReconStatus, COUNT(*) AS cnt
FROM BI_DB_dbo.BI_DB_US_Customer_Acount_Reconcilation
WHERE Date = (SELECT MAX(Date) FROM BI_DB_dbo.BI_DB_US_Customer_Acount_Reconcilation)
GROUP BY ReconStatus
```

### 7.2 Missing-in-Apex Trend (Last 30 Days)

```sql
SELECT Date, COUNT(*) AS missing_in_apex
FROM BI_DB_dbo.BI_DB_US_Customer_Acount_Reconcilation
WHERE ReconStatus = 'Missing In Apex Side'
  AND Date >= DATEADD(DAY, -30, GETDATE())
GROUP BY Date
ORDER BY Date
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 8 T1, 2 T2, 0 T3, 0 T4, 1 T5 | Elements: 11/11, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_US_Customer_Acount_Reconcilation | Type: Table | Production Source: External_USABroker + Dim_Customer via SP_US_Customer_Acount_Reconcilation*
