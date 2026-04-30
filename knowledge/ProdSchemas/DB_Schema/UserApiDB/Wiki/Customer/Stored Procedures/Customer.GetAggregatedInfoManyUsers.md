# Customer.GetAggregatedInfoManyUsers

> Retrieves the complete aggregated user profile for multiple users by GCID list - joining all four core Customer tables plus UserSettings, Publications, and EV verification results in two result sets. Optimized with OPTION (RECOMPILE).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ids (GCID list) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetAggregatedInfoManyUsers is the multi-user variant of GetAggregatedInfoByGCID. It returns the full aggregated user profile for a batch of users identified by GCIDs, with the same comprehensive column set covering basic identity, account configuration, contact data, risk/compliance data, user settings, publications, and electronic verification (EV) results.

This procedure serves batch operations that need the complete user profile for multiple users simultaneously - admin bulk review, compliance batch processing, CRM data export, and batch notification enrichment. It provides the same level of detail as GetAggregatedInfoByGCID but for multiple users in a single call.

The procedure returns two result sets: (1) full aggregated profiles for all matched GCIDs with ~60+ columns from all core Customer tables, (2) electronic verification history for all matched GCIDs from Ev.CustomerResult with provider type details. Uses OPTION (RECOMPILE) for optimal query plans with varying input list sizes.

---

## 2. Business Logic

### 2.1 Latest EV Result Selection (CTE)

**What**: The most recent electronic verification result per user is selected for inclusion in the main result set.

**Columns/Parameters Involved**: `GCID`, `EvStatusId`, `EvProviderId`

**Rules**:
- A CTE (evResult) selects the TOP 1 row from Ev.CustomerResult joined with @ids, ordered by CustomerEvResultId DESC
- This gives the most recent verification attempt for the batch
- Note: The CTE uses TOP 1 globally rather than per-user, which means only one user's latest EV result is included in result set 1

### 2.2 OPTION (RECOMPILE) Optimization

**What**: Forces fresh query plan compilation for each execution.

**Rules**:
- The main SELECT uses OPTION (RECOMPILE) at the end
- This is necessary because the @ids TVP can vary widely in size (1 to thousands of users)
- Without RECOMPILE, a cached plan optimized for 5 users would perform poorly for 5,000 users and vice versa

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ids | IdList (TVP) | NO | - | CODE-BACKED | READONLY list of GCIDs to retrieve full profiles for. |

**Result Set 1 - Aggregated Profile (key columns):**

| # | Element | Source Table | Confidence | Description |
|---|---------|-------------|------------|-------------|
| 1 | GCID | CustomerIdentification | CODE-BACKED | Global Customer ID. |
| 2 | RealCID | CustomerIdentification.CID | CODE-BACKED | Legacy Customer ID. |
| 3 | DemoCID | CustomerIdentification | CODE-BACKED | Demo account CID. |
| 4 | UserName | BasicUserInfo | CODE-BACKED | Platform username. |
| 5 | FirstName | BasicUserInfo | CODE-BACKED | First name. |
| 6 | LastName | BasicUserInfo | CODE-BACKED | Last name. |
| 7 | MiddleName | BasicUserInfo | CODE-BACKED | Middle name. |
| 8 | Gender | BasicUserInfo | CODE-BACKED | Gender: 'M'/'F'/'U'. |
| 9 | LanguageID | BasicUserInfo | CODE-BACKED | Preferred language. FK to Dictionary.Language. |
| 10 | BirthDate | BasicUserInfo | CODE-BACKED | Date of birth. |
| 11 | PlayerLevelID | BasicUserInfo | CODE-BACKED | eToro Club tier. FK to Dictionary.PlayerLevel. |
| 12 | OriginalCID | AccountUserInfo | CODE-BACKED | Original legacy CID. |
| 13 | AffiliateID | AccountUserInfo.SerialID | CODE-BACKED | Affiliate partner ID (aliased from SerialID). |
| 14 | WhiteLabelID | AccountUserInfo.LabelID | CODE-BACKED | Brand label. FK to Dictionary.Label. |
| 15 | AccountTypeID | AccountUserInfo | CODE-BACKED | Account type. |
| 16 | CreatedOn | BasicUserInfo.Registered | CODE-BACKED | Registration date. |
| 17 | TradeLevelID | AccountUserInfo | CODE-BACKED | Trading UI level. FK to Dictionary.TradeLevel. |
| 18 | CurrencyID | AccountUserInfo | CODE-BACKED | Account base currency. |
| 19 | PendingClosureStatusID | AccountUserInfo | CODE-BACKED | Pending closure status. |
| 20 | AccountStatusID | AccountUserInfo | CODE-BACKED | Account operational status. |
| 21 | MasterAccountCID | AccountUserInfo | CODE-BACKED | Parent account CID. |
| 22 | ManagerID | AccountUserInfo | CODE-BACKED | Account manager CID. |
| 23 | SubSerialID | AccountUserInfo | CODE-BACKED | Sub-affiliate tracking. |
| 24 | GuruStatusID | AccountUserInfo | CODE-BACKED | Popular Investor tier. FK to Dictionary.GuruStatus. |
| 25 | FunnelFromID | AccountUserInfo | CODE-BACKED | Registration funnel source. |
| 26 | KycState | AccountUserInfo | CODE-BACKED | KYC workflow state. |
| 27-46 | (Contact columns) | ContactUserInfo | CODE-BACKED | CountryID, Email, Address, City, Zip, Phone, PhonePrefix, PhoneBody, Mobile, Fax, StateID, CountryIDByIP, CitizenshipCountryID, POBCountryID, BuildingNumber, RegionID, RegionByIP_ID, SubRegionID, IsEmailVerified, EmailVerificationProviderID |
| 47-65 | (Risk columns) | RiskUserInfo | CODE-BACKED | RegulationID, DocumentStatusID, PhoneVerifiedID, VerificationLevelID, VerifiedBy, VerifiedByProvider, PlayerStatusID, PlayerStatusReasonID, SuitabilityTestStatusID, EvProviderId, EvResultsStatus, MifidCategorizationID, AsicClassificationID, DesignatedRegulationID, PlayerStatusSubReasonID, PlayerStatusSubReasonComment, EvMatchStatus, SeychellesCategorizationID, TradingRiskStatusID |
| 66-70 | (Settings columns) | UserSettings | CODE-BACKED | PrivacyPolicyID, OptOutReasonID, AllowDisplayFullName, AllowShareFollow, HomepageId |
| 71-74 | (Publication columns) | Publications | CODE-BACKED | AboutMe, AboutMeShort, StrategyID, BioLanguage |

