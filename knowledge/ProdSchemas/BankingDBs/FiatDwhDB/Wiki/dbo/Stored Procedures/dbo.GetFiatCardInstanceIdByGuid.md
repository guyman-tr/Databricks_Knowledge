# dbo.GetFiatCardInstanceIdByGuid

> Simple lookup that retrieves a card instance Id by its CardInstanceGuid. Returns TOP 1 Id only.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT TOP 1 Id from FiatCardInstances WHERE CardInstanceGuid = @CardInstanceGuid |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetFiatCardInstanceIdByGuid resolves a CardInstanceGuid to its internal Id. Returns only the Id (not full record). Uses TOP 1 as a safety measure since CardInstanceGuid may not have a unique constraint.

---

## 2. Business Logic

No complex logic. Simple GUID-to-Id resolution.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CardInstanceGuid | uniqueidentifier | NO | - | CODE-BACKED | The card instance GUID to resolve. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.FiatCardInstances | Read | GUID-to-Id resolution |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetFiatCardInstanceIdByGuid (procedure)
└── dbo.FiatCardInstances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatCardInstances | Table | SELECT source |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Resolve GUID to Id
```sql
EXEC dbo.GetFiatCardInstanceIdByGuid @CardInstanceGuid = 'A1B2C3D4-0000-0000-0000-000000000001';
```

### 8.2 Equivalent query
```sql
SELECT TOP 1 Id FROM dbo.FiatCardInstances WITH (NOLOCK) WHERE CardInstanceGuid = 'A1B2C3D4-0000-0000-0000-000000000001';
```

### 8.3 Use result for card status lookup
```sql
DECLARE @instanceId bigint;
DECLARE @r TABLE (Id bigint);
INSERT INTO @r EXEC dbo.GetFiatCardInstanceIdByGuid @CardInstanceGuid = 'A1B2C3D4-0000-0000-0000-000000000001';
SET @instanceId = (SELECT Id FROM @r);
SELECT * FROM dbo.FiatCardStatuses WITH (NOLOCK) WHERE CardInstanceId = @instanceId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.GetFiatCardInstanceIdByGuid | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.GetFiatCardInstanceIdByGuid.sql*
