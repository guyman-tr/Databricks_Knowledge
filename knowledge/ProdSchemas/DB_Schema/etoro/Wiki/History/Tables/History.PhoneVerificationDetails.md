# History.PhoneVerificationDetails

> SQL Server temporal history table storing prior row versions of Customer.PhoneVerificationDetails (now junked as of July 2025), preserving the complete audit trail of customer phone verification states with GDPR-compliant phone number masking.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; CLUSTERED on (EndTime ASC, StartTime ASC) |
| **Partition** | No |
| **Indexes** | 3 (clustered on EndTime/StartTime, NC on CID, NC on VerifacationDate) |

---

## 1. Business Meaning

History.PhoneVerificationDetails is the SQL Server system-versioning history table for Customer.PhoneVerificationDetails_JunkNoga0725 (renamed to indicate deprecation in July 2025). It stores 298,692 historical row versions covering phone verification records from the beginning of the platform through April 2025.

Customer.PhoneVerificationDetails (now junked) was the source of truth for each customer's phone verification status. It tracked: which phone number a customer registered, whether it was verified automatically or manually, risk scores from a phone verification service (Telesign or similar), the number of verification attempts, and abuse flagging. Each change to a customer's phone verification record created a new version in this history table.

The PhoneNumber column has dynamic data masking (`MASKED WITH (FUNCTION = 'default()')`) applied - users without UNMASK permission see "xxxx" or similar instead of the actual phone number. This is a GDPR/compliance measure to protect personal data. The source table used StartTime/EndTime as temporal period columns (not the standard SysStartTime/SysEndTime), and this history table uses the same naming convention.

---

## 2. Business Logic

### 2.1 Phone Verification State Machine

**What**: PhoneVerifiedID tracks the customer's phone verification status through a defined state machine.

**Columns/Parameters Involved**: `PhoneVerifiedID`, `VerifacationDate`, `VerificationAttemptCount`, `VerifactionCode`

**Rules**:
- 0=NotVerified: phone registered but not yet verified
- 1=AutomaticallyVerified: phone confirmed via automated verification (SMS code match)
- 2=ManuallyVerified: phone confirmed by a BackOffice manager (ManagerID is set)
- 3=Initiated: verification process started (code sent, waiting for customer response)
- 4=Rejected: verification failed or was rejected
- 5=AbuseFlag: phone number flagged for abuse (linked to AbuseAttemptCount)
- VerifacationDate: UTC timestamp of when verification was completed (defaults to 1900-01-01 when never verified)

### 2.2 Phone Risk Assessment

**What**: Risk info fields capture fraud/quality scores from the phone verification provider (e.g., Telesign).

**Columns/Parameters Involved**: `RiskInfoLevel`, `RiskInfoRecommendation`, `RiskInfoScore`

**Rules**:
- RiskInfoLevel: risk severity level (FK to Dictionary.PhoneVerificationRiskLevel)
- RiskInfoRecommendation: recommended action from the risk provider (FK to Dictionary.PhoneVerificationTransactionRecommendation)
- RiskInfoScore: numeric risk score from the provider. Higher score = higher risk.
- These fields are populated when a phone number is checked against a risk service API.

### 2.3 GDPR Data Masking

**What**: The PhoneNumber column is protected by dynamic data masking.

**Columns/Parameters Involved**: `PhoneNumber`

**Rules**:
- PhoneNumber is declared with `MASKED WITH (FUNCTION = 'default()')` - users without UNMASK permission see a default masked value.
- GDPR compliance requirement - phone numbers are PII and must be masked for users who do not have explicit unmask rights.
- Full phone numbers are only visible to users granted the UNMASK permission.

---

## 3. Data Overview

