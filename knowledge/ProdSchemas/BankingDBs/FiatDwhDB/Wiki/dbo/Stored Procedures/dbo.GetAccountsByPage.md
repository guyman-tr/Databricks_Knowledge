# dbo.GetAccountsByPage

> Paginated account listing procedure using cursor-based pagination (Id > @Next) with configurable page size.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT TOP(@Limit) from FiatAccount WHERE Id > @Next ORDER BY Id |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetAccountsByPage retrieves a page of fiat accounts using cursor-based (keyset) pagination. The caller provides the last seen Id (@Next) and desired page size (@Limit). Returns accounts with Id > @Next ordered by Id ascending, using WITH(NOLOCK) for non-blocking reads.

Note: The DDL has a minor formatting issue where AccountProgramId and SubProgramId columns are merged due to a missing comma, but this doesn't affect runtime since they resolve to a single aliased column.

---

## 2. Business Logic

### 2.1 Cursor-Based Pagination

**Rules**:
- @Next = 0 for first page
- Uses TOP(@Limit) + WHERE Id > @Next + ORDER BY Id for efficient keyset pagination
- WITH(NOLOCK) for non-blocking reads
- More efficient than OFFSET/FETCH for large datasets

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Next | bigint | NO | - | CODE-BACKED | Last seen Id from previous page. Use 0 for first page. |
| 2 | @Limit | int | NO | - | CODE-BACKED | Maximum number of rows to return per page. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.FiatAccount | Read | Paginated read |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAccountsByPage (procedure)
└── dbo.FiatAccount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatAccount | Table | SELECT source |

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

### 8.1 Get first page of 100 accounts
```sql
EXEC dbo.GetAccountsByPage @Next = 0, @Limit = 100;
```

### 8.2 Get next page (using last Id from previous result)
```sql
EXEC dbo.GetAccountsByPage @Next = 2135556, @Limit = 100;
```

### 8.3 Equivalent direct query
```sql
SELECT TOP (100) Id, Gcid, AccountGuid, Created, AccountProgramId, SubProgramId
FROM dbo.FiatAccount WITH (NOLOCK) WHERE Id > 0 ORDER BY Id ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.GetAccountsByPage | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.GetAccountsByPage.sql*
