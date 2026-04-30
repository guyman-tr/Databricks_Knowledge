# Customer.Ins_HistoryLoginOpenBook

> Records an OpenBook (social feed) login event to History.LoginOpenBook, detects the customer's first-ever login, conditionally dispatches a lead event via SQL Service Broker, and returns session context data to the caller.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID -> INSERT into History.LoginOpenBook; SELECT session context |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.Ins_HistoryLoginOpenBook is the login handler for customers accessing the OpenBook (eToro's public social trading feed). It performs three actions in a single atomic transaction: it checks whether this is the customer's first-ever login to any eToro product (OpenBook or platform), sends a CRM "lead" event via SQL Service Broker if it is (and if LeadMode=2 is configured), inserts a row into History.LoginOpenBook recording the login, and returns session context data (CID, PrivacyPolicyID, UserName, IsFirstLogin, AffiliateID, GCID) to the calling application.

This procedure exists because OpenBook had its own login flow separate from the main eToro platform (History.Login). The "lead" concept refers to CRM affiliate tracking: when a customer logs in for the first time (no prior login in either History.Login or History.LoginOpenBook), the system notifies the CRM/affiliate system via Service Broker so the affiliate who referred the customer can be credited.

Data flows: Customer.Customer provides full customer context. Maintenance.Feature.FeatureID=3 is the LeadMode toggle (1=OnRegister, 2=OnFirstLogin). History.Login and History.LoginOpenBook are checked for first-login detection. On first login with LeadMode=2, a LEAD XML message is sent via the Service Broker `svcLead` service. Finally, History.LoginOpenBook receives the INSERT. The procedure uses TRANSACTION ISOLATION LEVEL READ UNCOMMITTED throughout.

**Note**: @FunnelID and @LabelID are declared but never assigned from the Customer query - they are always 0 in the XML lead payload. This appears to be a historical incomplete implementation (FunnelID/LabelID fields were intended but not wired up in the SELECT from Customer.Customer).

---

## 2. Business Logic

### 2.1 First Login Detection

**What**: Determines whether this is the customer's first-ever login across both OpenBook and the main platform, used to trigger CRM lead attribution.

**Columns/Parameters Involved**: `@IsFirstLogin`, `History.Login.CID`, `History.LoginOpenBook.CID`

**Rules**:
- @IsFirstLogin = 1 ONLY IF: no rows in History.Login WHERE CID=@CID AND no rows in History.LoginOpenBook WHERE CID=@CID
- @IsFirstLogin = 0 if the customer has ANY prior login record in either table
- Both existence checks use WITH (NOLOCK) for performance
- The check uses dual-table logic to unify first-login detection across the platform's two login surfaces

**Diagram**:
```
Customer logs in to OpenBook
         |
History.Login exists for CID?  -->  YES --> IsFirstLogin = 0
         |
         NO
         |
History.LoginOpenBook exists?  -->  YES --> IsFirstLogin = 0
         |
         NO
         |
IsFirstLogin = 1 (first login ever)
```

### 2.2 Lead Event via Service Broker

**What**: On first login with LeadMode=2, a LEAD XML message is sent via SQL Service Broker to notify the CRM/affiliate system of the new lead.

**Columns/Parameters Involved**: `@LeadMode` (from Maintenance.Feature), `@IsFirstLogin`, `@PlayerLevelID`, `@XMLData`

**Rules**:
- Condition: @LeadMode = 2 AND @IsFirstLogin = 1 AND @PlayerLevelID <> 4 (not a test user)
- LeadMode controlled by Maintenance.Feature WHERE FeatureID=3: 1=OnRegister (leads sent at registration), 2=OnFirstLogin (leads sent at first login)
- PlayerLevelID = 4 = test account - test accounts are never sent as leads
- The XML payload includes OriginalCID, ProviderID, OriginalProviderID, RealProviderID, IsReal, CountryID, SerialID (affiliate), SubSerialID, DownloadID, BannerID, DownloadCounter, PlayerLevelID, FunnelID (always 0 - not wired), LabelID (always 0 - not wired), Occurred
- Service Broker dialog: FROM SERVICE svcInitiator, TO SERVICE 'svcLead', 'CURRENT DATABASE'
- @CountryID is derived from Internal.GetCountryIDByIP(@IP) - the customer's stored IP address, not @ClientIP

**Diagram**:
```
LeadMode (Maintenance.Feature.FeatureID=3)
  = 1 (OnRegister)  -> no action here (leads sent at registration)
  = 2 (OnFirstLogin) AND IsFirstLogin=1 AND PlayerLevelID<>4
                     -> Build LEAD XML -> Service Broker svcLead
                        (affiliate CRM notified of first login)
```

### 2.3 IP Hotfix Logic

**What**: The login IP recorded in History.LoginOpenBook prefers the @ClientIP parameter over the stored IP from Customer.Customer.

**Columns/Parameters Involved**: `@ClientIP`, `@IP` (from Customer.Customer), `History.LoginOpenBook.IP`

