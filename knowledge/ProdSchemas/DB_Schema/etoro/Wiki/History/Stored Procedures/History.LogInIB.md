# History.LogInIB

> Introducing Broker (IB) combined register-and-login procedure - authenticates existing customers or auto-registers new ones (using a pre-filled RegistrationRequest or minimal defaults) and then logs them in via History.LogIn. The IB path allows third-party broker partners to provision and authenticate eToro accounts.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PassedProviderID + @UserName - identifies the customer within the IB's provider space |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.LogInIB` is the authentication entry point for **Introducing Broker (IB)** integrations - partnerships where third-party financial brokers or affiliates bring customers to eToro and authenticate them on eToro's platform using the broker's own credentials. The procedure handles three scenarios in a single call:

1. **Existing customer, valid credentials**: Look up CID by ProviderID+UserName, update password if it changed at the provider level, then call History.LogIn to create the session.
2. **New customer with RegistrationRequest**: The broker pre-registered customer data via `Customer.RegistrationRequest`. Read all profile fields and call `Customer.RegisterReal` to create the account, then call History.LogIn.
3. **New customer with no RegistrationRequest**: Register with minimal defaults (LanguageID=English, CountryID=USA, CurrencyID=USD) via `Customer.RegisterReal`, then call History.LogIn.

Error scenarios: blocked user (LoginResult=3), provider/request mismatch (LoginResult=1), duplicate username (LoginResult=2).

The procedure wraps everything in a single transaction (BEGIN TRANSACTION at start, COMMIT at success, ROLLBACK on blocked/mismatch errors).

History note: Case 28292 - Varchar to NVarchar migration, Geri Reshef, 2015-07-27.

---

## 2. Business Logic

### 2.1 Existing Customer Login Path

**What**: If the customer already exists for this ProviderID+UserName (and is not blocked), authenticate and create a session.

**Columns/Parameters Involved**: `@PassedProviderID`, `@UserName`, `@Password`, `Customer.Customer`, `History.LogIn`

