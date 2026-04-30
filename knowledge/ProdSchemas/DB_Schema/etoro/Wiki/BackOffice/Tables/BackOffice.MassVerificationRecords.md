# BackOffice.MassVerificationRecords

> Stores results of automated batch KYC verification ("Semi Auto Customer Verification Phase 5", 2018). Each row is a denormalized snapshot capturing both customer-registered data and KYC document data (POI + POA) at the time of auto-verification, along with the matching score and pass/fail result. CustomerAddress is dynamically masked. Table does not exist in the live database as of 2026-03-17 (likely dropped or on a separate environment).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No (stored ON [PRIMARY] filegroup) |
| **Indexes** | 1 active (1 clustered PK) |

---

## 1. Business Meaning

BackOffice.MassVerificationRecords was created as part of "Semi Auto Customer Verification - Phase 5" (ticket 50714, March 2018, author Geri Reshef). It records the output of an automated batch process that attempts to verify customer KYC by comparing their registered profile data against their submitted KYC documents (POI = Proof of Identity, POA = Proof of Address).

**How it worked**:
The batch process would:
1. Select a cohort of customers meeting criteria (customer status, risk status, document quality thresholds, verification level < 3).
2. For each customer, collect data from both their registration profile and their KYC documents.
3. Run a matching/scoring algorithm, producing a ResultScore.
4. Write one row per processed customer into this table via SetMassVerificationRecords (bulk TVP insert).
5. Set VerificationProcessStatus=1 (passed) or 0 (failed) with a DeclineReason if failed.

**Deduplication role**: The (now-junk) GetMassVerificationRecords_JUNKYulia0325 procedure shows the original selection query used `WHERE MVR.CID IS NULL` - customers already in this table were excluded from re-processing. The table thus served as a "processed" sentinel, ensuring each customer was only mass-verified once.

**Dynamic data masking**: CustomerAddress is masked with `FUNCTION = 'default()'` - BackOffice agents without unmask permission see `XXXX` instead of the real address value. This protects PII in a table that may be accessed by broad query.

**Current status**: The table does not exist in the live database as of 2026-03-17 (`Invalid object name` error on query). It was likely dropped after the automated verification feature was retired or replaced. The SSDT DDL and procedures remain in source control but are not active.

---

## 2. Business Logic

### 2.1 Bulk Write via TVP (SetMassVerificationRecords)

**What**: Bulk-inserts a batch of verification results from an external service.

**Columns Involved**: All except ID (auto-generated).

**Rules**:
- SetMassVerificationRecords(@MassVerificationRecordsDataTable [dbo.MassVerificationRecordsDataTable] READONLY, @Updated BIT OUTPUT):
  - Wrapped in BEGIN TRAN / COMMIT with THROW-based rollback on error.
  - INSERT from TVP - no uniqueness check on CID (duplicates allowed in theory, though the selection logic prevented them).
  - CreateDate and UpdateDate are both set to GETUTCDATE() on insert - no separate update path.
  - @Updated=1 is set on success.

### 2.2 Deduplication Sentinel (legacy - GetMassVerificationRecords_JUNKYulia0325)

**What**: The original reader used `LEFT JOIN BackOffice.MassVerificationRecords MVR ON MVR.CID = CTE.CID` then `WHERE MVR.CID IS NULL` to exclude already-processed customers from the next batch selection.

**Status**: Procedure body is fully commented out and named with `_JUNK` suffix. Logic is inactive.

---

## 3. Data Overview

Table does not exist in the live database as of 2026-03-17. No live row data available.

