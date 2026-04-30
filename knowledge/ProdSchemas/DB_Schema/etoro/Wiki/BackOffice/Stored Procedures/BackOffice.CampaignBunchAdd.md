# BackOffice.CampaignBunchAdd

> Creates N campaigns in a single atomic transaction, each with a unique auto-generated Code and immediately linked to the specified BonusType, returning the newly created campaign rows.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CampaignGroupID + @BunchSize |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the bulk campaign creation path. Where CampaignAdd creates a single campaign, CampaignBunchAdd creates @BunchSize campaigns in one operation - all with identical settings (same group, dates, limits, description) but each with a unique auto-generated code. After creating each campaign, it immediately calls BonusLinkToCampaign to link the bonus type, so all campaigns are fully configured when the transaction commits.

The primary use case is generating batches of unique promotional codes for distribution to customers or partners - for example, creating 1,000 unique single-use referral codes that each grant the same deposit bonus. Each campaign gets a unique Code that a customer would enter at registration.

The code generation uses a longer pattern than CampaignAdd: optional @CampaignPrefix (up to 7 chars) + GenerateRandomString(8,4) + GenerateRandomString(2,4). Code collisions (extremely rare) are handled by re-looping without incrementing the counter. All campaigns are created under a single transaction - if any campaign fails (except collision skips), the entire batch rolls back.

---

## 2. Business Logic

### 2.1 Date Validation (Same as CampaignAdd)

**What**: Same three date guards as CampaignAdd prevent invalid campaigns.

**Rules**:
- @StartDate >= @EndDate -> RAISERROR(60024) "start date later than end date"
- DATEDIFF(min, GETDATE(), @EndDate) < 60 -> RAISERROR(60024) "end date less than NOW"
- DATEDIFF(min, @StartDate, @EndDate) < 30 -> RAISERROR(60024) "difference less than 30 minutes"
- @IsActive auto-set: StartDate < GETDATE() -> 1 (immediate), else 0 (scheduled)

### 2.2 WHILE Loop Campaign Creation with Collision Avoidance

**What**: Creates exactly @BunchSize campaigns, retrying on code collision without counting the failed attempt.

**Rules**:
- WHILE @i <= @BunchSize loop (counter @i starts at 1)
- Per iteration: generate Code = ISNULL(@CampaignPrefix,'') + GenerateRandomString(8,4) + GenerateRandomString(2,4)
- IF NOT EXISTS (SELECT FROM Campaign WHERE Code = @Code): INSERT + call BonusLinkToCampaign + increment @i
- IF EXISTS (collision): do NOT increment @i - retry the loop with a new generated code
- This means the loop always produces exactly @BunchSize campaigns (no short-counts due to collisions)
- All INSERTs are within BEGIN TRAN / COMMIT (TRY block) - all-or-nothing atomicity

### 2.3 BonusLinkToCampaign Called Per Campaign

**What**: Each newly created campaign is immediately linked to the specified BonusType.

**Rules**:
- EXEC BackOffice.BonusLinkToCampaign @CampaignID, @BonusTypeID, @Configuration after each INSERT
- All @BunchSize campaigns share the same BonusTypeID and Configuration
- If BonusLinkToCampaign fails, the CATCH block triggers ROLLBACK of the entire batch

### 2.4 Result Set: Newly Created Campaigns

**What**: Returns the just-created campaigns for caller verification.

**Rules**:
- SELECT TOP (@BunchSize) * FROM BackOffice.Campaign ORDER BY CampaignID DESC
- Returns all columns from BackOffice.Campaign for the @BunchSize most recently created campaigns
- The ordering by CampaignID DESC ensures the newly created campaigns are at the top

### 2.5 Error Handling (TRY/CATCH)

**Rules**:
- IF @@TRANCOUNT = 1: ROLLBACK (outermost transaction - rolls back entire batch)
- IF @@TRANCOUNT > 1: COMMIT (nested context - commits outer; inner error propagated)
- EXEC Internal.CallRaiseError - re-raises the original error for caller visibility
- MaxBonusAmount: same cents-to-MONEY conversion as CampaignAdd (CAST AS MONEY /100)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CampaignGroupID | INT | NO | - | VERIFIED | Campaign group all created campaigns belong to. All @BunchSize campaigns share this grouping. |
| 2 | @BunchSize | INT | NO | - | VERIFIED | Number of campaigns to create. The loop creates exactly this many campaigns. |
| 3 | @MaxNumberOfUsers | INT | NO | - | VERIFIED | User cap applied identically to all created campaigns. |
| 4 | @MaxBonusAmount | INT | NO | - | VERIFIED | Bonus pool cap in cents for each campaign. Stored as CAST AS MONEY /100 (e.g., 5000000 cents = $50,000.00). Applied identically to all created campaigns. |
| 5 | @StartDate | DATETIME | NO | - | VERIFIED | Start date applied to all campaigns. Must pass same 3 date guards as CampaignAdd. |
| 6 | @EndDate | DATETIME | NO | - | VERIFIED | End date applied to all campaigns. |
| 7 | @Description | VARCHAR(255) | NO | - | VERIFIED | Internal description applied to all campaigns. |
| 8 | @ExtendedCampaignProperties | XML | YES | - | CODE-BACKED | Optional XML extended properties applied to all campaigns. |
| 9 | @BonusTypeID | INT | NO | - | VERIFIED | BonusType to link to each campaign via BonusLinkToCampaign after each INSERT. All campaigns get the same bonus type. |
| 10 | @Configuration | XML | YES | - | VERIFIED | Bonus configuration XML passed to BonusLinkToCampaign for each campaign. Defines bonus parameters (amount, conditions, expiry). |
| 11 | @ManagerID | INT | NO | - | CODE-BACKED | Creating manager - stored as CreatedBy in each campaign. |
| 12 | @CreatedOn | DATETIME | NO | - | CODE-BACKED | Creation timestamp - stored in each campaign's CreatedOn field. |
| 13 | @CampaignPrefix | VARCHAR(7) | YES | NULL | CODE-BACKED | Optional prefix prepended to the auto-generated code for each campaign (e.g., "SPRING"). Max 7 chars. Generates code: prefix + GenerateRandomString(8,4) + GenerateRandomString(2,4). |

