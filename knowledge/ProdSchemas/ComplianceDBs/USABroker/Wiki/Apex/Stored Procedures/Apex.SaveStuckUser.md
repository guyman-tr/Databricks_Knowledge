# Apex.SaveStuckUser

> Marks a stuck user's ApexData record as needing sync (UpdatedSync=1), used to flag accounts identified by GetStuckUsers for re-processing by the trading platform sync.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates ApexData.UpdatedSync |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Apex.SaveStuckUser sets the UpdatedSync flag to 1 (true) for a specific customer's ApexData record. This is the remediation action taken after GetStuckUsers identifies accounts stuck in processing. By setting UpdatedSync=1, the trading platform's sync process will pick up this account on its next cycle and attempt to re-synchronize the data.

---

## 2. Business Logic

No complex business logic. Single UPDATE setting UpdatedSync=1 for the specified GCID.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID of the stuck user to flag for re-sync. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Apex.ApexData | Write | Updates UpdatedSync flag |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.SaveStuckUser (procedure)
└── Apex.ApexData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Apex.ApexData | Table | Updates UpdatedSync by GCID |

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

### 8.1 Flag a stuck user for re-sync

```sql
EXEC Apex.SaveStuckUser @GCID = 12345;
```

### 8.2 Remediate multiple stuck users

```sql
-- After running GetStuckUsers, iterate results:
EXEC Apex.SaveStuckUser @GCID = 12345;
EXEC Apex.SaveStuckUser @GCID = 67890;
```

### 8.3 Verify the flag was set

```sql
EXEC Apex.SaveStuckUser @GCID = 12345;
SELECT GCID, UpdatedSync FROM Apex.ApexData WITH (NOLOCK) WHERE GCID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.SaveStuckUser | Type: Stored Procedure | Source: USABroker/Apex/Stored Procedures/Apex.SaveStuckUser.sql*
