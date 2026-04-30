# Customer.InsertNewDemoCustomer

> Registers a demo (virtual money) account for an existing GCID by calling RegisterDemo and linking the demo CID to the customer's identity.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | OUTPUT @CID_Demo - the new demo account CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.InsertNewDemoCustomer creates a demo/virtual trading account for a customer who already has a GCID (typically created after the real account registration). Demo accounts let users practice trading with virtual money. The procedure calls the dbo.RegisterDemo stored procedure to create the actual demo account records, then links the demo CID to the customer via Customer.UpdateCustomerDemoCid.

If the demo registration succeeds, the procedure also cleans up any previous failed demo registration records from dbo.Register_Demo_Fail and updates the OrigCID via dbo.ChangeOrigCID.

---

## 2. Business Logic

### 2.1 Demo Registration Pipeline

**What**: Multi-step demo account creation with cleanup and linking.

**Rules**:
- EXEC RegisterDemo creates the demo account (returns @CID_Demo)
- If @CID_Demo IS NOT NULL (success):
  1. Delete any previous failed demo records for this GCID
  2. EXEC ChangeOrigCID to update the original CID reference
  3. EXEC Customer.UpdateCustomerDemoCid to link demo CID in CustomerIdentification
- If @CID_Demo IS NULL: RAISERROR('RegisterDemo failed')
- TRY/CATCH wraps the entire flow; rollback on error

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1-68 | (67 input parameters) | Various | - | - | CODE-BACKED | Same registration parameters as InsertNewCustomer: UserName, Email, ProviderID, ActionType, LoginID, GameType, DemoCredit, language, country, trade level, label, funnel, gender, currency, IP, phone, serial, referral, names, player level, account type, weekend fee, timezone, player status, spread group, occurred, expiration dates, privacy policy, regulation, risk status, state, phone prefix/body, GCID (required - already exists). |
| 69 | @CID_Demo (OUTPUT) | int | YES | - | CODE-BACKED | The newly created demo account CID. NULL if creation failed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.RegisterDemo | EXEC | Creates the demo account |
| - | dbo.Register_Demo_Fail | DELETE | Cleans up failed attempts |
| - | dbo.Real_Customer | JOIN | Links GCID in cleanup |
| - | dbo.ChangeOrigCID | EXEC | Updates OrigCID |
| - | Customer.UpdateCustomerDemoCid | EXEC | Links DemoCID in CustomerIdentification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Demo account creation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.InsertNewDemoCustomer (procedure)
+-- dbo.RegisterDemo (procedure)
+-- dbo.Register_Demo_Fail (table)
+-- dbo.Real_Customer (table)
+-- dbo.ChangeOrigCID (procedure)
+-- Customer.UpdateCustomerDemoCid (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.RegisterDemo | Procedure | EXEC - creates demo account |
| dbo.Register_Demo_Fail | Table | DELETE - cleanup |
| dbo.ChangeOrigCID | Procedure | EXEC - update OrigCID |
| Customer.UpdateCustomerDemoCid | Procedure | EXEC - link demo CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Demo registration service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH | Error handling | Rollback on failure; error details logged |
| RAISERROR | Validation | 'RegisterDemo failed And @CID_Demo Is Null' if demo creation fails |

---

## 8. Sample Queries

### 8.1 Create demo account (simplified)
```sql
DECLARE @DemoCID int
EXEC Customer.InsertNewDemoCustomer
    @UserName='testuser', @Email='test@example.com', @ProviderID=1,
    @ActionType=1, @LoginID=1, @GameType=1, @DemoCredit=100000,
    @OriginalProviderID=1, @RealProviderID=1, @OrigCID=0,
    @LangID=1, @CountryID=234, @TradeLevelID=1, @LabelID=1,
    @FunnelID=0, @Gender=1, @CurrencyID=1,
    @SerialID=0, @ReferralID=0, @SubSerialID='0',
    @DownloadID=0, @FunnelFromID=0, @BannerID=0,
    @ClientVersion='1.0', @DownloadCounter=0,
    @SendEmail=0, @BirthDate='1990-01-01',
    @PlayerLevelID=1, @IsRequestedCall=0, @AccountTypeID=1,
    @WeekendFeePercentage=0, @TimeZone=0, @PlayerStatusID=1,
    @SpreadGroupID=1, @Occurred=GETUTCDATE(),
    @CountryIdByIP=234, @ExpirationDateReal='2099-12-31',
    @ExpirationDateDemo='2099-12-31', @HelpDeskTypeID=1,
    @PrivacyPolicyID=1, @DefaultCashoutFeeGroupID=1,
    @RegulationID=1, @ChangePasswordDemo=0, @RiskStatusID=1,
    @StateID=0, @GCID=50001,
    @CID_Demo=@DemoCID OUTPUT
SELECT @DemoCID AS NewDemoCID
```

### 8.2 Verify demo account link
```sql
SELECT GCID, CID, DemoCID FROM Customer.CustomerIdentification WITH (NOLOCK) WHERE GCID = 50001
```

### 8.3 Check for failed demo registrations
```sql
SELECT * FROM dbo.Register_Demo_Fail WITH (NOLOCK) WHERE CID_Real IN (
    SELECT CID FROM dbo.Real_Customer WITH (NOLOCK) WHERE GCID = 50001
)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 69 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.InsertNewDemoCustomer | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.InsertNewDemoCustomer.sql*
