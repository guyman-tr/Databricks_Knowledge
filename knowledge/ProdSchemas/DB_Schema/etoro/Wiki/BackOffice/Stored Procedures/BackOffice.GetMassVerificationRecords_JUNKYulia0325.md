# BackOffice.GetMassVerificationRecords_JUNKYulia0325

> JUNK - Entirely commented-out procedure for batch retrieval of customers pending semi-automated KYC verification. All implementation code is disabled; the procedure executes nothing.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Top, @DateAdded, @CustomerStatus, @RiskStatus, @AddressScore |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure was part of Phase 5 of the "Semi Auto Customer Verification" initiative (March 2018). Its intended purpose was to retrieve a batch of customers who have a sufficiently high POA address score and qualifying POI/POA documents but have not yet been processed through the mass verification queue (`BackOffice.MassVerificationRecords`).

**Status: JUNK** - Marked for removal in March 2025 (Yulia). The entire implementation is commented out. The procedure body is empty - executing it returns no results and performs no action beyond setting NOCOUNT ON.

The commented-out logic reveals the original design: it would query customers with a POA AddressScore above a threshold, who have both POI and POA documents, are not already in `MassVerificationRecords`, and match a customer status/risk status filter. The result would include KYC profile data, document IDs, verification levels, and phone verification status for agent review.

---

## 2. Business Logic

### 2.1 Original Design (Commented Out - Not Active)

**What**: Would have returned customers ready for automated batch verification processing.

**Columns/Parameters Involved**: All parameters

**Rules** (from commented code, no longer active):
- @Top: Limits output to the specified number of rows - batch size control for the verification pipeline.
- @DateAdded: Filters to POA documents added after this date - only recent documents are processed.
- @CustomerStatus: Optional filter by PlayerStatusID - targets specific account states.
- @RiskStatus: Optional filter by RiskStatusID - targets specific risk classifications.
- @AddressScore: Minimum POA address match score threshold (value / 100 for comparison) - customers below this score are excluded.
- Excluded customers already in `BackOffice.MassVerificationRecords` (MVR.CID IS NULL filter).
- Excluded documents with DocumentTypeID = 6 (Rejected).
- Used `VerificationLevelID < 3` filter on BackOffice.Customer to target partially-verified customers.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Top | INT | NO | - | CODE-BACKED | (Inactive) Batch size limit - maximum number of verification candidates to return per call. |
| 2 | @DateAdded | DATETIME | NO | - | CODE-BACKED | (Inactive) Cutoff date for POA document recency filter. Only POA documents added after this date are considered. |
| 3 | @CustomerStatus | INT | NO | - | CODE-BACKED | (Inactive) Optional filter by PlayerStatusID. NULL = all statuses. |
| 4 | @RiskStatus | INT | NO | - | CODE-BACKED | (Inactive) Optional filter by RiskStatusID. NULL = all risk statuses. |
| 5 | @AddressScore | DECIMAL | NO | - | CODE-BACKED | (Inactive) Minimum POA address match score threshold (0-100 scale in parameter; divided by 100 for comparison to the stored decimal score). |

**Output Columns**: None - procedure is entirely commented out and produces no result set.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (commented) | BackOffice.CustomerDocumentToDocumentType | Lookup | Original dependency - document type classification |
| (commented) | BackOffice.CustomerDocument | Lookup | Original dependency - customer document records |
| (commented) | BackOffice.Customer | Lookup | Original dependency - BackOffice customer attributes |
| (commented) | BackOffice.MassVerificationRecords | Lookup | Original dependency - exclusion filter (already-processed customers) |
| (commented) | Customer.CustomerStatic | Lookup | Original dependency - customer profile data |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No EXECUTE grants found. JUNK with no active callers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetMassVerificationRecords_JUNKYulia0325 (procedure)
(No active dependencies - entire body is commented out)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| (none active) | - | All code is commented out |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none) | - | JUNK - no active callers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None active. All logic is commented out.

---

## 8. Sample Queries

### 8.1 Verify the procedure body is empty

```sql
-- This procedure does nothing when executed
EXEC BackOffice.GetMassVerificationRecords_JUNKYulia0325
    @Top = 100,
    @DateAdded = '2024-01-01',
    @CustomerStatus = NULL,
    @RiskStatus = NULL,
    @AddressScore = 70.0
-- Returns: empty result set
```

### 8.2 Check MassVerificationRecords directly (the table this was supposed to use)

```sql
SELECT TOP 10 *
FROM BackOffice.MassVerificationRecords WITH (NOLOCK)
ORDER BY CID DESC;
```

### 8.3 Find customers not yet in MassVerificationRecords

```sql
SELECT COUNT(DISTINCT cd.CID)
FROM BackOffice.CustomerDocument cd WITH (NOLOCK)
WHERE NOT EXISTS (
    SELECT 1 FROM BackOffice.MassVerificationRecords mvr WITH (NOLOCK)
    WHERE mvr.CID = cd.CID
);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 8.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 active callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetMassVerificationRecords_JUNKYulia0325 | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetMassVerificationRecords_JUNKYulia0325.sql*
