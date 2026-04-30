# BackOffice.Campaign

> Marketing bonus campaign registry defining time-bounded promotional campaigns with user and bonus amount caps. Each campaign has a unique Code, linked bonus types, and optional SQL Agent jobs for automated activation/deactivation. Last campaign added 2017 - system appears legacy/frozen.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | CampaignID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No (stored ON [MAIN] filegroup, DATA_COMPRESSION=PAGE) |
| **Indexes** | 4 active (1 clustered PK + 3 NC: CampaignGroupID, unique Code, IsActive) |

---

## 1. Business Meaning

BackOffice.Campaign defines marketing promotion campaigns that grant bonus credits to new or existing customers. A campaign controls: who can use it (unique Code, MaxNumberOfUsers cap), how much bonus is available (MaxBonusAmount cap), when it runs (StartDate/EndDate), and what bonus types are linked to it (via BackOffice.CampaignToBonusType).

Campaigns are the mechanism for eToro's referral and promotional programs - customers register with a campaign Code and receive bonuses defined by the linked BonusTypes. The Code is the public-facing identifier (e.g., "20coupon", "freecopyref") that customers enter at registration.

11,080 campaigns as of 2026-03-17, spanning 2008 to 2017. **No campaigns have been added since May 2017** - the system appears to have been frozen or superseded by an external campaign management system. 632 are still flagged IsActive=1, but many have EndDates in the past (IsActive is not auto-corrected on schedule expiry).

The largest campaign ever was CampaignID=6250 (Code="20coupon", 2012-2015) with 417,929 participants out of a 650,000 user cap and $150,000 maximum bonus pool.

---

## 2. Business Logic

### 2.1 Campaign Creation (Single or Bulk)

**What**: CampaignAdd creates a single campaign; CampaignBunchAdd creates N campaigns in one transaction, each linked to a BonusType.

**Columns Involved**: All columns

**Rules**:
- Date validation: StartDate must be before EndDate; EndDate must be at least 60 minutes from now; duration must be at least 30 minutes.
- IsActive auto-determination at creation: if StartDate < GETDATE() -> IsActive=1 (starts immediately); else IsActive=0 (scheduled start).
- Code: if not provided, auto-generated as Internal.GenerateRandomString(4,3) + Internal.GenerateRandomString(2,3). Must be globally unique (UNIQUE index on Code). varchar(15) max.
- CampaignBunchAdd generates longer codes: optional @CampaignPrefix + Internal.GenerateRandomString(8,4) + Internal.GenerateRandomString(2,4). Skips Code if collision.
- **MaxBonusAmount input is in cents** (integer): stored as CAST(@MaxBonusAmount AS MONEY)/100. A value of 1500000000 (cents) = $15,000,000.00.
- ParticipatedUsers initialized to 0.
- CampaignBunchAdd: wraps all inserts in a single transaction; after each insert, calls BackOffice.BonusLinkToCampaign to link the BonusType.

### 2.2 Campaign Date and Active Status Editing

**What**: CampaignEditActiveTime updates the time window and re-evaluates IsActive.

**Columns Involved**: `StartDate`, `EndDate`, `IsActive`

**Rules**:
- Same date validations as CampaignAdd (must be valid window, EndDate at least 60 min from now, duration at least 60 min).
- IsActive re-evaluated: if NOW is between StartDate and EndDate -> IsActive=1; otherwise IsActive=0.
- If IsActive becomes 0: calls Billing.P_EMail_BackOffice_Campaign_IsActive0 (sends admin notification email).
- Uses GETUTCDATE() (not GETDATE()) for time comparison - campaign times are UTC.

### 2.3 SQL Agent Job Automation

**What**: StartJobID and EndJobID reference SQL Agent jobs that automate campaign lifecycle events.

**Columns Involved**: `StartJobID`, `EndJobID`

**Rules**:
- StartJobID: binary(16) = SQL Agent job_id (matches msdb.dbo.sysjobs.job_id) for the job that activates the campaign at StartDate.
- EndJobID: binary(16) = SQL Agent job_id for the job that deactivates the campaign at EndDate.
- 2,087 campaigns have a StartJobID; 2,316 have an EndJobID. The majority (8,677) have neither (manually managed or pre-date automation).
- CampaignDelete: after deleting the row, checks msdb.dbo.sysjobs for each job and calls msdb.dbo.sp_delete_job to clean up the SQL Agent job.

