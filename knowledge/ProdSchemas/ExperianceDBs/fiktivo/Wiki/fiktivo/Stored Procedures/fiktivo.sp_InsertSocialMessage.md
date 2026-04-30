# fiktivo.sp_InsertSocialMessage

> Inserts a social trading message record into the affiliate social messages table, capturing all message metadata, user context, and trading instrument details.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into dbo.tblaff_SocialMessages (no OUTPUT parameter) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure inserts a social trading message record into `dbo.tblaff_SocialMessages`. Social messages represent user-generated content and social trading interactions on the platform -- such as trade alerts, copy notifications, ranking messages, and other social feed activity associated with affiliate-referred customers.

Social messages are a secondary tracking mechanism in the affiliate system. They capture the social engagement dimension of referred customers, which can be used for advanced affiliate analytics (e.g., measuring how engaged an affiliate's referred users are in the social trading community). This data supports business intelligence on affiliate quality beyond simple financial metrics.

The procedure is called by the platform's social feed pipeline when a social event occurs involving an affiliate-tracked customer. It has approximately 25 parameters covering message type, network context, trading instrument details, user identity, geographic context, and up to 10 optional custom fields. Unlike most other affiliate procedures, this one does not return an OUTPUT identity value.

---

## 2. Business Logic

### 2.1 Social Message Classification

**What**: Categorizes each social message by type, network, and trading context.

**Columns/Parameters Involved**: `@MessageTypeID`, `@Network`, `@InstrumentID`, `@IsBuy`, `@RiskType`, `@Leverage`

**Rules**:
- MessageTypeID classifies the type of social interaction (trade share, copy alert, ranking notification, etc.)
- Network identifies which social network or feed the message belongs to
- IsBuy indicates the trade direction when the message relates to a trade action
- RiskType and Leverage capture the risk profile of the associated trading activity
- PresetMessageID references a template when the message uses a predefined format

### 2.2 User and Geographic Context

**What**: Captures the full identity and location context of the message sender and subject.

**Columns/Parameters Involved**: `@GCID`, `@CID`, `@PID`, `@FromCID`, `@FromUserName`, `@CountryID`, `@LocationID`

**Rules**:
- GCID is the global customer ID; CID is the local customer ID; PID is the position/trade ID
- FromCID and FromUserName identify the message sender (may differ from the subject customer)
- CountryID and LocationID provide geographic context for the social interaction
- IsReal distinguishes live account activity from demo account messages

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MessageTypeID (IN) | INT | NO | - | CODE-BACKED | Type of social message. Classifies the interaction (trade share, copy event, ranking, etc.). |
| 2 | @Network (IN) | NVARCHAR | NO | - | CODE-BACKED | The social network or feed identifier where this message was posted. |
| 3 | @GCID (IN) | NVARCHAR | NO | - | CODE-BACKED | Global customer identifier. The platform-wide unique ID for the customer involved in this social event. |
| 4 | @CID (IN) | NVARCHAR | NO | - | CODE-BACKED | Local customer identifier. The account-level ID for the customer. |
| 5 | @PID (IN) | NVARCHAR | NO | - | CODE-BACKED | Position/trade identifier. References the specific trade or position associated with this social message. |
| 6 | @PositionID (IN) | NVARCHAR | NO | - | CODE-BACKED | Secondary position identifier. May reference a different position context than @PID. |
| 7 | @IsBuy (IN) | BIT | NO | - | CODE-BACKED | Trade direction: 1 = buy/long position, 0 = sell/short position. Relevant when the social message relates to a trade action. |
| 8 | @InstrumentID (IN) | INT | NO | - | CODE-BACKED | The trading instrument (stock, crypto, currency pair, etc.) associated with the social message. |
| 9 | @CountryID (IN) | INT | NO | - | CODE-BACKED | Country of the customer. Used for geographic analysis of social engagement. |
| 10 | @LocationID (IN) | INT | NO | - | NAME-INFERRED | More granular location identifier. May represent city or region within the country. |
| 11 | @TimpePeriodType (IN) | INT | NO | - | NAME-INFERRED | Time period classification for the message context (e.g., daily, weekly, monthly ranking period). Note: name has a typo in the DDL. |
| 12 | @RiskType (IN) | INT | NO | - | NAME-INFERRED | Risk classification of the associated trading activity. Categorizes the risk level of the trade or strategy. |
| 13 | @Leverage (IN) | INT | NO | - | NAME-INFERRED | Leverage level used in the associated trade. Higher values indicate more leveraged positions. |
| 14 | @PresetMessageID (IN) | INT | NO | - | CODE-BACKED | References a predefined message template. Zero or NULL when the message is user-generated rather than system-generated. |
| 15 | @Rank (IN) | INT | NO | - | CODE-BACKED | The user's ranking or leaderboard position when this message relates to a ranking event. |
| 16 | @FromCID (IN) | NVARCHAR | NO | - | CODE-BACKED | The customer ID of the message sender/author. May differ from @CID when the message is about someone else's activity. |
| 17 | @FromUserName (IN) | NVARCHAR | NO | - | CODE-BACKED | The display username of the message sender/author. |
| 18 | @InstrumentName (IN) | NVARCHAR | NO | - | CODE-BACKED | Human-readable name of the trading instrument (e.g., "AAPL", "BTC", "EUR/USD"). |
| 19 | @UserGeneratedContent (IN) | NVARCHAR | NO | - | CODE-BACKED | The actual text content of the message when user-generated. Empty for system-generated preset messages. |
| 20 | @Gain (IN) | FLOAT | NO | - | CODE-BACKED | The gain/return percentage or amount associated with the social event (e.g., trade profit percentage). |
| 21 | @TotalPrizes (IN) | INT | NO | - | NAME-INFERRED | Total number of prizes in a competition context. Relevant for competition or challenge-related messages. |
| 22 | @Prize (IN) | FLOAT | NO | - | NAME-INFERRED | Prize amount or value. Relevant for competition or challenge-related social messages. |
| 23 | @LanguageID (IN) | INT | NO | - | CODE-BACKED | Language of the message content. References the language lookup table. |
| 24 | @IsReal (IN) | BIT | NO | - | CODE-BACKED | Account type: 1 = real/live account, 0 = demo/virtual account. Filters social feed by account type. |
| 25 | @Optional1-10 (IN) | NVARCHAR | NO | - | NAME-INFERRED | Ten optional custom tracking fields (Optional1 through Optional10). Used for client-specific data dimensions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT target | dbo.tblaff_SocialMessages | Write | Inserts a new social message record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.sp_InsertSocialMessage (procedure)
└── dbo.tblaff_SocialMessages (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_SocialMessages | Table | INSERT target for social message records |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Insert a social message for a trade share
```sql
EXEC fiktivo.sp_InsertSocialMessage
    @MessageTypeID = 1,
    @Network = 'OpenBook',
    @GCID = '12345',
    @CID = '12345',
    @PID = '98765',
    @PositionID = '98765',
    @IsBuy = 1,
    @InstrumentID = 100,
    @CountryID = 1,
    @LocationID = 0,
    @TimpePeriodType = 0,
    @RiskType = 2,
    @Leverage = 5,
    @PresetMessageID = 0,
    @Rank = 0,
    @FromCID = '12345',
    @FromUserName = 'TraderJoe',
    @InstrumentName = 'AAPL',
    @UserGeneratedContent = 'Great entry point!',
    @Gain = 5.2,
    @TotalPrizes = 0,
    @Prize = 0,
    @LanguageID = 1,
    @IsReal = 1,
    @Optional1 = '', @Optional2 = '', @Optional3 = '',
    @Optional4 = '', @Optional5 = '', @Optional6 = '',
    @Optional7 = '', @Optional8 = '', @Optional9 = '', @Optional10 = ''
```

### 8.2 View recent social messages by customer
```sql
SELECT TOP 20 *
FROM dbo.tblaff_SocialMessages WITH (NOLOCK)
WHERE CID = '12345'
ORDER BY ID DESC
```

### 8.3 Social messages by message type with instrument details
```sql
SELECT sm.MessageTypeID, sm.InstrumentName, sm.FromUserName,
       sm.Gain, sm.IsReal, sm.UserGeneratedContent
FROM dbo.tblaff_SocialMessages sm WITH (NOLOCK)
WHERE sm.IsReal = 1
ORDER BY sm.ID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 6.0/10 (Elements: 7/10, Logic: 5/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 7 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.sp_InsertSocialMessage | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.sp_InsertSocialMessage.sql*
