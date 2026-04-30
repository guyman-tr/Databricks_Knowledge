# UserAttribution.FunnelToAttribute

> Mapping table linking registration funnels to user attributes. System-versioned (temporal) with history tracked in History.FunnelToAttribute.

| Property | Value |
|----------|-------|
| **Schema** | UserAttribution |
| **Object Type** | Table |
| **Key Identifier** | FunnelID + AttributeID (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

UserAttribution.FunnelToAttribute defines which user attributes should be automatically assigned when a user registers through a specific funnel. A "funnel" represents a registration pathway (e.g., referral campaign, partner landing page, app store install) and each funnel can map to one or more attributes that should be tagged on users who entered via that route.

This table enables automated attribution: when a new user registers, the system looks up the funnel they came through, finds the corresponding attributes in this table, and applies them to the user's profile in UserAttribution.UserAttributes. The table is system-versioned, meaning all changes are tracked over time in History.FunnelToAttribute for audit purposes.

---

## 2. Business Logic

### 2.1 Funnel-to-Attribute Mapping

**What**: Defines the attribution rules applied at registration.

**Columns/Parameters Involved**: `FunnelID`, `AttributeID`

**Rules**:
- Composite PK (FunnelID, AttributeID) ensures each funnel-attribute pair is unique
- One funnel can map to multiple attributes (multiple rows per FunnelID)
- One attribute can be assigned by multiple funnels (multiple rows per AttributeID)
- AttributeID has an explicit FK to Dictionary.Attribute

### 2.2 System Versioning

**What**: Temporal tracking of mapping changes.

**Rules**:
- Table is SYSTEM_VERSIONED = ON
- Changes (INSERT/UPDATE/DELETE) are automatically recorded to History.FunnelToAttribute
- Enables point-in-time queries: what did the funnel-attribute mapping look like on a given date?

---

## 3. Data Overview

N/A - configuration/mapping table; row count depends on active funnels.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FunnelID | int | NO | - | CODE-BACKED | Part of composite PK. Identifies the registration funnel (e.g., campaign, partner, channel). No FK — funnel definitions live in an external system or application layer. |
| 2 | AttributeID | int | NO | - | CODE-BACKED | Part of composite PK. FK to Dictionary.Attribute. The attribute to assign to users registering via this funnel. |
| 3 | SysStartTime | datetime2 | NO | - | CODE-BACKED | System-versioning period start. Managed by SQL Server; records when this row version became active. |
| 4 | SysEndTime | datetime2 | NO | - | CODE-BACKED | System-versioning period end. Managed by SQL Server; records when this row version ended (9999 = currently active). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AttributeID | Dictionary.Attribute | Explicit FK | The attribute definition being mapped |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.FunnelToAttribute | FunnelID, AttributeID | System versioning | Temporal history of mapping changes |
| UserAttribution.GetFunnelToAttributeMapping | - | SP reads | Returns all current mappings |
| UserAttribution.SetUserAttribute | FunnelID | Lookup source | Used upstream to determine which attributes to apply |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
UserAttribution.FunnelToAttribute (table)
  +-- Dictionary.Attribute (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Attribute | Table | FK: AttributeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.FunnelToAttribute | Table | System-versioned history |
| UserAttribution.GetFunnelToAttributeMapping | Stored Procedure | Reads all mappings |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FunnelToAttribute | CLUSTERED PK | FunnelID, AttributeID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_FTA_AttributeID | FOREIGN KEY | AttributeID -> Dictionary.Attribute |
| PERIOD FOR SYSTEM_TIME | System versioning | SysStartTime, SysEndTime managed by SQL Server |

---

## 8. Sample Queries

### 8.1 View all current funnel-attribute mappings
```sql
SELECT fta.FunnelID, fta.AttributeID, a.Name AS AttributeName
FROM UserAttribution.FunnelToAttribute fta WITH (NOLOCK)
JOIN Dictionary.Attribute a WITH (NOLOCK) ON fta.AttributeID = a.AttributeID
ORDER BY fta.FunnelID
```

### 8.2 Find all attributes for a specific funnel
```sql
SELECT fta.AttributeID, a.Name AS AttributeName
FROM UserAttribution.FunnelToAttribute fta WITH (NOLOCK)
JOIN Dictionary.Attribute a WITH (NOLOCK) ON fta.AttributeID = a.AttributeID
WHERE fta.FunnelID = @FunnelID
```

### 8.3 Point-in-time query (what was the mapping last month?)
```sql
SELECT FunnelID, AttributeID
FROM UserAttribution.FunnelToAttribute FOR SYSTEM_TIME AS OF '2026-03-01'
WHERE FunnelID = @FunnelID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: UserAttribution.FunnelToAttribute | Type: Table | Source: UserApiDB/UserApiDB/UserAttribution/Tables/UserAttribution.FunnelToAttribute.sql*