Based on the DDL and procedure logic, each row represents:
- One customer processed by the automated verification batch
- A snapshot of customer + POI + POA data at time of verification
- A ResultScore from the matching algorithm
- A binary VerificationProcessStatus (pass/fail) with optional DeclineReason

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | - | VERIFIED | Auto-incrementing surrogate key. NOT FOR REPLICATION. CLUSTERED PK. One row per verification batch record. |
| 2 | CID | int | YES | NULL | VERIFIED | Customer ID. No FK constraint declared. The customer being verified. Nullable despite being the primary business key - likely nullable to support partial/error records. |
| 3 | GCID | int | YES | NULL | VERIFIED | Global Customer ID (cross-entity identifier used in risk tracking). Corresponds to Customer.CustomerStatic.GCID. |
| 4 | CustomerStatus | varchar(255) | YES | NULL | VERIFIED | Denormalized snapshot of customer's player/account status at time of verification (e.g., "Active", "Blocked"). Stored as name string, not ID, for human-readable audit. |
| 5 | RiskStatus | varchar(255) | YES | NULL | VERIFIED | Denormalized snapshot of customer's risk status at time of verification. Stored as name string. |
| 6 | CustomerFullName | nvarchar(255) | YES | NULL | VERIFIED | Customer's full name from their registration profile at time of verification. NVARCHAR for Unicode support (international names). |
| 7 | CustomerAddress | nvarchar(255) | YES | NULL | VERIFIED | Customer's registered address. DYNAMICALLY MASKED with default() - unauthorized users see XXXX. PII field. |
| 8 | PoaDocumentID | int | YES | NULL | VERIFIED | DocumentID of the Proof of Address document used in this verification. Logical reference to BackOffice.CustomerDocument (no FK constraint). |
| 9 | PoaApproved | bit | YES | NULL | VERIFIED | Whether the POA document was approved at the time of verification. 1=approved, 0=not approved, NULL=not determined. |
| 10 | PoaIssueDate | datetime | YES | NULL | VERIFIED | Issue date extracted from the POA document (e.g., utility bill date). Used in the matching/scoring process. |
| 11 | PoaFullName | nvarchar(255) | YES | NULL | VERIFIED | Full name as it appears on the POA document (original language). |
| 12 | PoaFullNameTranslated | nvarchar(255) | YES | NULL | VERIFIED | Full name from the POA document translated to Latin characters (for non-Latin script documents). |
| 13 | PoaAddress | nvarchar(255) | YES | NULL | VERIFIED | Address as it appears on the POA document. Compared against CustomerAddress in the scoring algorithm. |
| 14 | PoiDocumentID | int | YES | NULL | VERIFIED | DocumentID of the Proof of Identity document used in this verification. Logical reference to BackOffice.CustomerDocument (no FK constraint). |
| 15 | PoiApproved | bit | YES | NULL | VERIFIED | Whether the POI document was approved at the time of verification. |
| 16 | PoiExpirationDate | datetime | YES | NULL | VERIFIED | Expiration date from the POI document (passport/ID card). Relevant for verifying document is not expired. |
| 17 | PoiFullName | nvarchar(255) | YES | NULL | VERIFIED | Full name as it appears on the POI document (original language). |
| 18 | PoiFullNameTranslated | nvarchar(255) | YES | NULL | VERIFIED | Full name from the POI document translated to Latin characters. |
| 19 | PoiDocumentSubType | varchar(255) | YES | NULL | VERIFIED | The sub-type of the POI document (e.g., Passport, National ID, Driver License). Corresponds to DocumentClassification values. |
| 20 | ResultScore | decimal(18,0) | YES | NULL | VERIFIED | Numeric matching score from the auto-verification algorithm. The JUNK procedure shows AddressScore was multiplied by 100 before storage (0-100 integer scale). |
| 21 | VerificationLevel | varchar(255) | YES | NULL | VERIFIED | Customer's verification level at time of batch (e.g., "Level 1", "Level 2"). Stored as name string. The batch only targeted customers with VerificationLevelID < 3. |
| 22 | RegistrationCountry | varchar(255) | YES | NULL | CODE-BACKED | Customer's country based on registration IP. Stored as country name string. |
| 23 | PhoneVerification | varchar(255) | YES | NULL | CODE-BACKED | Customer's phone verification status at time of batch. Stored as name string (e.g., "Verified", "Not Verified"). |
| 24 | VerificationProcessStatus | bit | YES | NULL | VERIFIED | Overall auto-verification outcome. 1=passed (customer auto-approved), 0=failed (declined), NULL=undetermined. |
| 25 | DeclineReason | nvarchar(1024) | YES | NULL | VERIFIED | Free-text description of why the auto-verification failed. NULL when VerificationProcessStatus=1. Up to 1024 chars for detailed decline notes. |
| 26 | CreateDate | datetime | YES | NULL | VERIFIED | UTC timestamp when the record was inserted. Set to GETUTCDATE() by SetMassVerificationRecords (not a DEFAULT constraint - set by procedure logic). |
| 27 | UpdateDate | datetime | YES | NULL | CODE-BACKED | UTC timestamp of last update. Also set to GETUTCDATE() on insert by SetMassVerificationRecords. No dedicated update procedure found - may reflect same value as CreateDate for all records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | BackOffice.Customer | Implicit | Customer being verified |
| PoaDocumentID | BackOffice.CustomerDocument | Implicit | POA document used in verification |
| PoiDocumentID | BackOffice.CustomerDocument | Implicit | POI document used in verification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.SetMassVerificationRecords | CID | WRITER (bulk TVP insert) | Writes batch verification results |
| BackOffice.GetMassVerificationRecords_JUNKYulia0325 | CID | READER (deprecated/JUNK) | Was used for deduplication sentinel; body fully commented out |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.MassVerificationRecords (batch results table - NOT IN LIVE DB)
- Implicit references: BackOffice.Customer, BackOffice.CustomerDocument
- TVP dependency: dbo.MassVerificationRecordsDataTable (User Defined Type)
- Writer: BackOffice.SetMassVerificationRecords
- Reader (JUNK): BackOffice.GetMassVerificationRecords_JUNKYulia0325
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | Implicit FK on CID |
| BackOffice.CustomerDocument | Table | Implicit - PoaDocumentID, PoiDocumentID |
| dbo.MassVerificationRecordsDataTable | User Defined Type (TVP) | Parameter type for SetMassVerificationRecords |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.SetMassVerificationRecords | Procedure | WRITER - bulk insert via TVP |
| BackOffice.GetMassVerificationRecords_JUNKYulia0325 | Procedure | READER (deprecated) - deduplication sentinel, body commented out |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| PK (auto-named) | CLUSTERED PK | ID ASC | Active in DDL (FILLFACTOR=95, ON [PRIMARY]) |

