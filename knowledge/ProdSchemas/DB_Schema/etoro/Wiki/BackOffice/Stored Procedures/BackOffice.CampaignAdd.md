# BackOffice.CampaignAdd

> Creates a new marketing campaign in BackOffice.Campaign with date validation, auto-generating the campaign Code if not provided, setting IsActive based on start date, and returning the new CampaignID via OUTPUT parameter.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CampaignID (OUTPUT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the single-campaign creation path for the BackOffice marketing campaign system. It validates campaign timing rules, auto-generates a unique Code if the caller does not provide one, determines whether the campaign should start immediately or be scheduled, and inserts the campaign into BackOffice.Campaign.

After CampaignAdd, callers typically call BonusLinkToCampaign to associate bonus types with the new campaign. For bulk campaign creation (multiple campaigns at once), CampaignBunchAdd is used instead - it calls CampaignAdd's logic internally for each campaign in a batch.

Key business rules:
- Campaigns must have a minimum 30-minute duration
- EndDate must be at least 60 minutes in the future (prevents creating campaigns that are already almost over)
- MaxBonusAmount is passed in cents (integer), stored as MONEY/100 (e.g., 15000000 cents = $150,000.00)
- IsActive is auto-determined: starts immediately (=1) if StartDate < now, else scheduled (=0)

Note: Two parameters are marked deprecated in the code - @CampaignID (OUTPUT) and @IsActive (OUTPUT). Both are still populated but the annotations indicate they may be removed in future versions.

---

## 2. Business Logic

### 2.1 Date Validation (Three Guards)

**What**: Three validation rules prevent logically invalid or expired campaigns from being created.

**Columns/Parameters Involved**: `@StartDate`, `@EndDate`

**Rules**:
- Guard 1: @StartDate >= @EndDate -> RAISERROR(60024) "start date later than end date". RETURN 60024.
- Guard 2: DATEDIFF(minutes, GETDATE(), @EndDate) < 60 -> RAISERROR(60024) "end date less than NOW". Campaign must end at least 60 minutes from now.
- Guard 3: DATEDIFF(minutes, @StartDate, @EndDate) < 30 -> RAISERROR(60024) "difference between start and end less than 30 minutes". Minimum campaign duration is 30 minutes.

### 2.2 Auto-Generated Code

**What**: If no Code is provided, a random alphanumeric code is generated.

**Columns/Parameters Involved**: `@Code`, `Internal.GenerateRandomString`

**Rules**:
- IF ISNULL(@Code,'') = '' -> @Code = Internal.GenerateRandomString(4,3) + Internal.GenerateRandomString(2,3)
- This produces a 6-character code composed of two random string segments
- If generated code collides with an existing Code (UNIQUE index on Campaign.Code), the INSERT fails with a constraint violation
- Callers can provide a specific Code (e.g., "20coupon", "freecopy") up to VARCHAR(15)

### 2.3 IsActive Auto-Determination

**What**: Whether the campaign is immediately active is determined by comparing StartDate to GETDATE().

**Rules**:
- @StartDate < GETDATE() -> @IsActive = 1 (campaign starts immediately - start time already passed)
- @StartDate >= GETDATE() -> @IsActive = 0 (scheduled start - not yet active)

### 2.4 MaxBonusAmount Currency Conversion

**What**: Input amount is in integer cents; stored value is in dollars (MONEY type).

**Rules**:
- CAST(@MaxBonusAmount AS MONEY)/100 - converts from cents to dollar MONEY type
- Example: @MaxBonusAmount=15000000 (cents) -> stored as $150,000.00

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CampaignID | INT OUTPUT | NO | - | VERIFIED | OUTPUT param that receives SCOPE_IDENTITY() of the newly created campaign. Marked as deprecated in code - still populated. |
| 2 | @CampaignGroupID | INT | NO | - | VERIFIED | The campaign group this campaign belongs to. References BackOffice.CampaignGroup.CampaignGroupID (implicit FK). Groups campaigns for reporting and bulk management. |
| 3 | @Code | VARCHAR(15) | YES | NULL | VERIFIED | Optional public-facing campaign code customers use at registration. If NULL or empty, auto-generated as Internal.GenerateRandomString(4,3) + GenerateRandomString(2,3). Must be unique - UNIQUE index on Campaign.Code. |
| 4 | @MaxNumberOfUsers | INT | NO | - | VERIFIED | Maximum number of customers who can participate in this campaign. When ParticipatedUsers reaches this cap, the campaign stops accepting new participants. |
| 5 | @MaxBonusAmount | INT | NO | - | VERIFIED | Maximum total bonus pool for the campaign, in cents. Stored as CAST(@MaxBonusAmount AS MONEY)/100 - e.g., 15000000 cents = $150,000.00. |
| 6 | @StartDate | DATETIME | NO | - | VERIFIED | Campaign start datetime. Must be before @EndDate. If < GETDATE(), campaign activates immediately (@IsActive=1). |
| 7 | @EndDate | DATETIME | NO | - | VERIFIED | Campaign end datetime. Must be >= 60 min from now and >= 30 min after @StartDate. Validation failures raise error 60024. |
| 8 | @Description | VARCHAR(255) | NO | - | VERIFIED | Internal description of the campaign for BackOffice staff identification. Not shown to customers. |
| 9 | @IsActive | BIT OUTPUT | NO | - | CODE-BACKED | OUTPUT param that receives the auto-determined active status (1=immediate, 0=scheduled). Marked as deprecated in code - still populated. |
| 10 | @ExtendedCampaignProperties | XML | YES | - | CODE-BACKED | Optional XML payload for extended campaign configuration. Stored in BackOffice.Campaign.ExtendedCampaignProperties. |
| 11 | @ManagerID | INT | NO | - | CODE-BACKED | BackOffice manager creating this campaign. Stored as CreatedBy in BackOffice.Campaign for audit trail. |
| 12 | @CreatedOn | DATETIME | NO | - | CODE-BACKED | Creation timestamp. Stored in BackOffice.Campaign.CreatedOn. Caller provides this (not GETDATE() internally). |

**Return Value:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 13 | RETURN | INT | NO | - | CODE-BACKED | 0=success, 60024=date validation failure, 60000=unexpected INSERT error. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Code (generated) | Internal.GenerateRandomString | Function call | Generates random code segments if @Code not provided |
| All params | BackOffice.Campaign | WRITER | INSERT target - creates the campaign record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CampaignBunchAdd | Campaign creation | Caller | Uses the same creation logic to create batches of campaigns |
| BackOffice application layer | - | Caller | Direct campaign creation via BackOffice UI |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CampaignAdd (procedure)
|- Internal.GenerateRandomString (function) [auto-generate Code if not provided]
+-- BackOffice.Campaign (table) [INSERT target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GenerateRandomString | Function (cross-schema) | Generates random Code segments when @Code not supplied |
| BackOffice.Campaign | Table | INSERT target; SCOPE_IDENTITY() captures new CampaignID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CampaignBunchAdd | Procedure | Calls for each campaign in bulk creation batch |
| BackOffice application layer | External | Calls for individual campaign creation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row-count messages |
| Date validation (3 guards) | Business rule | RAISERROR(60024) for invalid date ranges. MinDuration=30min, EndDate>=60min from now. |
| MaxBonusAmount cents | Data format | Input in cents, stored /100 as MONEY. Callers must multiply dollar amounts by 100. |
| @IsActive auto-set | Business rule | StartDate < GETDATE() = immediate activation; else scheduled |
| UNIQUE on Campaign.Code | Uniqueness | Auto-generated codes can theoretically collide (rare, causes INSERT failure) |
| Deprecated params | Design note | @CampaignID OUTPUT and @IsActive OUTPUT are marked deprecated in code comments |

---

## 8. Sample Queries

### 8.1 Create a new campaign with auto-generated code

```sql
DECLARE @campaignId INT, @isActive BIT
EXEC BackOffice.CampaignAdd
    @CampaignID = @campaignId OUTPUT,
    @CampaignGroupID = 1,
    @Code = NULL,               -- auto-generated
    @MaxNumberOfUsers = 1000,
    @MaxBonusAmount = 5000000,  -- $50,000 (in cents)
    @StartDate = '2026-04-01',
    @EndDate   = '2026-06-30',
    @Description = 'Spring 2026 Deposit Promotion',
    @IsActive = @isActive OUTPUT,
    @ExtendedCampaignProperties = NULL,
    @ManagerID = 742,
    @CreatedOn = GETDATE()
SELECT @campaignId AS NewCampaignID, @isActive AS IsActive
```

### 8.2 Verify the new campaign

```sql
SELECT CampaignID, Code, IsActive, StartDate, EndDate,
       MaxBonusAmount, MaxNumberOfUsers, ParticipatedUsers
FROM BackOffice.Campaign WITH (NOLOCK)
WHERE CampaignID = @campaignId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CampaignAdd | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CampaignAdd.sql*