| ID | CID | CountryID | PhoneType | PhoneVerifiedID | VerifacationDate | VerificationAttemptCount | StartTime | EndTime | Meaning |
|----|-----|-----------|-----------|-----------------|-----------------|--------------------------|-----------|---------|---------|
| 90612 | 16891056 | 219 | 9 | 0 (NotVerified) | 1900-01-01 | 0 | 2024-10-07 | 2025-04-06 | Customer's phone record was never verified; source table junked in Apr 2025, archiving this final version |
| 113784 | 18553176 | 0 | 14 | 0 (NotVerified) | 1900-01-01 | 0 | 2025-01-21 07:40 | 2025-01-21 07:40 | Millisecond-duration record - likely UPDATE immediately after INSERT (temporal capture) |
| 113783 | 18553175 | 0 | 14 | 0 (NotVerified) | 1900-01-01 | 0 | 2025-01-21 07:39 | 2025-01-21 07:39 | Same pattern - a new customer's initial phone record created and immediately versioned |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Phone verification record identifier from Customer.PhoneVerificationDetails (IDENTITY). Not unique in this history table. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer who owns this phone verification record. Indexed for fast customer lookup across history. Links to Customer.CustomerStatic. |
| 3 | CountryID | int | NO | - | CODE-BACKED | Country code for the phone number's country of origin. Default 0 in source when not provided. Implicit FK to Dictionary.Country. |
| 4 | City | nvarchar(50) | YES | - | CODE-BACKED | City associated with the phone number (from verification service). NULL when not provided. |
| 5 | PhoneNumber | varchar(30) | NO | - | CODE-BACKED | The customer's registered phone number. **Masked with dynamic data masking** - users without UNMASK permission see a masked value. GDPR PII protection. Actual values visible only to authorized roles. |
| 6 | PhoneType | tinyint | YES | - | CODE-BACKED | Type of phone line (mobile, landline, VOIP, etc.). FK to Dictionary.PhoneTypes in the source table. |
| 7 | PhoneVerifiedID | int | NO | - | CODE-BACKED | Verification status: 0=NotVerified, 1=AutomaticallyVerified (SMS code matched), 2=ManuallyVerified (BackOffice action), 3=Initiated (code sent), 4=Rejected (failed/rejected), 5=AbuseFlag (abuse detected). FK to Dictionary.PhoneVerified. Default 0. |
| 8 | VerifacationDate | smalldatetime | YES | - | CODE-BACKED | UTC datetime when phone verification was completed. 1900-01-01 when the phone has never been verified (default value used as null equivalent). Note: column name is misspelled as "Verifacation" (missing 'i'). |
| 9 | VerifactionCode | varchar(32) | YES | - | CODE-BACKED | The verification code sent to the customer via SMS. Stored temporarily during the verification process. Note: column name is misspelled as "Verifaction". |
| 10 | RiskInfoLevel | int | YES | - | CODE-BACKED | Risk severity level from phone verification provider API. FK to Dictionary.PhoneVerificationRiskLevel. NULL when risk check was not performed. |
| 11 | RiskInfoRecommendation | int | YES | - | CODE-BACKED | Recommended action from risk provider (allow, block, review). FK to Dictionary.PhoneVerificationTransactionRecommendation. NULL when risk check was not performed. |
| 12 | RiskInfoScore | int | YES | - | CODE-BACKED | Numeric risk score from the phone verification provider. Higher value = greater risk. NULL when risk check was not performed. |
| 13 | VerificationAttemptCount | int | NO | - | CODE-BACKED | Total number of times the customer has attempted to verify this phone number (failed + successful). Default 0. Used for rate limiting verification attempts. |
| 14 | ManagerID | int | YES | - | CODE-BACKED | BackOffice manager who performed a manual verification (PhoneVerifiedID=2). FK to BackOffice.Manager in the source table. NULL for automated verifications. |
| 15 | AbuseAttemptCount | int | NO | - | CODE-BACKED | Number of suspicious verification attempts for this phone number. Default 0. When this exceeds a threshold, PhoneVerifiedID may be set to 5=AbuseFlag. Not present in History.PhoneVerificationDetails_Old (added later). |
| 16 | StartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version became active. SQL Server temporal period start column (named StartTime instead of standard SysStartTime). |
| 17 | EndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version was superseded. SQL Server temporal period end column (named EndTime instead of standard SysEndTime). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (source table) | Customer.PhoneVerificationDetails_JunkNoga0725 | Temporal History | This table is the HISTORY_TABLE for the (now junked) source table. |
| PhoneVerifiedID | Dictionary.PhoneVerified | Implicit | Phone verification state lookup. |
| RiskInfoLevel | Dictionary.PhoneVerificationRiskLevel | Implicit | Risk level lookup from the source table FK. |
| RiskInfoRecommendation | Dictionary.PhoneVerificationTransactionRecommendation | Implicit | Risk recommendation lookup from source table FK. |
| PhoneType | Dictionary.PhoneTypes | Implicit | Phone line type lookup from source table FK. |
| ManagerID | BackOffice.Manager | Implicit | Manager who performed manual verification. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.PhoneVerificationDetails_JunkNoga0725 | HISTORY_TABLE | Temporal system versioning | All row version changes written here (source now junked). |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.PhoneVerificationDetails_JunkNoga0725 | Table | Source of all history writes (now deprecated) |
| History.GetPhoneVerification_JunkNoga240325 | Stored Procedure | READER - queries phone verification history (also junked) |
| Customer.GetRiskUserInfo | Stored Procedure | READER - retrieves risk info for customer phone verification |
| Customer.GDPRDeleteUser | Stored Procedure | MODIFIER - handles GDPR deletion requests involving phone data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_PhoneVerificationDetails | CLUSTERED | EndTime ASC, StartTime ASC | - | - | Active |
| IX_PhoneVerificationDetails_CID | NONCLUSTERED | CID ASC | - | - | Active |
| IX_PhoneVerificationDetails_VerifacationDate | NONCLUSTERED | VerifacationDate ASC | - | - | Active |

### 7.2 Constraints

None. Temporal history tables have no PK or FK constraints.

---

## 8. Sample Queries

### 8.1 Get full phone verification history for a customer

```sql
SELECT ID, CID, CountryID, PhoneType, PhoneVerifiedID, VerifacationDate,
       VerificationAttemptCount, AbuseAttemptCount, StartTime, EndTime
FROM History.PhoneVerificationDetails WITH (NOLOCK)
WHERE CID = 16891056
ORDER BY StartTime;
```

### 8.2 Find customers who had AbuseFlag set at any point

```sql
SELECT DISTINCT CID, StartTime, EndTime
FROM History.PhoneVerificationDetails WITH (NOLOCK)
WHERE PhoneVerifiedID = 5  -- AbuseFlag
ORDER BY StartTime DESC;
```

### 8.3 Count history entries by final verification status

```sql
SELECT pv.PhoneVerifiedName, COUNT(*) AS RecordCount
FROM History.PhoneVerificationDetails h WITH (NOLOCK)
JOIN Dictionary.PhoneVerified pv WITH (NOLOCK) ON pv.PhoneVerifiedID = h.PhoneVerifiedID
GROUP BY pv.PhoneVerifiedName
ORDER BY RecordCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PhoneVerificationDetails | Type: Table | Source: etoro/etoro/History/Tables/History.PhoneVerificationDetails.sql*