FILLFACTOR=95 consistent with high-volume sequential IDENTITY inserts expected for batch processing.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (auto-named PK) | PK | ID uniqueness |
| CustomerAddress masking | DYNAMIC DATA MASKING | default() mask - unauthorized users see XXXX |

No FK constraints. No unique constraint on CID.

---

## 8. Sample Queries

### 8.1 Get verification results for a customer
```sql
SELECT ID, CID, GCID, CustomerStatus, RiskStatus,
       VerificationProcessStatus, ResultScore, DeclineReason,
       CreateDate
FROM BackOffice.MassVerificationRecords WITH (NOLOCK)
WHERE CID = @CID
ORDER BY CreateDate DESC
```

### 8.2 Summary of batch results
```sql
SELECT VerificationProcessStatus,
       COUNT(*) AS RecordCount,
       AVG(CAST(ResultScore AS FLOAT)) AS AvgScore
FROM BackOffice.MassVerificationRecords WITH (NOLOCK)
GROUP BY VerificationProcessStatus
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. Ticket reference in procedure comment: ticket 50714 "Semi Auto Customer Verification - Phase 5 - DB Changes" (Geri Reshef, 07/03/2018). The feature was introduced as part of a phased automated KYC verification project.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 17 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.MassVerificationRecords | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.MassVerificationRecords.sql*
