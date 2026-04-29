# BI_DB_dbo.BI_DB_Failed_Verification_MA

> 1,039-row marketing automation table listing VL2 customers who failed document verification within the last 3 days, with categorised rejection reasons for POI and POA documents. Produced daily by `SP_Failed_Verification_MA` via full TRUNCATE+INSERT from `BI_DB_Operations_Onboarding_Flow_UserKPIs`.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.SP_Failed_Verification_MA |
| **Refresh** | Daily TRUNCATE+INSERT (full refresh, 3-day lookback window) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Failed_Verification_MA` is a small, narrow marketing automation table (~1,039 rows as of April 2026) that captures VL2 customers who have not yet reached VL3 specifically because their documents were not approved. The table is designed for Marketing Automation workflows to target customers with actionable verification failure reasons.

The SP filters `BI_DB_Operations_Onboarding_Flow_UserKPIs` to only those customers who:
- Are at VL2 but not VL3 (IsVL2=1, IsVL3=0)
- Have verified their phone (ManualyVerified or AutomaticallyVerified)
- Have no AML screening match (US_ScreeningStatus is NULL or 'NoMatch')
- Are not electronically verified (EV_MatchStatus != 'Verified')
- Have NonVerificationReason = 'Docs not Approved'
- Had their most recent POI or POA response within the last 3 days

Each row represents one customer (keyed by GCID, ~1,034 distinct GCIDs). The SP maps rejection reason text to a hardcoded set of 22 standardised reason codes, prioritising POI rejection reasons over POA. When no match is found in the standardised list, ReasonNumber defaults to 0 and the raw rejection text is preserved.

Distribution by regulation: BVI (881), FSA Seychelles (56), FSRA (37), CySEC (31), eToroUS (24), FINRAONLY (6), ASIC & GAML (4).

---

## 2. Business Logic

### 2.1 Rejection Reason Categorisation

**What**: Maps raw document rejection reason text to a standardised set of 22 numeric codes.

**Columns Involved**: `ReasonNumber`, `RejectReasonName`, `RejectionReasonPOI`, `RejectionReasonPOA`

**Rules**:
- SP creates a temp table `#TempRejectReasons` with 22 hardcoded rejection reason codes (1-22)
- POI reasons (codes 1-7, 17-19, 21): Expired, Incomplete, Clearer Required, Missing, Front side required, Missing expiry date, Back side required, Missing Name details, Cannot be accepted, Under different Name, Screenshot not accepted
- POA reasons (codes 8-13, 15-16, 20, 22): Older than 3 months, Missing issue Date, Missing address details, Cannot be accepted, Under different Name, Unclear/Incomplete, Missing Document, PO Box Not Accepted, Missing Name details, Back side required
- Code 14: POI+POA combined (One Doc Per Requirement)
- `ReasonNumber = COALESCE(trr.ReasonNumber, trr1.ReasonNumber, 0)` — tries POI match first, then POA match, defaults to 0
- `RejectReasonName = COALESCE(trr.RejectReasonName, trr1.RejectReasonName, RejectionReasonPOI, RejectionReasonPOA)` — tries mapped POI, then mapped POA, then raw POI text, then raw POA text
- ReasonNumber=0 indicates the rejection reason does not match any of the 22 standardised codes (e.g., Duplicate, Underage, High Risk Country, Corrupted File, SSN Card - Missing Document, POA - Business/Work Address)

### 2.2 VL2-Not-VL3 Population Filter

**What**: Restricts the population to customers stuck at VL2 due to document issues, excluding other blockers.

**Columns Involved**: All (this is a table-level WHERE filter)

**Rules**:
- `IsVL2=1 AND IsVL3=0` — only VL2 customers not yet fully verified
- `PhoneVerification IN ('ManualyVerified', 'AutomaticallyVerified')` — phone already verified (not a blocker)
- `ISNULL(US_ScreeningStatus, 'NoMatch') = 'NoMatch'` — no AML screening issues
- `ISNULL(EV_MatchStatus, 'NotSentToEV') <> 'Verified'` — not electronically verified (EV not the path to VL3)
- `NonVerificationReason = 'Docs not Approved'` — isolates document-related blockers only
- `CASE WHEN POI_IsApproved=0 THEN POI_ResponseDateTime ELSE POA_ResponseDateTime END >= DATEADD(DAY, -3, GETDATE())` — 3-day recency window on the most recent relevant document response

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP (no clustered index). At ~1K rows, this table is trivially small — full scans are negligible. No distribution key to optimise JOINs; use broadcast moves when joining to larger tables.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Rejection reasons by regulation | `GROUP BY CurrentRegulation, RejectReasonName ORDER BY cnt DESC` |
| Most common POI vs POA reasons | `WHERE ReasonNumber BETWEEN 1 AND 7` (POI) vs `BETWEEN 8 AND 16` (POA) |
| Uncategorised rejections | `WHERE ReasonNumber = 0` — these are reasons outside the 22 standard codes |
| Customer list for MA campaign | `SELECT GCID, RejectReasonName, CountryName WHERE CurrentRegulation = @reg` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_Operations_Onboarding_Flow_UserKPIs | ON GCID = GCID | Full onboarding context (VL dates, screening, STP) |
| DWH_dbo.Dim_Customer | ON GCID = GCID | Customer master attributes (email, registration date) |

