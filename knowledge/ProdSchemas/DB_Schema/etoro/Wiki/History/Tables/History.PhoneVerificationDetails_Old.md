# History.PhoneVerificationDetails_Old

> Pre-temporal-versioning history clone of Customer.PhoneVerificationDetails, capturing phone verification record changes using a manual ValidFrom/ValidTo pattern before SQL Server temporal was adopted.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PhoneVerificationDetailsHistoryID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

History.PhoneVerificationDetails_Old is the pre-temporal predecessor to History.PhoneVerificationDetails. Before SQL Server temporal system versioning was adopted, changes to Customer.PhoneVerificationDetails were manually tracked in this table using ValidFrom/ValidTo datetime columns. Each row represents a previous version of a phone verification record.

This table exists because the audit trail for phone verifications predates the temporal versioning implementation. When the team migrated to SQL Server temporal (using StartTime/EndTime in the source table), the history was maintained in the newer History.PhoneVerificationDetails table. This legacy table was kept for historical completeness but is no longer actively written.

The table currently has 0 rows in the live database. It is structurally similar to History.PhoneVerificationDetails but differs in: (1) has a surrogate IDENTITY PK, (2) uses ValidFrom/ValidTo instead of StartTime/EndTime, (3) is missing the AbuseAttemptCount column (added after this table's creation), and (4) does not have dynamic data masking on PhoneNumber.

---

## 2. Business Logic

### 2.1 Manual Validity Window Pattern (Pre-Temporal)

**What**: ValidFrom/ValidTo represent the time window when this phone verification record version was active, populated manually.

**Columns/Parameters Involved**: `ID`, `ValidFrom`, `ValidTo`

**Rules**:
- ID is the original Customer.PhoneVerificationDetails.ID - multiple rows with the same ID represent different versions.
- ValidFrom: when this version became active.
- ValidTo: when this version was superseded by a newer version (or the current one if still active).
- The manual pattern means ValidFrom/ValidTo were set by application code, unlike SQL Server temporal which sets them automatically.

---

## 3. Data Overview

Table is currently empty in the live database - legacy pre-temporal history table, no longer written. No sample data available.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PhoneVerificationDetailsHistoryID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate primary key. Distinguishes multiple history versions of the same ID. Differs from History.PhoneVerificationDetails which has no PK. |
| 2 | ID | int | NO | - | CODE-BACKED | Customer.PhoneVerificationDetails record ID. Multiple rows with the same ID represent different versions. |
| 3 | ValidFrom | datetime | NO | - | CODE-BACKED | Datetime when this row version became active (manually set by application code). |
| 4 | ValidTo | datetime | NO | - | CODE-BACKED | Datetime when this row version was superseded. The pre-temporal equivalent of EndTime in History.PhoneVerificationDetails. |
| 5 | CID | int | NO | - | CODE-BACKED | Customer identifier. Inherited from the source record. |
| 6 | CountryID | int | NO | - | CODE-BACKED | Country of the phone number. Default 0 when not specified. |
| 7 | City | nvarchar(50) | YES | - | CODE-BACKED | City from the verification service. NULL when not provided. |
| 8 | PhoneNumber | varchar(30) | NO | - | CODE-BACKED | Customer's phone number at the time of this version. Note: NO dynamic data masking (unlike History.PhoneVerificationDetails). This is a pre-GDPR masking version. |
| 9 | PhoneType | tinyint | YES | - | CODE-BACKED | Phone line type. FK to Dictionary.PhoneTypes. |
| 10 | PhoneVerifiedID | int | NO | - | CODE-BACKED | Verification status: 0=NotVerified, 1=AutomaticallyVerified, 2=ManuallyVerified, 3=Initiated, 4=Rejected, 5=AbuseFlag. FK to Dictionary.PhoneVerified. |
| 11 | VerifacationDate | smalldatetime | YES | - | CODE-BACKED | UTC datetime when verification was completed. Note: column name misspelled as "Verifacation" (consistent with source table typo). |
| 12 | VerifactionCode | varchar(32) | YES | - | CODE-BACKED | Verification code sent via SMS at the time of this version. Note: column name misspelled as "Verifaction". |
| 13 | RiskInfoLevel | int | YES | - | CODE-BACKED | Risk severity level from phone verification provider. |
| 14 | RiskInfoRecommendation | int | YES | - | CODE-BACKED | Recommended action from risk provider. |
| 15 | RiskInfoScore | int | YES | - | CODE-BACKED | Numeric risk score from verification provider. |
| 16 | VerificationAttemptCount | int | NO | - | CODE-BACKED | Number of verification attempts for this phone record version. |
| 17 | ManagerID | int | YES | - | CODE-BACKED | BackOffice manager who performed manual verification. NULL for automated verifications. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ID | Customer.PhoneVerificationDetails (legacy) | Implicit | The original source record this history entry was cloned from. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No procedures reference this legacy table by name.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.PhoneVerificationDetails | Table | Successor - replaced this table when SQL Server temporal was adopted |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PhoneVerificationDetails | CLUSTERED PK | PhoneVerificationDetailsHistoryID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_PhoneVerificationDetails | PRIMARY KEY | Unique per history entry |

---

## 8. Sample Queries

### 8.1 Check if legacy history table has any rows

```sql
SELECT COUNT(*) AS RowCount
FROM History.PhoneVerificationDetails_Old WITH (NOLOCK);
```

### 8.2 Get all versions for a specific customer (when table has data)

```sql
SELECT PhoneVerificationDetailsHistoryID, ID, CID, PhoneVerifiedID, ValidFrom, ValidTo
FROM History.PhoneVerificationDetails_Old WITH (NOLOCK)
WHERE CID = 12345
ORDER BY ValidFrom;
```

### 8.3 Compare schema difference from new temporal version (AbuseAttemptCount missing)

```sql
-- Old table: no AbuseAttemptCount column
SELECT ID, CID, PhoneNumber, PhoneVerifiedID, VerificationAttemptCount, ValidFrom, ValidTo
FROM History.PhoneVerificationDetails_Old WITH (NOLOCK)
ORDER BY ValidFrom DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PhoneVerificationDetails_Old | Type: Table | Source: etoro/etoro/History/Tables/History.PhoneVerificationDetails_Old.sql*
