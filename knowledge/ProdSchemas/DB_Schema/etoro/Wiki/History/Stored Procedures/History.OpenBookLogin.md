# History.OpenBookLogin

> Authenticates an eToro OpenBook user by username/password via the STS cross-database security service, detects first-ever logins for lead tracking, returns the customer profile result set, and records the login in History.LoginOpenBook.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Username + @Password (authentication credentials); returns CID, IsFirstLogin, GCID result set |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.OpenBookLogin` is the authentication and login-recording procedure for the eToro OpenBook platform - the social trading transparency layer that allowed users to view and analyze other traders' public portfolios. When an OpenBook user provides credentials, this procedure validates them through the external STS (Security Token Service) database, retrieves the customer profile, determines if this is the user's absolute first login (triggering the marketing lead pipeline if so), and logs the session to `History.LoginOpenBook`.

Unlike `History.LogIn` (which manages active sessions in `Customer.Login`), OpenBookLogin does not create an active session record. It only performs authentication validation and login auditing. The OpenBook platform had a separate session model. The procedure returns a result set to the caller with the customer profile and first-login flag, which the application uses to personalize the post-login experience.

Data flow: (1) STS.F_GetCustomerGcidByUsername resolves @Username to GCID; (2) dbo.STS_P_ValidatePasswordByGcid validates the password - if valid (@B=1), customer data is fetched from Customer.Customer; (3) if customer not found (@@ROWCOUNT != 1), RETURN -1 immediately; (4) first-login check: NOT EXISTS in History.Login AND NOT EXISTS in History.LoginOpenBook; (5) if LeadMode=2 AND first login AND not test user: send lead XML via Service Broker to svcLead; (6) SELECT result set (CID, PrivacyPolicyID, UserName, IsFirstLogin, AffiliateID, GCID); (7) INSERT into History.LoginOpenBook; (8) RETURN 0.

---

## 2. Business Logic

### 2.1 Cross-Database STS Password Validation

**What**: Authentication is delegated to the STS (Security Token Service) cross-database service, not handled in SQL code directly.

**Columns/Parameters Involved**: `@Username`, `@Password`, `@GCID`, `@B`

**Rules**:
- Step 1: `STS.F_GetCustomerGcidByUsername(@Username)` - resolves username string to the GCID (global customer ID) in the STS database
- Step 2: `dbo.STS_P_ValidatePasswordByGcid(@GCID, @Password, @B OUTPUT)` - @B = 1 if password is valid, else 0
- If @B = 1: SELECT customer profile WHERE GCID = @GCID (password correct, get full profile)
- If @B != 1: SELECT WHERE 1=0 (empty result set), causing @@ROWCOUNT = 0 and RETURN -1 on the next check
- This dual-branch SELECT-WHERE-1=0 pattern ensures the code path is consistent while cleanly returning -1 for bad credentials without RAISERROR

**Diagram**:
```
@Username + @Password
     |
     v
STS.F_GetCustomerGcidByUsername(@Username) -> @GCID
     |
     v
STS_P_ValidatePasswordByGcid(@GCID, @Password) -> @B
     |
     +-- @B = 1 (valid) --> SELECT customer data WHERE GCID=@GCID
     |
     +-- @B != 1 (invalid) --> SELECT WHERE 1=0 (no rows)
                                    |
                                    v
                              @@ROWCOUNT != 1 -> RETURN -1
