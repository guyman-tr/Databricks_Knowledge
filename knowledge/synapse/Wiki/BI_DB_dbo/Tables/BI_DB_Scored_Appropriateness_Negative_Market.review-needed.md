# Review Sidecar: BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market

> Generated: 2026-03-28 | Quality: 8.5/10 | Tier 4: 0

## Reviewer Corrections

_None yet — awaiting domain expert review._

## Tier 4 (UNVERIFIED) Columns

_None — all 35 columns are Tier 1 (13) or Tier 2 (22)._

## Columns Needing Clarification

### 1. Vestigial KYC Scoring Columns (6 columns)

**Columns**: `IsKYC_NM_Trading_Experience`, `IsKYC_NM_Risk_Factor`, `IsKYC_NM`, `AT_Total_Score_KYC`, `AT_Total_Max_Potential_Score`, `IsKYC_AT_Passed`

**Question**: All 6 columns are hardcoded to `-1` in the SP — the scoring logic is commented out. Should these columns be dropped from the table, or is there a plan to re-enable the scoring logic? Per Confluence, scoring now lives in the Compliance service (KYC Analyzer).

### 2. ApproprietnessScore_Status — Typo in Column Name

**Column**: `ApproprietnessScore_Status`

**Question**: The column name contains a typo ("Approprietness" instead of "Appropriateness"). Is this intentional / too risky to rename due to downstream dependencies?

### 3. RestrictionStatusDesc — Overlap with ApproprietnessScore_Status

**Column**: `RestrictionStatusDesc`

**Question**: Both `RestrictionStatusDesc` and `ApproprietnessScore_Status` appear to track restriction outcomes. How do they differ semantically? Current understanding: `ApproprietnessScore_Status` is the appropriateness test result (Passed/Failed/Borderline Pass), while `RestrictionStatusDesc` is the overall CFD restriction description (which may include non-AT reasons). Is this correct?

### 4. BlockDate / ReleaseDate — Current vs History Logic

**Columns**: `BlockDate`, `ReleaseDate`, `BlockReasonID`, `ReleaseReasonID`

**Question**: The SP uses complex branching: if `CFDRestrictionStatusID = 1` (currently blocked), block info comes from current data and release info from history; if `= 2` (currently allowed), block info comes from history and release info from current. Does this logic correctly capture the MOST RECENT block/release cycle, or could it miss intermediate cycles?

### 5. DesignatedRegulationName — Usage

**Column**: `DesignatedRegulationName`

**Question**: This is decoded from `Dim_Customer.DesignatedRegulationID`, which may differ from `RegulationID`. When does the designated regulation differ from the current regulation, and how should analysts interpret rows where `RegulationName ≠ DesignatedRegulationName`?

## Structural Questions

### S1. Hardcoded Date Filter

The SP filters `BeginTime >= '2020-02-20'`. What is significant about this date? Is it when the appropriateness test was first implemented?

### S2. Downstream SP Count

At least 9 other SPs reference this table. A full consumer inventory would strengthen the documentation. Are all 9 active?

### S3. EOM Side-Effect

On end-of-month runs (`@Date = EOMONTH(@Date)`), the SP also populates `BI_DB_Negative_Market_Monthly_Aggregated`. Should this relationship be documented more formally, and is the monthly table also in scope for documentation?

### S4. No Indexing Beyond GCID

The table has only a clustered index on GCID. Given that many queries filter on `CFD_Status`, `ApproprietnessScore_Status`, or `RegulationName`, should non-clustered indexes be considered?
