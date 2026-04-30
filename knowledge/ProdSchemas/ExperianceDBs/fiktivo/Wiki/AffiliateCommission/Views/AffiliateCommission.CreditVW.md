# AffiliateCommission.CreditVW

> View combining credit (deposit/chargeback) financial data with affiliate attribution from RegistrationMetaData, providing a unified record for commission reporting.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | View |
| **Key Identifier** | CreditID (from Credit) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

CreditVW is the primary reporting view for credit commissions. It joins Credit (financial: CreditDate, Amount, CreditTypeID, IsFirstDeposit) with RegistrationMetaData (attribution: AffiliateID, AffiliateCampaign, BannerID, etc.) using the same dual-path UNION ALL pattern as ClosedPositionVW.

Path 1 handles current credits (CID > 0, TrackingDate >= '2021-08-01') joined on CID. Path 2 handles legacy credits (CID = -1) joined on OriginalCID. The view includes CommissionSource and ProductID columns added for ISA MoneyFarm support (PART-5461, PART-3405).

---

## 2. Business Logic

### 2.1 Dual Join Strategy

**Rules**:
- Path 1: CID > 0 AND TrackingDate >= '2021-08-01' -> JOIN on CID
- Path 2: CID = -1 AND OriginalCID IS NOT NULL AND TrackingDate <= '2021-08-02' -> JOIN on OriginalCID
- UpdateDate = GREATEST(CreditDate, ValidFrom)

---

## 3. Data Overview

N/A - view combines Credit (4.75M) with RegistrationMetaData (18.8M).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | bigint | NO | - | CODE-BACKED | From Credit. Credit event identifier. |
| 2 | CreditDate | datetime | NO | - | CODE-BACKED | From Credit. Event timestamp. |
| 3 | CID | bigint | NO | - | CODE-BACKED | From RegistrationMetaData. Customer ID. |
| 4 | AffiliateCampaign | nvarchar(1024) | NO | - | CODE-BACKED | From RegistrationMetaData. Campaign tracking. |
| 5 | CreditTypeID | tinyint | NO | - | CODE-BACKED | From Credit. 1=Deposit, 4/5=Chargeback. |
| 6 | AdditionalData | varchar(512) | NO | - | CODE-BACKED | From RegistrationMetaData. |
| 7 | AffiliateID | int | NO | - | CODE-BACKED | From RegistrationMetaData. Referring affiliate. |
| 8 | Amount | float | NO | - | CODE-BACKED | From Credit. Credit amount. |
| 9 | BannerID | int | NO | - | CODE-BACKED | From RegistrationMetaData. |
| 10 | IsFirstDeposit | bit | NO | - | CODE-BACKED | From Credit. FTD flag. |
| 11 | DownloadID | bigint | NO | - | CODE-BACKED | From RegistrationMetaData. |
| 12 | ProviderID | bigint | NO | - | CODE-BACKED | From Credit. Provider. |
| 13 | OriginalProviderID | bigint | NO | - | CODE-BACKED | From Credit. Original provider. |
| 14 | RealProviderID | bigint | NO | - | CODE-BACKED | From Credit. Execution entity. |
| 15 | CountryID | bigint | NO | - | CODE-BACKED | From Credit. Customer country. |
| 16 | FunnelID | int | YES | - | CODE-BACKED | From RegistrationMetaData. Marketing funnel. |
| 17 | LabelID | - | YES | - | CODE-BACKED | Always NULL. Backward compatibility. |
| 18 | PlayerLevelID | int | YES | - | CODE-BACKED | From RegistrationMetaData. |
| 19 | Valid | bit | NO | - | CODE-BACKED | From Credit. Commission eligibility. |
| 20 | OriginalCID | bigint | YES | - | CODE-BACKED | From RegistrationMetaData. Original customer. |
| 21 | TrackingDate | datetime | NO | - | CODE-BACKED | From Credit. Tracking entry time. |
| 22 | IsProcessed | bit | NO | - | CODE-BACKED | From Credit. Processing flag. |
| 23 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | From RegistrationMetaData. Attribution effective date. |
| 24 | UpdateDate | datetime | - | - | CODE-BACKED | Computed: GREATEST(CreditDate, ValidFrom). |
| 25 | CommissionSource | varchar(30) | YES | - | CODE-BACKED | From Credit. Commission calculation source. |
| 26 | ProductID | varchar(50) | YES | - | CODE-BACKED | From Credit. Product identifier (ISA MoneyFarm). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.Credit | JOIN | Credit financial data |
| - | AffiliateCommission.RegistrationMetaData | JOIN | Attribution data |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.CreditVW (view)
├── AffiliateCommission.Credit (table)
└── AffiliateCommission.RegistrationMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.Credit | Table | INNER JOIN |
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

### 8.1 Recent FTDs with affiliate context
```sql
SELECT TOP 20 CreditID, CreditDate, Amount, AffiliateID, CountryID, IsFirstDeposit, UpdateDate
FROM AffiliateCommission.CreditVW WITH (NOLOCK)
WHERE IsFirstDeposit = 1 ORDER BY CreditDate DESC;
```

### 8.2 Credits by affiliate and type
```sql
SELECT AffiliateID, CreditTypeID, COUNT(*) AS Credits, SUM(Amount) AS TotalAmount
FROM AffiliateCommission.CreditVW WITH (NOLOCK) WHERE Valid = 1
GROUP BY AffiliateID, CreditTypeID ORDER BY TotalAmount DESC;
```

### 8.3 Incremental load
```sql
SELECT * FROM AffiliateCommission.CreditVW WITH (NOLOCK)
WHERE UpdateDate >= @LastLoadDate ORDER BY UpdateDate;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PART-5461](https://etoro-jira.atlassian.net/browse/PART-5461) | Jira | View updates for ISA support (Jan 2026) |
| [PART-3405](https://etoro-jira.atlassian.net/browse/PART-3405) | Jira | CreditID renamed to DepositID context, structural changes (2025) |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 26 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 2 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.CreditVW | Type: View | Source: fiktivo/AffiliateCommission/Views/AffiliateCommission.CreditVW.sql*
