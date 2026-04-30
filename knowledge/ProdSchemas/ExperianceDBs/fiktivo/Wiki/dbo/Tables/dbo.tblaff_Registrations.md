# dbo.tblaff_Registrations

> Tracks customer registration events - the highest-volume event table recording every new account signup attributed to the affiliate program.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | RegistrationID (INT IDENTITY, NC PK) |
| **Partition** | No |
| **Indexes** | 3 active (1 NC PK, 1 clustered on ORDER_DATE, 1 NC) |

---

## 1. Business Meaning

This is the highest-volume event table in the database with 3,688,465 records. It records every customer registration (account creation) attributed to the affiliate program. Registrations are a fundamental conversion event - the moment a potential customer referred by an affiliate creates an account on the trading platform.

Registration events are the basis for registration-based commission models and also serve as the starting point for tracking a customer's journey through the conversion funnel (registration -> lead -> deposit -> trade).

The table has cascade-delete and update triggers linking to tblaff_Registrations_Commissions.

---

## 2. Business Logic

### 2.1 Registration Validation

**What**: Each registration passes through validation and attribution.

**Columns/Parameters Involved**: `AffiliateRegistrationAccepted`, `Valid`, `Reason`, `Real`

**Rules**:
- AffiliateRegistrationAccepted=1: Registration attributed to an affiliate
- Valid=1: Registration passed validation (not duplicate IP, not bot, meets minimum criteria)
- Real=1: Registration from a real (production) account, not demo
- Both accepted and valid must be TRUE for registration commissions

---

## 3. Data Overview

N/A - registration events represent new customer signups from affiliate-referred traffic.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RegistrationID | int | NO | IDENTITY(1,1) | VERIFIED | Primary key. Unique identifier for each registration. NOT FOR REPLICATION. Referenced by tblaff_Registrations_Commissions. |
| 2 | CUSTOMER_ID | nvarchar(50) | YES | - | VERIFIED | Customer identifier assigned during registration. |
| 3 | ORDER_DATE | datetime | YES | - | VERIFIED | Registration timestamp. Clustered index column. |
| 4 | AffiliateRegistrationAccepted | bit | NO | 0 | VERIFIED | Attribution flag. 1=attributed to affiliate, 0=not attributed. |
| 5 | IPAddress | nvarchar(20) | YES | - | CODE-BACKED | Customer's IP at registration. Used for duplicate/fraud detection. |
| 6 | Browser | nvarchar(255) | YES | - | CODE-BACKED | Customer's user agent. |
| 7 | Valid | bit | NO | 0 | VERIFIED | Validation flag. 1=valid, 0=rejected. |
| 8 | Reason | nvarchar(50) | YES | - | CODE-BACKED | Rejection reason when Valid=0. |
| 9 | BannerID | int | NO | 0 | VERIFIED | Marketing banner. References dbo.tblaff_Banners [done]. |
| 10 | DaysToConvert | real | NO | 0 | CODE-BACKED | Days between affiliate click and registration. |
| 11 | Optional1 | nvarchar(25) | YES | - | CODE-BACKED | Sub-affiliate tracking parameter. |
| 12 | Optional2 | nvarchar(25) | YES | - | CODE-BACKED | Secondary tracking parameter. |
| 13 | Optional3 | bigint | YES | - | VERIFIED | Original CID or extended tracking ID. Has NC index. |
| 14 | Real | bit | YES | - | CODE-BACKED | Real vs demo account. 1=real, NULL/0=demo. |
| 15 | DownloadID | bigint | YES | 0 | CODE-BACKED | App download event ID. |
| 16 | ProviderID | bigint | NO | 1 | VERIFIED | Currently attributed affiliate provider. |
| 17 | OriginalProviderID | bigint | NO | 1 | VERIFIED | First affiliate that acquired this customer. |
| 18 | CountryID | bigint | NO | 0 | VERIFIED | Customer's country. References dbo.tblaff_Country [done]. |
| 19 | DID | bigint | YES | - | CODE-BACKED | Download tracking ID. |
| 20 | FID | bigint | YES | - | CODE-BACKED | Funnel tracking ID. |
| 21 | RealProviderID | bigint | NO | 1 | VERIFIED | Leaf-level provider after IB resolution. |
| 22 | FunnelID | int | YES | - | NAME-INFERRED | Marketing funnel identifier. |
| 23 | LabelID | int | YES | - | NAME-INFERRED | Marketing label/campaign identifier. |
| 24 | PlayerLevelID | int | YES | - | NAME-INFERRED | Customer tier at registration time. |
| 25 | ClubID | int | YES | - | NAME-INFERRED | Customer club membership. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BannerID | dbo.tblaff_Banners | Implicit | Marketing banner |
| CountryID | dbo.tblaff_Country | Implicit | Customer's country |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_Registrations_Commissions | RegistrationID | Trigger-enforced FK | Registration commission records |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Registrations_Commissions | Table | Cascade-deleted via trigger; trigger-enforced FK on RegistrationID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaatblaff_Registrations_PK | NC PK | RegistrationID | - | - | Active (PAGE compressed) |
| CIX_tblaff_Registrations_ORDER_DATE | CLUSTERED | ORDER_DATE | - | - | Active (PAGE compressed) |
| IDX_tblaff_Registrations_Optional3 | NC | Optional3 | RegistrationID | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page-level compression |
| tblaff_Registrations_DTrig | Trigger (DELETE) | Cascade-deletes to Registrations_Commissions |
| tblaff_Registrations_UTrig | Trigger (UPDATE) | Prevents RegistrationID changes when commissions exist |

---

## 8. Sample Queries

### 8.1 Recent valid registrations
```sql
SELECT TOP 10 RegistrationID, CUSTOMER_ID, ORDER_DATE, CountryID
FROM dbo.tblaff_Registrations WITH (NOLOCK)
WHERE AffiliateRegistrationAccepted = 1 AND Valid = 1
ORDER BY ORDER_DATE DESC
```

### 8.2 Registration volume by country
```sql
SELECT c.CountryName, COUNT(*) AS Registrations
FROM dbo.tblaff_Registrations r WITH (NOLOCK)
JOIN dbo.tblaff_Country c WITH (NOLOCK) ON r.CountryID = c.CountryID
WHERE r.Valid = 1
GROUP BY c.CountryName
ORDER BY Registrations DESC
```

### 8.3 Registrations with commissions
```sql
SELECT r.RegistrationID, r.CUSTOMER_ID, rc.AffiliateID, rc.Commission, rc.Tier, rc.Paid
FROM dbo.tblaff_Registrations r WITH (NOLOCK)
JOIN dbo.tblaff_Registrations_Commissions rc WITH (NOLOCK) ON r.RegistrationID = rc.RegistrationID
WHERE r.RegistrationID = 1000
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 8/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 11 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (triggers) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Registrations | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Registrations.sql*
