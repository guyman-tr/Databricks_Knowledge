# Customer.DynamicsInsert

> Sends a comprehensive customer record as an XML message to Microsoft Dynamics CRM via SQL Server Service Broker, resolving both the real and demo CIDs for the customer and including full profile, compliance, and affiliate data.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer to sync to Dynamics) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.DynamicsInsert is the CRM synchronization procedure: it sends a full customer profile snapshot to Microsoft Dynamics CRM whenever a customer's data changes. It reads from Customer.Customer, BackOffice.Customer, and BackOffice.Affiliate, builds an XML document with all key customer attributes, and enqueues the message via SQL Server Service Broker (to service 'svcDynamics') for asynchronous CRM processing.

The procedure exists as the central CRM sync point. Rather than each service directly calling Dynamics, all CRM updates flow through this single procedure with a standardized XML format. Created in 2012 (Yitzchak Wahnon) and progressively enhanced with LanguageID, CommunicationLanguageID, and RiskStatusID fields.

A key complexity is the cross-environment ID resolution: eToro runs both a "real" (production trading) and "demo" (paper trading) environment. Dynamics CRM needs to know both CIDs for each customer so it can link real and demo records. The procedure detects which environment it's running in (via Maintenance.Feature FeatureID=22), then uses linked-server synonyms (RealCustomers, DemoCustomers) to look up the corresponding other-environment CID via GCID.

The optional @Action parameter allows callers to inject a custom action verb (e.g., "Register", "Update") into the XML, which tells Dynamics what type of event triggered the sync.

---

## 2. Business Logic

### 2.1 Environment Detection and Cross-Environment CID Resolution

**What**: Determines which environment is running and resolves both CID_Real and CID_Demo for the XML payload.

**Columns/Parameters Involved**: `@IsRealDB`, `@RealCID`, `@DemoCID`, `@GCID`

**Rules**:
- Maintenance.Feature FeatureID=22: 1=real environment, other=demo environment
- If real environment: @RealCID = @CID, then lookup @DemoCID by GCID from DemoCustomers linked server
- If demo environment: @DemoCID = @CID, then lookup @RealCID by GCID from RealCustomers linked server
- GCID is the cross-environment link key - both environments share the same GCID for the same physical customer
- CID_Real and CID_Demo are both sent in the XML so Dynamics can link the accounts

**Diagram**:
```
IsRealDB=1 (real environment):
  CID -> @RealCID
  GCID lookup on DemoCustomers -> @DemoCID

IsRealDB=0 (demo environment):
  CID -> @DemoCID
  GCID lookup on RealCustomers -> @RealCID

Both paths produce:
  XML[CID_Real] = @RealCID
  XML[CID_Demo] = @DemoCID
```

### 2.2 OriginalProviderID/OriginalCID Normalization

**What**: Applies business rules to clean OriginalProviderID and OriginalCID before sending to Dynamics.

**Columns/Parameters Involved**: `OriginalProviderID`, `OriginalCID`

**Rules**:
- OriginalProviderID: if > 1, use as-is; if OriginalCID = @RealCID (self-referral), set to 1; if OriginalCID = 0 (no referral), set to 1; if Registered < 2007-10-02 (before affiliate program), set to 1; else use OriginalProviderID
- OriginalCID: if 0 (no referral recorded), replace with @RealCID (self-referral sentinel)

### 2.3 Optional Action Injection

**What**: Allows callers to include an action type in the XML, controlling Dynamics processing.

**Columns/Parameters Involved**: `@Action`

**Rules**:
- If @Action IS NULL: XML is sent without an Action element (default update)
- If @Action IS NOT NULL: XML is post-processed via string replacement to inject `<Action>{@Action}</Action>` as the first child of `<Customer>`
- Examples: @Action = 'Register' for new customer, @Action = 'Update' for profile change

### 2.4 Service Broker Message Delivery

**What**: The XML is delivered asynchronously via SQL Server Service Broker.

**Rules**:
- BEGIN DIALOG CONVERSATION from svcInitiator to 'svcDynamics' ON CONTRACT ctrAnyXMLData
- SEND ON CONVERSATION with MESSAGE TYPE mtAnyXMLData
- Asynchronous: the procedure returns immediately after enqueuing; actual Dynamics update happens when the queue is processed
- No CLOSE CONVERSATION in this procedure - the dialog remains open (single-use pattern typical for fire-and-forget broker messaging)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID - the customer to sync to Dynamics. Used to query Customer.Customer and BackOffice tables, and to determine which environment's CID this is (real or demo). |
| 2 | @Action | varchar(10) | YES | NULL | CODE-BACKED | Optional action type to inject into the CRM XML (e.g., 'Register', 'Update'). NULL = no action element, default update. Injected as `<Action>` child of `<Customer>` via string replacement. |

**XML payload fields sent to Dynamics (output):**

The procedure builds and sends an XML document with the following elements:

