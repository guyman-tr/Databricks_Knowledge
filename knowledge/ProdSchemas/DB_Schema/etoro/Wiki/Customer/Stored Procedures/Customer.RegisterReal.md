# Customer.RegisterReal

> Creates a new real (live) customer account: inserts Customer.CustomerStatic (IsReal=1), CustomerMoney, BackOffice.Customer with DesignatedRegulationID, optional tracking IDs (AppsFlyer/cookie/Firebase), and activates the application; the registration activation call to AffWiz Service Broker was disabled in March 2023 (PART-1253).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INTEGER (pre-generated) + @GCID INT (from UserDBAPI) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.RegisterReal` is the real-account creation endpoint for eToro. When a customer completes the full registration flow and is approved to trade with real money, this procedure provisions their permanent account record. Real accounts are distinguished from demo accounts by `IsReal=1` in `Customer.CustomerStatic` (note: real accounts use `Customer.CustomerStatic`, not `Customer.Customer` directly - real and demo accounts use different underlying tables in the vertical split architecture).

Key characteristics of real accounts:
- `IsReal = 1` - real money trading enabled.
- `DesignatedRegulationID` set at registration - determines which regulatory regime governs the account (MIFID, ASIC, FCA, etc.), added November 2018.
- Tracking IDs optionally inserted for AppsFlyer (TrackingID=1), UserUniqueIdentifierCookie (TrackingID=2), Firebase (TrackingID=3) if the values are provided.
- Account activation triggered via cross-DB call (`UserApiDB_CustomerActivateApplication`) if `@AccountActivationID=1`.
- OptOutReasonID = 0 if PrivacyPolicyID=1 (standard consent), else 1 (opted out).

The Service Broker registration notification to AffWiz was disabled in March 2023 (PART-1253, Noga Rozen). Error parameters are logged to `History.InsertLogErrorGeneral` on failure.

---

## 2. Business Logic

### 2.1 Customer Record Creation (Three-Table Pattern)

**What**: Initializes the real customer across three tables atomically.

**Rules**:
- INSERT `Customer.CustomerStatic`: 38+ columns, IsReal=1, Password='', OptOutReasonID = CASE WHEN PrivacyPolicyID=1 THEN 0 ELSE 1 END, OriginalCID = @OrigCID if non-zero else @CID.
- INSERT `Customer.CustomerMoney`: CID, GCID, Credit=0.
- INSERT `BackOffice.Customer`: CID, CashoutFeeGroupID, ChangePassword, RiskStatusID, AccountTypeID, RegulationID, RegulationChangeDate=@Occurred, DesignatedRegulationID.

### 2.2 Tracking ID Registration

**What**: Stores mobile/web tracking identifiers for attribution and push notifications.

**Rules**:
- IF AppsFlyerId IS NOT NULL AND != '': INSERT Customer.TrackingId(CID, GCID, TrackingID=1, TrackingValue=AppsFlyerId).
- IF UserUniqueIdentifierCookie IS NOT NULL AND != '': INSERT Customer.TrackingId(CID, GCID, TrackingID=2, TrackingValue=cookie).
- IF FirebaseId IS NOT NULL AND != '': INSERT Customer.TrackingId(CID, GCID, TrackingID=3, TrackingValue=FirebaseId).

### 2.3 Application Activation

**What**: Activates the customer's application access.

**Rules**:
- IF @AccountActivationID = 1: EXEC `UserApiDB_CustomerActivateApplication @GCID=@GCID, @ApplicationID=1`.
- @AccountActivationID defaults to 1 - activation runs by default.

### 2.4 OptOut Consent Mapping

**What**: Derives marketing opt-out status from privacy policy acceptance.

**Rules**:
- `@OptOutReasonID = CASE WHEN ISNULL(@PrivacyPolicyID, 1) = 1 THEN 0 ELSE 1 END`.
- PrivacyPolicyID=1 = standard/accepted consent -> OptOutReasonID=0 (not opted out).
- Other PrivacyPolicyID values = opted out (OptOutReasonID=1).

```
BEGIN TX:
  Resolve ExternalID (time+SPID), RegionID, PlatformID
  Compute OptOutReasonID from PrivacyPolicyID
  INSERT Customer.CustomerStatic (IsReal=1)
  INSERT Customer.CustomerMoney (Credit=0)
  INSERT BackOffice.Customer (with DesignatedRegulationID)
  IF AppsFlyerId != '': INSERT TrackingId (1)
  IF Cookie != '':      INSERT TrackingId (2)
  IF FirebaseId != '':  INSERT TrackingId (3)
  IF AccountActivationID=1: EXEC UserApiDB_CustomerActivateApplication
