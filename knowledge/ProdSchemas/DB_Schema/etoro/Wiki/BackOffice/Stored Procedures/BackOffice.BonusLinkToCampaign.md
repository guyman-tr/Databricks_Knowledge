# BackOffice.BonusLinkToCampaign

> Links a bonus type to a campaign by inserting a row into BackOffice.CampaignToBonusType, returning the SQL error code (0 = success).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CampaignID + @BonusTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure creates the association between a marketing campaign (BackOffice.Campaign) and a bonus type (BackOffice.BonusType), establishing what kind of credit customers will receive when they participate in the campaign. The link is stored in BackOffice.CampaignToBonusType with optional XML configuration defining the bonus parameters (amount percentage, minimum deposit threshold, expiry conditions, etc.).

BonusLinkToCampaign is called in two contexts: (1) directly from the BackOffice UI when an administrator manually links a bonus type to an existing campaign, and (2) programmatically from BackOffice.CampaignBunchAdd, which creates multiple campaigns in bulk and calls this procedure for each to associate the standard bonus type.

The companion procedures are BonusLinkToCampaignEdit (updates Configuration for an existing link) and BonusUnLinkFromCampaign (removes the link). A composite PK on (CampaignID, BonusTypeID) prevents duplicate links.

---

## 2. Business Logic

### 2.1 Campaign-BonusType Link Creation

**What**: Inserts a single row into CampaignToBonusType linking a campaign to a bonus type with its configuration.

**Columns/Parameters Involved**: `@CampaignID`, `@BonusTypeID`, `@Configuration`

**Rules**:
- INSERT uses positional VALUES (no named columns) - column order in DDL is (CampaignID, BonusTypeID, Configuration)
- No existence check on CampaignID or BonusTypeID - FK constraints on CampaignToBonusType enforce validity; invalid IDs cause FK violation
- Composite PK (CampaignID, BonusTypeID) prevents duplicate links for the same pair; duplicate INSERT causes PK violation
- Returns @@ERROR (0=success, non-zero=error code) - callers must check RETURN_VALUE
- In production, 89.1% of links use BonusTypeID=7 (Sales Promotion Code Bonus) with XML Configuration defining the promotion parameters

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CampaignID | INTEGER | NO | - | VERIFIED | ID of the campaign to link. Must reference an existing BackOffice.Campaign.CampaignID (FK enforced). The campaign must exist before calling this procedure. |
| 2 | @BonusTypeID | INTEGER | NO | - | VERIFIED | ID of the bonus type to associate with the campaign. Must reference an existing BackOffice.BonusType.BonusTypeID (FK enforced). Dominant value in production is 7 (Sales Promotion Code Bonus). |
| 3 | @Configuration | XML | YES | - | VERIFIED | XML payload defining the bonus parameters for this campaign-type pair. Contains rules like bonus amount percentage, minimum deposit, expiry period. Populated for 99.1% of production rows. Pass NULL for campaigns with no parameterized configuration (rare). |

**Return Value:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | RETURN | INT | NO | - | CODE-BACKED | @@ERROR after INSERT - 0=success, non-zero=SQL error (FK violation if invalid IDs, PK violation if duplicate link). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CampaignID, @BonusTypeID, @Configuration | BackOffice.CampaignToBonusType | WRITER | INSERT target - creates the campaign-bonus link row |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CampaignBunchAdd | @BonusTypeID, @Configuration | Caller | Calls this procedure after creating each campaign in a bulk campaign creation operation |
| BackOffice application layer | - | Caller | Called directly when manually linking a bonus type to a campaign in the BackOffice UI |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.BonusLinkToCampaign (procedure)
+-- BackOffice.CampaignToBonusType (table) [INSERT target; PK and FK constraints enforced]
    |- BackOffice.Campaign (FK on CampaignID)
    |- BackOffice.BonusType (FK on BonusTypeID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CampaignToBonusType | Table | INSERT target; composite PK and FKs enforced |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CampaignBunchAdd | Procedure | Calls to link each newly created campaign to a bonus type |
| BackOffice application layer | External | Calls for manual campaign-bonus linking |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row-count messages |
| Composite PK (on table) | Uniqueness | (CampaignID, BonusTypeID) must be unique - duplicate call causes PK violation |
| FK on CampaignID (on table) | Referential Integrity | @CampaignID must reference an existing BackOffice.Campaign |
| FK on BonusTypeID (on table) | Referential Integrity | @BonusTypeID must reference an existing BackOffice.BonusType |
| RETURN @@ERROR | Design | Returns SQL error code (not row count). 0=success. |

---

## 8. Sample Queries

### 8.1 Link a bonus type to a campaign with configuration

```sql
DECLARE @config XML = N'<BonusConfig><Percentage>25</Percentage><MinDeposit>200</MinDeposit><ExpiryDays>30</ExpiryDays></BonusConfig>'
DECLARE @rc INT
EXEC @rc = BackOffice.BonusLinkToCampaign
    @CampaignID = 5001,
    @BonusTypeID = 7,       -- 7 = Sales Promotion Code Bonus (most common)
    @Configuration = @config
IF @rc <> 0
    PRINT 'Link failed with error: ' + CAST(@rc AS VARCHAR)
```

### 8.2 Link without configuration (rare)

```sql
EXEC BackOffice.BonusLinkToCampaign
    @CampaignID = 5001,
    @BonusTypeID = 13,      -- 13 = Satisfaction Bonus
    @Configuration = NULL
```

### 8.3 Check what bonus types are linked to a campaign

```sql
SELECT
    c.CampaignID,
    c.Name AS CampaignName,
    bt.Name AS BonusTypeName,
    cb.Configuration
FROM BackOffice.CampaignToBonusType cb WITH (NOLOCK)
JOIN BackOffice.Campaign c WITH (NOLOCK) ON c.CampaignID = cb.CampaignID
JOIN BackOffice.BonusType bt WITH (NOLOCK) ON bt.BonusTypeID = cb.BonusTypeID
WHERE cb.CampaignID = 5001
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9/10, Logic: 9/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.BonusLinkToCampaign | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.BonusLinkToCampaign.sql*
