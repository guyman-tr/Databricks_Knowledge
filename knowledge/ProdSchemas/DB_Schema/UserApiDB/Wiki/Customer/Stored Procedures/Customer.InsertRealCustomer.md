# Customer.InsertRealCustomer

> The new-style customer registration procedure - creates accounts by directly inserting into Customer schema normalized tables (BasicUserInfo, ContactUserInfo, AccountUserInfo, RiskUserInfo, UserSettings) in a single transaction.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | OUTPUT @OrigCID, @CID_Demo, @CID_Real, @GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.InsertRealCustomer is the new-style registration procedure that writes directly into the normalized Customer schema tables rather than delegating to RegisterReal. It creates a complete customer record across 6+ tables in a single transaction: CustomerIdentification, BasicUserInfo, ContactUserInfo, AccountUserInfo, RiskUserInfo, UserSettings, and optionally ApplicationActivation and ToaDetails_Registration.

This procedure represents the migration from the legacy denormalized dbo tables (used by InsertNewCustomer) to the normalized Customer schema. It generates GCID via InsertGlobalCustomer, allocates CIDs via sequences, resolves region from IP if not provided (via Internal.GetRegionIDByIP), and handles TOA registration details.

Key differences from InsertNewCustomer: no RegisterReal call, no async action queue, direct INSERTs into Customer schema tables, fewer parameters (no demo credit, provider IDs, etc.), and includes Internal.GetRegionIDByIP for region resolution.

---

## 2. Business Logic

### 2.1 Registration Transaction Flow (New Style)

**What**: Direct INSERT into 6+ Customer schema tables in a single transaction.

**Rules**:
1. Resolve RegionByIP_ID and RegionID from IP if not provided
2. EXEC InsertGlobalCustomer -> @GCID
3. NEXT VALUE FOR Customer.SEQCustomerID -> @CID_Real
4. NEXT VALUE FOR Customer.SEQDemoCID -> @CID_Demo
5. If @OrigCID=0, set @OrigCID=@CID_Demo
6. INSERT Customer.CustomerIdentification (GCID, CID, DemoCID)
7. INSERT Customer.BasicUserInfo (GCID, UserName, PlayerLevel, Language, Names, Gender, BirthDate, Registered)
8. INSERT Customer.ContactUserInfo (GCID, Country, IP country, Region, Email, Address, Phone, IsEmailVerified)
9. INSERT Customer.AccountUserInfo (GCID, OrigCID, Serial, Label, TradeLevel, Currency, SubSerial, FunnelFrom, AccountType)
10. INSERT Customer.RiskUserInfo (GCID, Regulation, PlayerStatus, DesignatedRegulation)
11. INSERT Customer.UserSettings (GCID, PrivacyPolicy, OptOutReason)
12. If @AccountActivationID=1: INSERT Customer.ApplicationActivation
13. If @toaId provided: convert MamcId, EXEC InsertToaRegistrationDetails
14. COMMIT

### 2.2 Gender Conversion

**What**: Integer gender parameter converted to char for BasicUserInfo.

**Rules**:
- @Gender=0 -> NULL
- @Gender=1 -> 'M'
- else -> 'F'

### 2.3 Email Verification Default

**What**: IsEmailVerified defaults based on email presence.

