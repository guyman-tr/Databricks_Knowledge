# fiktivo.sp_UpdateCopyTraders

> Records a CopyTrader event (customer starts copying another trader) into the affiliate CopyTraders event table, capturing all tracking and classification attributes.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CopyTraderID OUTPUT (new event record identity) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure inserts a CopyTrader event record into `dbo.tblaff_CopyTraders`. A CopyTrader event occurs when a referred customer initiates a copy-trading relationship on the platform -- copying the trades of another (provider) user. This event is a key conversion milestone for the affiliate program because it demonstrates active engagement by the referred customer.

The procedure captures extensive context about the CopyTrader event: the customer involved, the date, whether the affiliate accepted the event, validation status, the marketing banner used, conversion timing, the trading provider being copied, country of the customer, and various classification dimensions (funnel, label, player level). This rich context enables detailed affiliate performance analysis and commission calculation.

The procedure is called by the platform's event pipeline when a new copy-trading relationship is detected for an affiliate-referred customer. After insertion, the returned @CopyTraderID is used by `sp_UpdateCopyTradersCommisions` to create the corresponding commission record.

---

## 2. Business Logic

### 2.1 CopyTrader Event Recording

**What**: Captures all dimensions of a CopyTrader initiation event for affiliate tracking and commission eligibility determination.

**Columns/Parameters Involved**: `@CUSTOMER_ID`, `@ORDER_DATE`, `@AffiliateCopyTraderAccepted`, `@Valid`, `@BannerID`, `@DaysToConvert`, `@ProviderID`, `@OriginalProviderID`, `@RealProviderID`

**Rules**:
- Each row represents a single copy-trading initiation by a referred customer
- @AffiliateCopyTraderAccepted indicates whether the affiliate has accepted/acknowledged this event
- @Valid indicates whether the event qualifies for commission calculation
- @DaysToConvert tracks the time from registration to CopyTrader initiation
- ProviderID, OriginalProviderID, and RealProviderID track the copied trader at different resolution levels

