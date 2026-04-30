# dbo.GetAccountByAccountGuid

> Simple lookup procedure that retrieves a fiat account record by its external GUID.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT from FiatAccount WHERE AccountGuid = @AccountGuid |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetAccountByAccountGuid retrieves a fiat account record by its external-facing AccountGuid. Returns Id, Gcid, AccountGuid, and Created. Used by the application layer when it has the GUID but needs the internal Id for subsequent operations.

---

## 2. Business Logic

No complex logic. Simple single-row SELECT by unique GUID.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AccountGuid | uniqueidentifier | NO | - | CODE-BACKED | The external GUID to look up. Uses IX_FiatAccount_AccountGuid index. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.FiatAccount | Read | Lookup target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAccountByAccountGuid (procedure)
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

### 8.1 Look up an account
```sql
EXEC dbo.GetAccountByAccountGuid @AccountGuid = '8C3984A1-CF81-4534-A907-5D81F2362D90';
```

### 8.2 Use in application flow
```sql
DECLARE @result TABLE (Id bigint, Gcid bigint, AccountGuid uniqueidentifier, Created datetime2);
INSERT INTO @result EXEC dbo.GetAccountByAccountGuid @AccountGuid = '8C3984A1-CF81-4534-A907-5D81F2362D90';
SELECT * FROM @result;
```

### 8.3 Equivalent direct query
```sql
SELECT Id, Gcid, AccountGuid, Created FROM dbo.FiatAccount WITH (NOLOCK)
WHERE AccountGuid = '8C3984A1-CF81-4534-A907-5D81F2362D90';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.GetAccountByAccountGuid | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.GetAccountByAccountGuid.sql*