**Rules**:
- If @Email IS NULL -> IsEmailVerified = NULL
- If @Email IS NOT NULL -> IsEmailVerified = 0 (unverified)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserName | varchar(20) | NO | - | CODE-BACKED | Account username. |
| 2 | @Email | varchar(50) | NO | - | CODE-BACKED | Email address. |
| 3 | @LangID | int | NO | - | CODE-BACKED | Language. FK to Dictionary.Language. |
| 4 | @CountryID | int | NO | - | CODE-BACKED | Registered country. |
| 5 | @TradeLevelID | int | NO | - | CODE-BACKED | Trading authorization level. |
| 6 | @LabelID | int | NO | - | CODE-BACKED | White label/brand. |
| 7 | @Gender | int | NO | - | CODE-BACKED | Gender: 0=NULL, 1=M, other=F. |
| 8 | @CurrencyID | int | NO | - | CODE-BACKED | Account currency. |
| 9 | @RegulationID | int | NO | - | CODE-BACKED | Primary regulation. |
| 10 | @PlayerStatusID | int | NO | - | CODE-BACKED | Initial player status. |
| 11 | @AccountTypeID | int | NO | - | CODE-BACKED | Account type. |
| 12 | @PlayerLevelID | int | NO | - | CODE-BACKED | Player experience level. |
| 13 | @DesignatedRegulationID | int | YES | NULL | CODE-BACKED | Designated regulation. |
| 14 | @AccountActivationID | int | YES | 1 | CODE-BACKED | 1=standard activation. |
| 15 | @PrivacyPolicyID | int | YES | NULL | CODE-BACKED | Privacy policy version. |
| 16 | @RegIP | varchar(15) | YES | NULL | CODE-BACKED | Registration IP. Used for region resolution. |
| 17 | @toaId | nvarchar(300) | YES | NULL | CODE-BACKED | TOA identifier. |
| 18 | @mamcId | nvarchar(300) | YES | NULL | CODE-BACKED | MAMC identifier. |
| 19 | @OrigCID (OUTPUT) | int | YES | - | CODE-BACKED | Original CID (set to @CID_Demo if 0). |
| 20 | @CID_Demo (OUTPUT) | int | YES | - | CODE-BACKED | Allocated demo CID. |
| 21 | @CID_Real (OUTPUT) | int | YES | - | CODE-BACKED | Allocated real CID. |
| 22 | @GCID (OUTPUT) | int | YES | 0 | CODE-BACKED | Generated Global Customer ID. |
| 23 | @Occurred | datetime | YES | NULL | CODE-BACKED | Registration timestamp. Defaults to GETDATE() if NULL. |
| 24-54 | (30+ additional params) | Various | - | - | CODE-BACKED | Phone, SerialID, SubSerialID, FunnelFromID, Names, Mobile, Fax, Address, City, Zip, BirthDate, CountryIdByIP, RegionByIP_ID, StateID, PhonePrefix, PhoneBody, TOA fields, RegionID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.InsertGlobalCustomer | EXEC | GCID generation |
| - | Customer.SEQCustomerID | SEQUENCE | Real CID allocation |
| - | Customer.SEQDemoCID | SEQUENCE | Demo CID allocation |
| - | Internal.GetRegionIDByIP | Function call | Region from IP resolution |
| - | Customer.CustomerIdentification | INSERT | Identity mapping |
| - | Customer.BasicUserInfo | INSERT | Basic profile |
| - | Customer.ContactUserInfo | INSERT | Contact data |
| - | Customer.AccountUserInfo | INSERT | Account data |
| - | Customer.RiskUserInfo | INSERT | Risk data |
| - | Customer.UserSettings | INSERT | Settings |
| - | Customer.ApplicationActivation | INSERT | Activation record |
| - | Customer.ConvertToaIdToMamcId | Function call | TOA conversion |
| - | Customer.InsertToaRegistrationDetails | EXEC | TOA registration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | New-style registration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.InsertRealCustomer (procedure)
+-- dbo.InsertGlobalCustomer (procedure)
+-- Customer.SEQCustomerID (sequence)
+-- Customer.SEQDemoCID (sequence)
+-- Internal.GetRegionIDByIP (function)
+-- Customer.CustomerIdentification (table)
+-- Customer.BasicUserInfo (table)
+-- Customer.ContactUserInfo (table)
+-- Customer.AccountUserInfo (table)
+-- Customer.RiskUserInfo (table)
+-- Customer.UserSettings (table)
+-- Customer.ApplicationActivation (table)
+-- Customer.ConvertToaIdToMamcId (function)
+-- Customer.InsertToaRegistrationDetails (procedure)
+-- History.LogErrorGeneral (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.InsertGlobalCustomer | Procedure | EXEC - GCID |
| Internal.GetRegionIDByIP | Function | Region resolution |
| Customer.CustomerIdentification | Table | INSERT |
| Customer.BasicUserInfo | Table | INSERT |
| Customer.ContactUserInfo | Table | INSERT |
| Customer.AccountUserInfo | Table | INSERT |
| Customer.RiskUserInfo | Table | INSERT |
| Customer.UserSettings | Table | INSERT |
| Customer.InsertToaRegistrationDetails | Procedure | EXEC |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | New registration service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| XACT_ABORT ON | Transaction | Auto-rollback |
| RAISERROR 60000 | Validation | GCID=-1 or @@RowCount!=1 on any INSERT |
| TRY/CATCH | Error handling | Logs to History.LogErrorGeneral |

---

## 8. Sample Queries

### 8.1 Register via new style
```sql
DECLARE @OrigCID int, @CID_Demo int, @CID_Real int, @GCID int
EXEC Customer.InsertRealCustomer
    @UserName='newuser', @Email='new@example.com',
    @LangID=1, @CountryID=234, @TradeLevelID=1, @LabelID=1,
    @Gender=1, @CurrencyID=1, @SerialID=0, @SubSerialID='0',
    @FunnelFromID=0, @BirthDate='1990-01-01', @PlayerLevelID=1,
    @AccountTypeID=1, @PlayerStatusID=1, @CountryIdByIP=234,
    @RegulationID=1, @StateID=0, @RegulationID=1,
    @OrigCID=@OrigCID OUTPUT, @CID_Demo=@CID_Demo OUTPUT,
    @CID_Real=@CID_Real OUTPUT, @GCID=@GCID OUTPUT
SELECT @GCID AS GCID, @CID_Real AS RealCID, @CID_Demo AS DemoCID
```

### 8.2 Compare with legacy
```sql
-- InsertNewCustomer: calls RegisterReal (legacy dbo tables), queues async demo creation
-- InsertRealCustomer: inserts directly into Customer schema tables (new, preferred)
```

### 8.3 Verify all tables populated
```sql
SELECT 'CustomerIdentification' AS T, * FROM Customer.CustomerIdentification WITH (NOLOCK) WHERE GCID = @GCID
UNION ALL SELECT 'BasicUserInfo', * FROM Customer.BasicUserInfo WITH (NOLOCK) WHERE GCID = @GCID
-- etc. for each Customer schema table
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 9/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 54 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.InsertRealCustomer | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.InsertRealCustomer.sql*