### 2.4 Campaign Deletion Guards

**What**: A campaign can only be deleted if it has never been used.

**Rules** (CampaignDelete enforcement):
- Blocks delete if CampaignToBonusType has rows for this CampaignID (campaign linked to bonus types).
- Blocks delete if History.Credit OR History.ActiveCreditRecentMemoryBucket has rows for this CampaignID (campaign has issued credits).
- Blocks delete if Customer.Customer has rows with this CampaignID (campaign assigned to customers).
- Only if all three checks pass: DELETE the row, then delete associated SQL Agent jobs.

### 2.5 Campaign Clearing

**What**: CampaignClear unlinks all customers from a campaign (does NOT delete the campaign).

**Rules**:
- UPDATE Customer.Customer SET CampaignID = NULL WHERE CampaignID = @CampaignID.
- Used to disassociate customers before a campaign can be deleted.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows (2026-03-17) | 11,080 |
| IsActive=1 | 632 (5.7%) |
| IsActive=0 | 10,448 (94.3%) |
| Campaigns with CampaignGroupID NULL | 3,385 (30.5%) |
| Unique CampaignGroups | 50 |
| Earliest StartDate | 2008-03-16 |
| Latest StartDate | 2017-05-23 (no new campaigns since) |
| Total ParticipatedUsers (sum) | 558,672 |
| Has StartJobID | 2,087 (18.8%) |
| Has EndJobID | 2,316 (20.9%) |
| Has ExtendedCampaignProperties | 9,105 (82.2%) |
| CurrentBonusAmount populated | 0 (always NULL) |
| MaxBonusAmount range | $0 - $15,000,000 |
| MaxNumberOfUsers range | 0 - 100,000,000 |

**Notable campaigns** (by participation):

