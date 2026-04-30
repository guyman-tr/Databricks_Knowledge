# Customer.GetPrivateDemoAggregatedInfo

> Retrieves private/internal aggregated profile data for demo customers - supports lookup by CID or GCID with linked real account data, settings, and bio.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns private demo customer profile rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetPrivateDemoAggregatedInfo is the demo-account equivalent of GetPrivateAggregatedInfo. It retrieves internal profile data starting from the demo customer record, linking to the associated real account for back-office and compliance fields. This procedure includes private fields like ExternalID, KycState, and VerificationLevelID that are not exposed in the public GetDemoAggregatedInfo.

The procedure supports two lookup modes: by demo CID (@isGcid=0) or by GCID (@isGcid=1). It starts from dbo.Demo_Customer via OUTER APPLY, then LEFT JOINs to Real_Customer, Real_BackOfficeCustomer, General_Settings, and Publications.

---

## 2. Business Logic

### 2.1 Dual Lookup Mode

**What**: Two code paths based on @isGcid flag.

**Columns/Parameters Involved**: `@isGcid`, `@ids`

**Rules**:
- @isGcid=0: Demo_Customer WHERE CID = ids.Id
- @isGcid=1: Demo_Customer WHERE GCID = ids.Id
- Both paths return identical output columns
- OUTER APPLY on Demo_Customer allows NULL results if not found

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ids | dbo.IdList (TVP) | NO | - | CODE-BACKED | List of demo CIDs or GCIDs. |
| 2 | @isGcid | int | NO | - | CODE-BACKED | 0=lookup by demo CID, 1=lookup by GCID. |
| 3 | GCID (output) | int | YES | - | CODE-BACKED | Global Customer ID from Demo_Customer. |
| 4 | RealCID (output) | int | YES | - | CODE-BACKED | Linked real account CID. |
| 5 | DemoCID (output) | int | YES | - | CODE-BACKED | Demo account CID. |
| 6 | UserName (output) | varchar | YES | - | CODE-BACKED | Demo username. |
| 7 | FirstName (output) | nvarchar | YES | - | CODE-BACKED | First name from demo record. |
| 8 | LastName (output) | nvarchar | YES | - | CODE-BACKED | Last name from demo record. |
| 9 | LanguageID (output) | int | YES | - | CODE-BACKED | Preferred language. |
| 10 | CountryID (output) | int | YES | - | CODE-BACKED | Registered country. |
| 11 | AllowDisplayFullName (output) | bit | YES | - | CODE-BACKED | Privacy setting. From General_Settings. |
| 12 | AboutMe (output) | nvarchar | YES | - | CODE-BACKED | User bio. From Publications. |
| 13 | StrategyID (output) | int | YES | - | CODE-BACKED | Investment strategy. From Publications. Added LOY-1023. |
| 14 | WhiteLabelID (output) | int | YES | - | CODE-BACKED | Brand/white label from demo record. |
| 15 | PrivacyPolicyID (output) | int | YES | - | CODE-BACKED | Privacy policy version from real account. |
| 16 | HomepageId (output) | int | YES | - | CODE-BACKED | Homepage preference. |
| 17 | GuruStatusID (output) | int | YES | - | CODE-BACKED | Popular Investor status. |
| 18 | PlayerStatusID (output) | int | YES | - | CODE-BACKED | Account lifecycle status from real account. |
| 19 | PlayerLevelID (output) | int | YES | - | CODE-BACKED | Player level from real account. |
| 20 | ExternalID (output) | varchar | YES | - | CODE-BACKED | External system identifier (private). |
| 21 | AccountTypeID (output) | int | YES | - | CODE-BACKED | Account type from back-office. |
| 22 | MasterAccountCID (output) | int | YES | - | CODE-BACKED | Master account CID for sub-accounts. |
| 23 | KycState (output) | int | YES | - | CODE-BACKED | KYC state machine value. |
| 24 | VerificationLevelID (output) | int | YES | - | CODE-BACKED | KYC verification level. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ids | dbo.Demo_Customer | OUTER APPLY | Demo customer data |
| GCID | dbo.Real_Customer | LEFT JOIN | Linked real account |
| CID | dbo.Real_BackOfficeCustomer | LEFT JOIN | Back-office data |
| CID | dbo.General_Settings | LEFT JOIN | Settings |
| CID | dbo.Publications | OUTER APPLY | Bio content |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Demo account admin profile |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetPrivateDemoAggregatedInfo (procedure)
+-- dbo.Demo_Customer (table)
+-- dbo.Real_Customer (table)
+-- dbo.Real_BackOfficeCustomer (table)
+-- dbo.General_Settings (table)
+-- dbo.Publications (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Demo_Customer | Table | OUTER APPLY - demo customer data |
| dbo.Real_Customer | Table | LEFT JOIN - linked real account |
| dbo.Real_BackOfficeCustomer | Table | LEFT JOIN - back-office |
| dbo.General_Settings | Table | LEFT JOIN - settings |
| dbo.Publications | Table | OUTER APPLY - bio |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called by application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get private demo info by demo CID
```sql
DECLARE @ids dbo.IdList
INSERT @ids VALUES (200001)
EXEC Customer.GetPrivateDemoAggregatedInfo @ids=@ids, @isGcid=0
```

### 8.2 Get private demo info by GCID
```sql
DECLARE @ids dbo.IdList
INSERT @ids VALUES (50001)
EXEC Customer.GetPrivateDemoAggregatedInfo @ids=@ids, @isGcid=1
```

### 8.3 Direct query - demo with real account link
```sql
SELECT dc.GCID, rc.CID AS RealCID, dc.CID AS DemoCID, dc.UserName,
       dc.FirstName, dc.LastName, bc.AccountTypeID, bc.KycState, bc.VerificationLevelID
FROM dbo.Demo_Customer dc WITH (NOLOCK)
LEFT JOIN dbo.Real_Customer rc WITH (NOLOCK) ON rc.GCID = dc.GCID
LEFT JOIN dbo.Real_BackOfficeCustomer bc WITH (NOLOCK) ON bc.CID = rc.CID
WHERE dc.CID = @DemoCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetPrivateDemoAggregatedInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetPrivateDemoAggregatedInfo.sql*
