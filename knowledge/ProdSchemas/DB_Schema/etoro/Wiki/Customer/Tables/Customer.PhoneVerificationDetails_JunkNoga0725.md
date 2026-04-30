# Customer.PhoneVerificationDetails_JunkNoga0725

> Temporal table storing per-customer phone verification records: phone number, verification status, risk scoring from the third-party verification provider, and attempt counts. Versioned to History.PhoneVerificationDetails for full audit trail.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | ID (int, IDENTITY PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 4 (1 clustered PK + 3 nonclustered: CID, PhoneNumber, unique CID+PhoneNumber filtered) |

---

## 1. Business Meaning

Customer.PhoneVerificationDetails_JunkNoga0725 stores the per-customer phone verification record: which phone number was verified, when, by what method, what risk level the third-party provider assigned, and how many verification attempts (legitimate and abusive) were made.

109,857 rows covering verified/attempted phone verifications. With temporal SYSTEM_VERSIONING (-> History.PhoneVerificationDetails), all changes are version-tracked for full audit history - critical for compliance and KYC investigations.

Four FK-constrained dimensions:
- `PhoneVerifiedID` -> Dictionary.PhoneVerified: the verification outcome (0=unverified, 3=verified in sample data)
- `PhoneType` -> Dictionary.PhoneTypes: type of phone (14 = some specific type in sample data)
- `RiskInfoLevel` -> Dictionary.PhoneVerificationRiskLevel: risk tier from the verification provider
- `RiskInfoRecommendation` -> Dictionary.PhoneVerificationTransactionRecommendation: provider's recommendation (allow/review/reject)
- `ManagerID` -> BackOffice.Manager: BackOffice operator who may have manually verified

The unique filtered index `UQ_CidPhone` on (CID, PhoneNumber) WHERE PhoneNumber != '-' ensures no duplicate verifications for the same customer+phone combination (the '-' placeholder is excluded to allow multiple NULL-equivalent entries).

The "_JunkNoga0725" suffix follows the team-tagging pattern, but with 109K rows, FKs, temporal versioning, and a unique index, this is the active production phone verification table.

---

## 2. Business Logic

### 2.1 Phone Verification Flow

**What**: A customer submits their phone number; the platform calls a third-party risk provider; the result is stored here with risk score and recommendation.

**Columns/Parameters Involved**: `PhoneNumber`, `PhoneVerifiedID`, `RiskInfoLevel`, `RiskInfoRecommendation`, `RiskInfoScore`, `VerificationAttemptCount`, `AbuseAttemptCount`

**Rules**:
- PhoneVerifiedID=0 (default): not yet verified
- PhoneVerifiedID=3 (seen in data): verified/passed
- RiskInfoLevel, RiskInfoRecommendation, RiskInfoScore: populated from third-party phone verification API response (nullable - not all verifications include risk scoring)
- VerificationAttemptCount: total verification code attempts (incremented on each OTP attempt)
- AbuseAttemptCount: number of attempts that exceeded rate limits or were flagged as abusive; links to Customer.OTPAbusers blocklist
- ManagerID: set when a BackOffice manager manually overrides the verification status

### 2.2 Temporal Versioning

**What**: All INSERT/UPDATE/DELETE operations are automatically captured in History.PhoneVerificationDetails via SYSTEM_VERSIONING.

**Columns/Parameters Involved**: `StartTime`, `EndTime`

**Rules**:
- StartTime: system-generated row start timestamp (GENERATED ALWAYS AS ROW START)
- EndTime: system-generated row end timestamp (GENERATED ALWAYS AS ROW END); default='9999-12-31' for current rows
- Historical queries: use FOR SYSTEM_TIME AS OF syntax to reconstruct past verification states
- Default for StartTime: getutcdate(); default for EndTime: '99991231 23:59:59.9999999'

### 2.3 Phone Number Uniqueness per Customer

**What**: Unique filtered index UQ_CidPhone prevents a customer from having duplicate verifications for the same real phone number.

**Rules**:
- Unique on (CID, PhoneNumber) WHERE PhoneNumber != '-'
- '-' (dash) is used as a placeholder when phone number is not available
- Multiple '-' rows allowed per CID (for historical records with no phone data)
- Real phone numbers must be unique per customer (no re-verification of the same number)

---

## 3. Data Overview

| ID | CID | CountryID | PhoneType | PhoneVerifiedID | VerifacationDate | RiskInfo | Attempts | Meaning |
|---|---|---|---|---|---|---|---|---|
| 113784 | 18553176 | 0 | 14 | 3 | 2025-01-21 | NULL | 0 | Verified (ID=3), type 14, no risk score, zero attempts (bulk import?) |
| 113783 | 18553175 | 0 | 14 | 3 | 2025-01-21 | NULL | 0 | Same pattern - bulk verification batch on Jan 21, 2025 |

*109,857 total rows. Recent data from Jan 2025. CountryID=0 in sample (may indicate default/unknown). RiskInfo columns NULL - risk scoring not enabled for these records.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-increment surrogate PK. NOT FOR REPLICATION. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID. Indexed via IX_PhoneVerificationDetails_CID. Part of unique constraint UQ_CidPhone. |
| 3 | CountryID | int | NO | 0 | CODE-BACKED | Country code associated with this phone verification record. Default=0. Not FK-constrained to Dictionary.Country. |
| 4 | City | nvarchar(50) | YES | - | CODE-BACKED | City associated with the phone number (from verification provider). Nullable. |
| 5 | PhoneNumber | varchar(30) | NO | - | VERIFIED | The phone number being verified. **Dynamic Data Masking: default().** Indexed via IX_Customer_PhoneVerificationDetails_PhoneNumber (fillfactor=70). Part of unique constraint UQ_CidPhone. '-' used as placeholder. |
| 6 | PhoneType | tinyint | YES | - | VERIFIED | Type of phone. FK to Dictionary.PhoneTypes. 14 is the common value in recent data. Nullable. |
| 7 | PhoneVerifiedID | int | NO | 0 | VERIFIED | Verification outcome. FK to Dictionary.PhoneVerified. 0=unverified (default), 3=verified (confirmed in data). |
| 8 | VerifacationDate | smalldatetime | YES | - | CODE-BACKED | Date/time of verification completion. smalldatetime (minute precision). Nullable when not yet verified. Note: column name typo "VerifacationDate" instead of "VerificationDate". |
| 9 | VerifactionCode | varchar(32) | YES | - | CODE-BACKED | OTP code sent to the customer for verification. varchar(32). Nullable post-verification. Note: column name typo "VerifactionCode". |
| 10 | RiskInfoLevel | int | YES | - | VERIFIED | Risk tier from the third-party phone verification provider. FK to Dictionary.PhoneVerificationRiskLevel. NULL when risk scoring not performed. |
| 11 | RiskInfoRecommendation | int | YES | - | VERIFIED | Provider recommendation. FK to Dictionary.PhoneVerificationTransactionRecommendation. NULL when risk scoring not performed. |
| 12 | RiskInfoScore | int | YES | - | CODE-BACKED | Numeric risk score from the provider. NULL in current data - may not be enabled. |
| 13 | VerificationAttemptCount | int | NO | 0 | VERIFIED | Total number of OTP verification attempts for this record. Incremented on each attempt. Default=0. |
| 14 | ManagerID | int | YES | - | VERIFIED | BackOffice manager who manually verified this phone (if applicable). FK to BackOffice.Manager. NULL for automated verifications. |
| 15 | AbuseAttemptCount | int | NO | 0 | CODE-BACKED | Count of attempts that were flagged as abusive (rate-limit violations, suspicious patterns). Default=0. Feeds into Customer.OTPAbusers blocklist logic. |
| 16 | StartTime | datetime2(7) | NO | getutcdate() | VERIFIED | Temporal period start - system-generated UTC timestamp when this row version became active. GENERATED ALWAYS AS ROW START. |
| 17 | EndTime | datetime2(7) | NO | '9999-12-31...' | VERIFIED | Temporal period end - '9999-12-31' for current rows. Set to actual change time when superseded. GENERATED ALWAYS AS ROW END. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ManagerID | BackOffice.Manager | FK (FK_Customer_PhoneVerificationDetails_ManagerID) | Manual verification by BackOffice manager |
| RiskInfoLevel | Dictionary.PhoneVerificationRiskLevel | FK (FK_Customer_PhoneVerificationDetails_RiskInfoLevel) | Risk tier from verification provider |
| RiskInfoRecommendation | Dictionary.PhoneVerificationTransactionRecommendation | FK (FK_Customer_PhoneVerificationDetails_RiskInfoRecommendation) | Provider recommendation |
| PhoneType | Dictionary.PhoneTypes | FK (FK_PhoneVerificationDetails_DictionaryPhoneTypes) | Type of phone number |
| PhoneVerifiedID | Dictionary.PhoneVerified | FK (FK_PhoneVerificationDetails_PhoneVerifiedID) | Verification outcome |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.PhoneVerificationDetails | ID | Temporal History | Receives superseded row versions automatically |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.PhoneVerificationDetails_JunkNoga0725
|- BackOffice.Manager [FK]
|- Dictionary.PhoneVerificationRiskLevel [FK]
|- Dictionary.PhoneVerificationTransactionRecommendation [FK]
|- Dictionary.PhoneTypes [FK]
|- Dictionary.PhoneVerified [FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Manager | Table | FK - ManagerID for manual verification |
| Dictionary.PhoneVerificationRiskLevel | Table | FK - risk tier lookup |
| Dictionary.PhoneVerificationTransactionRecommendation | Table | FK - recommendation lookup |
| Dictionary.PhoneTypes | Table | FK - phone type lookup |
| Dictionary.PhoneVerified | Table | FK - verification outcome lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.PhoneVerificationDetails | Table | Temporal history destination |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PhoneVerificationDetails | CLUSTERED | ID ASC | - | - | Active |
| IX_Customer_PhoneVerificationDetails_PhoneNumber | NC | PhoneNumber ASC | - | - | Active (fillfactor=70) |
| IX_PhoneVerificationDetails_CID | NC | CID ASC | - | - | Active (fillfactor=70) |
| UQ_CidPhone | UNIQUE NC | CID ASC, PhoneNumber ASC | - | PhoneNumber != '-' | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_PhoneVerificationDetails | PRIMARY KEY | ID unique |
| FK_Customer_PhoneVerificationDetails_ManagerID | FOREIGN KEY | ManagerID -> BackOffice.Manager |
| FK_Customer_PhoneVerificationDetails_RiskInfoLevel | FOREIGN KEY | RiskInfoLevel -> Dictionary.PhoneVerificationRiskLevel |
| FK_Customer_PhoneVerificationDetails_RiskInfoRecommendation | FOREIGN KEY | RiskInfoRecommendation -> Dictionary.PhoneVerificationTransactionRecommendation |
| FK_PhoneVerificationDetails_DictionaryPhoneTypes | FOREIGN KEY | PhoneType -> Dictionary.PhoneTypes |
| FK_PhoneVerificationDetails_PhoneVerifiedID | FOREIGN KEY | PhoneVerifiedID -> Dictionary.PhoneVerified |
| df_PhoneVerificationDetailsdefault_CountryID | DEFAULT | CountryID = 0 |
| DF_PhoneVerificationDetails_PhoneVerifiedID | DEFAULT | PhoneVerifiedID = 0 |
| DF_CustomerPhoneVerificationDetails_VerificationAttemptCount | DEFAULT | VerificationAttemptCount = 0 |
| Df_GDPR_PhoneVerificationDetails_StartTime | DEFAULT | StartTime = getutcdate() |
| Df_GDPR_PhoneVerificationDetails_EndTime | DEFAULT | EndTime = '9999-12-31 23:59:59.9999999' |

---

## 8. Sample Queries

### 8.1 Get phone verification record for a customer

```sql
SELECT
    pvd.ID,
    pvd.CID,
    pvd.PhoneNumber,
    pvd.PhoneType,
    pv.PhoneVerifiedName,
    pvd.VerifacationDate,
    pvd.RiskInfoLevel,
    pvd.RiskInfoScore,
    pvd.VerificationAttemptCount,
    pvd.AbuseAttemptCount
FROM Customer.PhoneVerificationDetails_JunkNoga0725 pvd WITH (NOLOCK)
LEFT JOIN Dictionary.PhoneVerified pv WITH (NOLOCK)
    ON pv.PhoneVerifiedID = pvd.PhoneVerifiedID
WHERE pvd.CID = 18553176
ORDER BY pvd.ID DESC
```

### 8.2 Find customers with high abuse attempt counts

```sql
SELECT
    CID,
    PhoneNumber,
    AbuseAttemptCount,
    VerificationAttemptCount,
    VerifacationDate
FROM Customer.PhoneVerificationDetails_JunkNoga0725 WITH (NOLOCK)
WHERE AbuseAttemptCount > 5
ORDER BY AbuseAttemptCount DESC
```

### 8.3 View verification history for a customer

```sql
SELECT
    CID,
    PhoneVerifiedID,
    VerifacationDate,
    AbuseAttemptCount,
    StartTime,
    EndTime
FROM Customer.PhoneVerificationDetails_JunkNoga0725
FOR SYSTEM_TIME ALL
WHERE CID = 18553176
ORDER BY StartTime
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Complete Phone Verification on Prod](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/883982370) | Confluence (CR) | CustomerStatic + PhoneVerificationDetails joined query for verification code lookup on prod environment |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.PhoneVerificationDetails_JunkNoga0725 | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.PhoneVerificationDetails_JunkNoga0725.sql*
