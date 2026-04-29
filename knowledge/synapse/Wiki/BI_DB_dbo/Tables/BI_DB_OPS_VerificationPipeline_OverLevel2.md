# BI_DB_dbo.BI_DB_OPS_VerificationPipeline_OverLevel2

> 880K-row operations verification pipeline table tracking customers above verification level 1 within a 5-month rolling window. Classifies each customer into one of 16 verification outcome categories based on EV status, document uploads, screening hits, phone/email verification, and risk alerts. Daily TRUNCATE+INSERT via SP_OPS_VerificationPipeline_Level2. Registrations from Nov 2025 to present.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer (primary) via `SP_OPS_VerificationPipeline_Level2` |
| **Refresh** | Daily (TRUNCATE+INSERT, 5-month rolling window from first day of current month minus 5 months) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | Pavlina Masoura (2021-12-28) |
| **Row Count** | ~880,112 (as of 2026-04-12) |

---

## 1. Business Meaning

`BI_DB_OPS_VerificationPipeline_OverLevel2` provides a comprehensive breakdown of where customers stand in the KYC verification pipeline from level 2 onward. It covers a 5-month rolling window of new registrations (customers with `RegisteredReal >= 5 months ago`) who have reached at least VL2.

The table's primary output is the `Category` column — a 16-value classification that diagnoses exactly why a customer is at their current verification state. Categories distinguish between EV-verified vs non-EV paths, document upload completeness (both docs / POI only / POA only / none), screening hit resolution, phone/email verification gaps, risk alert blocks, and timing of VL2→VL3 transitions.

Key metrics tracked: DDCategoryVL2toVL3 (time bucket from VL2 to VL3, ranging from <=3 minutes to >30 days or NotCompleted), TotalHits from screening providers, IsManual flag for manual case resolution, and document upload status for POI/POA.

As of 2026-04-12: 880K accounts — 60% at VL2 (530K), 40% at VL3 (350K). Largest categories: No Docs Uploaded (386K, 44%), EV + Multiple issues (132K, 15%), EV+L3 completed (100K, 11%), Not EV + L3 (93K, 11%).

---

## 2. Business Logic

### 2.1 Category Classification (16 outcomes)

**What**: Complex CASE-based classification of each customer's verification state.
**Columns Involved**: `Category`, `EvMatchStatusName`, `VerificationLevelID`, `TotalHits`, `IsManual`, `PhoneVerifiedName`, `IsEmailVerified`, `RiskAlerts`, `ScreeningStatus`, document upload flags
**Rules**:
- **EV+L3**: EV Verified + VL3 + no pending manual hits + phone auto-verified + email verified + no alerts (100K, 11%)
- **Error**: EV Verified + VL2 + screening NoMatch + phone verified + email verified + no alerts — should be VL3 (2.4K)
- **EV + L2/L3: Phone Not Verified**: EV Verified + no hits + email OK but phone not verified (14K)
- **EV + L2/L3: Email Not Verified**: EV Verified + no hits + phone OK but email not verified (42K)
- **EV + L2/L3: With Hits Pending**: EV Verified + screening not NoMatch (7K)
- **EV + L2/L3: With Alerts Pending**: EV Verified + all clear except risk alerts (2.2K)
- **EV + L2/L3: Multiple**: EV Verified + multiple blocking issues (132K)
- **Not EV + L3**: Not EV verified but reached VL3 via documents (93K)
- **Not EV + L2/L3: No Docs Uploaded**: Not EV + no docs (386K, largest)
- **Not EV + L2/L3: POI Uploaded Only**: Only POI submitted (47K)
- **Not EV + L2/L3: POA Uploaded Only**: Only POA submitted (11K)
- **No EV + L2/L3: Docs Rejected**: Docs submitted but POI or POA rejected (38K)
- **No EV + L2: Docs Accepted + Pending Hits**: Docs OK but screening hits unresolved (1.7K)
- **No EV + L2: Docs Accepted + Alerts Pending**: Docs OK but risk alerts (234)
- **No EV + L2: Docs Accepted + Phone Not Verified**: Docs OK but phone not verified (162)
- **NULL category**: Unclassified (3.8K — falls through all CASE branches)

### 2.2 DDCategoryVL2toVL3 — Transition Timing

**What**: Time bucket measuring how long it took from VL2 to VL3 transition.
**Columns Involved**: `DDCategoryVL2toVL3`
**Rules**:
- VL3<=3minutes, VL3<=5minutes, VL3<=10minutes, VL3<=20minutes, VL3<=1Hour
- 1Hour<VL3<=24Hours, 1Day<VL3<=7Days, 7Days<VL3<=14Days, 14Days<VL3<=30Days, VL3>30Days
- NotCompleted (VL3 date is NULL — still at VL2)
- Source: `general.etoro_History_BackOfficeCustomer` VL change timestamps via LAG window function

### 2.3 IsManual — Screening Resolution Type