```

### 2.2 First-Ever Login Detection and Lead Tracking

**What**: Same lead-tracking logic as History.LogIn - detects if this is the customer's absolute first login across all platforms and sends their profile to the marketing pipeline.

**Columns/Parameters Involved**: `@IsFirstLogin`, `@LeadMode`, `@CID`, `@PlayerLevelID`

**Rules**:
- @IsFirstLogin = 1 when: NOT EXISTS in History.Login WHERE CID=@CID AND NOT EXISTS in History.LoginOpenBook WHERE CID=@CID
- Note: Unlike History.LogIn which checks History.LoginArch, this procedure checks History.Login directly (slightly different first-login definition)
- LeadMode read from Maintenance.Feature WHERE FeatureID=3; only value=2 triggers lead sending
- Lead XML sent via SQL Service Broker dialog to svcLead: OriginalCID, ProviderID, OriginalProviderID, RealProviderID, IsReal, CountryID, SerialID, SubSerialID, DownloadID, BannerID, DownloadCounter, PlayerLevelID, FunnelID (null-coalesced to 0), LabelID (null-coalesced to 0), Occurred (GETDATE)
- Excluded: PlayerLevelID=4 (test users)
- IsFirstLogin is included in the returned result set for the application to use

### 2.3 Result Set Returned

**What**: After successful authentication, a single-row result set is returned to the caller with the customer profile and authentication metadata.

**Rules**:
- Always returned (even before the INSERT into LoginOpenBook)
- Columns: CID, PrivacyPolicyID, UserName (the stored username, not necessarily exactly matching @Username due to normalization), IsFirstLogin (BIT 0/1), AffiliateID (= SerialID from Customer.Customer), GCID
- The application uses this to establish the session context, display the user's name, and conditionally show first-login onboarding

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Username | VARCHAR(20) | NO | - | CODE-BACKED | OpenBook username submitted by the user. Passed to STS.F_GetCustomerGcidByUsername to resolve to GCID. Also re-read from Customer.Customer.UserName after authentication (may differ from input if stored username has different case or normalization). |
| 2 | @Password | VARCHAR(20) | NO | - | CODE-BACKED | Password submitted by the user. Passed to dbo.STS_P_ValidatePasswordByGcid for validation. Never stored or logged within this procedure. |
| 3 | @ClientVersion | VARCHAR(20) | YES | NULL | CODE-BACKED | Client application version string. Stored in History.LoginOpenBook.ClientVersion on successful login. Optional - NULL is accepted (older clients may not send this). |
| 4 | @ClientTypeID | TINYINT | YES | 0 | CODE-BACKED | Client platform type identifier. Default 0. Stored in History.LoginOpenBook.ClientTypeID to distinguish web vs. mobile vs. other OpenBook client types. |

**Result Set Columns Returned:**

| # | Column | Description |
|---|--------|-------------|
| R1 | CID | Customer ID from Customer.Customer. Used by the application to identify the session owner. |
| R2 | PrivacyPolicyID | Privacy policy version the customer last accepted. Used by the application to prompt re-acceptance if policy has been updated. |
| R3 | UserName | Stored username from Customer.Customer (authoritative, may differ slightly from @Username input). |
| R4 | IsFirstLogin | 1 = this is the customer's first-ever login on any eToro platform (History.Login + History.LoginOpenBook both empty). 0 = returning user. Used by application for first-login onboarding flows. |
| R5 | AffiliateID | SerialID from Customer.Customer - the affiliate/tracking serial number associated with this customer's registration. |
| R6 | GCID | Global Customer ID from the STS system. Cross-system identifier linking this customer to the STS security service. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Username | STS.F_GetCustomerGcidByUsername | Function call (cross-DB) | Resolves username to GCID in the STS security database |
| @GCID, @Password | dbo.STS_P_ValidatePasswordByGcid | Procedure call (cross-DB) | Validates password against the STS security service |
| @GCID | Customer.Customer | Lookup | Reads full customer profile (CID, PrivacyPolicyID, UserName, PlayerLevelID, OriginalCID, ProviderID, IsReal, IP, SerialID, etc.) after successful authentication |
| @CID | History.Login | EXISTS check | Checks if any prior login record exists across the main login history |
| @CID | History.LoginOpenBook | EXISTS check + WRITER (INSERT) | Checks prior OpenBook logins for first-login detection; then INSERTs new login record |
| FeatureID=3 | Maintenance.Feature | Lookup | Reads LeadMode setting for first-login lead tracking |
| - | Internal.GetCountryIDByIP | Function call | Resolves Customer.Customer.IP to CountryID for the lead XML payload |
| - | Internal.CallRaiseError | Procedure call | Called in CATCH block to handle and re-raise exceptions |

### 5.2 Referenced By (other objects point to this)

No callers found in SSDT repository. Called externally by the OpenBook platform application. History.LoginOpenBook.md documents this procedure as one of the primary writers to that table.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.OpenBookLogin (procedure)
+-- Customer.Customer (table)
+-- History.Login (table)
+-- History.LoginOpenBook (table)
+-- Maintenance.Feature (table)
+-- STS.F_GetCustomerGcidByUsername (function, cross-DB)
+-- dbo.STS_P_ValidatePasswordByGcid (procedure, cross-DB)
+-- Internal.GetCountryIDByIP (function)
+-- Internal.CallRaiseError (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | SELECT customer profile (CID, PrivacyPolicyID, PlayerLevelID, OriginalCID, ProviderID, IsReal, IP, SerialID, etc.) WHERE GCID=@GCID |
| History.Login | Table | EXISTS check to determine first-ever login status |
| History.LoginOpenBook | Table | EXISTS check for first-login; INSERT to record this OpenBook login event |
| Maintenance.Feature | Table | SELECT Value WHERE FeatureID=3 to read LeadMode |
| STS.F_GetCustomerGcidByUsername | Function (cross-DB) | Resolves @Username to GCID |
| dbo.STS_P_ValidatePasswordByGcid | Procedure (cross-DB) | Validates @Password for the given GCID; OUTPUT @B = 1/0 |
| Internal.GetCountryIDByIP | Function | Resolves IP to CountryID for lead XML |
| Internal.CallRaiseError | Procedure | CATCH block error handler and re-raiser |

### 6.2 Objects That Depend On This

No dependents found in SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| READ UNCOMMITTED isolation | Session | SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED - all reads in this procedure are dirty reads; acceptable for login auditing where eventual consistency is sufficient |
| RETURN -1 on auth failure | Business rule | If @B != 1 (invalid password) or GCID not found, @@ROWCOUNT != 1, and the procedure returns -1 before any writes occur |

---

## 8. Sample Queries

### 8.1 Check all OpenBook logins for a customer

```sql
SELECT LoginID, CID, LoggedIn, IP, ClientVersion, ClientTypeID
FROM History.LoginOpenBook WITH (NOLOCK)
WHERE CID = 12345678
ORDER BY LoggedIn DESC
```

### 8.2 Find customers whose first-ever login was via OpenBook (not History.Login)

```sql
SELECT ob.CID, MIN(ob.LoggedIn) AS FirstOpenBookLogin
FROM History.LoginOpenBook ob WITH (NOLOCK)
WHERE NOT EXISTS (
    SELECT 1 FROM History.Login hl WITH (NOLOCK) WHERE hl.CID = ob.CID
)
GROUP BY ob.CID
ORDER BY FirstOpenBookLogin DESC
```

### 8.3 Count OpenBook logins by client type

```sql
SELECT ClientTypeID, COUNT(*) AS LoginCount
FROM History.LoginOpenBook WITH (NOLOCK)
GROUP BY ClientTypeID
ORDER BY LoginCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 8.5/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (LoginOpenBook table doc) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.OpenBookLogin | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.OpenBookLogin.sql*
