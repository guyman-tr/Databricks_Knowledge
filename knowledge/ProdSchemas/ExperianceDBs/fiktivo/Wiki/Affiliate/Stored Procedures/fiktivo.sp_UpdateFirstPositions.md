# fiktivo.sp_UpdateFirstPositions

> Inserts a new first-position event record into dbo.tblaff_FirstPositions, returning the new record ID.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NewID OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

sp_UpdateFirstPositions records the moment an affiliate-referred customer closes their first trading position. This event is a key milestone in the affiliate commission lifecycle because it triggers first-position commission eligibility. Once a first position is recorded, the affiliate commission engine can evaluate whether the referring affiliate qualifies for a first-position bonus.

The procedure inserts a single row into dbo.tblaff_FirstPositions with all relevant metadata about the event, including the order date, total amount, banner context, conversion timing, provider details, and label/funnel classification. The name "Update" is a legacy misnomer; the procedure exclusively performs INSERT operations.

First-position tracking is essential for CPA (Cost Per Acquisition) commission models where affiliates earn a one-time payment when their referred customer completes a qualifying first trade. The @AffiliateFirstPositionAccepted flag indicates whether the event passed initial validation checks, while the @Valid flag controls whether the record is active for commission processing. Author: Amir Moualem, 17/03/2013.

---

## 2. Business Logic

### 2.1 Insert First-Position Record

**What**: Inserts a single row into dbo.tblaff_FirstPositions with the provided parameter values.

**Columns/Parameters Involved**: ORDER_DATE, GRAND_TOTAL, AffiliateFirstPositionAccepted, Valid, BannerID, DaysToConvert, Optional1, Optional2, OriginalCID, DownloadID, ProviderID, OriginalProviderID, CountryID, RealProviderID, FunnelID, LabelID, PlayerLevelID

**Rules**:
- INSERT INTO dbo.tblaff_FirstPositions with all parameter values mapped directly to columns
- SELECT @NewID = SCOPE_IDENTITY() to capture the auto-generated identity value of the newly inserted row
- No validation or transformation is performed on the input values; all business validation is expected to have been performed by the caller

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ORDER_DATE | DATETIME (IN) | NO | - | CODE-BACKED | The date and time the first position was closed by the customer. |
| 2 | @GRAND_TOTAL | FLOAT (IN) | NO | - | CODE-BACKED | The monetary value of the first position trade. |
| 3 | @AffiliateFirstPositionAccepted | BIT (IN) | NO | 1 | CODE-BACKED | Whether the first-position event passed initial validation. 1 = accepted, 0 = rejected. |
| 4 | @Valid | BIT (IN) | NO | 1 | CODE-BACKED | Whether the record is active for commission processing. 1 = valid, 0 = invalidated. |
| 5 | @BannerID | INT (IN) | NO | 0 | CODE-BACKED | The marketing banner or creative that the customer clicked through. 0 = no banner tracked. |
| 6 | @DaysToConvert | REAL (IN) | NO | 0 | CODE-BACKED | Number of days between customer registration and first position close. |
| 7 | @Optional1 | NVARCHAR(25) (IN) | YES | - | CODE-BACKED | Custom tracking field 1, typically used for sub-campaign or tracking token. |
| 8 | @Optional2 | NVARCHAR(25) (IN) | YES | - | CODE-BACKED | Custom tracking field 2, typically used for additional segmentation. |
| 9 | @OriginalCID | BIGINT (IN) | NO | - | CODE-BACKED | The original customer ID of the referred customer who closed the first position. |
| 10 | @DownloadID | BIGINT (IN) | NO | 0 | CODE-BACKED | Reference to the download/registration event. 0 = not tracked. |
| 11 | @ProviderID | BIGINT (IN) | NO | 0 | CODE-BACKED | The provider (broker/platform) ID assigned at the time of the event. |
| 12 | @OriginalProviderID | BIGINT (IN) | NO | 0 | CODE-BACKED | The original provider ID at the time of customer registration. |
| 13 | @CountryID | BIGINT (IN) | NO | 0 | CODE-BACKED | The country code of the customer. 0 = unknown. |
| 14 | @RealProviderID | BIGINT (IN) | NO | 1 | CODE-BACKED | The actual provider ID used for commission calculations. |
| 15 | @FunnelID | INT (IN) | NO | 0 | CODE-BACKED | Marketing funnel identifier. 0 = default/unclassified. |
| 16 | @LabelID | INT (IN) | NO | 1 | CODE-BACKED | White-label identifier. 1 = default label. |
| 17 | @PlayerLevelID | INT (IN) | NO | 1 | CODE-BACKED | Player tier/level classification. 1 = default level. |
| 18 | @NewID | INT (OUTPUT) | NO | - | CODE-BACKED | Returns the SCOPE_IDENTITY() value of the newly inserted first-position record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.tblaff_FirstPositions | INSERT | Inserts new first-position event record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.sp_UpdateFirstPositions (procedure)
└── dbo.tblaff_FirstPositions (table, cross-schema)
```

### 6.1 Objects This Depends On

1 cross-schema dbo table (tblaff_FirstPositions).

### 6.2 Objects That Depend On This

No dependents found in the fiktivo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Record a first position for a referred customer
```sql
DECLARE @NewID INT
EXEC fiktivo.sp_UpdateFirstPositions
    @ORDER_DATE = '2026-04-12 14:30:00',
    @GRAND_TOTAL = 500.00,
    @AffiliateFirstPositionAccepted = 1,
    @Valid = 1,
    @BannerID = 42,
    @DaysToConvert = 3.5,
    @Optional1 = N'campaign_spring',
    @Optional2 = N'landing_v2',
    @OriginalCID = 987654,
    @DownloadID = 112233,
    @ProviderID = 5,
    @OriginalProviderID = 5,
    @CountryID = 276,
    @RealProviderID = 1,
    @FunnelID = 10,
    @LabelID = 1,
    @PlayerLevelID = 1,
    @NewID = @NewID OUTPUT
SELECT @NewID AS NewFirstPositionID
```

### 8.2 Verify newly inserted first-position record
```sql
SELECT TOP 10
    FirstPositionID,
    ORDER_DATE,
    GRAND_TOTAL,
    OriginalCID,
    AffiliateFirstPositionAccepted,
    Valid
FROM dbo.tblaff_FirstPositions WITH (NOLOCK)
WHERE OriginalCID = 987654
ORDER BY FirstPositionID DESC
```

### 8.3 Count first-position events by date range
```sql
SELECT
    CAST(ORDER_DATE AS DATE) AS EventDate,
    COUNT(*) AS FirstPositionCount,
    SUM(GRAND_TOTAL) AS TotalVolume
FROM dbo.tblaff_FirstPositions WITH (NOLOCK)
WHERE ORDER_DATE >= DATEADD(DAY, -30, GETDATE())
    AND Valid = 1
    AND AffiliateFirstPositionAccepted = 1
GROUP BY CAST(ORDER_DATE AS DATE)
ORDER BY EventDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 8.0/10, Logic: 7.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.sp_UpdateFirstPositions | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.sp_UpdateFirstPositions.sql*
