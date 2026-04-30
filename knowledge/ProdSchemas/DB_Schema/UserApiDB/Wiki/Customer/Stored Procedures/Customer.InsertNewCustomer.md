# Customer.InsertNewCustomer

> The primary full customer registration procedure - creates both real and demo accounts in a single transaction, assigns GCID/CIDs via sequences, calls RegisterReal, inserts CustomerIdentification, handles TOA details, and queues post-registration actions.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | OUTPUT @CID_Demo, @CID_Real, @GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.InsertNewCustomer is the primary customer registration procedure for the legacy registration flow. It orchestrates the entire account creation process: generates a GCID via InsertGlobalCustomer, allocates demo and real CIDs via sequences (Customer.SEQDemoCID, Customer.SEQCustomerID), calls dbo.RegisterReal to create the real account records, inserts the Customer.CustomerIdentification mapping, optionally creates TOA registration details, and queues post-registration actions via dbo.ActionsToExecute_Registration.

This procedure has been maintained since 2014 with extensive modifications for social registration (2017), MamcId support (2017), designated regulation (2018), one-registration-activation (2020), password removal (2022), and IP-based country changes (2022). It returns three OUTPUT parameters: @CID_Demo, @CID_Real, and @GCID.

The entire operation runs in a single transaction with XACT_ABORT ON. Errors are caught, logged via dbo.InsertLogErrorGeneral, and the error number is returned.

---

## 2. Business Logic

### 2.1 Registration Transaction Flow

**What**: Multi-step registration in a single transaction.

**Rules**:
1. EXEC InsertGlobalCustomer -> gets @GCID (returns -1 on failure -> error 60000)
2. NEXT VALUE FOR Customer.SEQDemoCID -> @CID_Demo
3. NEXT VALUE FOR Customer.SEQCustomerID -> @CID_Real
4. If @OrigCID=0, set @OrigCID=@CID_Demo (self-referencing for non-referred customers)
5. EXEC RegisterReal with all parameters -> creates real account
6. INSERT Customer.CustomerIdentification (GCID, CID, DemoCID)
7. If @toaId provided: convert to MamcId if needed, then EXEC InsertToaRegistrationDetails
8. COMMIT
9. Build XML parameters, INSERT into dbo.ActionsToExecute_Registration (ActionID=8) for async post-registration processing

### 2.2 Post-Registration Action Queue

**What**: After commit, queues ActionID=8 in ActionsToExecute_Registration for async processing.