COMMIT
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements (Key Parameters)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Pre-generated CID (from UserDBAPI). Primary key of the new real account. |
| 2 | @GCID | INT | YES | 0 | CODE-BACKED | Pre-generated Global Customer ID. Used for cross-DB activation and tracking ID inserts. |
| 3 | @ProviderID | INTEGER | NO | - | CODE-BACKED | Trading provider for this account. |
| 4 | @OrigCID | INTEGER | YES | NULL | CODE-BACKED | Prior CID if migrated; 0/NULL for new registrations (OriginalCID = @CID). |
| 5 | @UserName | VARCHAR(20) | NO | - | CODE-BACKED | Username. Stored in CustomerStatic. |
| 6 | @Email | VARCHAR(50) | NO | - | CODE-BACKED | Email; IsEmailVerified=0. |
| 7 | @CountryID | INTEGER | NO | - | CODE-BACKED | Customer's country. |
| 8 | @RegulationID | INT | NO | - | CODE-BACKED | Regulatory regime at registration time. |
| 9 | @DesignatedRegulationID | INT | YES | NULL | CODE-BACKED | Regulatory entity that governs the account going forward; written to BackOffice.Customer. Added Nov 2018. |
| 10 | @BirthDate | DATETIME | NO | - | CODE-BACKED | Date of birth. |
| 11 | @AppsFlyerId | VARCHAR(50) | YES | NULL | CODE-BACKED | AppsFlyer mobile attribution ID; if provided, inserted as Customer.TrackingId TrackingID=1. |
| 12 | @UserUniqueIdentifierCookie | VARCHAR(50) | YES | NULL | CODE-BACKED | Web tracking cookie; if provided, inserted as Customer.TrackingId TrackingID=2. |
| 13 | @FirebaseId | VARCHAR(50) | YES | NULL | CODE-BACKED | Firebase push notification ID; if provided, inserted as Customer.TrackingId TrackingID=3. |
| 14 | @AccountActivationID | INT | YES | 1 | CODE-BACKED | 1=activate application (calls UserApiDB_CustomerActivateApplication); 0=skip activation. |
| 15 | @PrivacyPolicyID | INT | NO | - | CODE-BACKED | Privacy policy version accepted; 1=standard consent (OptOutReasonID=0), other=opted out (OptOutReasonID=1). |
| 16 | @PlayerLevelID | Int | NO | - | CODE-BACKED | Initial tier: typically 1=Bronze. |
| 17 | @RiskStatusID | Int | NO | - | CODE-BACKED | Risk classification at registration. |
| 18 | @SpreadGroupID | Int | NO | - | CODE-BACKED | Spread group for pricing. |
| 19 | @Occurred | DATETIME | NO | - | CODE-BACKED | Registration timestamp; written to Registered. |
| 20 | @AffiliateStatusID | Int | YES | NULL | OUTPUT | Output: affiliate status resolved during registration. |
| 21 | @ExternalID | DECIMAL(38,0) | YES | NULL | OUTPUT | Output: auto-generated external tracking ID (timestamp+SPID format). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerStatic | INSERT | Creates real customer row (IsReal=1) |
| @CID | Customer.CustomerMoney | INSERT | Initializes Credit=0 |
| @CID | BackOffice.Customer | INSERT | Creates BO record with DesignatedRegulationID |
| @CID | Customer.TrackingId | INSERT (conditional) | Inserts tracking IDs if provided |
| @GCID | UserApiDB_CustomerActivateApplication | EXEC (cross-DB) | Activates account in application system |
| @FunnelID | Dictionary.Funnel | READ | Resolves PlatformID |
| (error) | History.InsertLogErrorGeneral | EXEC | Logs error details on failure |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Registration API | External call | Caller | Real account registration endpoint |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.RegisterReal (procedure)
├── Customer.CustomerStatic (table) [INSERT - real account (IsReal=1)]
├── Customer.CustomerMoney (table) [INSERT - Credit=0]
├── BackOffice.Customer (table) [INSERT - with DesignatedRegulationID]
├── Customer.TrackingId (table) [INSERT - conditional: AppsFlyer, Cookie, Firebase]
├── Dictionary.Funnel (table) [READ - PlatformID]
├── Internal.GetRegionIDByIP (function) [CALL - IP geolocation]
├── UserApiDB_CustomerActivateApplication (external proc) [EXEC - activation]
└── History.InsertLogErrorGeneral (procedure) [EXEC - error logging]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | INSERT - real customer registration |
| Customer.CustomerMoney | Table | INSERT - Credit=0 |
| BackOffice.Customer | Table | INSERT - BO record with DesignatedRegulationID |
| Customer.TrackingId | Table | INSERT - attribution IDs (conditional) |
| Dictionary.Funnel | Table | READ - PlatformID lookup |
| Internal.GetRegionIDByIP | Function | CALL - IP to RegionID |
| UserApiDB_CustomerActivateApplication | External Procedure | EXEC - application activation |
| History.InsertLogErrorGeneral | Procedure | EXEC - error logging |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Registration API | External | Calls to provision real accounts |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IsReal = 1 | Application | Hard-coded: real accounts always have IsReal=1 in CustomerStatic |
| Password = '' | Application | Never stored; STS handles authentication |
| AffWiz SB disabled | Design | Registration notification to AffWiz Service Broker commented out (PART-1253, March 2023) |
| OptOutReasonID | Application | Derived from PrivacyPolicyID: 1->0 (consented), other->1 (opted out) |
| TRY/CATCH + RAISERROR | Error handling | On failure: rollback, log to InsertLogErrorGeneral, RAISERROR |

