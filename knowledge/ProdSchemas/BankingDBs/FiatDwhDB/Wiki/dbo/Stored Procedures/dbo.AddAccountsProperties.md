# dbo.AddAccountsProperties

> Inserts a new account property snapshot recording a change to an account's program and sub-program assignment.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Simple INSERT into FiatAccountsProperties |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddAccountsProperties records a new account property snapshot when a customer's program or sub-program assignment changes. It performs a simple INSERT into dbo.FiatAccountsProperties, capturing the AccountId, AccountProgramId, SubProgramId, and timestamp. This is called by the operational system whenever a program transition occurs.

This procedure exists to maintain the event-sourced history of account program assignments. Each call creates a new row, preserving the full history of changes. The latest row for an AccountId represents the current program assignment.

Called by the operational system when a customer's sub-program changes (upgrade, downgrade, or migration).

---

## 2. Business Logic

No complex business logic. Simple INSERT with no conditional logic, deduplication, or transformation.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AccountId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatAccount.Id. The account whose program assignment changed. |
| 2 | @AccountProgramId | tinyint | NO | - | CODE-BACKED | New account program: 1=card, 2=iban. See [Account Program](../../_glossary.md#account-program). |
| 3 | @SubProgramId | tinyint | NO | - | CODE-BACKED | New sub-program: 1-16. See [Sub-Program](../../_glossary.md#sub-program). |
| 4 | @Created | datetime2(7) | NO | - | CODE-BACKED | Timestamp of the program change event. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AccountId | dbo.FiatAccount | FK | Target account |
| INSERT target | dbo.FiatAccountsProperties | Write | Inserts property record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddAccountsProperties (procedure)
└── dbo.FiatAccountsProperties (table)
    └── dbo.FiatAccount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatAccountsProperties | Table | INSERT target |

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

### 8.1 Call the procedure
```sql
EXEC dbo.AddAccountsProperties @AccountId = 2135575, @AccountProgramId = 2, @SubProgramId = 6, @Created = '2026-04-14T13:51:23';
```

### 8.2 Verify the insertion
```sql
SELECT TOP 1 * FROM dbo.FiatAccountsProperties WITH (NOLOCK) WHERE AccountId = 2135575 ORDER BY Created DESC;
```

### 8.3 Check program change history for an account
```sql
SELECT AccountProgramId, SubProgramId, Created
FROM dbo.FiatAccountsProperties WITH (NOLOCK)
WHERE AccountId = 2135575 ORDER BY Created;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddAccountsProperties | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddAccountsProperties.sql*