**Rules**:
- XML contains ExternalID, CreditTypeID=1, CID_Real, CID_Demo, DemoCredit, RealProviderID, ChangePasswordDemo, ActionType, LoginID, GameType, SendEmail, AccountTypeID, RegulationID, RiskStatusID, AffiliateStatusID, WasOrigCIDZero
- This triggers demo account creation and other post-registration steps asynchronously

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserName | varchar(20) | NO | - | CODE-BACKED | Account username. |
| 2 | @Email | varchar(50) | NO | - | CODE-BACKED | Email address. |
| 3 | @ProviderID | int | NO | - | CODE-BACKED | Registration provider. |
| 4 | @ActionType | int | NO | - | CODE-BACKED | Registration action type. |
| 5 | @CountryID | int | NO | - | CODE-BACKED | Registered country. |
| 6 | @LabelID | int | NO | - | CODE-BACKED | White label/brand. |
| 7 | @CurrencyID | int | NO | - | CODE-BACKED | Account base currency. |
| 8 | @RegulationID | int | NO | - | CODE-BACKED | Primary regulation. |
| 9 | @DesignatedRegulationID | int | YES | NULL | CODE-BACKED | Designated regulation override. Added 2018. |
| 10 | @AccountActivationID | int | YES | 1 | CODE-BACKED | Activation flow: 1=standard eToro activation. |
| 11 | @toaId | nvarchar(300) | YES | NULL | CODE-BACKED | TOA identifier for Chinese market transfers. |
| 12 | @mamcId | nvarchar(300) | YES | NULL | CODE-BACKED | MAMC identifier. Auto-derived from @toaId if NULL. |
| 13 | @CID_Demo (OUTPUT) | int | NO | - | CODE-BACKED | Newly allocated demo account CID. |
| 14 | @CID_Real (OUTPUT) | int | NO | - | CODE-BACKED | Newly allocated real account CID. |
| 15 | @GCID (OUTPUT) | int | NO | 0 | CODE-BACKED | Newly generated Global Customer ID. |
| 16-107 | (90+ additional params) | Various | - | - | CODE-BACKED | Full registration data: DemoCredit, OrigCID, language, trade level, funnel, gender, IP, phone, serial, referral, sub-serial, download, banner, client version, names, mobile, fax, address, city, state, country, zip, birth date, person ID, player level, requested call, account type, weekend fee, timezone, player status, spread group, occurred, IP country, region, expiration dates, helpdesk type, privacy policy, cashout fee group, change passwords, risk status, state ID, phone prefix/body, TOA fields, AppsFlyer ID, cookie, region, Firebase ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.InsertGlobalCustomer | EXEC | Generates GCID |
| - | Customer.SEQDemoCID | SEQUENCE | Allocates demo CID |
| - | Customer.SEQCustomerID | SEQUENCE | Allocates real CID |
| - | dbo.RegisterReal | EXEC | Creates real account records |
| - | Customer.CustomerIdentification | INSERT | GCID/CID/DemoCID mapping |
| - | Customer.ConvertToaIdToMamcId | Function call | TOA ID conversion |
| - | Customer.InsertToaRegistrationDetails | EXEC | TOA registration |
| - | dbo.ActionsToExecute_Registration | INSERT | Post-registration action queue |
| - | dbo.InsertLogErrorGeneral | EXEC | Error logging |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Primary registration entry point (legacy) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.InsertNewCustomer (procedure)
+-- dbo.InsertGlobalCustomer (procedure)
+-- Customer.SEQDemoCID (sequence)
+-- Customer.SEQCustomerID (sequence)
+-- dbo.RegisterReal (procedure)
+-- Customer.CustomerIdentification (table)
+-- Customer.ConvertToaIdToMamcId (function)
+-- Customer.InsertToaRegistrationDetails (procedure)
+-- dbo.ActionsToExecute_Registration (table)
+-- dbo.InsertLogErrorGeneral (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.InsertGlobalCustomer | Procedure | EXEC - GCID generation |
| dbo.RegisterReal | Procedure | EXEC - real account creation |
| Customer.CustomerIdentification | Table | INSERT - identity mapping |
| Customer.InsertToaRegistrationDetails | Procedure | EXEC - TOA details |
| dbo.ActionsToExecute_Registration | Table | INSERT - async actions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Legacy registration service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| XACT_ABORT ON | Transaction | Automatic rollback on any error |
| RAISERROR 60000 | Validation | GCID=-1 or RegisterReal failure |
| TRY/CATCH | Error handling | Rolls back, logs error XML via InsertLogErrorGeneral |

---

## 8. Sample Queries

### 8.1 Register a new customer (minimal)
```sql
DECLARE @CID_Demo int, @CID_Real int, @GCID int
EXEC Customer.InsertNewCustomer
    @UserName='newuser', @Email='new@example.com',
    @ProviderID=1, @ActionType=1, @LoginID=1, @GameType=1,
    @DemoCredit=100000, @OriginalProviderID=1, @RealProviderID=1,
    @OrigCID=0, @LangID=1, @CountryID=234, @TradeLevelID=1,
    @LabelID=1, @FunnelID=0, @Gender=1, @CurrencyID=1,
    @SerialID=0, @ReferralID=0, @SubSerialID='0',
    @DownloadID=0, @FunnelFromID=0, @BannerID=0,
    @ClientVersion='1.0', @DownloadCounter=0,
    @SendEmail=0, @BirthDate='1990-01-01', @PersonID=NULL,
    @PlayerLevelID=1, @IsRequestedCall=0, @AccountTypeID=1,
    @WeekendFeePercentage=0, @TimeZone=0, @PlayerStatusID=1,
    @SpreadGroupID=1, @Occurred=GETUTCDATE(), @CountryIdByIP=234,
    @ExpirationDateReal='2099-12-31', @ExpirationDateDemo='2099-12-31',
    @HelpDeskTypeID=1, @PrivacyPolicyID=1, @DefaultCashoutFeeGroupID=1,
    @RegulationID=1, @ChangePasswordReal=0, @ChangePasswordDemo=0,
    @RiskStatusID=1, @StateID=0,
    @CID_Demo=@CID_Demo OUTPUT, @CID_Real=@CID_Real OUTPUT, @GCID=@GCID OUTPUT
SELECT @GCID AS GCID, @CID_Real AS RealCID, @CID_Demo AS DemoCID
```

### 8.2 Compare with new registration SP
```sql
-- InsertNewCustomer: legacy (calls RegisterReal, queues async demo creation)
-- InsertRealCustomer: new (inserts directly into Customer schema tables)
```

### 8.3 Verify registration
```sql
SELECT GCID, CID, DemoCID FROM Customer.CustomerIdentification WITH (NOLOCK) WHERE GCID = @GCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.6/10 (Elements: 9/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 107 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.InsertNewCustomer | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.InsertNewCustomer.sql*
