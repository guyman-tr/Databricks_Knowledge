# BackOffice.BonusUnLinkFromCampaign

> Removes the link between a bonus type and a campaign from BackOffice.CampaignToBonusType, returning the SQL error code (0 = success).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CampaignID + @BonusTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure removes a campaign-bonus type association from BackOffice.CampaignToBonusType. It is used when a bonus type should no longer be available under a specific campaign - for example, when a promotional program ends and the campaign should stop offering that bonus to new participants, or when a bonus type is being replaced with a different type under the same campaign.

It is the DELETE path in the three-procedure lifecycle for CampaignToBonusType: BonusLinkToCampaign (INSERT), BonusLinkToCampaignEdit (UPDATE), and BonusUnLinkFromCampaign (DELETE). Note that CampaignDelete also checks CampaignToBonusType before deleting a campaign - the campaign cannot be deleted if this table still has rows for it, so BonusUnLinkFromCampaign must be called for each linked bonus type before CampaignDelete can succeed.

---

## 2. Business Logic

### 2.1 Campaign-BonusType Link Removal

**What**: Deletes the row matching (CampaignID, BonusTypeID) from CampaignToBonusType.

**Columns/Parameters Involved**: `@CampaignID`, `@BonusTypeID`

**Rules**:
- DELETE by exact composite PK match (CampaignID AND BonusTypeID) - only the specific link is removed
- If the (CampaignID, BonusTypeID) pair does not exist, DELETE affects 0 rows silently (no error)
- Returns @@ERROR (0=success, non-zero=SQL error)
- No cascade effects on historical data (already-issued bonuses under this type/campaign are in BackOffice.Bonus and are NOT affected)
- CampaignDelete guards against deleting campaigns that still have rows in CampaignToBonusType - call BonusUnLinkFromCampaign for each link before CampaignDelete

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CampaignID | INTEGER | NO | - | VERIFIED | CampaignID part of the composite PK identifying the link to remove. No error if the pair is not found (0 rows deleted). |
| 2 | @BonusTypeID | INTEGER | NO | - | VERIFIED | BonusTypeID part of the composite PK identifying the link to remove. Together with @CampaignID, uniquely identifies the CampaignToBonusType row to delete. |

**Return Value:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | RETURN | INT | NO | - | CODE-BACKED | @@ERROR after DELETE - 0=success, non-zero=SQL error code. Returns 0 even if no row was found (silent no-op). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CampaignID, @BonusTypeID | BackOffice.CampaignToBonusType | DELETER | DELETE target - removes the matching campaign-bonus link row |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application layer | - | Caller | Called to remove a bonus type from a campaign, or to clear all links before deleting the campaign |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.BonusUnLinkFromCampaign (procedure)
+-- BackOffice.CampaignToBonusType (table) [DELETE target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CampaignToBonusType | Table | DELETE target - removes the link row WHERE CampaignID+BonusTypeID match |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application layer | External | Must call for each linked bonus type before CampaignDelete can succeed (CampaignDelete guards against rows in CampaignToBonusType) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row-count messages |
| Silent no-op | Design | If (CampaignID, BonusTypeID) not found, DELETE affects 0 rows with no error |
| Historical data intact | Design | Deleting the link does not affect already-issued bonuses (BackOffice.Bonus rows remain) |
| CampaignDelete dependency | Design | CampaignDelete will fail if CampaignToBonusType still has rows for the campaign - must call this first for each link |
| RETURN @@ERROR | Design | Returns SQL error code; 0=success |

---

## 8. Sample Queries

### 8.1 Remove a bonus type from a campaign

```sql
DECLARE @rc INT
EXEC @rc = BackOffice.BonusUnLinkFromCampaign
    @CampaignID = 5001,
    @BonusTypeID = 7
IF @rc <> 0
    PRINT 'Unlink failed with error: ' + CAST(@rc AS VARCHAR)
```

### 8.2 Remove all bonus types from a campaign (to enable CampaignDelete)

```sql
-- First, identify all linked bonus types
SELECT BonusTypeID FROM BackOffice.CampaignToBonusType WITH (NOLOCK)
WHERE CampaignID = 5001

-- Then call BonusUnLinkFromCampaign for each BonusTypeID
EXEC BackOffice.BonusUnLinkFromCampaign @CampaignID = 5001, @BonusTypeID = 7
-- (repeat for each linked type)
-- Now CampaignDelete can proceed
```

### 8.3 Confirm removal

```sql
SELECT COUNT(*) AS LinksRemaining
FROM BackOffice.CampaignToBonusType WITH (NOLOCK)
WHERE CampaignID = 5001
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.BonusUnLinkFromCampaign | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.BonusUnLinkFromCampaign.sql*
