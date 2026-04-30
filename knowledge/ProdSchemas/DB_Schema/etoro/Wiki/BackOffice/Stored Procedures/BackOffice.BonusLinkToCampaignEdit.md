# BackOffice.BonusLinkToCampaignEdit

> Updates the XML configuration for an existing campaign-bonus type link in BackOffice.CampaignToBonusType, returning the SQL error code (0 = success).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CampaignID + @BonusTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the update path for campaign-bonus type link configuration. When a campaign's bonus parameters need to change (e.g., adjusting the deposit percentage, minimum threshold, or expiry period), this procedure updates the Configuration XML for the specific (CampaignID, BonusTypeID) pairing in BackOffice.CampaignToBonusType.

It is one of three procedures managing the CampaignToBonusType lifecycle: BonusLinkToCampaign (INSERT), BonusLinkToCampaignEdit (UPDATE Configuration), and BonusUnLinkFromCampaign (DELETE). Only the Configuration XML is updatable via this procedure - CampaignID and BonusTypeID are the immutable composite key. To change the bonus type for a campaign, the old link must be deleted (BonusUnLinkFromCampaign) and a new one created (BonusLinkToCampaign).

---

## 2. Business Logic

### 2.1 Campaign-BonusType Configuration Update

**What**: Updates only the Configuration XML for the matching (CampaignID, BonusTypeID) row.

**Columns/Parameters Involved**: `@CampaignID`, `@BonusTypeID`, `@Configuration`

**Rules**:
- WHERE clause targets the exact (CampaignID, BonusTypeID) composite PK - no other rows affected
- Only Configuration is updated - CampaignID and BonusTypeID are identity keys, not changeable
- If the (CampaignID, BonusTypeID) pair does not exist, UPDATE affects 0 rows silently (no error)
- Configuration can be set to NULL (removing parameters from an existing link)
- Returns @@ERROR (0=success, non-zero=SQL error)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CampaignID | INTEGER | NO | - | VERIFIED | CampaignID part of the composite PK to locate the row to update. Must match an existing (CampaignID, BonusTypeID) link; no error if pair not found (0 rows updated). |
| 2 | @BonusTypeID | INTEGER | NO | - | VERIFIED | BonusTypeID part of the composite PK to locate the row to update. Combined with @CampaignID to uniquely identify the link row. |
| 3 | @Configuration | XML | YES | - | VERIFIED | New XML configuration to set for the campaign-bonus pair. Replaces the existing Configuration value. Pass NULL to clear configuration. Typically contains bonus amount rules, minimum deposit, expiry parameters. |

**Return Value:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | RETURN | INT | NO | - | CODE-BACKED | @@ERROR after UPDATE - 0=success, non-zero=SQL error code. Returns 0 even if no row was found (silent no-op). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CampaignID, @BonusTypeID | BackOffice.CampaignToBonusType | MODIFIER | UPDATE target - modifies the Configuration for the matching link row |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application layer | - | Caller | Called when campaign bonus parameters need adjustment without relinking |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.BonusLinkToCampaignEdit (procedure)
+-- BackOffice.CampaignToBonusType (table) [UPDATE target - Configuration column only]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CampaignToBonusType | Table | UPDATE target - Configuration field updated WHERE CampaignID+BonusTypeID match |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application layer | External | Calls to adjust bonus configuration for an existing campaign-bonus link |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row-count messages |
| Single column updated | Design | Only Configuration is updated; CampaignID and BonusTypeID are key-only |
| Silent no-op | Design | If (CampaignID, BonusTypeID) pair not found, UPDATE affects 0 rows with no error |
| RETURN @@ERROR | Design | Returns SQL error code; 0=success |

---

## 8. Sample Queries

### 8.1 Update bonus configuration for a campaign

```sql
DECLARE @config XML = N'<BonusConfig><Percentage>30</Percentage><MinDeposit>500</MinDeposit><ExpiryDays>60</ExpiryDays></BonusConfig>'
DECLARE @rc INT
EXEC @rc = BackOffice.BonusLinkToCampaignEdit
    @CampaignID = 5001,
    @BonusTypeID = 7,
    @Configuration = @config
IF @rc <> 0
    PRINT 'Edit failed with error: ' + CAST(@rc AS VARCHAR)
```

### 8.2 Clear configuration (set to NULL)

```sql
EXEC BackOffice.BonusLinkToCampaignEdit
    @CampaignID = 5001,
    @BonusTypeID = 7,
    @Configuration = NULL
```

### 8.3 Verify the updated configuration

```sql
SELECT CampaignID, BonusTypeID, Configuration
FROM BackOffice.CampaignToBonusType WITH (NOLOCK)
WHERE CampaignID = 5001 AND BonusTypeID = 7
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.BonusLinkToCampaignEdit | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.BonusLinkToCampaignEdit.sql*
