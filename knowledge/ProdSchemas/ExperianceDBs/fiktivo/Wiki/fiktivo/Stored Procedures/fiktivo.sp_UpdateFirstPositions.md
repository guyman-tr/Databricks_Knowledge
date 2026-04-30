# fiktivo.sp_UpdateFirstPositions

> Records a first-position event (customer's first trade) into the affiliate first positions event table, capturing all tracking and classification attributes.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NewID OUTPUT (new event record identity) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure inserts a first-position event record into `dbo.tblaff_FirstPositions`. A first position is the very first trade opened by a referred customer on the platform. This milestone event is critical for affiliate tracking because it represents the customer's transition from a depositing user to an active trader.

First-position events are a key conversion metric. They prove that the affiliate's referred customer has not only registered and funded their account, but has also engaged with the core trading functionality. Many affiliate compensation models include a first-position bonus or use this event as a CPA trigger. Without this procedure, first-trade milestones would not be captured for affiliate attribution.

The procedure is called by the platform's event pipeline when a customer's first trade is detected. It captures the trade value, conversion timing, marketing context, and classification dimensions. The returned @NewID is used downstream by `sp_UpdateFirstPositionsCommissions` to create the corresponding commission record.

---

## 2. Business Logic

### 2.1 First Position Event Recording

**What**: Captures all dimensions of a customer's first trade for affiliate tracking and commission eligibility.

**Columns/Parameters Involved**: `@ORDER_DATE`, `@GRAND_TOTAL`, `@AffiliateFirstPositionAccepted`, `@Valid`, `@BannerID`, `@DaysToConvert`, `@OriginalCID`

**Rules**:
- Each row represents one customer's first trade milestone
- @GRAND_TOTAL captures the monetary value of the first trade
- @AffiliateFirstPositionAccepted indicates affiliate acknowledgment of the event
- @Valid determines commission eligibility
- @DaysToConvert measures the customer journey from registration to first trade
- @OriginalCID preserves the original customer ID before any account merges or reassignments

**Diagram**:
```
Customer Opens First Trade
    |
    v
sp_UpdateFirstPositions
    |
    +--> INSERT INTO tblaff_FirstPositions
    |        (ORDER_DATE, GRAND_TOTAL, AffiliateFirstPositionAccepted, Valid,
    |         BannerID, DaysToConvert, Optional1-2, OriginalCID, DownloadID,
    |         ProviderID, OriginalProviderID, CountryID, RealProviderID,
    |         FunnelID, LabelID, PlayerLevelID)
    |
    +--> SCOPE_IDENTITY() --> @NewID OUTPUT
    |
    v
sp_UpdateFirstPositionsCommissions (downstream)
    +--> Creates commission record referencing @NewID
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ORDER_DATE (IN) | DATETIME | NO | - | CODE-BACKED | The date and time when the customer opened their first trade position. |
| 2 | @GRAND_TOTAL (IN) | FLOAT | NO | - | CODE-BACKED | The monetary value (volume or notional amount) of the first trade position. |
| 3 | @AffiliateFirstPositionAccepted (IN) | BIT | NO | - | CODE-BACKED | Whether the affiliate accepted this first-position event: 1 = accepted, 0 = not accepted. Controls affiliate portal visibility. |
| 4 | @Valid (IN) | BIT | NO | - | CODE-BACKED | Whether this event qualifies for commission: 1 = valid, 0 = disqualified. Invalid events are recorded but generate no commissions. |
| 5 | @BannerID (IN) | INT | NO | - | CODE-BACKED | The marketing banner/creative used to refer this customer. References dbo.tblaff_Banners. Zero if no specific banner. |
| 6 | @DaysToConvert (IN) | REAL | NO | - | CODE-BACKED | Days between registration and first trade. Measures conversion velocity for affiliate quality analysis. |
| 7 | @Optional1 (IN) | NVARCHAR | NO | - | NAME-INFERRED | Optional custom tracking field 1. Used for client-specific tracking dimensions. |
| 8 | @Optional2 (IN) | NVARCHAR | NO | - | NAME-INFERRED | Optional custom tracking field 2. Used for client-specific tracking dimensions. |
| 9 | @OriginalCID (IN) | BIGINT | NO | - | CODE-BACKED | The original customer ID before any account merges or reassignments. Preserves attribution history. |
| 10 | @DownloadID (IN) | BIGINT | NO | 0 | CODE-BACKED | The download/click tracking ID. References the tracking system. Zero if not tracked. |
| 11 | @ProviderID (IN) | BIGINT | NO | 0 | CODE-BACKED | The resolved provider/broker identifier. Zero if not applicable. |
| 12 | @OriginalProviderID (IN) | BIGINT | NO | 0 | CODE-BACKED | The original provider identifier as received from the platform, before any mapping. |
| 13 | @CountryID (IN) | BIGINT | NO | 0 | CODE-BACKED | The country of the customer. References dbo.tblaff_Countries. Used for geo-based reporting and commission rules. |
| 14 | @RealProviderID (IN) | BIGINT | NO | 1 | CODE-BACKED | The ultimate real provider identifier after all resolution. Default 1 indicates primary provider. |
| 15 | @FunnelID (IN) | INT | NO | 0 | CODE-BACKED | The marketing funnel that drove this conversion. Zero indicates no funnel attribution. |
| 16 | @LabelID (IN) | INT | NO | 1 | CODE-BACKED | The brand/label for this event. Default 1 is the primary label. Multi-brand environment support. |
| 17 | @PlayerLevelID (IN) | INT | NO | 1 | CODE-BACKED | The customer's player/VIP level at the time of the event. Default 1 is the base level. |
| 18 | @NewID (OUT) | INT | YES | - | CODE-BACKED | The SCOPE_IDENTITY() of the newly inserted first-position event. Used downstream by sp_UpdateFirstPositionsCommissions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BannerID | dbo.tblaff_Banners | Implicit | Marketing banner used to refer the customer |
| @CountryID | dbo.tblaff_Countries | Implicit | Country of the customer |
| INSERT target | dbo.tblaff_FirstPositions | Write | Inserts a new first-position event record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.sp_UpdateFirstPositionsCommissions | @FirstPositionID | Procedure chain | Uses the returned NewID to create the commission record |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.sp_UpdateFirstPositions (procedure)
└── dbo.tblaff_FirstPositions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_FirstPositions | Table | INSERT target for first-position event records |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.sp_UpdateFirstPositionsCommissions | Stored Procedure | Consumes the @NewID output to create commission records |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Record a first-position event
```sql
DECLARE @NewID INT
EXEC fiktivo.sp_UpdateFirstPositions
    @ORDER_DATE = '2026-04-12 14:30:00',
    @GRAND_TOTAL = 500.00,
    @AffiliateFirstPositionAccepted = 1,
    @Valid = 1,
    @BannerID = 25,
    @DaysToConvert = 2.5,
    @Optional1 = '', @Optional2 = '',
    @OriginalCID = 12345,
    @DownloadID = 0,
    @ProviderID = 0,
    @OriginalProviderID = 0,
    @CountryID = 1,
    @RealProviderID = 1,
    @FunnelID = 0,
    @LabelID = 1,
    @PlayerLevelID = 1,
    @NewID = @NewID OUTPUT
SELECT @NewID AS NewFirstPositionEventID
```

### 8.2 View recent first-position events
```sql
SELECT TOP 20 *
FROM dbo.tblaff_FirstPositions WITH (NOLOCK)
ORDER BY ORDER_DATE DESC
```

### 8.3 First-position events with country and banner details
```sql
SELECT fp.*, b.BannerName, c.CountryName
FROM dbo.tblaff_FirstPositions fp WITH (NOLOCK)
LEFT JOIN dbo.tblaff_Banners b WITH (NOLOCK) ON b.BannerID = fp.BannerID
LEFT JOIN dbo.tblaff_Countries c WITH (NOLOCK) ON c.CountryID = fp.CountryID
WHERE fp.Valid = 1
ORDER BY fp.ORDER_DATE DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.sp_UpdateFirstPositions | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.sp_UpdateFirstPositions.sql*
