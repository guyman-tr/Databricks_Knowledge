# AffiliateCommission.Registration

> Core entity table storing customer registrations attributed to affiliates, tracking each registration through the commission processing pipeline from creation to payout.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | RegistrationID (bigint, IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 4 active (PK clustered + 3 NC) |

---

## 1. Business Meaning

Registration is the central fact table in the affiliate commission system's registration domain. Each row represents a customer registration that is attributed to an affiliate referral and tracked for commission calculation. When a new customer registers on the platform through an affiliate link, a Registration record is created to track that registration through the commission pipeline.

This table exists because registration-based commissions (CPA model) are a fundamental affiliate revenue stream. Affiliates earn a flat commission for each customer they bring to the platform who registers. The system has tracked 14.5 million registrations dating back to December 2008, with 99.7% processed. The table stores the financial context (provider chain, country) but NOT the affiliate attribution details - those are stored in RegistrationMetaData and RegistrationEvent.

Data flows into this table via InsertRegistration, which atomically creates Registration + RegistrationCommission records. SaveRegistrationCommission updates the processing state. Unlike ClosedPosition, Registration uses an IDENTITY column for its PK (auto-generated, not sourced from a staging table).

---

## 2. Business Logic

### 2.1 Registration Commission Pipeline

**What**: Each registration flows through validation and commission calculation.

**Columns/Parameters Involved**: `IsProcessed`, `Valid`, `RegistrationDate`, `TrackingDate`

**Rules**:
- InsertRegistration creates the record with IsProcessed=0 (default)
- SaveRegistrationCommission sets IsProcessed=1 and updates RegistrationDate
- UpdateRegistrationTracking also sets IsProcessed=1 as alternative completion marker
- Valid determines commission eligibility: 1=eligible, 0=not eligible
- TrackingDate precedes RegistrationDate slightly (tracking enters before commission is calculated)

### 2.2 Provider Chain

**What**: Three provider IDs track the entity chain for multi-entity brokerages.

**Columns/Parameters Involved**: `ProviderID`, `OriginalProviderID`, `RealProviderID`

**Rules**:
- All three are 0 in recent data, suggesting single-entity operation in this environment
- In multi-entity setups, these would track provider assignment, original registration entity, and real execution entity

---

## 3. Data Overview

| RegistrationID | CID | RegistrationDate | CountryID | Valid | IsProcessed | Meaning |
|---|---|---|---|---|---|---|
| 15411827 | 25476148 | 2026-03-18 16:53 | 218 | 1 | 1 | Recent registration from country 218. Valid and fully processed. No copy-trade (OriginalCID NULL). |
| 15411826 | 25476147 | 2026-03-18 16:53 | 79 | 1 | 1 | Rapid sequential registration (sub-second). Country 79. All providers = 0. |
| 15411825 | 25476146 | 2026-03-18 16:53 | 79 | 1 | 1 | Batch of registrations at same second - likely automated test or bulk import. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RegistrationID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing unique identifier. PK. Used as the key in RegistrationCommission, RegistrationEvent, and CIDRegistrationID. |
| 2 | CID | bigint | NO | - | CODE-BACKED | Customer ID of the newly registered customer. Indexed alongside OriginalCID for attribution lookups. |
| 3 | OriginalCID | bigint | YES | - | CODE-BACKED | Original customer in sub-account scenarios. NULL for standard registrations (vast majority). |
| 4 | RegistrationDate | datetime | NO | - | CODE-BACKED | Timestamp of the registration. Updated by SaveRegistrationCommission during commission processing. Used for reporting periods. |
| 5 | CountryID | bigint | NO | - | CODE-BACKED | Customer's registration country. Used in geography-specific commission rules. |
| 6 | ProviderID | bigint | NO | - | CODE-BACKED | Current provider entity. 0 in single-entity environments. |
| 7 | OriginalProviderID | bigint | NO | - | CODE-BACKED | Original registration provider. 0 = not transferred. |
| 8 | RealProviderID | bigint | NO | - | CODE-BACKED | Actual execution entity. 0 in single-entity environments. |
| 9 | TrackingDate | datetime | NO | - | CODE-BACKED | Timestamp when the registration entered the tracking system. Typically a few seconds before RegistrationDate. Indexed for pipeline performance queries. |
| 10 | Valid | bit | NO | - | CODE-BACKED | Commission eligibility flag. 1=eligible, 0=not eligible. Nearly all recent registrations are valid. |
| 11 | IsProcessed | bit | NO | 0 | CODE-BACKED | Commission processing completion flag. 0=pending, 1=commission calculated and saved. 99.7% processed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no explicit FK references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.RegistrationCommission | RegistrationID | Implicit FK | Commission records per tier |
| AffiliateCommission.RegistrationEvent | RegistrationID | Implicit FK | Event tracking records |
| AffiliateCommission.CIDRegistrationID | RegistrationID | Implicit FK | CID-to-Registration mapping |
| AffiliateCommission.RegistrationVW | - | View | View built on this table |
| AffiliateCommission.InsertRegistration | INSERT | Writer | Creates registration + commission atomically |
| AffiliateCommission.SaveRegistrationCommission | UPDATE | Modifier | Sets IsProcessed=1, updates RegistrationDate |
| AffiliateCommission.UpdateRegistrationTracking | UPDATE | Modifier | Marks as processed |
| AffiliateCommission.GetRegistrationDetails | SELECT | Reader | Reads registration details |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.RegistrationCommission | Table | Child records - commission per tier |
| AffiliateCommission.RegistrationEvent | Table | Event tracking |
| AffiliateCommission.CIDRegistrationID | Table | CID mapping |
| AffiliateCommission.RegistrationVW | View | Reads registration data |
| AffiliateCommission.InsertRegistration | Stored Procedure | Writer |
| AffiliateCommission.SaveRegistrationCommission | Stored Procedure | Modifier |
| AffiliateCommission.UpdateRegistrationTracking | Stored Procedure | Modifier |
| AffiliateCommission.UpdateRegistrationTrackingAffiliate | Stored Procedure | Modifier |
| AffiliateCommission.UpdateRegistrationTrackingEligibility | Stored Procedure | Modifier |
| AffiliateCommission.ResetRegistrationTrackingEligibility | Stored Procedure | Modifier |
| AffiliateCommission.GetRegistrationDetails | Stored Procedure | Reader |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Registration | CLUSTERED PK | RegistrationID ASC | - | - | Active |
| IDX_Registration_CIDOriginalCID | NC | CID, OriginalCID | - | - | Active |
| IX_Registration_RegistrationDate | NC | RegistrationDate, RegistrationID | - | - | Active |
| IX_Registration_TrackingDate | NC | TrackingDate, RegistrationID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Registration | PRIMARY KEY | IDENTITY-based unique registration ID |
| DF_Registration_IsProcessedFinal | DEFAULT | (0) - new registrations start unprocessed |

---

## 8. Sample Queries

### 8.1 Recent registrations with commission status
```sql
SELECT TOP 20 r.RegistrationID, r.CID, r.RegistrationDate, r.CountryID,
       r.Valid, r.IsProcessed,
       rc.AffiliateID, rc.Commission, rc.Tier
FROM AffiliateCommission.Registration r WITH (NOLOCK)
LEFT JOIN AffiliateCommission.RegistrationCommission rc WITH (NOLOCK)
    ON r.RegistrationID = rc.RegistrationID
ORDER BY r.RegistrationID DESC;
```

### 8.2 Unprocessed valid registrations
```sql
SELECT RegistrationID, CID, RegistrationDate, CountryID, TrackingDate
FROM AffiliateCommission.Registration WITH (NOLOCK)
WHERE IsProcessed = 0 AND Valid = 1
ORDER BY TrackingDate;
```

### 8.3 Daily registration counts
```sql
SELECT CAST(RegistrationDate AS DATE) AS RegDate,
       COUNT(*) AS Registrations,
       SUM(CASE WHEN Valid = 1 THEN 1 ELSE 0 END) AS ValidCount
FROM AffiliateCommission.Registration WITH (NOLOCK)
WHERE RegistrationDate >= DATEADD(day, -30, GETUTCDATE())
GROUP BY CAST(RegistrationDate AS DATE)
ORDER BY RegDate DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PART-1195](https://etoro-jira.atlassian.net/browse/PART-1195) | Jira | Registration commission support - new SP and TVP (Feb 2022) |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.Registration | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.Registration.sql*
