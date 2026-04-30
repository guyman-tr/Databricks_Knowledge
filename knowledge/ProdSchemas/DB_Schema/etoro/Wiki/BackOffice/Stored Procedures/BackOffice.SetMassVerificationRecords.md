# BackOffice.SetMassVerificationRecords

> Bulk-inserts a batch of automated KYC verification results into BackOffice.MassVerificationRecords using a table-valued parameter, recording customer profile data, document snapshots, matching scores, and pass/fail outcomes from the Semi Auto Customer Verification system.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MassVerificationRecordsDataTable TVP - batch of verification results |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.SetMassVerificationRecords is the bulk write procedure for the "Semi Auto Customer Verification" batch system (Phase 5, ticket 50714, March 2018). When the automated verification batch runs, it collects KYC data for a cohort of customers, runs a document-to-profile matching algorithm, and submits all results in one TVP call to this procedure.

Each record in the TVP represents one customer's verification attempt: their current profile data (customer status, risk status, full name, address), their KYC document data (POI and POA document IDs, approval status, document name fields, dates), the matching result score, and whether verification passed or failed.

The table serves as a "processed" sentinel - customers with an existing row in MassVerificationRecords were excluded from re-processing in subsequent batch runs, preventing duplicate verification attempts.

**Current status**: BackOffice.MassVerificationRecords does not exist in the live database as of 2026-03-17 - the table was dropped when the automated verification feature was retired. This procedure and the table DDL remain in source control but are not active.

---

## 2. Business Logic

### 2.1 Bulk TVP Insert with UTC Timestamps

**What**: All rows from the TVP are inserted in one operation with server-generated CreateDate and UpdateDate.

**Columns/Parameters Involved**: All TVP columns, GETUTCDATE()

**Rules**:
- INSERT INTO BackOffice.MassVerificationRecords ... SELECT * FROM @MassVerificationRecordsDataTable
- CreateDate and UpdateDate are set to GETUTCDATE() at insert time - the TVP does not supply these (they are overwritten by the server)
- All other columns are passed directly from the TVP without transformation
- @Updated OUTPUT set to 1 on successful COMMIT
- Wrapped in BEGIN TRAN/COMMIT with CATCH ROLLBACK + THROW
- Nested transaction handling: IF @@TRANCOUNT > 1 COMMIT TRAN (allow outer transaction to control), ELSE ROLLBACK

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MassVerificationRecordsDataTable | dbo.MassVerificationRecordsDataTable (TVP) | NO | - | VERIFIED | Table-valued parameter of type `dbo.MassVerificationRecordsDataTable` (READONLY). Contains one row per customer verification result. Columns: CID, GCID, CustomerStatus, RiskStatus, CustomerFullName, CustomerAddress, PoaDocumentID, PoaApproved, PoaIssueDate, PoaFullName, PoaFullNameTranslated, PoaAddress, PoiDocumentID, PoiApproved, PoiExpirationDate, PoiFullName, PoiFullNameTranslated, PoiDocumentSubType, ResultScore, VerificationLevel, RegistrationCountry, PhoneVerification, VerificationProcessStatus, DeclineReason. |
| 2 | @Updated | BIT | - | 0 | CODE-BACKED | OUTPUT parameter. Set to 1 on successful completion of the TRY block. Returned to the caller confirming the bulk insert committed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MassVerificationRecordsDataTable | BackOffice.MassVerificationRecords | WRITER (bulk INSERT) | Inserts all batch verification results |
| Type reference | dbo.MassVerificationRecordsDataTable | User Defined Type | TVP type definition |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Semi Auto Customer Verification batch service | - | Caller | Called once per batch run to persist all verification results (feature now retired) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.SetMassVerificationRecords (procedure)
├── BackOffice.MassVerificationRecords (table) [dropped in live DB]
└── dbo.MassVerificationRecordsDataTable (user defined table type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.MassVerificationRecords | Table | Bulk INSERT target - all TVP rows inserted with server UTC timestamps |
| dbo.MassVerificationRecordsDataTable | User Defined Type | TVP parameter type definition |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Semi Auto Verification batch service | External | Called to write batch KYC verification results (feature retired ~2018) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Operational Status

BackOffice.MassVerificationRecords does not exist in the live database as of 2026-03-17. This procedure cannot be executed in the current environment. The DDL and procedure remain in source control for reference. The automated verification feature it supported was retired after Phase 5.

---

## 8. Sample Queries

### 8.1 Execute the procedure (conceptual - table does not exist in live DB)
```sql
-- Declare and populate the TVP
DECLARE @batch AS dbo.MassVerificationRecordsDataTable
INSERT @batch (CID, GCID, CustomerStatus, ...) VALUES (...)

DECLARE @Updated BIT = 0
EXEC BackOffice.SetMassVerificationRecords
    @MassVerificationRecordsDataTable = @batch,
    @Updated = @Updated OUTPUT
SELECT @Updated AS Updated
```

### 8.2 Check if the target table exists
```sql
SELECT OBJECT_ID('BackOffice.MassVerificationRecords') AS ObjectID
-- Returns NULL if table does not exist in current DB
```

### 8.3 View verification process results (when table exists)
```sql
SELECT TOP 100
    CID, GCID,
    VerificationProcessStatus,
    DeclineReason,
    ResultScore,
    VerificationLevel,
    CreateDate
FROM BackOffice.MassVerificationRecords WITH (NOLOCK)
ORDER BY CreateDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.SetMassVerificationRecords | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.SetMassVerificationRecords.sql*