| XML Field | Source | Business Meaning |
|-----------|--------|-----------------|
| CID_Real | @RealCID | Customer's real trading account CID |
| CID_Demo | @DemoCID | Customer's demo/paper trading account CID |
| FirstName, LastName | Customer.Customer | Customer name |
| Email, UserName | Customer.Customer | Contact and login identity |
| Phone, Mobile, Fax | Customer.Customer | Contact details |
| OriginalProviderID | Derived (normalized) | Affiliate/provider who acquired the customer |
| OriginalCID | Derived (normalized) | Self-referral when 0, original referring customer otherwise |
| CityID, Address, ZIP | Customer.Customer | Physical address |
| Gender, BirthDate | Customer.Customer | Demographics |
| AffiliateID | Customer.Customer.SerialID | Affiliate channel ID |
| ProviderID | Customer.Customer | Customer's current provider |
| CountryID, StateID | Customer.Customer | Geographic registration |
| CountryIDByIP | Internal.GetCountryIDByIP(IP) | Geo-IP derived country |
| LanguageID, CommunicationLanguageID | Customer.Customer | Language preferences |
| CurrencyID | Customer.Customer | Account currency |
| PlayerStatusID | Customer.Customer | Customer status |
| IsReal | @IsRealDB | 1=real environment, 0=demo |
| BannerID | Customer.Customer | Marketing banner that acquired customer |
| AccountExpirationDate | Hardcoded '3000-01-01' | Always far-future (accounts don't expire) |
| Credit | Customer.Customer | Current balance |
| DownloadID, SubSerialID | Customer.Customer | Download tracking and sub-affiliate |
| PlayerLevelID, LabelID | Customer.Customer | Gamification level and label |
| SalesStatusID | BackOffice.Customer | CRM sales stage |
| RegulationID | BackOffice.Customer | Regulatory jurisdiction |
| Verified, VerificationLevelID | BackOffice.Customer | KYC verification state |
| DocumentStatusID | BackOffice.Customer | Document review state |
| IsAffiliate | BackOffice.Customer | Whether customer is an affiliate |
| AffiliateStatusID | BackOffice.Affiliate | Affiliate program status |
| AccountTypeID | BackOffice.Customer | Private/Corporate account type |
| GuruStatusID | BackOffice.Customer | Popular Investor status |
| RiskClassificationID | BackOffice.Customer | Risk classification |
| AcceptanceStatusID | BackOffice.Customer | Acceptance status |
| PhoneVerifiedID | BackOffice.Customer | Phone verification state |
| GDCCheckID | BackOffice.Customer | GDC check result |
| RiskStatusID | BackOffice.Customer | Risk status (added 2014-02-16) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeatureID=22 | Maintenance.Feature | Read | Determines real vs demo environment |
| @CID | Customer.Customer | Read | Full customer profile data |
| @CID | BackOffice.Customer | LEFT JOIN (read) | Compliance and sales status data |
| SerialID | BackOffice.Affiliate | LEFT JOIN (read) | Affiliate status for the customer's affiliate |
| @GCID | dbo.DemoCustomers (linked server) | Read | Resolves demo CID from GCID (in real environment) |
| @GCID | dbo.RealCustomers (linked server) | Read | Resolves real CID from GCID (in demo environment) |
| I.IP | Internal.GetCountryIDByIP | Function call | Geo-IP country lookup |
| svcDynamics | SQL Server Service Broker | Message target | CRM sync message destination |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.GenerateMirrorDataForDynamics | EXEC | Caller | Bulk Dynamics sync for mirror customers |
| Customer.GenerateTradeDateFromDynamics | EXEC | Caller | Trade date sync to Dynamics |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.DynamicsInsert (procedure)
├── Maintenance.Feature (table - cross-schema)
├── Customer.Customer (view)
├── BackOffice.Customer (table - cross-schema)
├── BackOffice.Affiliate (table - cross-schema)
├── dbo.DemoCustomers (synonym -> [Demo].[tradonomi].[Customer].[Customer])
├── dbo.RealCustomers (synonym -> [Real].[etoro].[Customer].[Customer])
├── Internal.GetCountryIDByIP (function - cross-schema)
└── svcDynamics (Service Broker service)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | FeatureID=22: real vs demo environment detection |
| Customer.Customer | View | Full customer profile data for XML payload |
| BackOffice.Customer | Table | Compliance, sales, verification data |
| BackOffice.Affiliate | Table | Affiliate status lookup by SerialID |
| dbo.DemoCustomers | Synonym (linked server) | Demo CID lookup by GCID |
| dbo.RealCustomers | Synonym (linked server) | Real CID lookup by GCID |
| Internal.GetCountryIDByIP | Function | IP-to-country resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.GenerateMirrorDataForDynamics | Procedure | Calls per customer to sync mirror data to Dynamics |
| Customer.GenerateTradeDateFromDynamics | Procedure | Calls to sync trade date data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FOR XML RAW ('Customer'), BINARY BASE64, ELEMENTS, TYPE | XML generation | Generates XML with element-centric format, BINARY BASE64 encoding, wrapped in XML type |
| Service Broker dialog | Async delivery | Fire-and-forget: returns after enqueue, no synchronous Dynamics confirmation |

---

## 8. Sample Queries

### 8.1 Trigger a Dynamics sync for a customer

```sql
EXEC Customer.DynamicsInsert @CID = 12345678
-- Sends default update (no action type)
```

### 8.2 Trigger a Dynamics sync with explicit action type

```sql
EXEC Customer.DynamicsInsert @CID = 12345678, @Action = 'Register'
```

### 8.3 Check Service Broker queue for pending Dynamics messages

```sql
SELECT TOP 10 message_type_name, CAST(message_body AS VARCHAR(MAX)) AS MessageBody
FROM svcDynamics
WITH (NOLOCK)
ORDER BY queuing_order
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 30 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.DynamicsInsert | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.DynamicsInsert.sql*
