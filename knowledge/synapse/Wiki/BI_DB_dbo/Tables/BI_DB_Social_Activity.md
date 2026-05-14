# BI_DB_dbo.BI_DB_Social_Activity

> 1.27B-row social activity fact table tracking every user interaction on the eToro social feed from 2014 to September 2025 — posts, comments, likes, and shares — with message content, word counts, and customer identity resolution via Dim_Customer. Populated daily by SP_Social_Activity from the Streams microservice external table. Last loaded ActionDateID=20250904; no data after that date suggests the feed may be dormant or migrated.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Fact) |
| **Production Source** | Streams microservice via SP_Social_Activity |
| **Refresh** | Daily (1440 min) — DELETE+INSERT by ActionDateID |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (ActionDateID ASC, RealCID ASC, PostID ASC, CommentID ASC) |
| **UC Target** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity` |
| **UC Format** | delta |
| **UC Copy Strategy** | Append |
| **UC Table Type** | Gold export from Synapse |
| **Row Count** | ~1.27 billion |
| **Date Range** | 2014-01-01 to 2025-09-04 |

---

## 1. Business Meaning

`BI_DB_Social_Activity` is the BI layer's comprehensive social feed activity log. It captures every user interaction on the eToro social network — original posts (Discussion), automated trading posts (OpenTrade, CloseTrade, OpenOrder, StartCopyTrader, StopCopyTrader), comments, likes (on both posts and comments), and shares.

Each row represents a single social action performed by a platform user. The SP resolves usernames to `RealCID` via a case-sensitive join to `Dim_Customer` (lowercased username match with `Latin1_General_100_BIN` collation), linking social activity to the customer dimension.

The table is loaded daily by `SP_Social_Activity(@dt)`, which:
1. Creates an external table (`Streams_dbo_Entries_Social_Activity_Daily`) pointing to the Streams microservice data for the given date.
2. Deletes any existing rows for that `ActionDateID`.
3. Inserts five separate action types: Posts (ActionTypeID=1 or 5), Comments (2), Likes on posts (3), Likes on comments (3), and Shares (4).

The table contains ~1.27 billion rows spanning 2014-01-01 to 2025-09-04. Data stops at September 2025, suggesting the pipeline may be dormant or migrated to a different system.

---

## 2. Business Logic

### 2.1 ActionTypeID Assignment

**What**: Each social action is classified into one of five types based on the Streams `TypeName` field.
**Columns Involved**: ActionTypeID, SubTypeName
**Rules**:
- `TypeName = 'Discussion'` with `RootId = ParentId = Id` → ActionTypeID=1 (Post)
- `TypeName = 'Comment'` → ActionTypeID=2 (Comment)
- `TypeName = 'Like'` with `RootId = ParentId` → ActionTypeID=3 (Like on Post)
- `TypeName = 'Like'` with `RootId <> ParentId` → ActionTypeID=3 (Like on Comment)
- `TypeName = 'Discussion'` with `SharedEntryId IS NOT NULL` → ActionTypeID=4 (Share)
- `TypeName IN ('CloseTrade','CopyCloseTrade','OpenOrder','OpenTrade','StartCopyTrader','StopCopyTrader')` with `RootId = ParentId = Id` → ActionTypeID=5 (Automatic Post)

### 2.2 Post vs Comment Hierarchy

**What**: The Streams entry tree determines whether a row is a root post, a comment, or a nested interaction.
**Columns Involved**: PostID, CommentID, ParentID
**Rules**:
- Root posts: `RootId = ParentId = Id` → PostID=Id, CommentID=NULL
- Comments: `TypeName='Comment'` → PostID=RootId (the parent post), CommentID=Id
- Likes on posts: `RootId = ParentId` → PostID=RootId, CommentID=NULL
- Likes on comments: `RootId <> ParentId` → PostID=RootId, CommentID=ParentId
- Shares: PostID=SharedEntryId (the shared post), CommentID=NULL

### 2.3 Username Resolution

**What**: Streams usernames are matched to RealCID via Dim_Customer using case-sensitive binary collation.
**Columns Involved**: Username, RealCID
**Rules**:
- The Streams `Username` field has a leading character stripped: `SUBSTRING([Username], 2, 50)`
- Joined to `LOWER(Dim_Customer.UserName)` using `COLLATE Latin1_General_100_BIN` (case-sensitive binary match)
- Rows without a matching Dim_Customer record are excluded (INNER JOIN)

### 2.4 Message Metrics

**What**: Text content and metrics are populated only for Posts and Comments; Likes and Shares have NULL message fields.
**Columns Involved**: MessageText, MessageSize, MessageWordNum
**Rules**:
- Posts/Comments: MessageText=MessageBody, MessageSize=LEN(MessageBody), MessageWordNum=space-count+1
- Likes/Shares: All three fields are NULL

### 2.5 Daily Idempotent Load

**What**: The SP ensures idempotent daily loads by deleting and reinserting all rows for the given date.
**Columns Involved**: ActionDateID
**Rules**:
- `DELETE FROM BI_DB_Social_Activity WHERE ActionDateID = @DateID` precedes all INSERTs
- ActionDateID is computed as `CAST(CONVERT(varchar, @dt, 112) AS INT)` — integer YYYYMMDD format

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN — no affinity column; queries benefit from predicate pushdown on the clustered index.
- **Clustered Index**: (ActionDateID, RealCID, PostID, CommentID) — optimized for date-range + customer + post lookups.
- **Large table** (~1.27B rows): always filter on `ActionDateID` to avoid full scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily post volume | `SELECT ActionDateID, COUNT(*) FROM ... WHERE ActionTypeID=1 GROUP BY ActionDateID` |
| User's social activity | `WHERE RealCID = @cid AND ActionDateID BETWEEN @start AND @end` |
| Posts with most comments | Join self on PostID, filter ActionTypeID=2, GROUP BY PostID |
| Active users per day | `SELECT ActionDateID, COUNT(DISTINCT RealCID) WHERE ActionDateID >= @date` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | RealCID = RealCID | Customer demographics, regulation, country |
| BI_DB_dbo.BI_DB_Social_Activity_Type | ActionTypeID = ActionID | Resolve action type name |

### 3.4 Gotchas

- **ActionTypeID vs ActionID**: `ActionTypeID` is the action classification (1-5); `ActionID` is the auto-increment surrogate PK. The lookup table `BI_DB_Social_Activity_Type` confusingly uses `ActionID` as its PK (not `ActionTypeID`).
- **Likes are doubled**: A like on a post appears with `CommentID=NULL`; a like on a comment appears with `CommentID=ParentId`. Both have `ActionTypeID=3` — distinguish via CommentID IS NULL/IS NOT NULL.
- **Username leading character stripped**: The Streams feed prepends a character to usernames; the SP strips it with `SUBSTRING(Username, 2, 50)`. The stored `Username` matches `Dim_Customer.UserName` in lowercase.
- **No data after 2025-09-04**: The pipeline appears dormant. Queries for recent dates will return zero rows.
- **MessageText/Size/WordNum NULL for Likes and Shares**: Only Posts (1, 5) and Comments (2) carry message content.
- **MediaTypeID mostly NULL**: Only a small fraction of rows have a non-NULL MediaTypeID (values 5, 6 observed).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (production source documented) |
| Tier 2 | Derived from SP source code or ETL logic |
| Tier 3 | No upstream documentation; described from DDL + data evidence |
| Tier 4 | Inferred from column name only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ActionTypeID | smallint | NO | Social action classification. 1=ManualPositionOpen, 2=CopyPositionOpen, 3=CopyPlusPositionOpen, 4=ManualPositionClose, 5=CopyPositionClose (BI_DB_Social_Activity_Type). Derived via CASE on Streams TypeName: Discussion→1, Comment→2, Like→3, Discussion+SharedEntryId→4, other entry types→5. (Tier 2 — Streams_dbo_Entries_Social_Activity_Daily) |
| 2 | ActionDate | datetime | NO | Timestamp when the social action occurred. Passthrough from Streams OccurredAt field (renamed). (Tier 2 — Streams_dbo_Entries_Social_Activity_Daily) |
| 3 | PostID | varchar(300) | YES | Identifier of the root post. For original posts: the entry Id; for comments and likes: the RootId (top-level post); for shares: the SharedEntryId (the shared post). GUID-based string format. (Tier 2 — Streams_dbo_Entries_Social_Activity_Daily) |
| 4 | CommentID | varchar(150) | YES | Identifier of the comment. NULL for posts, likes-on-posts, and shares. For comments: the entry Id. For likes-on-comments: the ParentId (the liked comment). (Tier 2 — Streams_dbo_Entries_Social_Activity_Daily) |
| 5 | Username | varchar(100) | YES | Customer username on the social feed. Derived from Streams Username with leading character stripped via SUBSTRING([Username], 2, 50). Matches Dim_Customer.UserName in lowercase. (Tier 2 — Streams_dbo_Entries_Social_Activity_Daily) |
| 6 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer via Username JOIN. (Tier 1 — Customer.CustomerStatic) |
| 7 | MessageText | nvarchar(max) | YES | Full text content of the social post or comment. Passthrough from Streams MessageBody (renamed). NULL for Likes (ActionTypeID=3) and Shares (ActionTypeID=4). (Tier 2 — Streams_dbo_Entries_Social_Activity_Daily) |
| 8 | MessageSize | int | YES | Character length of the message text. Computed as LEN(MessageBody). NULL for Likes and Shares. (Tier 2 — Streams_dbo_Entries_Social_Activity_Daily) |
| 9 | MessageWordNum | int | YES | Approximate word count of the message text. Computed as LEN(MessageBody) - LEN(REPLACE(MessageBody, ' ', '')) + 1 (space-delimited count). NULL for Likes and Shares. (Tier 2 — Streams_dbo_Entries_Social_Activity_Daily) |
| 10 | ActionDateID | int | YES | Integer date key in YYYYMMDD format. Computed from SP @dt parameter as CAST(CONVERT(varchar, @dt, 112) AS INT). Used as the clustered index lead column and the daily DELETE partition key. (Tier 2 — SP_Social_Activity) |
| 11 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() at insert time. NULL for rows loaded before UpdateDate was added to the SP. (Tier 2 — SP_Social_Activity) |
| 12 | ParentID | varchar(150) | YES | Parent entry identifier in the Streams entry tree. For root posts: equals PostID (self-referencing). For comments: the direct parent entry. For likes/shares: the entry being liked or shared. Passthrough from Streams ParentId (renamed). (Tier 2 — Streams_dbo_Entries_Social_Activity_Daily) |
| 13 | SubTypeName | varchar(50) | YES | Original Streams entry type name. Values: Discussion, CloseTrade, CopyCloseTrade, OpenOrder, OpenTrade, StartCopyTrader, StopCopyTrader, Comment, Like. Passthrough from Streams TypeName (renamed). (Tier 2 — Streams_dbo_Entries_Social_Activity_Daily) |
| 14 | MediaTypeID | int | YES | Rich media attachment type. Passthrough from Streams RichMediaScrapDataType (renamed). Mostly NULL; observed values include 5 and 6. (Tier 2 — Streams_dbo_Entries_Social_Activity_Daily) |
| 15 | ActionID | bigint | NO | Auto-generated surrogate primary key. IDENTITY(1,1). Monotonically increasing across all inserts. Not related to ActionTypeID or BI_DB_Social_Activity_Type.ActionID. (Tier 2 — SP_Social_Activity) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| ActionTypeID | Streams.dbo.Entries | TypeName | CASE mapping to 1-5 |
| ActionDate | Streams.dbo.Entries | OccurredAt | Renamed |
| PostID | Streams.dbo.Entries | Id / RootId / SharedEntryId | Varies by action type |
| CommentID | Streams.dbo.Entries | Id / ParentId | Varies by action type; NULL for non-comment actions |
| Username | Streams.dbo.Entries | Username | SUBSTRING(Username, 2, 50) |
| RealCID | Customer.CustomerStatic | CID | Dim-lookup via Dim_Customer on Username |
| MessageText | Streams.dbo.Entries | MessageBody | Renamed; NULL for likes/shares |
| MessageSize | Streams.dbo.Entries | MessageBody | LEN(MessageBody) |
| MessageWordNum | Streams.dbo.Entries | MessageBody | Space-count word estimation |
| ActionDateID | SP parameter | @dt | CAST(CONVERT(varchar, @dt, 112) AS INT) |
| UpdateDate | SP runtime | — | GETDATE() |
| ParentID | Streams.dbo.Entries | ParentId | Renamed |
| SubTypeName | Streams.dbo.Entries | TypeName | Renamed |
| MediaTypeID | Streams.dbo.Entries | RichMediaScrapDataType | Renamed |
| ActionID | Synapse | — | IDENTITY(1,1) |

### 5.2 ETL Pipeline

```
Streams microservice (social feed entries)
  |-- SP_Create_External_Streams_dbo_Entries_Range(@dt, @dt, 'BI_DB_dbo.Streams_dbo_Entries_Social_Activity_Daily')
  v