### 3.4 Gotchas

- **ReasonNumber = 0 is overloaded**: It covers all rejection reasons not in the 22-code lookup (Duplicate, Underage, High Risk Country, Corrupted File, SSN Card, Visa issues, POA - Business/Work Address, Not Needed, Other, etc.). Do not treat 0 as "no reason".
- **NonVerificationReason is always 'Docs not Approved'**: The WHERE clause enforces this. Do not use this column to distinguish between non-verification reasons — use the parent table `BI_DB_Operations_Onboarding_Flow_UserKPIs` for that.
- **GCID is NOT unique**: Some GCIDs appear more than once (1,039 rows vs 1,034 distinct GCIDs). This happens when a customer has both POI and POA rejections matching different reason codes.
- **3-day rolling window**: Only customers with a POI/POA response in the last 3 days appear. The table is fully refreshed daily — row count fluctuates.
- **EV_MatchStatus excludes 'Verified'**: By design, electronically verified customers are filtered out. Values present: empty/NULL (71%), NotVerified (20%), PartiallyVerified (9%).
- **TRUNCATE+INSERT daily**: No intra-day updates. Data reflects state as of the last SP execution.
- **@Date parameter unused**: The SP accepts a `@Date` parameter but uses `GETDATE()` directly for the 3-day lookback. The parameter is unused.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (verbatim) | Highest |
| Tier 2 | SP code analysis | High |
| Tier 3 | Inferred from data | Medium |
| Tier 4 | Best guess / Confluence | Lower |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | NO | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs. (Tier 1 — Customer.CustomerStatic) |
| 2 | ReasonNumber | int | YES | Numeric rejection reason code mapped from a hardcoded 22-row lookup in SP_Failed_Verification_MA. COALESCE(POI match, POA match, 0). Codes 1-7 = POI reasons, 8-13 = POA reasons, 14 = POI+POA combined, 15-16 = additional POA, 17-21 = additional POI, 22 = POA back side. 0 = unmatched (raw reason text preserved in RejectReasonName). (Tier 2 — SP_Failed_Verification_MA) |
| 3 | RejectReasonName | nvarchar(100) | YES | Resolved rejection reason label. COALESCE priority: mapped POI reason name, mapped POA reason name, raw RejectionReasonPOI, raw RejectionReasonPOA. When ReasonNumber > 0, this is the standardised label from the 22-code lookup; when ReasonNumber = 0, this is the raw upstream rejection text (e.g., Duplicate, Underage, High Risk Country). (Tier 2 — SP_Failed_Verification_MA) |
| 4 | CountryName | nvarchar(100) | YES | Full country name in English. Unique per country. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs. (Tier 1 — Dictionary.Country) |
| 5 | CurrentRegulation | nvarchar(100) | YES | Current regulation name for the customer (via Dim_Customer.RegulationID -> Dim_Regulation.Name). May differ from DesignatedRegulation if customer's regulation changed after registration. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs. (Tier 1 — Dictionary.Regulation) |
| 6 | RejectionReasonPOA | nvarchar(100) | YES | Rejection reason text for the POA document. NULL if POA was approved or not submitted. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs. (Tier 1 — BI_DB_Operations_Onboarding_Flow_UserKPIs) |
| 7 | RejectionReasonPOI | nvarchar(100) | YES | Rejection reason text for the POI document. NULL if POI was approved or not submitted. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs. (Tier 1 — BI_DB_Operations_Onboarding_Flow_UserKPIs) |
| 8 | NonVerificationReason | nvarchar(100) | YES | Reason why a VL2 customer has not reached VL3. CASE logic: 'Docs not Approved', 'Missing Docs', 'User Screening Issue', 'Phone Not Verified', 'Others', 'Not Relevant'. Only meaningful for VL2 customers. DWH note: in this table, always 'Docs not Approved' due to WHERE filter. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs. (Tier 1 — BI_DB_Operations_Onboarding_Flow_UserKPIs) |
| 9 | EV_MatchStatus | nvarchar(100) | YES | Human-readable EV match status label (None, PartiallyVerified, Verified, NotVerified). Resolved via Dim_EvMatchStatus. DWH note: in this table, 'Verified' is excluded by the WHERE filter; observed values are empty/NULL, NotVerified, PartiallyVerified. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs. (Tier 1 — BI_DB_Operations_Onboarding_Flow_UserKPIs) |
| 10 | UpdateDate | datetime | NO | ETL execution timestamp. Set to GETDATE() at SP run time. Not a business date. (Tier 2 — SP_Failed_Verification_MA) |

