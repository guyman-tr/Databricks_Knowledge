# dbo.GuidListType

> User-defined table type that provides a list of GUIDs for batch lookup operations in stored procedures.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | User Defined Type |
| **Key Identifier** | Table type with a single Guid column |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GuidListType is a table-valued parameter type that holds a list of uniqueidentifier values. It enables stored procedures to accept multiple GUIDs as a single parameter for efficient batch lookups, avoiding repeated single-value calls.

This type exists because the fiat platform uses GUIDs extensively as external-facing identifiers (AccountGuid, CardGuid, CurrencyBalanceGuid, PlatformId). When the application needs to retrieve data for multiple entities at once, it passes a batch of GUIDs through this type rather than making individual calls.

Data flows through this type when the application layer needs to resolve multiple GUIDs to their corresponding records. For example, GetFiatAccountsByAccountGuids accepts a GuidListType to look up multiple accounts in a single database round-trip, and GetProgramTransitionsEligibilityByPlatformIds uses it to find eligibility records by platform IDs.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple container type for batch GUID passing.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Guid | uniqueidentifier | NO | - | CODE-BACKED | A GUID value to include in the batch lookup. Typically represents an AccountGuid, PlatformId, or other external-facing identifier. NOT NULL enforces that every entry in the list is a valid GUID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.GetFiatAccountsByAccountGuids | @AccountGuids parameter | Parameter Type | Accepts batch of account GUIDs for multi-account lookup |
| dbo.GetProgramTransitionsEligibilityByPlatformIds | @PlatformIds parameter | Parameter Type | Accepts batch of platform IDs for eligibility lookup |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.GetFiatAccountsByAccountGuids | Stored Procedure | TVP parameter for batch account lookup by GUID |
| dbo.GetProgramTransitionsEligibilityByPlatformIds | Stored Procedure | TVP parameter for batch eligibility lookup by platform ID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for account lookup
```sql
DECLARE @Guids dbo.GuidListType;
INSERT INTO @Guids (Guid) VALUES ('A1B2C3D4-E5F6-7890-ABCD-EF1234567890');
INSERT INTO @Guids (Guid) VALUES ('B2C3D4E5-F6A7-8901-BCDE-F12345678901');
EXEC dbo.GetFiatAccountsByAccountGuids @AccountGuids = @Guids;
```

### 8.2 Populate from existing query results
```sql
DECLARE @Guids dbo.GuidListType;
INSERT INTO @Guids (Guid)
SELECT AccountGuid FROM dbo.FiatAccount WITH (NOLOCK) WHERE Gcid = 12345;
EXEC dbo.GetFiatAccountsByAccountGuids @AccountGuids = @Guids;
```

### 8.3 Check the type definition
```sql
SELECT c.name AS ColumnName, t.name AS DataType, c.is_nullable
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id
WHERE tt.name = 'GuidListType' AND tt.schema_id = SCHEMA_ID('dbo');
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.GuidListType | Type: User Defined Type | Source: FiatDwhDB/dbo/User Defined Types/dbo.GuidListType.sql*
