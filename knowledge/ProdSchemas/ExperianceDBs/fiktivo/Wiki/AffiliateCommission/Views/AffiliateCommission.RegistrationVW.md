# AffiliateCommission.RegistrationVW

> View combining Registration event data with affiliate attribution from RegistrationMetaData, providing unified registration records for commission reporting with dual-path UNION ALL for current and legacy registrations.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | View |
| **Key Identifier** | RegistrationID (from Registration) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

RegistrationVW is the primary reporting view for registration commissions. It joins Registration (event data) with RegistrationMetaData (attribution) using the UNION ALL dual-path pattern. Path 1 handles current registrations (CID > 0) on CID, Path 2 handles legacy (CID = -1) on OriginalCID. No date cutoff unlike ClosedPositionVW - all registrations are included.

---

## 2. Business Logic

### 2.1 Dual Join Strategy

**Rules**:
- Path 1: CID > 0 -> JOIN on CID with partition alignment
- Path 2: CID = -1 AND OriginalCID IS NOT NULL -> JOIN on OriginalCID
- UpdateDate = GREATEST(RegistrationDate, ValidFrom)

---

## 3. Data Overview

N/A - combines Registration (14.5M) with RegistrationMetaData (18.8M).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RegistrationID | bigint | NO | - | CODE-BACKED | From Registration. Registration identifier. |
| 2 | CID | bigint | NO | - | CODE-BACKED | From RegistrationMetaData. Customer ID. |
| 3 | OriginalCID | bigint | NO | - | CODE-BACKED | From RegistrationMetaData. Original customer. |
| 4 | AffiliateID | int | NO | - | CODE-BACKED | From RegistrationMetaData. Referring affiliate. |
| 5 | AffiliateCampaign | nvarchar(1024) | NO | - | CODE-BACKED | From RegistrationMetaData. Campaign. |
| 6 | AdditionalData | varchar(512) | NO | - | CODE-BACKED | From RegistrationMetaData. Extensible metadata. |
| 7 | RegistrationDate | datetime | NO | - | CODE-BACKED | From Registration. Registration timestamp. |
| 8 | DownloadID | bigint | NO | - | CODE-BACKED | From RegistrationMetaData. |
| 9 | BannerID | int | NO | - | CODE-BACKED | From RegistrationMetaData. |
| 10 | CountryID | bigint | NO | - | CODE-BACKED | From Registration. Customer country. |
| 11 | ProviderID | bigint | NO | - | CODE-BACKED | From Registration. |
| 12 | OriginalProviderID | bigint | NO | - | CODE-BACKED | From Registration. |
| 13 | RealProviderID | bigint | NO | - | CODE-BACKED | From Registration. |
| 14 | FunnelID | int | YES | - | CODE-BACKED | From RegistrationMetaData. |
| 15 | LabelID | - | YES | - | CODE-BACKED | Always NULL. |
| 16 | PlayerLevelID | int | YES | - | CODE-BACKED | From RegistrationMetaData. |
| 17 | TrackingDate | datetime | NO | - | CODE-BACKED | From Registration. Tracking entry. |
| 18 | Valid | bit | NO | - | CODE-BACKED | From Registration. Eligibility. |
| 19 | IsProcessed | bit | NO | - | CODE-BACKED | From Registration. Processing flag. |
| 20 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | From RegistrationMetaData. Attribution effective. |
| 21 | UpdateDate | datetime | - | - | CODE-BACKED | Computed: GREATEST(RegistrationDate, ValidFrom). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.Registration | JOIN | Registration data |
| - | AffiliateCommission.RegistrationMetaData | JOIN | Attribution data |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.RegistrationVW (view)
├── AffiliateCommission.Registration (table)
└── AffiliateCommission.RegistrationMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.Registration | Table | INNER JOIN |
| AffiliateCommission.RegistrationMetaData | Table | INNER JOIN |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Recent registrations with affiliate
```sql
SELECT TOP 20 RegistrationID, RegistrationDate, CID, AffiliateID, CountryID, Valid, UpdateDate
FROM AffiliateCommission.RegistrationVW WITH (NOLOCK) ORDER BY RegistrationDate DESC;
```

### 8.2 Registrations by affiliate
```sql
SELECT AffiliateID, COUNT(*) AS Registrations FROM AffiliateCommission.RegistrationVW WITH (NOLOCK)
WHERE Valid = 1 GROUP BY AffiliateID ORDER BY Registrations DESC;
```

### 8.3 Incremental load
```sql
SELECT * FROM AffiliateCommission.RegistrationVW WITH (NOLOCK)
WHERE UpdateDate >= @LastLoadDate ORDER BY UpdateDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.RegistrationVW | Type: View | Source: fiktivo/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.sql*
