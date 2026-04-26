# BI_DB_dbo.BI_DB_Failed_Verification_MA

> 1,130-row daily TRUNCATE+INSERT marketing automation table identifying customers with failed KYC document verification in the last 3 days. Filters BI_DB_Operations_Onboarding_Flow_UserKPIs to partially verified users (VL2 but not VL3) whose documents were not approved, mapping rejection reasons to 22 standardized codes. Populated by SP_Failed_Verification_MA.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_Operations_Onboarding_Flow_UserKPIs via SP_Failed_Verification_MA |
| **Refresh** | Daily (SB_Daily, Priority 0) — TRUNCATE + INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

BI_DB_Failed_Verification_MA feeds marketing automation workflows with customers whose KYC document verification has recently failed. It identifies users who have passed phone verification and VL2 (Level 2) but not VL3 (Level 3), where the non-verification reason is specifically "Docs not Approved" and the rejection happened within the last 3 days.

The table contains ~1,130 rows (TRUNCATE+INSERT daily, so the count reflects the current 3-day window). Each row represents one customer (GCID) with their rejection reason mapped to a standardized code from a 22-item lookup table covering POI (Proof of Identity) and POA (Proof of Address) rejection categories.

The SP was authored by Eti Rozolio (2025-05-04) for marketing automation purposes — likely to trigger re-engagement emails or push notifications prompting users to resubmit documents.

The filter criteria ensure only actionable cases are included:
- Phone-verified (ManuallyVerified or AutomaticallyVerified)
- US screening passed (NoMatch)
- Not already EV-verified
- Documents specifically not approved (not other non-verification reasons)
- Recent rejection (within 3 days)

---

## 2. Business Logic

### 2.1 Population Filter

**What**: Identifies customers stuck in KYC limbo — passed phone but failed document verification recently.

**Columns Involved**: All columns (filter determines population)

**Rules**:
- IsVL3 = 0 AND IsVL2 = 1 (partially verified — phone done, docs pending)
- PhoneVerification IN ('ManualyVerified', 'AutomaticallyVerified') — note: typo 'ManualyVerified' in SP
- US_ScreeningStatus = 'NoMatch' (or NULL, treated as NoMatch)
- EV_MatchStatus <> 'Verified' (not already electronically verified)
- NonVerificationReason = 'Docs not Approved'
- POI or POA ResponseDateTime >= GETDATE() - 3 days (recent rejection)

### 2.2 Rejection Reason Standardization

**What**: Maps free-text rejection reasons to 22 standardized codes.

**Columns Involved**: `ReasonNumber`, `RejectReasonName`, `RejectionReasonPOI`, `RejectionReasonPOA`