**Rules**:
- Check: `SELECT * FROM Customer.Customer WHERE ProviderID=@PassedProviderID AND UserName=@UserName AND PlayerStatusID != 2`
- Reads CID, current Credit*100 (in cents), and current Password
- Password sync: if `@Password != @CurrentPassword`, UPDATE Customer.Customer SET Password=@Password (provider's password takes precedence)
- EXEC History.LogIn @CID, GameTypeID=0, @LanguageID, @ClientVersion, @IP, @MACID -> outputs @ActionID, @NumberOfConnections, @CustomerSessionID
- If History.LogIn returns non-zero, propagate the error

### 2.2 Blocked Customer

**What**: Customer exists but has PlayerStatusID=2 (blocked) - login is rejected.

**Rules**:
- Detected in the ELSE branch: `EXISTS (... WHERE ProviderID=@PassedProviderID AND UserName=@UserName)` without the `!= 2` filter
- ROLLBACK TRANSACTION, SET @LoginResult=3, RETURN 60019

### 2.3 New Customer - RegistrationRequest Path

**What**: Customer does not exist; a pre-filled registration request exists for the GUID.

**Columns/Parameters Involved**: `@RegisterRequestID`, `Customer.RegistrationRequest`, `Customer.RegisterReal`

**Rules**:
- Normalize GUID: `Internal.NormalizeString(@RegisterRequestID)` cast to UNIQUEIDENTIFIER
- Check: `EXISTS (... FROM Customer.RegistrationRequest WHERE RegistrationRequestID=@RegisterRequestGUID)`
- Read all profile fields: ProviderID, Email, CountryID, Gender, CurrencyID, TradeLevelID, LabelID, FunnelID, Name, Phone, Address, City, StateID, Zip, DOB parts, IP, SerialID, ReferralID, SubSerialID, DownloadID, BannerID, ClientVersion, PersonID, DownloadCounter
- Provider validation: `IF @PassedProviderID != @ProviderID` -> ROLLBACK, SET @LoginResult=1, RETURN 60020
- StateID resolution: if StateID IS NOT NULL, lookup Name from Dictionary.State (to pass state name to RegisterReal)
- EXEC Customer.RegisterReal (full profile data) -> outputs @CID
- Then EXEC History.LogIn -> creates session

### 2.4 New Customer - No RegistrationRequest (Minimal Defaults)

**What**: Customer does not exist and no RegistrationRequest found. Register with minimal required defaults.

**Columns/Parameters Involved**: `Customer.RegisterReal`, default values

**Rules**:
- EXEC Customer.RegisterReal with hardcoded defaults:
  - LanguageID = 1 (English)
  - CountryID = 219 (USA)
  - TradeLevelID = 0 (unknown)
  - LabelID = 0 (Default)
  - FunnelID = NULL (unknown)
  - Gender = 0 (unknown)
  - CurrencyID = 1 (USD)
  - All personal info fields (Name, Phone, Address, etc.) = NULL
  - RegIP = @IP, ClientVersion = @ClientVersion
- Then EXEC History.LogIn -> creates session

### 2.5 @LoginResult Return Codes

**What**: @LoginResult (OUTPUT) encodes the success or failure reason for the caller.

**Rules**:
```
0 = Success (default; exception already raised on failure, so this may not be meaningful on error)
1 = PassedProviderID does not match stored provider in RegistrationRequest
2 = Duplicate username for this provider
3 = User is blocked (PlayerStatusID=2) or not found
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RegisterRequestID | CHAR(36) | NO | - | CODE-BACKED | GUID string of the pre-filled registration request. Normalized via Internal.NormalizeString and cast to UNIQUEIDENTIFIER. Used to look up Customer.RegistrationRequest for new customer registration. |
| 2 | @CID | INT | OUT | - | CODE-BACKED | Customer ID - OUTPUT parameter. For existing customers, read from Customer.Customer. For new customers, output from Customer.RegisterReal. |
| 3 | @PassedProviderID | INT | NO | - | CODE-BACKED | The IB partner's provider ID as passed by the caller. Must match ProviderID in Customer.RegistrationRequest (if exists) or Customer.Customer. |
| 4 | @PassedOriginalProviderID | INT | NO | - | CODE-BACKED | Original source provider ID. Passed to Customer.RegisterReal as OriginalProviderID. Used when the account originated from a different provider than the current IB. |
| 5 | @PassedOrigCID | INT | NO | - | CODE-BACKED | Original customer ID from the source provider. Passed to Customer.RegisterReal as OriginalCID for cross-provider account linking. |
| 6 | @UserName | VARCHAR(20) | NO | - | CODE-BACKED | Login username. Must be unique per ProviderID. Case 28292: converted from VARCHAR to NVarchar at schema level (2015-07-27). |
| 7 | @Password | VARCHAR(20) | NO | - | CODE-BACKED | Login password. If customer exists and @Password != stored password, stored password is updated to match (provider-level password sync). |
| 8 | @Credit | INT | NO | - | CODE-BACKED | Initial credit allocation in CENTS. Passed to registration path (declared but the DDL comment notes "in cents"). |
| 9 | @LanguageID | INT | NO | - | CODE-BACKED | Language preference ID. Passed to History.LogIn (for session) and Customer.RegisterReal (for profile). |
| 10 | @ClientVersion | VARCHAR(20) | NO | - | CODE-BACKED | Client application version (W=Web, M=Mobile, etc.). Passed to History.LogIn and Customer.RegisterReal. |
| 11 | @IP | VARCHAR(15) | NO | - | CODE-BACKED | Client IP address. Passed to History.LogIn for session logging and used as RegIP for new customer registration. |
| 12 | @MACID | CHAR(17) | NO | - | CODE-BACKED | Client MAC address. Passed to History.LogIn. |
| 13 | @ActionID | BIGINT | OUT | - | CODE-BACKED | Login action ID - OUTPUT from History.LogIn. Identifies the login event in the action log. |
| 14 | @NumberOfConnections | INT | OUT | - | CODE-BACKED | Number of active connections for this customer - OUTPUT from History.LogIn. |
| 15 | @CustomerSessionID | CHAR(36) | OUT | - | CODE-BACKED | Session GUID - OUTPUT from History.LogIn. The authenticated session token used for subsequent API calls. |
| 16 | @LoginResult | INT | OUT | - | CODE-BACKED | Outcome code: 0=success (default), 1=provider mismatch, 2=duplicate username, 3=blocked/not found. |
| 17 | @LobbyID | INT | NO | - | CODE-BACKED | Lobby/game server ID. Passed to History.LogIn. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PassedProviderID, @UserName | Customer.Customer | READ + conditional UPDATE | Checks customer existence; updates Password if changed at provider |
| @RegisterRequestID | Customer.RegistrationRequest | READ | Reads pre-filled registration profile for new customer auto-registration |
| @StateID | Dictionary.State | READ | Resolves StateID to State Name for Customer.RegisterReal |
| @CID (new customers) | Customer.RegisterReal | Calls (EXEC) | Registers new IB customers with full or minimal profile data |
| @CID (all paths) | History.LogIn | Calls (EXEC) | Creates authenticated session after successful authentication or registration |

### 5.2 Referenced By (other objects point to this)

No callers found in SSDT repository. Called by IB (Introducing Broker) application layer.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.LogInIB (procedure)
+-- Customer.Customer (table, cross-schema)
+-- Customer.RegistrationRequest (table, cross-schema)
+-- Internal.NormalizeString (function, cross-schema)
+-- Dictionary.State (table)
+-- Customer.RegisterReal (procedure, cross-schema)
+-- History.LogIn (procedure)
      +-- Customer.Login (table)
      +-- History.LogOutByLoginID (procedure)
      +-- Customer.SendEvent (procedure)
      ... (see History.LogIn documentation)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table (cross-schema) | Existence check, CID lookup, Password sync |
| Customer.RegistrationRequest | Table (cross-schema) | Pre-filled registration profile for new customers |
| Internal.NormalizeString | Function (cross-schema) | GUID normalization: `CAST(Internal.NormalizeString(@RegisterRequestID) AS UNIQUEIDENTIFIER)` |
| Dictionary.State | Table | StateID -> State Name resolution for Customer.RegisterReal |
| Customer.RegisterReal | Procedure (cross-schema) | New customer account creation (with full or minimal profile) |
| History.LogIn | Procedure | Session creation for all successful authentication paths |

### 6.2 Objects That Depend On This

No dependents found in SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BEGIN/COMMIT TRANSACTION | ACID | Entire procedure wrapped in a transaction; ROLLBACK on blocked/mismatch errors |
| Provider/Username uniqueness | Business rule | Duplicate username for same ProviderID returns 60018 (LoginResult=2) |
| Provider mismatch guard | Business rule | If RegistrationRequest.ProviderID != @PassedProviderID: ROLLBACK, LoginResult=1, RETURN 60020 |
| Blocked user guard | Security | PlayerStatusID=2 -> ROLLBACK, LoginResult=3, RETURN 60019; no session created |
| Password sync | IB contract | If provider password differs from stored, eToro updates to match: `UPDATE Customer.Customer SET Password=@Password` |
| Minimal defaults | Fallback | No RegistrationRequest -> CountryID=219 (USA), CurrencyID=1 (USD), LanguageID=1 (English) for new customer |

---

## 8. Sample Queries

### 8.1 Typical IB login flow (for reference)

```sql
DECLARE @CID INT, @ActionID BIGINT, @Connections INT, @SessionID CHAR(36), @LoginResult INT

EXEC History.LogInIB
    @RegisterRequestID     = '550E8400-E29B-41D4-A716-446655440000',
    @CID                   = @CID OUTPUT,
    @PassedProviderID      = 15,
    @PassedOriginalProviderID = 0,
    @PassedOrigCID         = 0,
    @UserName              = 'ibcustomer01',
    @Password              = 'pass123',
    @Credit                = 0,
    @LanguageID            = 1,
    @ClientVersion         = 'W',
    @IP                    = '192.168.1.1',
    @MACID                 = '00:00:00:00:00:00',
    @ActionID              = @ActionID OUTPUT,
    @NumberOfConnections   = @Connections OUTPUT,
    @CustomerSessionID     = @SessionID OUTPUT,
    @LoginResult           = @LoginResult OUTPUT,
    @LobbyID               = 0

SELECT @CID AS CID, @SessionID AS SessionID, @LoginResult AS LoginResult
```

### 8.2 Check pending IB registration requests

```sql
SELECT TOP 10 RegistrationRequestID, ProviderID, UserName, Email, CountryID
FROM Customer.RegistrationRequest WITH (NOLOCK)
ORDER BY CreatedDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.LogInIB | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.LogInIB.sql*
