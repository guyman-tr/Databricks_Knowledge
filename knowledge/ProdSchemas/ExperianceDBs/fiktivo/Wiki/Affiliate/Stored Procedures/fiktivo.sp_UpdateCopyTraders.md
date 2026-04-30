# fiktivo.sp_UpdateCopyTraders

> Inserts a new copy trader event record into dbo.tblaff_CopyTraders when an affiliate-referred customer initiates copy trading activity.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CopyTraderID OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

sp_UpdateCopyTraders records a new copy trading event in the affiliate commission system. When a customer who was referred by an affiliate starts copying another trader, this procedure creates the event record that will later trigger commission calculations. Copy trading is one of eToro's signature features, and affiliates earn commissions when their referred customers engage in copy trading.

This is a WRITER procedure for the tblaff_CopyTraders table. It captures the customer ID, order date, acceptance status, geographic data (CountryID), provider attribution, and funnel metadata. The returned CopyTraderID is then used by sp_UpdateCopyTradersCommisions to create the associated commission records.

---

## 2. Business Logic

### 2.1 Copy Trader Event Creation

**What**: Creates a new copy trader event with affiliate attribution and geographic context.

**Columns/Parameters Involved**: Multiple parameters covering customer, affiliate, and geographic data

**Rules**:
- AffiliateCopyTraderAccepted defaults to 1 (accepted) and Valid defaults to 1 (valid)
- CountryID, ProviderID, OriginalProviderID track the geographic and provider context
- RealProviderID defaults to 1 (primary provider), LabelID defaults to 1, PlayerLevelID defaults to 1
- @Real (BIT) indicates whether the copy trade is with real money vs virtual/demo
- SCOPE_IDENTITY() returns the new CopyTraderID

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CUSTOMER_ID | nvarchar(50) (IN) | NO | - | CODE-BACKED | Customer identifier who initiated the copy trade. |
| 2 | @ORDER_DATE | datetime (IN) | NO | - | CODE-BACKED | Date/time when the copy trading event occurred. |
| 3 | @AffiliateCopyTraderAccepted | bit (IN) | YES | 1 | CODE-BACKED | Whether the event is accepted for commission. 1=accepted (default). |
| 4 | @Valid | bit (IN) | YES | 1 | CODE-BACKED | Whether the event is valid for processing. 1=valid (default). |
| 5 | @Reason | nvarchar(50) (IN) | YES | NULL | CODE-BACKED | Reason code if the event was rejected or invalidated. |
| 6 | @BannerID | int (IN) | YES | 0 | CODE-BACKED | Marketing banner that drove the original customer acquisition. |
| 7 | @DaysToConvert | real (IN) | YES | 0 | CODE-BACKED | Days between customer registration and this copy trade event. |
| 8 | @Optional1 | NVARCHAR(25) (IN) | YES | NULL | CODE-BACKED | Optional tracking field 1. |
| 9 | @Optional2 | NVARCHAR(25) (IN) | YES | NULL | CODE-BACKED | Optional tracking field 2. |
| 10 | @Optional3 | bigint (IN) | YES | NULL | CODE-BACKED | Optional tracking field 3 (typically CID). |
| 11 | @Real | BIT (IN) | YES | NULL | CODE-BACKED | Whether this is a real-money copy trade (1) or virtual/demo (0/NULL). |
| 12 | @DownloadID | bigint (IN) | YES | 0 | CODE-BACKED | Links to the original download event. |
| 13 | @ProviderID | bigint (IN) | YES | 0 | CODE-BACKED | Provider/broker ID at the time of event. |
| 14 | @OriginalProviderID | bigint (IN) | YES | 0 | CODE-BACKED | Original provider ID from registration time. |
| 15 | @CountryID | bigint (IN) | YES | 0 | CODE-BACKED | Country of the customer. |
| 16 | @RealProviderID | bigint (IN) | YES | 1 | CODE-BACKED | Real provider identifier. Default 1 (primary). |
| 17 | @FunnelID | int (IN) | YES | NULL | CODE-BACKED | Marketing funnel that led to this customer. |
| 18 | @LabelID | int (IN) | YES | 1 | CODE-BACKED | White-label brand identifier. Default 1. |
| 19 | @PlayerLevelID | int (IN) | YES | 1 | CODE-BACKED | Customer's player/VIP level. Default 1 (Bronze). |
| 20 | @CopyTraderID | int (OUTPUT) | NO | - | CODE-BACKED | Returns the new CopyTraderID from SCOPE_IDENTITY(). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.tblaff_CopyTraders | INSERT | Creates new copy trader event record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.sp_UpdateCopyTraders (procedure)
└── dbo.tblaff_CopyTraders (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_CopyTraders | Table (cross-schema) | INSERT new copy trader event |

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

### 8.1 Insert a new copy trader event
```sql
DECLARE @NewID INT
EXEC fiktivo.sp_UpdateCopyTraders
    @CUSTOMER_ID = '12345', @ORDER_DATE = '2012-06-15',
    @Optional3 = 12345, @Real = 1, @CountryID = 106,
    @CopyTraderID = @NewID OUTPUT
SELECT @NewID AS NewCopyTraderID
```

### 8.2 Check recent copy trader events
```sql
SELECT TOP 10 * FROM dbo.tblaff_CopyTraders WITH (NOLOCK) ORDER BY CopyTraderID DESC
```

### 8.3 Count copy trader events by country
```sql
SELECT CountryID, COUNT(*) AS EventCount
FROM dbo.tblaff_CopyTraders WITH (NOLOCK)
GROUP BY CountryID ORDER BY COUNT(*) DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.sp_UpdateCopyTraders | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.sp_UpdateCopyTraders.sql*