BI_DB_dbo.Streams_dbo_Entries_Social_Activity_Daily (external table, date-scoped)
  |-- SP_Social_Activity(@dt)
  |   1. DELETE WHERE ActionDateID = @DateID
  |   2. SELECT into #Entries (Id, OccurredAt, Username, MessageBody, TypeName, RootId, ParentId, SharedEntryId, RichMediaScrapDataType)
  |   3. Build #Dim_Customer (RealCID, LOWER(UserName)) from DWH_dbo.Dim_Customer
  |   4. INSERT Posts (ActionTypeID=1/5): WHERE TypeName IN (Discussion, CloseTrade, ...) AND RootId=ParentId=Id
  |   5. INSERT Comments (ActionTypeID=2): WHERE TypeName='Comment'
  |   6. INSERT Likes on Posts (ActionTypeID=3): WHERE TypeName='Like' AND RootId=ParentId
  |   7. INSERT Likes on Comments (ActionTypeID=3): WHERE TypeName='Like' AND RootId<>ParentId
  |   8. INSERT Shares (ActionTypeID=4): WHERE TypeName='Discussion' AND SharedEntryId IS NOT NULL
  v
BI_DB_dbo.BI_DB_Social_Activity (~1.27B rows)
  |-- Generic Pipeline (Append, daily, parquet)
  v
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity (UC Gold)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| ActionTypeID | BI_DB_dbo.BI_DB_Social_Activity_Type | Resolves action type ID to name (Post, Comment, Like, Share, Automatic Post) |
| RealCID | DWH_dbo.Dim_Customer | Customer identity — demographics, regulation, country |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Relationship | Description |
|-------------------|-------------|-------------|
| SP_UsersEngagement | Reads | User engagement metrics aggregation |
| SP_Reg_UK_Compliance_SocialActivity | Reads | UK regulatory compliance social activity reporting |
| SP_Reg_UK_Compliance_SocialActivityM | Reads | UK regulatory compliance social activity monthly |
| SP_CorpDevDashboard | Reads | Corporate development dashboard metrics |
| SP_Social_Activity_Updates | Reads | Social activity update tracking |
| SP_Social_Activity_GDRP | Reads | GDPR data deletion/anonymization for social activity |
| BI_DB_Social_Activity_GDRP_PostsComments | Related | GDPR backup for posts and comments |
| BI_DB_Social_Activity_GDRP_LikesOnPosts | Related | GDPR backup for likes on posts |
| BI_DB_Social_Activity_GDRP_LikesOnComments | Related | GDPR backup for likes on comments |