---

## 5. Lineage

### 5.1 Production Sources

| Source | Type | Role |
|--------|------|------|
| BI_DB_dbo.BI_DB_Operations_Onboarding_Flow_UserKPIs | Table | Primary source — filtered VL2-not-VL3 customers with document rejections |
| BI_DB_dbo.SP_Failed_Verification_MA | Stored Procedure | Writer SP — TRUNCATE+INSERT with hardcoded rejection reason lookup |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_Operations_Onboarding_Flow_UserKPIs (9.9M rows)
  |-- WHERE IsVL2=1 AND IsVL3=0 AND NonVerificationReason='Docs not Approved'
  |   AND PhoneVerification verified AND no AML match AND EV not verified
  |   AND POI/POA response within 3 days
  |
  +-- LEFT JOIN #TempRejectReasons (22 hardcoded codes) ON RejectionReasonPOI
  +-- LEFT JOIN #TempRejectReasons ON RejectionReasonPOA
  |
  -> SP_Failed_Verification_MA @Date
      -> TRUNCATE BI_DB_Failed_Verification_MA
      -> INSERT INTO BI_DB_Failed_Verification_MA (~1,039 rows)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID | DWH_dbo.Dim_Customer.GCID | Customer master dimension (cross-product identity) |
| CountryName | DWH_dbo.Dim_Country.CountryName | Country dimension |
| CurrentRegulation | DWH_dbo.Dim_Regulation.Name | Regulation dimension |
| (all passthrough columns) | BI_DB_dbo.BI_DB_Operations_Onboarding_Flow_UserKPIs | Parent onboarding analytics table |

### 6.2 Referenced By

No known downstream consumers found in the SSDT project.

---

## 7. Sample Queries

### 7.1 Rejection Reason Breakdown by Regulation

```sql
SELECT
    CurrentRegulation,
    RejectReasonName,
    COUNT(*) AS customer_count
FROM BI_DB_dbo.BI_DB_Failed_Verification_MA
GROUP BY CurrentRegulation, RejectReasonName
ORDER BY CurrentRegulation, customer_count DESC
```

### 7.2 Uncategorised Rejections (ReasonNumber = 0)

```sql
SELECT
    RejectReasonName,
    CountryName,
    COUNT(*) AS cnt
FROM BI_DB_dbo.BI_DB_Failed_Verification_MA
WHERE ReasonNumber = 0
GROUP BY RejectReasonName, CountryName
ORDER BY cnt DESC
```

### 7.3 POI vs POA Rejection Split

```sql
SELECT
    CASE
        WHEN RejectionReasonPOI IS NOT NULL AND RejectionReasonPOA IS NOT NULL THEN 'Both'
        WHEN RejectionReasonPOI IS NOT NULL THEN 'POI Only'
        WHEN RejectionReasonPOA IS NOT NULL THEN 'POA Only'
        ELSE 'Neither'
    END AS rejection_type,
    COUNT(*) AS cnt
FROM BI_DB_dbo.BI_DB_Failed_Verification_MA
GROUP BY
    CASE
        WHEN RejectionReasonPOI IS NOT NULL AND RejectionReasonPOA IS NOT NULL THEN 'Both'
        WHEN RejectionReasonPOI IS NOT NULL THEN 'POI Only'
        WHEN RejectionReasonPOA IS NOT NULL THEN 'POA Only'
        ELSE 'Neither'
    END
ORDER BY cnt DESC
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources searched (regen harness mode).

---

*Generated: 2026-04-27 | Quality: pending judge | Phases: 11/14*
*Tiers: 7 T1, 3 T2, 0 T3, 0 T4 | Elements: 10/10, Logic: 8/10*
*Object: BI_DB_dbo.BI_DB_Failed_Verification_MA | Type: Table | Production Source: SP_Failed_Verification_MA*