| CampaignID | Code | ParticipatedUsers | MaxBonusAmount | IsActive |
|-----------|------|-------------------|----------------|---------|
| 6250 | 20coupon | 417,929 | $15,000,000 | 1 (EndDate 2015) |
| 5498 | freecopyref | 52,223 | $100,000 | 1 (EndDate 2016) |
| 5600 | etorocopy1012 | 14,650 | $3,000 | 0 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CampaignID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-incrementing campaign identifier. Clustered PK. NOT FOR REPLICATION. Referenced by BackOffice.CampaignToBonusType, Customer.Customer.CampaignID, and History.Credit. |
| 2 | CampaignGroupID | int | YES | - | VERIFIED | Campaign group this campaign belongs to. FK (WITH CHECK) to BackOffice.CampaignGroup. NULL for 30.5% of campaigns (older campaigns predating groups, or ungrouped). |
| 3 | Code | varchar(15) | NO | - | VERIFIED | Unique public-facing campaign code. UNIQUE index. The identifier customers enter at registration (e.g., "20coupon", "freecopyref"). Auto-generated if not supplied to CampaignAdd: 6-char random string. CampaignBunchAdd generates longer codes with optional prefix. Case-sensitivity depends on server collation. |
| 4 | MaxNumberOfUsers | int | NO | - | VERIFIED | Maximum number of customers who can use this campaign. When ParticipatedUsers reaches this cap, the campaign is full. Range: 0 (unlimited/test) to 100,000,000. |
| 5 | StartDate | datetime | NO | - | VERIFIED | Campaign activation datetime (UTC per CampaignEditActiveTime). Campaigns with StartDate < NOW at creation time are immediately activated (IsActive=1). SQL Agent job StartJobID automates activation for future-dated campaigns. |
| 6 | EndDate | datetime | NO | - | VERIFIED | Campaign expiry datetime (UTC). Must be at least 60 minutes after StartDate and at least 60 minutes from now at creation/edit time. SQL Agent job EndJobID automates deactivation. Note: IsActive is NOT automatically set to 0 when EndDate passes - many "active" campaigns have past EndDates. |
| 7 | MaxBonusAmount | money | NO | - | VERIFIED | Maximum total bonus pool for this campaign in dollars (stored as money type). **IMPORTANT**: CampaignAdd/CampaignBunchAdd/CampaignEdit receive the value in cents (integer) and store as CAST(@val AS MONEY)/100. So caller passes 1500000000 to store $15,000,000.00. |
| 8 | IsActive | bit | NO | - | VERIFIED | Whether the campaign is currently active and accepting new users. 1=active, 0=inactive. Auto-set at creation based on whether StartDate < NOW. Updated by CampaignEditActiveTime when dates change. NOT automatically updated when EndDate passes. |
| 9 | ParticipatedUsers | int | NO | - | VERIFIED | Count of customers who have used this campaign. Initialized to 0 at creation. Incremented when a customer registers with this campaign Code. When ParticipatedUsers >= MaxNumberOfUsers, the campaign is full. |
| 10 | Description | varchar(255) | YES | - | VERIFIED | Human-readable description of the campaign's purpose or terms. 10,984 of 11,080 campaigns have descriptions. |
| 11 | StartJobID | binary(16) | YES | - | VERIFIED | SQL Server Agent job_id (matches msdb.dbo.sysjobs.job_id) for the job that activates this campaign at StartDate. binary(16) = uniqueidentifier format used by SQL Agent. NULL if no scheduled start job. CampaignDelete removes the job via msdb.dbo.sp_delete_job when the campaign is deleted. |
| 12 | EndJobID | binary(16) | YES | - | VERIFIED | SQL Server Agent job_id for the job that deactivates this campaign at EndDate. NULL if no scheduled end job. CampaignDelete removes it on deletion. |
| 13 | ExtendedCampaignProperties | xml | YES | - | VERIFIED | Flexible XML field for additional campaign configuration not covered by the fixed columns (bonus rules, eligibility criteria, tracking parameters, etc.). 82.2% of campaigns have a value. Structure varies by campaign type. |
| 14 | CreatedOn | datetime | YES | - | VERIFIED | When the campaign was created. Passed explicitly from the application via CampaignAdd/@CreatedOn parameter (not server-side GETDATE()). Populated since 2013 (2013-01-29 earliest). NULL for older campaigns. |
| 15 | CreatedBy | int | YES | - | VERIFIED | ManagerID of the BackOffice manager who created the campaign. FK (WITH CHECK) to BackOffice.Manager. NULL for campaigns created before this field was added. Passed as @ManagerID to CampaignAdd. |
| 16 | CurrentBonusAmount | money | YES | - | VERIFIED | Intended to track current total bonus issued vs. the MaxBonusAmount cap. Always NULL in production (0 populated rows) - not maintained by any current procedure. Appears to be an unused planned feature. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CampaignGroupID | BackOffice.CampaignGroup | FK (WITH CHECK) | Campaign grouping for organization/reporting |
| CreatedBy | BackOffice.Manager | FK (WITH CHECK) | Manager who created the campaign |
| StartJobID | msdb.dbo.sysjobs | Semantic (no FK) | SQL Agent job for automated activation |
| EndJobID | msdb.dbo.sysjobs | Semantic (no FK) | SQL Agent job for automated deactivation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CampaignAdd | CampaignID | WRITER | Creates single campaign |
| BackOffice.CampaignBunchAdd | CampaignID | WRITER (bulk) | Creates N campaigns in one transaction |
| BackOffice.CampaignEdit | CampaignID | MODIFIER | Updates code, cap, bonus amount, description |
| BackOffice.CampaignEditActiveTime | CampaignID | MODIFIER | Updates dates and re-evaluates IsActive |
| BackOffice.CampaignDelete | CampaignID | DELETER | Deletes campaign + SQL Agent jobs (guarded) |
| BackOffice.CampaignClear | CampaignID | READER | Reads CampaignID; writes to Customer.Customer |
| BackOffice.CampaignToBonusType | CampaignID | FK child | Links bonus types to campaigns |
| Customer.Customer | CampaignID | FK child | Customer's assigned campaign |
| History.Credit | CampaignID | FK child | Credits issued under this campaign |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.Campaign (table)
- FK targets: BackOffice.CampaignGroup, BackOffice.Manager
- Referenced by: BackOffice.CampaignToBonusType, Customer.Customer, History.Credit
- SQL Agent: StartJobID/EndJobID -> msdb.dbo.sysjobs (cleaned up on delete)
- Email: CampaignEditActiveTime -> Billing.P_EMail_BackOffice_Campaign_IsActive0
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CampaignGroup | Table | FK on CampaignGroupID |
| BackOffice.Manager | Table | FK on CreatedBy |
| msdb.dbo.sysjobs | System Table | Job existence check and deletion in CampaignDelete |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CampaignToBonusType | Table | CampaignID FK - links bonus types to campaigns |
| BackOffice.CampaignAdd | Procedure | WRITER |
| BackOffice.CampaignBunchAdd | Procedure | WRITER (bulk) |
| BackOffice.CampaignEdit | Procedure | MODIFIER |
| BackOffice.CampaignEditActiveTime | Procedure | MODIFIER |
| BackOffice.CampaignDelete | Procedure | DELETER |
| BackOffice.CampaignClear | Procedure | Reads this table; modifies Customer.Customer |
| Customer.Customer | Table | CampaignID FK - customer's campaign |
| History.Credit | Table | CampaignID reference - credits issued per campaign |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BCMP | CLUSTERED PK | CampaignID ASC | - | - | Active (FILLFACTOR=90, DATA_COMPRESSION=PAGE, ON [MAIN]) |
| BCMP_CAMPAIGNGROUP | NC | CampaignGroupID ASC | - | - | Active (FILLFACTOR=90, DATA_COMPRESSION=PAGE, ON [MAIN]) |
| BCMP_CODE | UNIQUE NC | Code ASC | - | - | Active (FILLFACTOR=90, DATA_COMPRESSION=PAGE, ON [MAIN]) |
| IX_Campaign_IsActive | NC | IsActive ASC | - | - | Active (FILLFACTOR=95, ON [MAIN]) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BCMP | PK | CampaignID uniqueness |
| BCMP_CODE | UNIQUE | Code uniqueness across all campaigns |
| FK_BCMG_BCMP | FK (WITH CHECK) | CampaignGroupID -> BackOffice.CampaignGroup(CampaignGroupID) |
| FK_BackOffice_Campaign_CreatedBy | FK (WITH CHECK) | CreatedBy -> BackOffice.Manager(ManagerID) |

