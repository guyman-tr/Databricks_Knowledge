# dbo.GetFiatAccountsByAccountGuids

> Batch lookup procedure that retrieves multiple fiat accounts by a list of AccountGuids passed via the GuidListType TVP.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT from FiatAccount INNER JOIN GuidListType TVP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetFiatAccountsByAccountGuids retrieves multiple fiat accounts by joining against a TVP of GUIDs. Copies TVP to temp table for performance, then INNER JOINs FiatAccount on AccountGuid. Uses WITH(NOLOCK). Enables efficient batch resolution of GUIDs to account records.

---

## 2. Business Logic

### 2.1 TVP-Based Batch Lookup

**Rules**:
- Copies GuidListType TVP to #AccountGuids temp table for performance
- INNER JOIN FiatAccount.AccountGuid = #AccountGuids.Guid
- Returns Id, Gcid, AccountGuid, Created for all matching accounts

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AccountGuids | dbo.GuidListType | NO | READONLY | CODE-BACKED | TVP containing list of AccountGuids to look up. See dbo.GuidListType. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT/JOIN | dbo.FiatAccount | Read | Batch GUID lookup |
| @param | dbo.GuidListType | Type | TVP parameter type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetFiatAccountsByAccountGuids (procedure)
├── dbo.FiatAccount (table)
└── dbo.GuidListType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatAccount | Table | JOIN source |
| dbo.GuidListType | UDT | TVP parameter type |

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

### 8.1 Batch lookup
```sql
DECLARE @guids dbo.GuidListType;
INSERT INTO @guids VALUES ('8C3984A1-CF81-4534-A907-5D81F2362D90'), ('12AAA44B-D136-4EB1-A537-BAB85D7B2229');
EXEC dbo.GetFiatAccountsByAccountGuids @AccountGuids = @guids;
```

### 8.2 Single GUID lookup via TVP
```sql
DECLARE @guids dbo.GuidListType;
INSERT INTO @guids VALUES ('8C3984A1-CF81-4534-A907-5D81F2362D90');
EXEC dbo.GetFiatAccountsByAccountGuids @AccountGuids = @guids;
```

### 8.3 Equivalent direct query
```sql
SELECT Id, Gcid, AccountGuid, Created FROM dbo.FiatAccount WITH (NOLOCK)
WHERE AccountGuid IN ('8C3984A1-CF81-4534-A907-5D81F2362D90', '12AAA44B-D136-4EB1-A537-BAB85D7B2229');
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.GetFiatAccountsByAccountGuids | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.GetFiatAccountsByAccountGuids.sql*
