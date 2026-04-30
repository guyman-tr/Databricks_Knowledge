# UserAttribution.GetFunnelToAttributeMapping

> Returns all rows from UserAttribution.FunnelToAttribute, providing the complete funnel-to-attribute mapping table to callers.

| Property | Value |
|----------|-------|
| **Schema** | UserAttribution |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

UserAttribution.GetFunnelToAttributeMapping is a simple read-all procedure that returns the complete set of funnel-to-attribute mappings. It is typically called by the application layer at startup or on configuration refresh to cache the mapping in memory, avoiding repeated table hits per-user during registration processing.

Since UserAttribution.FunnelToAttribute is a relatively small configuration table, returning all rows is the efficient pattern — the caller applies its own filtering by FunnelID.

---

## 2. Business Logic

No complex business logic. SELECT * FROM UserAttribution.FunnelToAttribute with NOLOCK hint.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|

No input parameters.

Output: FunnelID, AttributeID (and system-versioning period columns) for all rows in UserAttribution.FunnelToAttribute.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | UserAttribution.FunnelToAttribute | SELECT FROM | Returns all current mapping rows |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by application layer for configuration loading.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
UserAttribution.GetFunnelToAttributeMapping (procedure)
  +-- UserAttribution.FunnelToAttribute (table)
        +-- Dictionary.Attribute (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| UserAttribution.FunnelToAttribute | Table | SELECT FROM |

### 6.2 Objects That Depend On This

No dependents found in SQL layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all mappings
```sql
EXEC UserAttribution.GetFunnelToAttributeMapping
```

### 8.2 Direct equivalent query
```sql
SELECT FunnelID, AttributeID FROM UserAttribution.FunnelToAttribute WITH (NOLOCK)
ORDER BY FunnelID, AttributeID
```

### 8.3 Count attributes per funnel (after loading all mappings)
```sql
DECLARE @Mappings TABLE (FunnelID INT, AttributeID INT)
INSERT INTO @Mappings EXEC UserAttribution.GetFunnelToAttributeMapping
SELECT FunnelID, COUNT(*) AS AttributeCount FROM @Mappings GROUP BY FunnelID ORDER BY AttributeCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: UserAttribution.GetFunnelToAttributeMapping | Type: Stored Procedure | Source: UserApiDB/UserApiDB/UserAttribution/Stored Procedures/UserAttribution.GetFunnelToAttributeMapping.sql*
