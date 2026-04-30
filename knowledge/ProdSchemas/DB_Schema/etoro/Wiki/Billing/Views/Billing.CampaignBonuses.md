# Billing.CampaignBonuses

> Real-time view of currently available marketing campaign bonuses, filtered to active campaigns that have started, not yet expired, and still have participant capacity remaining.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | View |
| **Key Identifier** | (CampaignID, BonusTypeID) - one row per active campaign-bonus pairing |
| **Partition** | N/A |
| **Indexes** | N/A for view |

---

## 1. Business Meaning

`Billing.CampaignBonuses` provides a live snapshot of which bonus types are currently available for customer enrollment - the answer to "what bonuses can I offer this customer right now?" It joins campaign definitions with their associated bonus type configurations, applying time-window and capacity filters to return only campaigns that are open for new participants.

The view exists to isolate bonus eligibility logic from the consuming code. Without it, every bonus-issuance flow would need to replicate the same five-condition WHERE clause (active flag, start date, end date, capacity check, bonus type active). Centralizing this in a view ensures consistent eligibility rules across all callers and makes it easy to see "what's live now" at a glance.

Data flows from three BackOffice tables: `BackOffice.Campaign` (campaign metadata and capacity tracking), `BackOffice.CampaignToBonusType` (many-to-many mapping of campaigns to bonus types with per-campaign configuration), and `BackOffice.BonusType` (bonus type definitions and default configurations). The view is time-dependent - its result set changes as campaigns open and close. Currently returns 0 rows, indicating no active campaigns are running at this moment.

---

## 2. Business Logic

### 2.1 Active Campaign Eligibility Filter

**What**: Five conditions must ALL be true for a campaign-bonus combination to appear in this view.

**Columns/Parameters Involved**: `IsActive` (Campaign + BonusType), `StartDate`, `EndDate`, `MaxNumberOfUsers`, `ParticipatedUsers`

**Rules**:
- `BCMP.IsActive = 1`: Campaign must be marked as administratively active
- `BCMP.StartDate < GETDATE()`: Campaign must have already started (uses server time - rows vanish if clock crosses midnight into a new day before campaign start)
- `BCMP.EndDate > GETDATE()`: Campaign must not have expired yet
- `BCMP.MaxNumberOfUsers > BCMP.ParticipatedUsers`: Capacity not yet exhausted - at least one slot remains
- `BBNT.IsActive = 1`: The bonus type itself must be active (prevents defunct bonus types from appearing even if linked to an active campaign)

**Diagram**:
```
BackOffice.Campaign row visible in this view only when:
  IsActive = 1 (admin-enabled)
  AND StartDate < NOW < EndDate (within time window)
  AND ParticipatedUsers < MaxNumberOfUsers (has capacity)
  AND linked BonusType.IsActive = 1 (bonus type active)

 --> When EndDate passes or capacity fills up, the row disappears automatically
```

### 2.2 Per-Campaign Bonus Configuration Override

**What**: Each campaign-bonus pairing can carry its own configuration JSON, overriding the bonus type's default configuration. The view surfaces both.

**Columns/Parameters Involved**: `DefaultConfiguration`, `Configuration`

**Rules**:
- `DefaultConfiguration`: The bonus type's base configuration from `BackOffice.BonusType.Configuration` - applies to all campaigns using this bonus type unless overridden
- `Configuration`: The per-campaign override from `BackOffice.CampaignToBonusType.Configuration` - campaign-specific parameters (e.g., bonus amount, percentage, conditions)
- Consumers are expected to prefer `Configuration` over `DefaultConfiguration` when the former is non-null

### 2.3 MaxBonusAmount Unit Conversion

**What**: The `MaxBonusAmount` from BackOffice.Campaign is stored as a decimal (e.g., 100.00 USD) but is surfaced in this view as an integer in cents (e.g., 10000).

**Columns/Parameters Involved**: `MaxBonusAmount`