**Result Set:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 14 | (all Campaign columns) | Various | - | - | CODE-BACKED | SELECT TOP (@BunchSize) * FROM BackOffice.Campaign ORDER BY CampaignID DESC - returns the newly created campaign rows. All columns from BackOffice.Campaign are returned. |

**Return Value:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 15 | RETURN | INT | NO | - | CODE-BACKED | 0=success, 60024=date validation failure, error code from Internal.CallRaiseError on unexpected error. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CampaignGroupID | BackOffice.Campaign | WRITER | INSERT target - creates @BunchSize campaign records |
| @CampaignID, @BonusTypeID, @Configuration | BackOffice.BonusLinkToCampaign | Caller | Called per campaign to link the bonus type immediately after INSERT |
| (code generation) | Internal.GenerateRandomString | Function call | Generates unique code segments for each campaign |
| (error handling) | Internal.CallRaiseError | System call | Re-raises caught errors in CATCH block |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application layer | - | Caller | Called when bulk generating promotional campaign codes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CampaignBunchAdd (procedure)
|- Internal.GenerateRandomString (function) [generates unique codes]
|- BackOffice.Campaign (table) [INSERT target]
|- BackOffice.BonusLinkToCampaign (procedure) [called per campaign to link BonusType]
+-- Internal.CallRaiseError (procedure) [CATCH block error propagation]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GenerateRandomString | Function (cross-schema) | Generates code segments for each campaign |
| BackOffice.Campaign | Table | INSERT target; SCOPE_IDENTITY() captures each new CampaignID |
| BackOffice.BonusLinkToCampaign | Procedure | Called after each campaign INSERT to link the BonusType |
| Internal.CallRaiseError | Procedure (cross-schema) | Called in CATCH to re-raise errors |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application layer | External | Calls when bulk generating campaigns for promotional distributions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row-count messages during WHILE loop |
| BEGIN TRAN / TRY/CATCH | Atomicity | All @BunchSize campaigns created atomically - if any fail, entire batch rolls back |
| Collision retry (no-increment) | Design | @i only increments inside IF NOT EXISTS - code collision causes retry without short-counting |
| MaxBonusAmount cents conversion | Data format | Input in cents, stored as MONEY/100 |
| @@TRANCOUNT handling | Nesting | =1: ROLLBACK; >1: COMMIT (nested transaction awareness) |
| Result set ordering | Design | SELECT TOP (@BunchSize) ORDER BY CampaignID DESC ensures newly created campaigns are returned |

---

## 8. Sample Queries

### 8.1 Create 100 promotional campaigns for a referral program

```sql
DECLARE @config XML = N'<BonusConfig><Percentage>25</Percentage><MinDeposit>200</MinDeposit></BonusConfig>'

EXEC BackOffice.CampaignBunchAdd
    @CampaignGroupID = 5,
    @BunchSize = 100,
    @MaxNumberOfUsers = 1,          -- single-use codes
    @MaxBonusAmount = 5000000,      -- $50,000 pool per campaign (in cents)
    @StartDate = '2026-04-01',
    @EndDate   = '2026-06-30',
    @Description = 'Q2 2026 Referral Program',
    @ExtendedCampaignProperties = NULL,
    @BonusTypeID = 7,               -- Sales Promotion Code Bonus
    @Configuration = @config,
    @ManagerID = 742,
    @CreatedOn = GETDATE(),
    @CampaignPrefix = 'REF'         -- codes will be like "REF" + random chars
```

### 8.2 Verify the created batch

```sql
SELECT TOP 10
    CampaignID, Code, IsActive, MaxNumberOfUsers, ParticipatedUsers,
    StartDate, EndDate
FROM BackOffice.Campaign WITH (NOLOCK)
ORDER BY CampaignID DESC
```

### 8.3 Check bonus links for newly created campaigns

```sql
SELECT c.CampaignID, c.Code, bt.Name AS BonusType
FROM BackOffice.Campaign c WITH (NOLOCK)
JOIN BackOffice.CampaignToBonusType cb WITH (NOLOCK) ON cb.CampaignID = c.CampaignID
JOIN BackOffice.BonusType bt WITH (NOLOCK) ON bt.BonusTypeID = cb.BonusTypeID
ORDER BY c.CampaignID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.3/10 (Elements: 9/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CampaignBunchAdd | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CampaignBunchAdd.sql*