---

## 7. Sample Queries

### 7.1 Daily Post Volume Trend

```sql
SELECT
    ActionDateID,
    COUNT(*) AS total_actions,
    SUM(CASE WHEN ActionTypeID = 1 THEN 1 ELSE 0 END) AS posts,
    SUM(CASE WHEN ActionTypeID = 2 THEN 1 ELSE 0 END) AS comments,
    SUM(CASE WHEN ActionTypeID = 3 THEN 1 ELSE 0 END) AS likes,
    SUM(CASE WHEN ActionTypeID = 4 THEN 1 ELSE 0 END) AS shares,
    SUM(CASE WHEN ActionTypeID = 5 THEN 1 ELSE 0 END) AS auto_posts
FROM BI_DB_dbo.BI_DB_Social_Activity
WHERE ActionDateID BETWEEN 20250101 AND 20250904
GROUP BY ActionDateID
ORDER BY ActionDateID
```

### 7.2 Top Active Users by Post Count

```sql
SELECT TOP 20
    sa.RealCID,
    dc.UserName,
    COUNT(*) AS post_count,
    AVG(sa.MessageWordNum) AS avg_word_count
FROM BI_DB_dbo.BI_DB_Social_Activity sa
JOIN DWH_dbo.Dim_Customer dc ON sa.RealCID = dc.RealCID
WHERE sa.ActionTypeID = 1
  AND sa.ActionDateID >= 20250101
GROUP BY sa.RealCID, dc.UserName
ORDER BY post_count DESC
```

### 7.3 Posts with Most Comments

```sql
SELECT TOP 10
    p.PostID,
    p.Username AS poster,
    p.ActionDate AS post_date,
    LEFT(p.MessageText, 100) AS post_preview,
    COUNT(c.ActionID) AS comment_count
FROM BI_DB_dbo.BI_DB_Social_Activity p
JOIN BI_DB_dbo.BI_DB_Social_Activity c
    ON p.PostID = c.PostID AND c.ActionTypeID = 2
WHERE p.ActionTypeID = 1
  AND p.ActionDateID >= 20250801
GROUP BY p.PostID, p.Username, p.ActionDate, LEFT(p.MessageText, 100)
ORDER BY comment_count DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode — Jira/Confluence scan skipped).

---

*Generated: 2026-04-30 | Phases: 11/14*
*Tiers: 1 T1, 14 T2, 0 T3, 0 T4 | Elements: 15/15, Logic: 5 patterns*
*Object: BI_DB_dbo.BI_DB_Social_Activity | Type: Table (Fact) | Production Source: Streams microservice via SP_Social_Activity*
