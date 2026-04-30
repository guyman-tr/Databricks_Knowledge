# BackOffice.KycAddILQ

> Upserts the full US KYC (ILQ) profile for a customer - updating Customer.Customer basic fields and inserting or updating BackOffice.KYC with all 60+ regulatory fields, then sets VerificationLevelID = 1 via ChangeCustomerVerificationLevel.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @ManagerID; writes to Customer.Customer + BackOffice.KYC; @Success BIT OUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`KycAddILQ` is the primary write procedure for the US-specific KYC (Know Your Customer) Individual License Questionnaire (ILQ) workflow. It captures the full set of personal, financial, employment, and regulatory information required for US retail forex/trading customers under NFA/CFTC regulations.

The ILQ (Individual License Questionnaire) is the US regulatory onboarding form required by the NFA (National Futures Association) and CFTC for retail forex counterparty account opening. eToro USA collects this data via the front-end registration flow and submits it to this SP to be persisted.

The procedure performs a dual write:
1. **Customer.Customer**: Updates basic personal fields (name, DOB, gender, address, phone) on the primary customer record
2. **BackOffice.KYC**: Upserts the full ILQ dataset with all US-regulatory fields (SSN, driver's license, employment, net worth, bankruptcy history, trading experience, regulatory questions, agreement acknowledgements)

After both writes, `BackOffice.ChangeCustomerVerificationLevel` is called to set the customer to VerificationLevelID = 1 (basic KYC step started). This is the entry point for US customer compliance.

The procedure's 63 parameters cover 6 categories:
1. **Basic details**: identity, address, SSN, driver's license
2. **Employment details**: status, income, employer, business type, source of funds
3. **Economic profile**: net worth, liquid assets, bankruptcy history
4. **Trading experience**: forex and securities experience levels
5. **Regulatory questions**: CFTC-required disclosures (family associations, retail forex relationships, commodity pool status, third-party financial interests)
6. **Agreements**: consent flags for all required regulatory agreements and e-signature

---

## 2. Business Logic

### 2.1 Customer Existence Guard

**What**: The entire operation is conditional on the customer existing in Customer.Customer.

**Rules**:
- `IF EXISTS (SELECT 1 FROM Customer.Customer WITH (NOLOCK) WHERE CID = @CID)` -> proceed
- Otherwise: `SET @Success = 0` and return silently
- No error raised for non-existent CID - the caller must check @Success

### 2.2 KYC Upsert (INSERT or UPDATE)

**What**: Inserts a new KYC record or updates the existing one.

**Rules**:
- Check `IF EXISTS (SELECT 1 FROM BackOffice.KYC WITH (NOLOCK) WHERE CID = @CID)` -> @HaveCustomerInKYC
- **UPDATE path**: Updates all 33 KYC fields including `UpdateDate = GETDATE()`
- **INSERT path**: Inserts all 33 KYC fields with `UpdateDate = GETDATE()`

### 2.3 Dual Transaction: Customer + KYC + Verification Level

**What**: All three writes (Customer.Customer UPDATE, KYC upsert, ChangeCustomerVerificationLevel) occur atomically in a single named transaction.

**Rules**:
- `BEGIN TRANSACTION T1`
- 1. UPDATE Customer.Customer (FirstName, LastName, BirthDate, Gender, Address, City, Zip, Phone)
- 2. IF @HaveCustomerInKYC = 1: UPDATE BackOffice.KYC ... WHERE CID = @CID
     IF @HaveCustomerInKYC = 0: INSERT INTO BackOffice.KYC (all fields)
- 3. EXEC BackOffice.ChangeCustomerVerificationLevel @CID, 1 (sets VerificationLevelID to 1)
- 4. SET @Success = 1
- 5. COMMIT TRANSACTION T1
- On any error: ROLLBACK (if @@TRANCOUNT = 1), log to History.InsertLogErrorGeneral, RAISERROR, @Success = 0

### 2.4 Comprehensive Error Logging

**What**: On any exception, all 63 input parameters are serialized to XML and logged to the error history table.

**Rules**:
- CATCH block captures all input params into `@Param_XML` via `SELECT ... FOR XML RAW('KycAddILQ'), BINARY BASE64, ELEMENTS, TYPE`
- Calls `EXECUTE [History].[InsertLogErrorGeneral] 'BackOffice.KycAddILQ', @Param_XML, @ErrorNumber, ...`
- Rolls back the transaction, then re-raises the error with RAISERROR

**Diagram**:
```
@CID exists in Customer.Customer?
  NO  -> @Success = 0, RETURN
  YES ->
    BEGIN TRANSACTION T1
      UPDATE Customer.Customer (basic fields)
      IF KYC exists -> UPDATE BackOffice.KYC
      IF KYC new    -> INSERT INTO BackOffice.KYC
      EXEC BackOffice.ChangeCustomerVerificationLevel @CID, 1
      @Success = 1
    COMMIT T1
    (ON ERROR: ROLLBACK, log to History.InsertLogErrorGeneral, RAISERROR, @Success = 0)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input parameters grouped by category:**

**General:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | BIGINT | NO | - | CODE-BACKED | Customer ID. Must exist in Customer.Customer or @Success is set to 0. Also the join key for BackOffice.KYC upsert. |
| 2 | @ManagerID | BIGINT | NO | - | CODE-BACKED | Back Office manager performing the KYC entry. Stored in BackOffice.KYC.ManagerID. |

**Basic Details (written to both Customer.Customer and BackOffice.KYC):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | @Title | NVARCHAR(5) | NO | - | CODE-BACKED | Customer title (Mr/Ms/Dr etc). Stored in BackOffice.KYC only. |
| 4 | @FirstName | NVARCHAR(50) | NO | - | CODE-BACKED | Updates Customer.Customer.FirstName. |
| 5 | @LastName | NVARCHAR(50) | NO | - | CODE-BACKED | Updates Customer.Customer.LastName. |
| 6 | @Citizenship | NVARCHAR(50) | NO | - | CODE-BACKED | Country of citizenship. Stored in BackOffice.KYC. |
| 7 | @DateOfBirth | DATETIME | NO | - | CODE-BACKED | Updates Customer.Customer.BirthDate. |
| 8 | @Gender | NVARCHAR(1) | NO | - | CODE-BACKED | Updates Customer.Customer.Gender. |
| 9 | @SocialSecurityNumber | NVARCHAR(9) | NO | - | CODE-BACKED | US SSN. Stored in BackOffice.KYC. Required for US regulatory compliance. |
| 10 | @ResidentialAddress | NVARCHAR(100) | NO | - | CODE-BACKED | Updates Customer.Customer.Address. |
| 11 | @City | NVARCHAR(50) | NO | - | CODE-BACKED | Updates Customer.Customer.City. |
| 12 | @Zip | NVARCHAR(50) | NO | - | CODE-BACKED | Updates Customer.Customer.Zip. |
| 13 | @MailingAddress | NVARCHAR(50) | NO | - | CODE-BACKED | Mailing address if different from residential. Stored in BackOffice.KYC. |
| 14 | @Phone | NVARCHAR(30) | NO | - | CODE-BACKED | Updates Customer.Customer.Phone. |
| 15 | @PermanentUsResident | BIT | NO | - | CODE-BACKED | Whether the customer is a permanent US resident. CFTC/NFA regulatory field. |
| 16 | @DriversLicenseOrStateIdCard | NVARCHAR(20) | NO | - | CODE-BACKED | Driver's license or state ID number used as identity document for US KYC. |
| 17 | @IssuingState | NVARCHAR(50) | NO | - | CODE-BACKED | US state that issued the driver's license or ID card. |

**Employment Details:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 18 | @EmploymentStatus | NVARCHAR(25) | NO | - | CODE-BACKED | Employment status (Employed, Self-employed, Retired, Student, etc.). |
| 19 | @Income | NVARCHAR(200) | NO | - | CODE-BACKED | Annual income range or amount. |
| 20 | @EmployerName | NVARCHAR(50) | YES | NULL | CODE-BACKED | Employer name. Optional - only required if employed. |
| 21 | @BusinessType | NVARCHAR(60) | YES | NULL | CODE-BACKED | Type of business. Optional. |
| 22 | @SourceOfFunds | NVARCHAR(256) | YES | NULL | CODE-BACKED | Source of funds category (salary, savings, investment, etc.). Optional. |
| 23 | @SourceOfFundsExplain | NVARCHAR(256) | NO | - | CODE-BACKED | Free-text explanation of source of funds. Anti-money-laundering (AML) field. |

**Economic Profile:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 24 | @NetWorth | NVARCHAR(30) | NO | - | CODE-BACKED | Total net worth range (CFTC appropriateness check). |
| 25 | @LiquidAssets | NVARCHAR(30) | NO | - | CODE-BACKED | Liquid assets available (suitability assessment). |
| 26 | @HasFiledBankruptcy | BIT | NO | - | CODE-BACKED | Whether the customer has ever filed for bankruptcy. |
| 27 | @BankruptcyDischargeDate | DATETIME | YES | NULL | CODE-BACKED | Date of bankruptcy discharge. Required only if @HasFiledBankruptcy = 1. |

**Trading Experience:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 28 | @InterbankOrOTCForeignExchange | NVARCHAR(30) | NO | - | CODE-BACKED | Self-assessed experience level in interbank/OTC forex trading. |
| 29 | @StocksBondFuturesOptions | NVARCHAR(30) | NO | - | CODE-BACKED | Self-assessed experience level in stocks, bonds, futures, options. |

**Regulatory Questions (CFTC/NFA required):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 30 | @HasFamilyRelationWithPersonAssociatedWithUs | BIT | NO | - | CODE-BACKED | NFA-required disclosure: family member associated with CFTC/NFA-regulated entity. |
| 31 | @HasFamilyRelationWithPersonAssociatedWithUsExplain | NVARCHAR(256) | NO | - | CODE-BACKED | Explanation if above = 1. |
| 32 | @IsRelatedToRetailForexCounterParty | BIT | NO | - | CODE-BACKED | NFA: whether customer is related to a retail forex counterparty. |
| 33 | @IsRelatedToRetailForexCounterPartyExplain | NVARCHAR(256) | NO | - | CODE-BACKED | Explanation if above = 1. |
| 34 | @IsCommodityPoolOrInvestmentVehicleOrIntermediary | BIT | NO | - | CODE-BACKED | NFA: whether customer acts as a commodity pool, investment vehicle, or intermediary. |
| 35 | @IsCommodityPoolOrInvestmentVehicleOrIntermediaryExplain | NVARCHAR(256) | NO | - | CODE-BACKED | Explanation if above = 1. |
| 36 | @OtherPersonHasFinancialInterest | BIT | NO | - | CODE-BACKED | NFA: whether another person has a financial interest in this account. |
| 37 | @OtherPersonHasFinancialInterestExplain | NVARCHAR(256) | NO | - | CODE-BACKED | Explanation if above = 1. |

**Agreements:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 38 | @ClientAgreement | BIT | NO | - | CODE-BACKED | Customer agreed to the client agreement. |
| 39 | @RiskDisclosure | BIT | NO | - | CODE-BACKED | Customer acknowledged risk disclosure statement. |
| 40 | @AdditionalRiskDisclosure | BIT | NO | - | CODE-BACKED | Customer acknowledged additional risk disclosure (CFTC-required for forex). |
| 41 | @CounterpartyRiskDisclosure | BIT | NO | - | CODE-BACKED | Customer acknowledged counterparty risk disclosure. |
| 42 | @HighRiskInvestment | BIT | NO | - | CODE-BACKED | Customer acknowledged high-risk investment warning. |
| 43 | @ElectronicSignatureAndRecords | BIT | NO | - | CODE-BACKED | Customer consented to electronic signature and records. |
| 44 | @ConfirmIdentity | BIT | NO | - | CODE-BACKED | Customer confirmed their identity is correct. |
| 45 | @Signature | NVARCHAR(50) | NO | - | CODE-BACKED | Customer's electronic signature (name string). |
| 46 | @SlippageExecutionPolicy | BIT | NO | - | CODE-BACKED | Customer acknowledged the slippage and execution policy. |

**Return:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 47 | @Success | BIT OUTPUT | NO | - | CODE-BACKED | 1 = transaction committed (both Customer.Customer and KYC written, verification level set). 0 = CID not found OR an exception occurred (transaction rolled back). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Guard + Writer | EXISTS check then UPDATE basic personal fields |
| @CID | BackOffice.KYC | Writer (upsert) | INSERT or UPDATE full ILQ KYC dataset |
| @CID, 1 | BackOffice.ChangeCustomerVerificationLevel | EXEC | Sets VerificationLevelID = 1 after KYC submission |
| Error logging | History.InsertLogErrorGeneral | EXEC (error path) | Logs full parameter XML on exception |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.KycAddILQ (procedure)
├── Customer.Customer (table) [EXISTS guard + UPDATE basic fields]
├── BackOffice.KYC (table) [EXISTS check + INSERT or UPDATE]
├── BackOffice.ChangeCustomerVerificationLevel (procedure) [EXEC - sets VerificationLevelID = 1]
└── History.InsertLogErrorGeneral (procedure) [EXEC - error logging with full XML params]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | EXISTS guard + UPDATE (FirstName, LastName, BirthDate, Gender, Address, City, Zip, Phone) |
| BackOffice.KYC | Table | EXISTS check (HaveCustomerInKYC) + UPSERT (all 33 KYC fields) |
| BackOffice.ChangeCustomerVerificationLevel | Stored Procedure | Sets VerificationLevelID = 1 for the customer |
| History.InsertLogErrorGeneral | Stored Procedure | Error audit logging with full XML parameter capture |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SSDT dependents found. | - | Called by US customer registration/KYC service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages |
| BEGIN TRANSACTION T1 (named) | Transaction | Atomic write across Customer.Customer, BackOffice.KYC, and ChangeCustomerVerificationLevel |
| ROLLBACK if @@TRANCOUNT = 1 | Safety | Rollback only at the outermost transaction to avoid partial rollback of outer transactions |
| COMMIT if @@TRANCOUNT > 1 | Safety | If nested inside a larger transaction, commit inner savepoint only |
| FOR XML RAW(...) BINARY BASE64 | Error logging | Serializes all 63 input params to XML for audit/debugging |
| History.InsertLogErrorGeneral | Error logging | Central error audit table for procedural errors |
| No NOCOUNT in CATCH | Omission | Row counts flow during error path (benign) |

---

## 8. Sample Queries

### 8.1 Submit full ILQ KYC for a US customer

```sql
DECLARE @Success BIT;
EXEC [BackOffice].[KycAddILQ]
    @CID = 12345,
    @ManagerID = 99,
    @Title = 'Mr',
    @FirstName = 'John',
    @LastName = 'Smith',
    @Citizenship = 'United States',
    @DateOfBirth = '1985-03-15',
    @Gender = 'M',
    @SocialSecurityNumber = '123456789',
    @ResidentialAddress = '123 Main St',
    @City = 'New York',
    @Zip = '10001',
    @MailingAddress = '123 Main St',
    @Phone = '+12125551234',
    @PermanentUsResident = 1,
    @DriversLicenseOrStateIdCard = 'D123456',
    @IssuingState = 'New York',
    -- employment
    @EmploymentStatus = 'Employed',
    @Income = '50000-100000',
    @SourceOfFundsExplain = 'Employment income',
    -- economic profile
    @NetWorth = '100000-250000',
    @LiquidAssets = '50000-100000',
    @HasFiledBankruptcy = 0,
    -- trading experience
    @InterbankOrOTCForeignExchange = 'Limited',
    @StocksBondFuturesOptions = 'Moderate',
    -- regulatory questions
    @HasFamilyRelationWithPersonAssociatedWithUs = 0,
    @HasFamilyRelationWithPersonAssociatedWithUsExplain = '',
    @IsRelatedToRetailForexCounterParty = 0,
    @IsRelatedToRetailForexCounterPartyExplain = '',
    @IsCommodityPoolOrInvestmentVehicleOrIntermediary = 0,
    @IsCommodityPoolOrInvestmentVehicleOrIntermediaryExplain = '',
    @OtherPersonHasFinancialInterest = 0,
    @OtherPersonHasFinancialInterestExplain = '',
    -- agreements
    @ClientAgreement = 1,
    @RiskDisclosure = 1,
    @AdditionalRiskDisclosure = 1,
    @CounterpartyRiskDisclosure = 1,
    @HighRiskInvestment = 1,
    @ElectronicSignatureAndRecords = 1,
    @ConfirmIdentity = 1,
    @Signature = 'John Smith',
    @SlippageExecutionPolicy = 1,
    @Success = @Success OUTPUT;

SELECT @Success AS KycSubmitSuccess; -- 1 = success, 0 = failure
```

### 8.2 Check existing KYC record for a customer

```sql
SELECT CID, ManagerID, SocialSecurityNumber, EmploymentStatus,
       NetWorth, HasFiledBankruptcy, UpdateDate
FROM BackOffice.KYC WITH (NOLOCK)
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 5.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 47 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SSDT | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.KycAddILQ | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.KycAddILQ.sql*