---

## 8. Sample Queries

### 8.1 Find recently registered real customers

```sql
SELECT TOP 20
    cs.CID,
    cs.GCID,
    cs.UserName,
    cs.Email,
    cs.CountryID,
    cs.Registered,
    cs.PlayerLevelID,
    cs.IsReal
FROM Customer.CustomerStatic cs WITH (NOLOCK)
WHERE cs.IsReal = 1
ORDER BY cs.Registered DESC
```

### 8.2 Check tracking IDs for a customer

```sql
SELECT
    ti.CID,
    ti.TrackingID,
    CASE ti.TrackingID
        WHEN 1 THEN 'AppsFlyer'
        WHEN 2 THEN 'UserUniqueIdentifierCookie'
        WHEN 3 THEN 'Firebase'
    END AS TrackingType,
    ti.TrackingValue
FROM Customer.TrackingId ti WITH (NOLOCK)
WHERE ti.CID = 12345
```

### 8.3 Check DesignatedRegulationID distribution for recently registered customers

```sql
SELECT
    bc.DesignatedRegulationID,
    COUNT(*) AS CustomerCount
FROM BackOffice.Customer bc WITH (NOLOCK)
JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cs.CID = bc.CID
WHERE cs.IsReal = 1
  AND cs.Registered >= DATEADD(DAY, -30, GETUTCDATE())
GROUP BY bc.DesignatedRegulationID
ORDER BY CustomerCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| PART-1253 | Jira | Disabled AffWiz SB registration notification (March 2023, Noga Rozen) |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 6.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.RegisterReal | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.RegisterReal.sql*
