# BackOffice.CampaignEdit

> Updates the editable fields of a marketing campaign (code, user cap, bonus amount, description, extended properties) without touching dates or active status.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CampaignID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure allows BackOffice operators to modify the configurable properties of an existing marketing campaign: its unique code, user cap, maximum bonus pool, description, and extended XML properties. It is the standard edit operation for campaigns that does not touch the date window or active status - those are managed separately by `BackOffice.CampaignEditActiveTime`.

It exists as a single-responsibility update procedure to isolate the "what is this campaign and how much can it give" concerns from the "when is it active" concerns. BackOffice campaign management screens call this to update campaign details without accidentally changing the active status or time window.

Data flows as a single UPDATE on `BackOffice.Campaign` WHERE CampaignID=@CampaignID, returning @@ERROR to the caller.

---

## 2. Business Logic

### 2.1 MaxBonusAmount Unit Conversion

**What**: The input @MaxBonusAmount is provided in cents (integer) but stored as dollars (MONEY) in the database.

**Columns/Parameters Involved**: `@MaxBonusAmount`, `BackOffice.Campaign.MaxBonusAmount`

**Rules**:
- Input: integer cents (e.g., 150000000 cents = $1,500,000.00)
- Stored: `CAST(@MaxBonusAmount AS MONEY) / 100` -> dollars
- This is consistent with CampaignAdd: per BackOffice.Campaign doc, "MaxBonusAmount input is in cents, stored as CAST(@MaxBonusAmount AS MONEY)/100"
- The largest campaign ever had MaxBonusAmount=$150,000.00 (stored value), meaning @MaxBonusAmount input would be 15000000 cents

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CampaignID | INTEGER | NO | - | CODE-BACKED | Campaign identifier. PK of BackOffice.Campaign. Identifies which campaign to update. |
| 2 | @Code | VARCHAR(15) | NO | - | CODE-BACKED | Unique campaign code (the public-facing promo code customers enter at registration). Must be unique across all campaigns (UNIQUE index on Code). Max 15 characters. |
| 3 | @MaxNumberOfUsers | INTEGER | NO | - | CODE-BACKED | Maximum number of users allowed to participate in this campaign. When reached, the campaign code is no longer accepted. |
| 4 | @MaxBonusAmount | INTEGER | NO | - | VERIFIED | Maximum total bonus pool for this campaign, provided in CENTS. Stored as CAST(@MaxBonusAmount AS MONEY)/100 (dollars). Example: 1500000 cents = $15,000.00. |
| 5 | @Description | VARCHAR(255) | NO | - | CODE-BACKED | Human-readable description of the campaign purpose (internal BackOffice use, not customer-facing). Max 255 characters. |
| 6 | @ExtendedCampaignProperties | XML | YES | - | CODE-BACKED | Optional XML blob for additional campaign configuration properties not captured in standard columns. Flexible extension point. |

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 7 | RETURN | INT | Returns @@ERROR: 0 on success, non-zero SQL error number on failure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CampaignID | BackOffice.Campaign | MODIFIER | Updates Code, MaxNumberOfUsers, MaxBonusAmount, Description, ExtendedCampaignProperties |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found. Called directly from BackOffice campaign management UI.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CampaignEdit (procedure)
+-- BackOffice.Campaign (table) [UPDATE target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Campaign | Table | UPDATE: sets Code, MaxNumberOfUsers, MaxBonusAmount, Description, ExtendedCampaignProperties WHERE CampaignID=@CampaignID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice campaign management UI | External | Calls this to update campaign configuration details |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| MaxBonusAmount unit | Application | Input @MaxBonusAmount is in cents; division by 100 converts to dollars before storage |
| Return value | Application | Returns @@ERROR not affected rows - caller must check for non-zero return |
| No date/IsActive update | Design | StartDate, EndDate, IsActive are NOT updated by this procedure; use CampaignEditActiveTime for those |

---

## 8. Sample Queries

### 8.1 Edit a campaign's description and user cap

```sql
EXEC BackOffice.CampaignEdit
    @CampaignID = 1234,
    @Code = 'SUMMER25',
    @MaxNumberOfUsers = 5000,
    @MaxBonusAmount = 2500000, -- $25,000.00 in cents
    @Description = 'Summer 2023 referral promotion',
    @ExtendedCampaignProperties = NULL
```

### 8.2 Verify campaign after edit

```sql
SELECT CampaignID, Code, MaxNumberOfUsers, MaxBonusAmount, Description, IsActive
FROM BackOffice.Campaign WITH (NOLOCK)
WHERE CampaignID = 1234
-- MaxBonusAmount displayed in dollars (stored value)
```

### 8.3 Check the unique Code constraint before editing

```sql
SELECT CampaignID, Code, IsActive
FROM BackOffice.Campaign WITH (NOLOCK)
WHERE Code = 'SUMMER25'
-- Must return no rows (or only the target CampaignID) before updating to this code
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CampaignEdit | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CampaignEdit.sql*