**What**: Whether screening case was manually resolved by a human agent vs automated.
**Columns Involved**: `IsManual`, `TotalHits`
**Rules**:
- 0 = automated resolution (provider username = 'devteam-compliance-ops@etoro.com')
- 1 = manual human resolution
- NULL = no screening record
- MAX across all cases per customer (any manual = 1)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no preferred join key. For JOINs to Dim_Customer use `RealCID = RealCID`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Verification funnel by category | `SELECT Category, COUNT(*) FROM ... GROUP BY Category ORDER BY COUNT(*) DESC` |
| Customers stuck at VL2 who should be VL3 | `WHERE Category = 'Error'` |
| VL2→VL3 transition speed | `SELECT DDCategoryVL2toVL3, COUNT(*) FROM ... WHERE VerificationLevelID=3 GROUP BY DDCategoryVL2toVL3` |
| Customers with pending screening hits | `WHERE Category LIKE '%Hits Pending%'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `RealCID = RealCID` | Full customer profile |

### 3.4 Gotchas

- **Columns with spaces**: `[Uploaded 2 Docs]`, `[Uploaded POI only]`, `[Uploaded POA only]` require square brackets
- **RiskAlerts is varchar**: Despite being 0/1, stored as varchar(max) due to CASE producing string in intermediate steps
- **NULL Category**: ~3.8K rows have NULL Category — these fall through all CASE branches (edge cases not covered)
- **5-month rolling window**: Data only covers recent registrations — historical customers excluded
- **VerificationLevelID can be 2 or 3**: Unlike the VL2Stuck table, this one includes already-verified (VL3) customers
- **NOLOCK on Dim_Customer**: SP uses WITH(NOLOCK) which is unnecessary on Synapse (snapshot isolation default)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available knowledge, limited confidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | bigint | YES | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 2 | EvMatchStatusName | varchar(max) | YES | Human-readable label for the EV match status. Renamed from Name in production source. Values: None, PartiallyVerified, Verified, NotVerified. Passthrough from Dim_EvMatchStatus. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 3 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values in this table: 2 (intermediate) or 3 (fully verified). Passthrough from Dim_Customer. (Tier 1 — BackOffice.Customer) |
| 4 | Country | varchar(100) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |
| 5 | Uploaded 2 Docs | int | YES | 1 if customer uploaded both POI (Proof of Identity) and POA (Proof of Address) documents within the 5-month window; 0 otherwise. (Tier 2 — SP_OPS_VerificationPipeline_Level2) |
| 6 | Uploaded POI only | int | YES | 1 if customer uploaded only POI (no POA) within the window; 0 otherwise. (Tier 2 — SP_OPS_VerificationPipeline_Level2) |
| 7 | Uploaded POA only | int | YES | 1 if customer uploaded only POA (no POI) within the window; 0 otherwise. (Tier 2 — SP_OPS_VerificationPipeline_Level2) |
| 8 | TotalHits | bigint | YES | Total screening hits from the main screening provider. Higher values indicate more potential matches requiring review. NULL if no screening record. (Tier 2 — SP_OPS_VerificationPipeline_Level2, ScreeningService) |
| 9 | PhoneVerifiedName | varchar(100) | YES | Human-readable verification state label. Note: ID=2 has value "ManualyVerified" — a production typo (single 'l') preserved verbatim from etoro.Dictionary.PhoneVerified. Passthrough from Dim_PhoneVerified. (Tier 1 — Dictionary.PhoneVerified) |
| 10 | IsEmailVerified | int | YES | Raw email verification flag from Dim_Customer. 1=verified, 0=not verified. Passthrough from Dim_Customer. (Tier 1 — BackOffice.Customer) |
| 11 | IsManual | int | YES | 1 if screening case was manually resolved by a human agent (ProviderUsername != automated compliance bot); 0 if auto-resolved; NULL if no screening record. (Tier 2 — SP_OPS_VerificationPipeline_Level2, ScreeningService) |
| 12 | DDCategoryVL2toVL3 | varchar(max) | YES | Time bucket for VL2→VL3 transition duration. Values: VL3<=3minutes, VL3<=5minutes, VL3<=10minutes, VL3<=20minutes, VL3<=1Hour, 1Hour<VL3<=24Hours, 1Day<VL3<=7Days, 7Days<VL3<=14Days, 14Days<VL3<=30Days, VL3>30Days, NotCompleted. Derived from History_BackOfficeCustomer VL change timestamps. (Tier 2 — SP_OPS_VerificationPipeline_Level2) |
| 13 | ScreeningStatus | varchar(max) | YES | Screening service result from Dim_ScreeningStatus. Key value: 'NoMatch' = clear. NULL if no screening record. (Tier 2 — SP_OPS_VerificationPipeline_Level2) |
| 14 | RegisteredReal | datetime | YES | Account registration date (renamed from Registered). Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 15 | Category | varchar(max) | YES | Verification pipeline outcome classification. 16 distinct values diagnosing exactly why a customer is at their current VL state. See Section 2.1 for full breakdown. NULL for unclassified edge cases. (Tier 2 — SP_OPS_VerificationPipeline_Level2) |
| 16 | Regulation | varchar(100) | YES | Short code for the regulation. Values match production Dictionary.Regulation.Name. Passthrough from Dim_Regulation. (Tier 1 — Dictionary.Regulation) |
| 17 | RiskAlerts | varchar(max) | YES | 1 if customer has Relations or HighRiskLogin alerts in BI_DB_RiskAlertManagementTool; 0 otherwise. Stored as varchar despite being binary. (Tier 2 — SP_OPS_VerificationPipeline_Level2) |
| 18 | UpdateDate | datetime | YES | ETL execution timestamp. GETDATE() at SP execution time. All rows share the same value per daily run. (Tier 2 — SP_OPS_VerificationPipeline_Level2) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| RealCID | Customer.CustomerStatic | CID | passthrough via Dim_Customer |
| Country | Dictionary.Country | Name | dim-lookup via Dim_Country |
| VerificationLevelID | BackOffice.Customer | VerificationLevelID | passthrough via Dim_Customer |
| PhoneVerifiedName | Dictionary.PhoneVerified | PhoneVerifiedName | dim-lookup via Dim_PhoneVerified |
| IsEmailVerified | BackOffice.Customer | IsEmailVerified | passthrough via Dim_Customer |
| RegisteredReal | Customer.CustomerStatic | Registered | rename via Dim_Customer |
| Regulation | Dictionary.Regulation | Name | dim-lookup via Dim_Regulation |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (VL>1, IsValidCustomer=1, registered in 5-month window)
  + general.etoro_History_BackOfficeCustomer (VL change history)
  + DWH_dbo.Dim_Country, Dim_EvMatchStatus, Dim_PhoneVerified
  + DWH_dbo.Dim_ScreeningStatus, Dim_Regulation
  + External_ScreeningService (hits, manual resolution)
  + External_BackOffice_CustomerDocument (POI/POA uploads)
  + External_UserApiDB_Ev_CustomerResult (EV provider)
  + BI_DB_RiskAlertManagementTool (risk alerts)
  |
  |-- SP_OPS_VerificationPipeline_Level2 (daily TRUNCATE+INSERT)
  |   Step 1: Build VL change history from History_BackOfficeCustomer
  |   Step 2: Compute verification KPIs (VL transition timing, buckets)
  |   Step 3: Build #pop — base population VL>1 + dim lookups
  |   Step 4: Build #hits — screening hits + manual flag
  |   Step 5: Build #doc/#doctype — document upload classification
  |   Step 6: Build #final — combine all checks + screening + alerts
  |   Step 7: Build #FINALDETAILS — apply Category CASE classification
  |   Step 8: TRUNCATE + INSERT into target
  v
BI_DB_dbo.BI_DB_OPS_VerificationPipeline_OverLevel2 (880K rows, ROUND_ROBIN HEAP)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer (RealCID) | Primary customer dimension |
| Country | DWH_dbo.Dim_Country (Name) | Country dimension |
| EvMatchStatusName | DWH_dbo.Dim_EvMatchStatus | EV identity verification |
| PhoneVerifiedName | DWH_dbo.Dim_PhoneVerified | Phone verification state |
| ScreeningStatus | DWH_dbo.Dim_ScreeningStatus | Screening result |
| Regulation | DWH_dbo.Dim_Regulation (Name) | Regulatory authority |
| RiskAlerts | BI_DB_dbo.BI_DB_RiskAlertManagementTool | Risk alert screening |

### 6.2 Referenced By (other objects point to this)

No known consumers in the current wiki inventory.

---

## 7. Sample Queries

### 7.1 Verification Funnel by Category

```sql
SELECT Category, COUNT(*) AS cnt,
       CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(5,1)) AS pct
FROM BI_DB_dbo.BI_DB_OPS_VerificationPipeline_OverLevel2
GROUP BY Category
ORDER BY cnt DESC
```

### 7.2 Error Cases — Should Be VL3

```sql
SELECT RealCID, Country, Regulation, ScreeningStatus, PhoneVerifiedName
FROM BI_DB_dbo.BI_DB_OPS_VerificationPipeline_OverLevel2
WHERE Category = 'Error'
ORDER BY RegisteredReal ASC
```

### 7.3 VL2→VL3 Transition Speed Distribution

```sql
SELECT DDCategoryVL2toVL3, COUNT(*) AS cnt
FROM BI_DB_dbo.BI_DB_OPS_VerificationPipeline_OverLevel2
WHERE VerificationLevelID = 3
  AND DDCategoryVL2toVL3 IS NOT NULL
GROUP BY DDCategoryVL2toVL3
ORDER BY cnt DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable due to permissions).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 7 T1, 11 T2, 0 T3, 0 T4, 0 T5 | Elements: 18/18, Logic: 9/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_OPS_VerificationPipeline_OverLevel2 | Type: Table | Production Source: DWH_dbo.Dim_Customer via SP_OPS_VerificationPipeline_Level2*
