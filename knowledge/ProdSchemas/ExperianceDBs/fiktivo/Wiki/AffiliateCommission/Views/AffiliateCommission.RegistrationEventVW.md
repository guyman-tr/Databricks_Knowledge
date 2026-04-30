# AffiliateCommission.RegistrationEventVW

> View combining RegistrationEvent processing data with affiliate attribution from RegistrationMetaData, providing enriched registration event records for commission pipeline monitoring.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | View |
| **Key Identifier** | RegistrationID (from RegistrationEvent) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

RegistrationEventVW joins RegistrationEvent (processing state) with RegistrationMetaData (attribution) on CID with partition alignment. Same single-path pattern as CreditEventVW (no UNION ALL). Provides the complete picture for monitoring registration events: processing state + attributed affiliate context.

---

## 2. Business Logic

### 2.1 Single-Path Attribution Join

**Rules**:
- Joins RegistrationEvent.CID to RegistrationMetaData.CID with PartitionCol = CID % 50
- No legacy handling (single SELECT)

---

## 3. Data Overview

N/A - combines RegistrationEvent (176 rows) with RegistrationMetaData.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | - | CODE-BACKED | From RegistrationEvent. Surrogate key. |
| 2 | RegistrationID | bigint | NO | - | CODE-BACKED | From RegistrationEvent. Registration identifier. |
| 3 | RegistrationDate | datetime | NO | - | CODE-BACKED | From RegistrationEvent. Event timestamp. |
| 4 | AffiliateID | int | NO | - | CODE-BACKED | From RegistrationMetaData. Attributed affiliate. |
| 5 | AffiliateCampaign | nvarchar(1024) | NO | - | CODE-BACKED | From RegistrationMetaData. Campaign. |
| 6 | DownloadID | bigint | NO | - | CODE-BACKED | From RegistrationMetaData. |
| 7 | BannerID | int | NO | - | CODE-BACKED | From RegistrationMetaData. |
| 8 | CountryID | bigint | NO | - | CODE-BACKED | From RegistrationEvent. Customer country. |
| 9 | ProviderID | bigint | NO | - | CODE-BACKED | From RegistrationEvent. |
| 10 | RealProviderID | bigint | NO | - | CODE-BACKED | From RegistrationEvent. |
| 11 | OriginalProviderID | bigint | NO | - | CODE-BACKED | From RegistrationEvent. |
| 12 | FunnelID | int | YES | - | CODE-BACKED | From RegistrationMetaData. |
| 13 | LabelID | - | YES | - | CODE-BACKED | Always NULL. |
| 14 | PlayerLevelID | int | YES | - | CODE-BACKED | From RegistrationMetaData. |
| 15 | CID | bigint | NO | - | CODE-BACKED | From RegistrationMetaData. Customer ID. |
| 16 | OriginalCID | bigint | NO | - | CODE-BACKED | From RegistrationMetaData. |
| 17 | LastCheckDate | datetime | YES | - | CODE-BACKED | From RegistrationEvent. Last check. |
| 18 | Source | nvarchar(50) | YES | - | CODE-BACKED | From RegistrationEvent. Processing node. |
| 19 | DateModified | datetime | NO | - | CODE-BACKED | From RegistrationEvent. |
| 20 | NonOrganicUpdated | datetime | YES | - | CODE-BACKED | From RegistrationEvent. Organic check. |
| 21 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | From RegistrationMetaData. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.RegistrationEvent | JOIN | Event data |
| - | AffiliateCommission.RegistrationMetaData | JOIN | Attribution data |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.RegistrationEventVW (view)
├── AffiliateCommission.RegistrationEvent (table)
└── AffiliateCommission.RegistrationMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.RegistrationEvent | Table | INNER JOIN |
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

### 8.1 Active registration events
```sql
SELECT RegistrationID, RegistrationDate, CID, AffiliateID, Source, NonOrganicUpdated
FROM AffiliateCommission.RegistrationEventVW WITH (NOLOCK) ORDER BY DateModified DESC;
```

### 8.2 Events pending organic check
```sql
SELECT RegistrationID, CID, AffiliateID FROM AffiliateCommission.RegistrationEventVW WITH (NOLOCK)
WHERE NonOrganicUpdated IS NULL;
```

### 8.3 Events by source node
```sql
SELECT Source, COUNT(*) AS Events FROM AffiliateCommission.RegistrationEventVW WITH (NOLOCK)
GROUP BY Source;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.RegistrationEventVW | Type: View | Source: fiktivo/AffiliateCommission/Views/AffiliateCommission.RegistrationEventVW.sql*