**Result Set 2 - EV Verification History:**

| # | Element | Source | Confidence | Description |
|---|---------|-------|------------|-------------|
| 1 | EvStatusId | Ev.CustomerResult | CODE-BACKED | Verification status. |
| 2 | EvProviderId | Ev.CustomerResult | CODE-BACKED | Verification provider. |
| 3 | EvProviderTypeId | Dictionary.EvProvider | CODE-BACKED | Provider type classification. |
| 4 | TransactionDate | Ev.CustomerResult | CODE-BACKED | Verification date. |
| 5 | GCID | Ev.CustomerResult | CODE-BACKED | User identifier. |
| 6 | TransactionID | Ev.CustomerResult | CODE-BACKED | External transaction reference. |
| 7 | VerificationType | Ev.CustomerResult | CODE-BACKED | Type of verification. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Customer.CustomerIdentification | JOIN (READER) | GCID/CID/DemoCID resolution |
| (body) | Customer.BasicUserInfo | JOIN (READER) | Identity data |
| (body) | Customer.AccountUserInfo | JOIN (READER) | Account configuration |
| (body) | Customer.ContactUserInfo | JOIN (READER) | Contact data |
| (body) | Customer.RiskUserInfo | JOIN (READER) | Risk/compliance data |
| (body) | Customer.UserSettings | LEFT JOIN (READER) | User preferences |
| (body) | Ev.CustomerResult | CTE + SELECT (READER) | EV verification history |
| (body) | dbo.Publications | LEFT JOIN (READER) | Bio/strategy |
| (body) | Dictionary.EvProvider | LEFT JOIN (READER) | EV provider classification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by batch profile retrieval services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetAggregatedInfoManyUsers (procedure)
+-- Customer.CustomerIdentification (table)
+-- Customer.BasicUserInfo (table)
+-- Customer.AccountUserInfo (table)
+-- Customer.ContactUserInfo (table)
+-- Customer.RiskUserInfo (table)
+-- Customer.UserSettings (table)
+-- Ev.CustomerResult (table)
+-- dbo.Publications (table/synonym)
+-- Dictionary.EvProvider (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerIdentification | Table | JOIN - ID resolution |
| Customer.BasicUserInfo | Table | JOIN - identity data |
| Customer.AccountUserInfo | Table | JOIN - account config |
| Customer.ContactUserInfo | Table | JOIN - contact data |
| Customer.RiskUserInfo | Table | JOIN - risk/compliance |
| Customer.UserSettings | Table | LEFT JOIN - preferences |
| Ev.CustomerResult | Table | CTE + SELECT - EV verification |
| dbo.Publications | Table/Synonym | LEFT JOIN - bio/strategy |
| Dictionary.EvProvider | Table | LEFT JOIN - provider type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (no database callers found) | - | Called from application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| OPTION (RECOMPILE) | Performance | Forces fresh plan compilation for varying TVP sizes |
| TRY/CATCH | Error handling | Logs detailed error info and re-throws |

---

## 8. Sample Queries

### 8.1 Get profiles for multiple users
```sql
DECLARE @ids IdList
INSERT INTO @ids (Id) VALUES (12345), (67890), (11111)
EXEC Customer.GetAggregatedInfoManyUsers @ids = @ids
-- Returns 2 result sets: profiles + EV history
```

### 8.2 Equivalent manual query
```sql
SELECT bi.UserName, ai.GuruStatusID, ri.RegulationID, ri.PlayerStatusID
FROM Customer.CustomerIdentification ci WITH (NOLOCK)
JOIN Customer.BasicUserInfo bi WITH (NOLOCK) ON bi.GCID = ci.GCID
JOIN Customer.AccountUserInfo ai WITH (NOLOCK) ON ai.GCID = ci.GCID
JOIN Customer.RiskUserInfo ri WITH (NOLOCK) ON ri.GCID = ci.GCID
WHERE ci.GCID IN (12345, 67890, 11111)
```

### 8.3 Check EV history for multiple users
```sql
SELECT EvStatusId, EvProviderId, TransactionDate, GCID
FROM Ev.CustomerResult WITH (NOLOCK)
WHERE GCID IN (12345, 67890, 11111)
ORDER BY TransactionDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 82 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetAggregatedInfoManyUsers | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetAggregatedInfoManyUsers.sql*
