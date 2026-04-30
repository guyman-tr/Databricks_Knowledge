# AffiliateCommission.CreditEventVW

> View combining CreditEvent processing data with affiliate attribution from RegistrationMetaData, providing enriched credit event records for commission pipeline monitoring.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | View |
| **Key Identifier** | CreditID (from CreditEvent) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

CreditEventVW joins CreditEvent (processing state: LastCheckDate, Source, NonOrganicUpdated, ReAttributeUpdated) with RegistrationMetaData (attribution: AffiliateID, AffiliateCampaign, BannerID, etc.) on CID with partition alignment. Unlike the dual-path UNION ALL pattern in CreditVW, this view uses a single JOIN (no legacy handling), making it simpler.

This view provides the complete picture for monitoring credit events in the pipeline: both the processing state and the attributed affiliate context in a single query.

---

## 2. Business Logic

### 2.1 Single-Path Attribution Join

**Rules**:
- Joins CreditEvent.CID to RegistrationMetaData.CID with PartitionCol = CID % 50
- No UNION ALL for legacy positions
- Inherits ValidFrom from RegistrationMetaData for temporal context

---

## 3. Data Overview

N/A - combines CreditEvent (1.32M) with RegistrationMetaData.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | bigint | NO | - | CODE-BACKED | From CreditEvent. Credit identifier. |
| 2 | CreditDate | datetime | NO | - | CODE-BACKED | From CreditEvent. Event timestamp. |
| 3 | AffiliateID | int | NO | - | CODE-BACKED | From RegistrationMetaData. Attributed affiliate. |
| 4 | AffiliateCampaign | nvarchar(1024) | NO | - | CODE-BACKED | From RegistrationMetaData. Campaign. |
| 5 | Amount | float | NO | - | CODE-BACKED | From CreditEvent. Credit amount. |
| 6 | IsFirstDeposit | bit | NO | - | CODE-BACKED | From CreditEvent. FTD flag. |
| 7 | CreditTypeID | tinyint | NO | - | CODE-BACKED | From CreditEvent. Credit type. |
| 8 | DownloadID | bigint | NO | - | CODE-BACKED | From RegistrationMetaData. |
| 9 | BannerID | int | NO | - | CODE-BACKED | From RegistrationMetaData. |
| 10 | CountryID | bigint | NO | - | CODE-BACKED | From CreditEvent. Customer country. |
| 11 | ProviderID | bigint | NO | - | CODE-BACKED | From CreditEvent. |
| 12 | RealProviderID | bigint | NO | - | CODE-BACKED | From CreditEvent. |
| 13 | OriginalProviderID | bigint | NO | - | CODE-BACKED | From CreditEvent. |
| 14 | FunnelID | int | YES | - | CODE-BACKED | From RegistrationMetaData. |
| 15 | LabelID | - | YES | - | CODE-BACKED | Always NULL. Backward compatibility. |
| 16 | PlayerLevelID | int | YES | - | CODE-BACKED | From RegistrationMetaData. |
| 17 | CID | bigint | NO | - | CODE-BACKED | From RegistrationMetaData. Customer ID. |
| 18 | OriginalCID | bigint | NO | - | CODE-BACKED | From RegistrationMetaData. |
| 19 | LastCheckDate | datetime | YES | - | CODE-BACKED | From CreditEvent. Last pipeline check. |
| 20 | Source | nvarchar(50) | YES | - | CODE-BACKED | From CreditEvent. Processing node. |
| 21 | DateModified | datetime | NO | - | CODE-BACKED | From CreditEvent. |
| 22 | GCID | bigint | NO | - | CODE-BACKED | From RegistrationMetaData. Global CID. |
| 23 | NonOrganicUpdated | datetime | YES | - | CODE-BACKED | From CreditEvent. Organic check timestamp. |
| 24 | ReAttributeUpdated | datetime | YES | - | CODE-BACKED | From CreditEvent. Re-attribution timestamp. |
| 25 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | From RegistrationMetaData. Attribution effective. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.CreditEvent | JOIN | Event processing data |
| - | AffiliateCommission.RegistrationMetaData | JOIN | Attribution data |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.CreditEventVW (view)
├── AffiliateCommission.CreditEvent (table)
└── AffiliateCommission.RegistrationMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CreditEvent | Table | INNER JOIN |
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

### 8.1 Active credit events with attribution
```sql
SELECT TOP 20 CreditID, CreditDate, Amount, AffiliateID, CID, Source, NonOrganicUpdated
FROM AffiliateCommission.CreditEventVW WITH (NOLOCK) ORDER BY DateModified DESC;
```

### 8.2 FTD events pending organic check
```sql
SELECT CreditID, CreditDate, CID, AffiliateID, Amount
FROM AffiliateCommission.CreditEventVW WITH (NOLOCK)
WHERE IsFirstDeposit = 1 AND NonOrganicUpdated IS NULL;
```

### 8.3 Events by processing source
```sql
SELECT Source, COUNT(*) AS EventCount FROM AffiliateCommission.CreditEventVW WITH (NOLOCK)
GROUP BY Source ORDER BY EventCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 25 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.CreditEventVW | Type: View | Source: fiktivo/AffiliateCommission/Views/AffiliateCommission.CreditEventVW.sql*