**Rules**:
- 22 predefined codes (1-22) covering POI (1-7, 14, 17-19, 21) and POA (8-16, 20, 22) categories
- ReasonNumber = COALESCE(POI match, POA match, 0) — 0 = unmatched reason
- RejectReasonName = COALESCE(POI matched name, POA matched name, raw POI text, raw POA text)
- Unmatched reasons (ReasonNumber=0) include: Duplicate, High Risk Country, Underage, SSN Card, Corrupted File, etc.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP. Small table (~1K rows), any query pattern is fine.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Count failures by rejection type | `GROUP BY ReasonNumber, RejectReasonName` |
| Failures by country/regulation | `GROUP BY CountryName, CurrentRegulation` |
| Unmatched rejection reasons | `WHERE ReasonNumber = 0` |
| POI vs POA failures | `WHERE RejectionReasonPOI IS NOT NULL` vs `WHERE RejectionReasonPOA IS NOT NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON f.GCID = dc.GCID | Full customer profile |

### 3.4 Gotchas

- **TRUNCATE table**: All rows represent the current 3-day window. No historical data is retained.
- **ReasonNumber=0**: 19 distinct unmatched rejection reason texts fall to 0 (not in the 22 predefined codes). These include: Duplicate, High Risk Country, Underage, SSN Card, Corrupted File, Other.
- **NonVerificationReason always 'Docs not Approved'**: This is a filter condition, so the column is constant across all rows.
- **EV_MatchStatus never 'Verified'**: Also a filter condition — blank (64%), NotVerified (27%), PartiallyVerified (9%).
- **Typo in SP**: 'ManualyVerified' (single 'l') is the actual value in the source data.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 2 | SP code analysis | High — traced from ETL stored procedure logic |
| Tier 5 | ETL metadata | Standard — system-generated ETL column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | NO | Global Customer ID — cross-platform identifier. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs. FK to Dim_Customer. (Tier 2 — SP_Failed_Verification_MA) |
| 2 | ReasonNumber | int | YES | Standardized rejection reason code. 1-22 = mapped to predefined POI/POA categories; 0 = unmatched reason text. COALESCE(POI match, POA match, 0). Top values: 11=POA cannot be accepted (31%), 10=POA missing address (21%), 8=POA older than 3 months (13%). (Tier 2 — SP_Failed_Verification_MA) |
| 3 | RejectReasonName | nvarchar(100) | YES | Rejection reason display text. Mapped name from 22-code lookup when matched; otherwise raw RejectionReasonPOI or RejectionReasonPOA text. COALESCE(POI match name, POA match name, raw POI, raw POA). (Tier 2 — SP_Failed_Verification_MA) |
| 4 | CountryName | nvarchar(100) | YES | Customer's registered country name. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs. (Tier 2 — SP_Failed_Verification_MA) |
| 5 | CurrentRegulation | nvarchar(100) | YES | Customer's current regulatory jurisdiction. Values: BVI, CySEC, FCA, ASIC, FSA Seychelles, eToroUS, FINRAONLY, etc. Passthrough from source. (Tier 2 — SP_Failed_Verification_MA) |
| 6 | RejectionReasonPOA | nvarchar(100) | YES | Raw Proof of Address rejection reason text from source. NULL if only POI was rejected. Used as input to ReasonNumber/RejectReasonName mapping. (Tier 2 — SP_Failed_Verification_MA) |
| 7 | RejectionReasonPOI | nvarchar(100) | YES | Raw Proof of Identity rejection reason text from source. NULL if only POA was rejected. Used as input to ReasonNumber/RejectReasonName mapping. (Tier 2 — SP_Failed_Verification_MA) |
| 8 | NonVerificationReason | nvarchar(100) | YES | Reason for non-verification. Always 'Docs not Approved' in this table (filter condition). (Tier 2 — SP_Failed_Verification_MA) |
| 9 | EV_MatchStatus | nvarchar(100) | YES | Electronic verification match status. Never 'Verified' (filter condition). 4 values: blank (64%), NotVerified (27%), PartiallyVerified (9%), None (<1%). (Tier 2 — SP_Failed_Verification_MA) |
| 10 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was inserted by the ETL pipeline. Set to GETDATE() at insert time. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| GCID | BI_DB_Operations_Onboarding_Flow_UserKPIs | GCID | Passthrough |
| ReasonNumber | #TempRejectReasons | ReasonNumber | COALESCE match on POI/POA text |
| RejectReasonName | #TempRejectReasons / source | RejectReasonName | COALESCE cascade |
| CountryName–EV_MatchStatus | BI_DB_Operations_Onboarding_Flow_UserKPIs | Various | Passthrough |
| UpdateDate | ETL metadata | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_Operations_Onboarding_Flow_UserKPIs
  |-- Filter: IsVL2=1, IsVL3=0, PhoneVerified, DocsNotApproved, 3-day window ---|
  + #TempRejectReasons (22 predefined POI/POA rejection codes)
  |-- LEFT JOIN on RejectionReasonPOI → ReasonNumber ---|
  |-- LEFT JOIN on RejectionReasonPOA → ReasonNumber ---|
  |-- COALESCE for standardized reason mapping ---|
  v
BI_DB_dbo.BI_DB_Failed_Verification_MA (~1,130 rows)
  TRUNCATE + INSERT
  Daily via SP_Failed_Verification_MA (SB_Daily, Priority 0)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID | DWH_dbo.Dim_Customer | FK — customer identification |

### 6.2 Referenced By (other objects point to this)

No downstream consumers found in SSDT. Likely consumed by marketing automation tools directly.

---

## 7. Sample Queries

### 7.1 Rejection Reason Distribution

```sql
SELECT ReasonNumber, RejectReasonName, COUNT(*) AS cnt
FROM BI_DB_dbo.BI_DB_Failed_Verification_MA
GROUP BY ReasonNumber, RejectReasonName
ORDER BY cnt DESC
```

### 7.2 Failures by Regulation

```sql
SELECT CurrentRegulation, COUNT(*) AS cnt,
       SUM(CASE WHEN RejectionReasonPOI IS NOT NULL THEN 1 ELSE 0 END) AS poi_failures,
       SUM(CASE WHEN RejectionReasonPOA IS NOT NULL THEN 1 ELSE 0 END) AS poa_failures
FROM BI_DB_dbo.BI_DB_Failed_Verification_MA
GROUP BY CurrentRegulation
ORDER BY cnt DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 9 T2, 0 T3, 0 T4, 1 T5 | Elements: 10/10, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Failed_Verification_MA | Type: Table | Production Source: BI_DB_Operations_Onboarding_Flow_UserKPIs via SP_Failed_Verification_MA*