### 7.3 Known Issues

- **IsActive stale for expired campaigns**: IsActive is set at creation and when CampaignEditActiveTime is called, but is NOT automatically set to 0 when EndDate passes. 632 campaigns show IsActive=1 but many have EndDates years in the past.
- **CurrentBonusAmount unused**: The column is always NULL - the intended bonus tracking feature was never implemented or was removed.
- **System frozen since 2017**: No campaigns have been added since May 2017. The system may be replaced by an external platform, with the table kept for historical reference.

---

## 8. Sample Queries

### 8.1 Get currently active campaigns with bonus type details
```sql
SELECT
    c.CampaignID,
    c.Code,
    cg.Name AS GroupName,
    c.MaxNumberOfUsers,
    c.ParticipatedUsers,
    c.MaxBonusAmount,
    c.StartDate,
    c.EndDate
FROM BackOffice.Campaign c WITH (NOLOCK)
LEFT JOIN BackOffice.CampaignGroup cg WITH (NOLOCK) ON cg.CampaignGroupID = c.CampaignGroupID
WHERE c.IsActive = 1
  AND c.EndDate > GETUTCDATE()  -- filter truly active (EndDate not yet passed)
ORDER BY c.ParticipatedUsers DESC
```

### 8.2 Find a campaign by Code
```sql
SELECT
    c.CampaignID,
    c.Code,
    c.IsActive,
    c.StartDate,
    c.EndDate,
    c.MaxNumberOfUsers,
    c.ParticipatedUsers,
    c.MaxBonusAmount
FROM BackOffice.Campaign c WITH (NOLOCK)
WHERE c.Code = 'freecopyref'  -- replace with target code
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9.2/10, Logic: 9.2/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.Campaign | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.Campaign.sql*