**Diagram**:
```
Customer Initiates Copy Trading
    |
    v
sp_UpdateCopyTraders
    |
    +--> INSERT INTO tblaff_CopyTraders
    |        (CUSTOMER_ID, ORDER_DATE, AffiliateCopyTraderAccepted, Valid,
    |         BannerID, DaysToConvert, Optional1-3, Real, DownloadID,
    |         ProviderID, OriginalProviderID, CountryID, RealProviderID,
    |         FunnelID, LabelID, PlayerLevelID)
    |
    +--> SCOPE_IDENTITY() --> @CopyTraderID OUTPUT
    |
    v
sp_UpdateCopyTradersCommisions (downstream)
    +--> Creates commission record referencing @CopyTraderID
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CUSTOMER_ID (IN) | NVARCHAR(50) | NO | - | CODE-BACKED | The platform customer identifier of the user who initiated copy-trading. Links to the customer system. |
| 2 | @ORDER_DATE (IN) | DATETIME | NO | - | CODE-BACKED | The date and time when the CopyTrader relationship was initiated. |
| 3 | @AffiliateCopyTraderAccepted (IN) | BIT | NO | - | CODE-BACKED | Whether the affiliate has accepted this CopyTrader event: 1 = accepted, 0 = not yet accepted. Controls visibility in affiliate reporting. |
| 4 | @Valid (IN) | BIT | NO | - | CODE-BACKED | Whether this event is valid for commission calculation: 1 = valid/qualifies, 0 = invalid/disqualified. Invalid events are recorded but do not generate commissions. |
| 5 | @BannerID (IN) | INT | NO | - | CODE-BACKED | The marketing banner/creative that was used to refer this customer. References dbo.tblaff_Banners. Zero if no specific banner. |
| 6 | @DaysToConvert (IN) | REAL | NO | - | CODE-BACKED | The number of days between the customer's registration and their first CopyTrader initiation. Measures conversion velocity. |
| 7 | @Optional1 (IN) | NVARCHAR | NO | - | NAME-INFERRED | Optional custom tracking field 1. Used for client-specific tracking dimensions. |
| 8 | @Optional2 (IN) | NVARCHAR | NO | - | NAME-INFERRED | Optional custom tracking field 2. Used for client-specific tracking dimensions. |
| 9 | @Optional3 (IN) | NVARCHAR | NO | - | NAME-INFERRED | Optional custom tracking field 3. Used for client-specific tracking dimensions. |
| 10 | @Real (IN) | BIT | NO | - | CODE-BACKED | Whether this is a real (live) account event vs. demo: 1 = real account, 0 = demo account. Only real events typically qualify for commissions. |
| 11 | @DownloadID (IN) | BIGINT | NO | 0 | CODE-BACKED | The download/click tracking ID that led to this customer. References the tracking system. Zero if not tracked. |
| 12 | @ProviderID (IN) | BIGINT | NO | - | CODE-BACKED | The resolved provider (copied trader) identifier. May differ from OriginalProviderID after provider resolution/mapping. |
| 13 | @OriginalProviderID (IN) | BIGINT | NO | - | CODE-BACKED | The original provider identifier as received from the platform. Before any provider mapping or resolution logic. |
| 14 | @CountryID (IN) | BIGINT | NO | - | CODE-BACKED | The country of the customer. References dbo.tblaff_Countries. Used for geo-based commission rules and reporting. |
| 15 | @RealProviderID (IN) | BIGINT | NO | 1 | CODE-BACKED | The ultimate real provider identifier after all resolution layers. Default 1 indicates the primary/default provider. |
| 16 | @FunnelID (IN) | INT | NO | 0 | CODE-BACKED | The marketing funnel that drove this conversion. Zero indicates no specific funnel attribution. |
| 17 | @LabelID (IN) | INT | NO | 1 | CODE-BACKED | The brand/label under which this event occurred. Default 1 indicates the primary label. Used in multi-brand environments. |
| 18 | @PlayerLevelID (IN) | INT | NO | 1 | CODE-BACKED | The customer's player/VIP level classification at the time of the event. Default 1 indicates the base level. |
| 19 | @CopyTraderID (OUT) | INT | YES | - | CODE-BACKED | The SCOPE_IDENTITY() of the newly inserted CopyTrader event record. Used downstream by sp_UpdateCopyTradersCommisions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BannerID | dbo.tblaff_Banners | Implicit | Marketing banner used to refer the customer |
| @CountryID | dbo.tblaff_Countries | Implicit | Country of the customer initiating copy-trading |
| INSERT target | dbo.tblaff_CopyTraders | Write | Inserts a new CopyTrader event record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.sp_UpdateCopyTradersCommisions | @CopyTraderID | Procedure chain | Uses the returned CopyTraderID to create the commission record |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.sp_UpdateCopyTraders (procedure)
└── dbo.tblaff_CopyTraders (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_CopyTraders | Table | INSERT target for CopyTrader event records |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.sp_UpdateCopyTradersCommisions | Stored Procedure | Consumes the @CopyTraderID output to create commission records |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Record a new CopyTrader event
```sql
DECLARE @CopyTraderID INT
EXEC fiktivo.sp_UpdateCopyTraders
    @CUSTOMER_ID = '12345',
    @ORDER_DATE = '2026-04-12 10:00:00',
    @AffiliateCopyTraderAccepted = 1,
    @Valid = 1,
    @BannerID = 50,
    @DaysToConvert = 3.5,
    @Optional1 = '', @Optional2 = '', @Optional3 = '',
    @Real = 1,
    @DownloadID = 0,
    @ProviderID = 9001,
    @OriginalProviderID = 9001,
    @CountryID = 1,
    @RealProviderID = 1,
    @FunnelID = 0,
    @LabelID = 1,
    @PlayerLevelID = 1,
    @CopyTraderID = @CopyTraderID OUTPUT
SELECT @CopyTraderID AS NewCopyTraderEventID
```

### 8.2 View recent CopyTrader events for a customer
```sql
SELECT *
FROM dbo.tblaff_CopyTraders WITH (NOLOCK)
WHERE CUSTOMER_ID = '12345'
ORDER BY ORDER_DATE DESC
```

### 8.3 CopyTrader events with banner and country details
```sql
SELECT ct.*, b.BannerName, c.CountryName
FROM dbo.tblaff_CopyTraders ct WITH (NOLOCK)
LEFT JOIN dbo.tblaff_Banners b WITH (NOLOCK) ON b.BannerID = ct.BannerID
LEFT JOIN dbo.tblaff_Countries c WITH (NOLOCK) ON c.CountryID = ct.CountryID
WHERE ct.Valid = 1
ORDER BY ct.ORDER_DATE DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 3 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.sp_UpdateCopyTraders | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.sp_UpdateCopyTraders.sql*
