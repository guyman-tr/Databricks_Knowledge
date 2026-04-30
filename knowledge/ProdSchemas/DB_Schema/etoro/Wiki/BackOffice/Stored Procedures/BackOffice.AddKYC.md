# BackOffice.AddKYC

> Upserts a customer's KYC regulatory questionnaire responses into BackOffice.KYC (INSERT on first submission, UPDATE on resubmission), and sets the customer's default regulation to CySec if none has been assigned.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (KYC.CID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the write path for customer KYC (Know Your Customer) suitability questionnaire data. Under MiFID II, NFA/CFTC, and other financial regulatory frameworks, eToro must collect detailed information about a customer's financial situation, trading experience, and investment objectives before they can trade. This procedure records or updates those questionnaire responses.

The procedure exists because KYC data changes over time - customers update their questionnaire answers, or BackOffice agents re-submit corrected data. The upsert design (INSERT if no record, UPDATE if one exists) ensures there is always exactly one KYC record per customer while supporting re-submissions without constraint violations. The one-row-per-customer design of `BackOffice.KYC` means this procedure is always an authoritative full-record replacement on updates.

Data flows as follows: a BackOffice agent or regulatory submission workflow calls this procedure with the customer's questionnaire responses. If this is the customer's first KYC submission, a new record is inserted and the customer's RegulationID in `BackOffice.Customer` is set to 1 (CySec) if it was previously 0 (None) - establishing the default regulation. On subsequent calls, all questionnaire fields are overwritten with the new values.

---

## 2. Business Logic

### 2.1 Upsert Pattern - INSERT or UPDATE Based on CID Existence

**What**: The procedure implements a manual upsert: check first, then INSERT or UPDATE.

**Columns/Parameters Involved**: `@CID`, `BackOffice.KYC.CID`

**Rules**:
- First, SELECT TOP 1 CID FROM BackOffice.KYC WHERE CID = @CID to detect existing record
- If NULL (no record): INSERT all fields (first submission)
- If not NULL (record exists): UPDATE all fields WHERE CID = @CID (resubmission replaces all data)
- No MERGE statement is used - explicit IF/ELSE guards the DML
- No transaction wrapper on the upsert itself - if update fails, partial state is possible

### 2.2 Default Regulation Assignment on First Submission

**What**: When a customer first submits KYC, the procedure sets their default regulation if none has been assigned.

**Columns/Parameters Involved**: `BackOffice.Customer.RegulationID`

**Rules**:
- After the KYC upsert, UPDATE BackOffice.Customer SET RegulationID=1 (CySec) WHERE RegulationID=0 (None) AND CID=@CID
- This fires on both INSERT and UPDATE paths (no conditional on first-submit only)
- RegulationID=0 = "None" (no regulation assigned); RegulationID=1 = CySec (Cyprus Securities and Exchange Commission)
- If the customer already has a non-zero RegulationID, this UPDATE is a no-op (CASE WHEN RegulationID=0 THEN 1 ELSE RegulationID END)

### 2.3 Commented-Out Verification Level Logic

**What**: Original code also set VerificationLevelID=1 (Basic) on first submission; this was removed.

**Rules**:
- The commented-out line `VerificationLevelID = CASE WHEN VerificationLevelID = 0 THEN 1 ELSE VerificationLevelID END` was intended to set Basic verification level when customer first completes KYC
- This logic was removed - VerificationLevelID is now managed separately

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | BIGINT | NO | - | CODE-BACKED | Customer ID. Used both to check KYC record existence and as the WHERE key for INSERT/UPDATE. Maps to BackOffice.KYC.CID (clustered PK - one record per customer). |
| 2 | @ManagerID | BIGINT | NO | - | CODE-BACKED | BackOffice manager ID submitting the KYC data. Records which agent entered or updated the questionnaire. Maps to BackOffice.KYC.ManagerID. |
| 3 | @EmploymentStatus | NVARCHAR(200) | NO | - | CODE-BACKED | Customer's employment status (free-text questionnaire answer, e.g., "Employed", "Self-Employed", "Retired"). Stored verbatim as submitted. |
| 4 | @JobTitle | NVARCHAR(200) | NO | - | CODE-BACKED | Customer's job title or occupation as stated in the KYC questionnaire. Free-text. |
| 5 | @Gender | NVARCHAR(20) | NO | - | CODE-BACKED | Customer's gender as declared in the KYC questionnaire. Free-text (e.g., "Male", "Female"). |
| 6 | @Income | NVARCHAR(200) | NO | - | CODE-BACKED | Annual income bracket selected by the customer (e.g., "Under $25,000", "25,000-50,000"). Regulatory suitability field. |
| 7 | @PlanningToInvest | NVARCHAR(200) | NO | - | CODE-BACKED | Amount the customer plans to invest on the platform (questionnaire range selection). Regulatory suitability field. |
| 8 | @AnnualInvest | NVARCHAR(200) | NO | - | CODE-BACKED | Annual investment amount bracket stated by the customer. Used to assess financial capacity for risk. |
| 9 | @IsRiskDesclaimed | BIT | NO | - | VERIFIED | Whether the customer accepted the risk disclaimer: 1=Yes (risk accepted), 0=No. Mandatory NOT NULL field in BackOffice.KYC. |
| 10 | @Purpose | NVARCHAR(200) | NO | - | CODE-BACKED | Customer's stated purpose for opening the account (e.g., "Long term investment", "Active trading"). Regulatory requirement. |
| 11 | @WorkExperience | NVARCHAR(200) | NO | - | CODE-BACKED | Years/level of relevant work experience in finance or trading. Suitability assessment field. |
| 12 | @TradingExperience | NVARCHAR(200) | NO | - | CODE-BACKED | Level of prior trading experience (e.g., "None", "1-3 years", "3+ years"). Core suitability field. |
| 13 | @InvestExperience | NVARCHAR(200) | NO | - | CODE-BACKED | Level of prior investment experience across financial instruments. Suitability assessment field. |
| 14 | @InvestRisk | NVARCHAR(200) | NO | - | CODE-BACKED | Customer's stated risk tolerance for investments. Regulatory suitability field. |
| 15 | @InfoClear | NVARCHAR(200) | NO | - | CODE-BACKED | Whether the customer confirmed that platform information was clear and understandable. Disclosure confirmation field. |
| 16 | @UpdateDate | DATETIME | NO | - | CODE-BACKED | Timestamp of this KYC submission. Stored as BackOffice.KYC.UpdateDate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.KYC | WRITER (UPSERT) | INSERT or UPDATE KYC questionnaire record for the customer |
| @CID | BackOffice.Customer | MODIFIER | Sets RegulationID=1 (CySec) if currently 0 (None) |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found in the BackOffice schema. Called from BackOffice application layer during KYC questionnaire submission workflow.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.AddKYC (procedure)
|- BackOffice.KYC (table) [UPSERT - KYC questionnaire data]
+-- BackOffice.Customer (table) [UPDATE RegulationID default]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.KYC | Table | SELECT to check existence; INSERT on first submission; UPDATE on resubmission |
| BackOffice.Customer | Table | UPDATE RegulationID=1 (CySec) WHERE RegulationID=0 (None) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application layer | External | Called when customer submits or resubmits KYC questionnaire |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Single record per customer | Design | SELECT TOP 1 CID check enforces one-record-per-customer logic matching the KYC table's clustered PK on CID |
| No-op regulation update | Design | RegulationID update is a CASE expression that preserves existing non-zero values - safe to call repeatedly |

---

## 8. Sample Queries

### 8.1 Submit KYC questionnaire for a customer (first time)

```sql
EXEC BackOffice.AddKYC
    @CID = 12345,
    @ManagerID = 742,
    @EmploymentStatus = N'Employed',
    @JobTitle = N'Software Engineer',
    @Gender = N'Male',
    @Income = N'50,000-100,000',
    @PlanningToInvest = N'1,000-5,000',
    @AnnualInvest = N'5,000-10,000',
    @IsRiskDesclaimed = 1,
    @Purpose = N'Long term investment',
    @WorkExperience = N'1-3 years',
    @TradingExperience = N'1-3 years',
    @InvestExperience = N'1-3 years',
    @InvestRisk = N'Moderate',
    @InfoClear = N'Yes',
    @UpdateDate = GETUTCDATE()
```

### 8.2 Check current KYC record for a customer

```sql
SELECT CID, ManagerID, EmploymentStatus, TradingExperience, IsRiskDesclaimed, UpdateDate
FROM BackOffice.KYC WITH (NOLOCK)
WHERE CID = 12345
```

### 8.3 Verify regulation assignment after KYC submission

```sql
SELECT c.CID, c.RegulationID, k.UpdateDate AS KYCDate
FROM BackOffice.Customer c WITH (NOLOCK)
LEFT JOIN BackOffice.KYC k WITH (NOLOCK) ON c.CID = k.CID
WHERE c.CID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.AddKYC | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.AddKYC.sql*