**Rules**:
- DDL: `CAST(BCMP.MaxBonusAmount * 100 AS INTEGER) AS MaxBonusAmount`
- The multiplication by 100 converts the dollar/euro amount to minor units (cents)
- Consumers of this view receive MaxBonusAmount in minor currency units, consistent with the fee columns in Billing.ConversionFee and Billing.ConversionFeeOverride

---

## 3. Data Overview

The view currently returns 0 rows - no active campaigns are running at this time. This is expected behavior as the view is time-dependent (filters to StartDate < NOW < EndDate with capacity available). The view's result set changes dynamically as campaigns open and close.

A representative row when campaigns are active would look like:

| CampaignID | Code | MaxNumberOfUsers | MaxBonusAmount | ParticipatedUsers | BonusTypeID | IsWithdrawable | Meaning |
|---|---|---|---|---|---|---|---|
| 501 | WELCOME100 | 5000 | 10000 (=$100) | 3247 | 7 | 1 | A welcome-bonus campaign ("WELCOME100") offering $100 (stored as 10000 cents) to new depositors. 3247 of 5000 slots used; 1753 remaining. BonusTypeID=7, IsWithdrawable=1 means the bonus can be withdrawn once trading conditions are met. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CampaignID | int | NO | - | CODE-BACKED | Unique identifier of the active campaign. From BackOffice.Campaign.CampaignID. Used to group all bonus types associated with one marketing campaign and to track enrollment (ParticipatedUsers). References BackOffice.Campaign. |
| 2 | Code | varchar/nvarchar | YES | - | CODE-BACKED | Human-readable campaign code (e.g., "WELCOME100", "SUMMER2024"). From BackOffice.Campaign.Code. Used by the application layer to reference campaigns by name rather than by numeric ID. May be presented to customers or used in promotional materials. |
| 3 | MaxNumberOfUsers | int | NO | - | CODE-BACKED | Maximum number of customers who can participate in this campaign. From BackOffice.Campaign.MaxNumberOfUsers. The view only returns rows where MaxNumberOfUsers > ParticipatedUsers (capacity check). When this limit is reached, the campaign disappears from the view. |
| 4 | StartDate | datetime | NO | - | CODE-BACKED | UTC (or server-local) datetime when the campaign opens for enrollment. From BackOffice.Campaign.StartDate. The view filters StartDate < GETDATE(), so campaigns whose start date is in the future are hidden. |
| 5 | EndDate | datetime | NO | - | CODE-BACKED | UTC (or server-local) datetime when the campaign closes. From BackOffice.Campaign.EndDate. The view filters EndDate > GETDATE(), so expired campaigns are hidden. When a campaign expires, its rows vanish automatically from this view. |
| 6 | MaxBonusAmount | int | NO | - | CODE-BACKED | Maximum bonus amount per participant, in minor currency units (cents). Computed in view: CAST(BackOffice.Campaign.MaxBonusAmount * 100 AS INTEGER). E.g., $100 bonus -> 10000. The multiplication by 100 converts the stored dollar/euro decimal to cents for consistency with Billing fee columns. |
| 7 | ParticipatedUsers | int | NO | - | CODE-BACKED | Current count of users who have already enrolled in this campaign. From BackOffice.Campaign.ParticipatedUsers. Must be less than MaxNumberOfUsers for the row to appear in this view. Incremented when a new user is enrolled via the campaign bonus flow. |
| 8 | Description | nvarchar | YES | - | CODE-BACKED | Human-readable campaign description. From BackOffice.Campaign.Description. Provides campaign context for admin UIs and reporting. Not used in eligibility logic. |
| 9 | BonusTypeID | int | NO | - | CODE-BACKED | Identifier of the bonus type associated with this campaign via CampaignToBonusType. From BackOffice.BonusType.BonusTypeID. Multiple bonus types can be linked to one campaign; each produces a separate row in this view. References BackOffice.BonusType for type definitions and Default Configuration. |
| 10 | ParentID | int | YES | - | CODE-BACKED | Parent bonus type ID from BackOffice.BonusType.ParentID. Supports hierarchical bonus type structures (child bonus type inheriting from a parent). NULL for top-level bonus types. |
| 11 | DefaultConfiguration | nvarchar/varchar | YES | - | CODE-BACKED | JSON or structured configuration string from BackOffice.BonusType.Configuration. The global default parameters for this bonus type. Aliased as DefaultConfiguration to distinguish from the per-campaign Configuration override (Element 13). |
| 12 | IsWithdrawable | bit | NO | - | CODE-BACKED | From BackOffice.BonusType.IsWithdrawable. 1=the bonus amount can be withdrawn by the customer once any required trading conditions are met. 0=bonus is non-withdrawable (e.g., credit that expires or can only be used for trading). Critical for customer communications and compliance. |
| 13 | Configuration | nvarchar/varchar | YES | - | CODE-BACKED | Per-campaign override configuration from BackOffice.CampaignToBonusType.Configuration. When non-null, these campaign-specific parameters take precedence over DefaultConfiguration (Element 11). Stores bonus amount, conditions, or other campaign-specific rules in a structured format. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CampaignID | BackOffice.Campaign | Source (FROM + WHERE filter) | Campaign definitions, capacity tracking, and time window; filtered to currently active campaigns |
| BonusTypeID | BackOffice.BonusType | Source (FROM + WHERE IsActive=1) | Bonus type definitions and default configuration; filtered to active types only |
| CampaignID + BonusTypeID | BackOffice.CampaignToBonusType | Source (FROM + JOIN) | Junction table linking campaigns to their bonus types with per-campaign configuration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No stored procedures in Billing schema reference this view | - | - | Likely consumed by application-layer bonus issuance flows or BackOffice admin interfaces |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CampaignBonuses (view)
├── BackOffice.Campaign (table, cross-schema)
├── BackOffice.CampaignToBonusType (table, cross-schema)
└── BackOffice.BonusType (table, cross-schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Campaign | Table | FROM source: provides campaign metadata, time window, capacity fields; filtered to IsActive=1 + date window + capacity |
| BackOffice.CampaignToBonusType | Table | FROM source (implicit join): maps campaigns to bonus types, provides per-campaign Configuration override |
| BackOffice.BonusType | Table | FROM source: provides bonus type metadata (BonusTypeID, ParentID, DefaultConfiguration, IsWithdrawable); filtered to IsActive=1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No code-level dependents discovered in Billing schema | - | Available for application-layer bonus eligibility checks |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. No SCHEMABINDING (cross-schema view). Uses implicit CROSS JOIN syntax (comma-separated FROM with WHERE-based JOIN conditions, not ANSI JOIN syntax). Note: the view is time-sensitive - its result changes dynamically as GETDATE() advances.

---

## 8. Sample Queries

### 8.1 View all currently available campaign bonuses

```sql
-- Returns 0 rows when no campaigns are active; result changes in real time
SELECT CampaignID, Code, BonusTypeID, MaxBonusAmount, ParticipatedUsers, MaxNumberOfUsers,
       StartDate, EndDate, IsWithdrawable
FROM Billing.CampaignBonuses WITH (NOLOCK)
ORDER BY CampaignID, BonusTypeID
```

### 8.2 Find campaigns still with capacity by slot availability

```sql
SELECT CampaignID, Code, MaxNumberOfUsers, ParticipatedUsers,
       (MaxNumberOfUsers - ParticipatedUsers) AS SlotsRemaining,
       EndDate
FROM Billing.CampaignBonuses WITH (NOLOCK)
ORDER BY SlotsRemaining DESC
```

### 8.3 Get effective configuration for a specific campaign-bonus combination

```sql
-- Configuration column overrides DefaultConfiguration when non-null
SELECT CampaignID, Code, BonusTypeID,
       ISNULL(Configuration, DefaultConfiguration) AS EffectiveConfiguration,
       MaxBonusAmount, IsWithdrawable
FROM Billing.CampaignBonuses WITH (NOLOCK)
WHERE CampaignID = @CampaignID
  AND BonusTypeID = @BonusTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CampaignBonuses | Type: View | Source: etoro/etoro/Billing/Views/Billing.CampaignBonuses.sql*