**Rules**:
- `ISNULL(@ClientIP, @IP)`: if @ClientIP is provided by the caller, use it; otherwise fall back to the stored IP from Customer.Customer
- Comment "hotfix Yitzchak" - this was added as a fix to address the case where the caller knows the current session IP but the stored Customer.IP is stale (from a prior session)
- The @ClientIP was added on 28/12/2014 per the SP header comment

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | VERIFIED | Internal eToro Customer ID of the customer logging in. Used to look up all customer context from Customer.Customer and for the History.LoginOpenBook INSERT. Returns -1 if not found. |
| 2 | @ClientVersion | varchar(20) | YES | NULL | CODE-BACKED | Version string of the client application (e.g., browser version, mobile app version). Stored in History.LoginOpenBook.ClientVersion. Optional - NULL if the client doesn't send it. |
| 3 | @ClientType | varchar(50) | YES | '' | CODE-BACKED | Client platform type (e.g., "Web", "Mobile", "iOS"). Stored in History.LoginOpenBook.ClientType. Defaults to empty string. Used for platform-specific analytics. |
| 4 | @UserAgent | varchar(255) | YES | '' | CODE-BACKED | HTTP User-Agent string from the client browser or app. Stored in History.LoginOpenBook.UserAgent. Defaults to empty string. Used for device and browser analytics. |
| 5 | @ClientIP | varchar(15) | YES | NULL | VERIFIED | IP address of the client at the time of this login. If provided, overrides the stored IP (Customer.Customer.IP) for the History.LoginOpenBook record. Hotfix added 28/12/2014 to capture the current session IP when the stored IP is stale. |

**Output (SELECT result set)**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Internal Customer ID - the @CID parameter echoed back for confirmation. |
| 2 | PrivacyPolicyID | int | YES | - | VERIFIED | Privacy policy version the customer has accepted. The calling application uses this to determine if the customer needs to re-accept an updated policy before proceeding. |
| 3 | UserName | varchar | NO | - | VERIFIED | Customer's public username - returned for session context. |
| 4 | IsFirstLogin | bit | NO | - | VERIFIED | 1 = this is the customer's first-ever login across all eToro products; 0 = returning customer. The calling application uses this to show a welcome experience and for analytics. |
| 5 | AffiliateID | int | YES | - | CODE-BACKED | Maps to Customer.CustomerStatic.SerialID - the affiliate/referral source that originally referred this customer. Returned so the application can perform affiliate-specific actions on first login. |
| 6 | GCID | int | YES | - | VERIFIED | Group Customer ID - the cross-product identifier. Returned for session context and cross-system identity correlation. |

**Return codes**:
- 0: Success
- -1: Customer not found (@@ROWCOUNT <> 1 after the Customer.Customer SELECT)
- Other: SQL error code from Internal.CallRaiseError (in CATCH block)

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Reader (SELECT) | Fetches full customer context for session data and lead payload |
| FeatureID=3 | Maintenance.Feature | Reader (SELECT) | Reads LeadMode configuration (1=OnRegister, 2=OnFirstLogin) |
| @CID | History.Login | Reader (EXISTS) | First-login detection: checks if any prior platform login exists |
| @CID | History.LoginOpenBook | Reader (EXISTS) + Writer (INSERT) | First-login detection and new login record insertion |
| @IP | Internal.GetCountryIDByIP | Function call | Resolves stored IP to a CountryID for the lead XML payload |
| svcLead | Service Broker | Message send | Sends LEAD XML to CRM/affiliate system on first login |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | EXECUTE permission | Caller | Called by the OpenBook application login flow |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.Ins_HistoryLoginOpenBook (procedure)
├── Customer.Customer (view)
│     ├── Customer.CustomerStatic (table)
│     └── Customer.CustomerMoney (table)
├── Maintenance.Feature (table)
├── History.Login (table)
├── History.LoginOpenBook (table)
└── Internal.GetCountryIDByIP (function)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | SELECT customer context: CID, PrivacyPolicyID, UserName, PlayerLevelID, IP, GCID, affiliate/provider fields |
| Maintenance.Feature | Table | SELECT LeadMode value (FeatureID=3): 1=OnRegister, 2=OnFirstLogin |
| History.Login | Table | EXISTS check for first-login detection |
| History.LoginOpenBook | Table | EXISTS check for first-login detection; INSERT for new login record |
| Internal.GetCountryIDByIP | Function | Called with stored IP to resolve CountryID for lead XML payload |

### 6.2 Objects That Depend On This

No callers found in the codebase. Called externally by the OpenBook application.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Note: uses TRANSACTION ISOLATION LEVEL READ UNCOMMITTED for all reads. Error handling via TRY/CATCH with Internal.CallRaiseError re-raise.

---

## 8. Sample Queries

### 8.1 Log an OpenBook login with client metadata
```sql
EXEC Customer.Ins_HistoryLoginOpenBook
    @CID = 12345678,
    @ClientVersion = '1.2.3',
    @ClientType = 'Web',
    @UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) ...',
    @ClientIP = '1.2.3.4';
```

### 8.2 Minimal call (all optional params use defaults)
```sql
EXEC Customer.Ins_HistoryLoginOpenBook @CID = 12345678;
```

### 8.3 Check recent OpenBook logins for a customer
```sql
SELECT TOP 10 CID, LoggedIn, IP, ClientVersion, ClientType, UserAgent
FROM History.LoginOpenBook WITH (NOLOCK)
WHERE CID = 12345678
ORDER BY LoggedIn DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.Ins_HistoryLoginOpenBook | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.Ins_HistoryLoginOpenBook.sql*
