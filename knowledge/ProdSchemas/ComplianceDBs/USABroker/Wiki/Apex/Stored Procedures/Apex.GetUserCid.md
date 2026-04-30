# Apex.GetUserCid

> Retrieves the platform Customer ID (CID) for a customer by their Global Customer ID (GCID), providing the GCID-to-CID mapping from UserData.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Apex.GetUserCid retrieves the platform's Customer ID (CID) from the UserData table for a given GCID. CID and GCID are separate identifier systems - this procedure bridges between them. Used when the Apex integration needs to reference the customer in the broader platform's user management system.

---

## 2. Business Logic

No complex business logic. Simple SELECT CID FROM UserData WHERE GCID = @GCID.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID to look up. |

**Returns**: CID (int) from Apex.UserData.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Apex.UserData | Read | Retrieves CID by GCID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.GetUserCid (procedure)
└── Apex.UserData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Apex.UserData | Table | Read CID by GCID |

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

### 8.1 Get CID for a customer

```sql
EXEC Apex.GetUserCid @GCID = 19533157;
-- Returns CID = 19245008
```

### 8.2 Verify GCID-CID mapping

```sql
EXEC Apex.GetUserCid @GCID = 22055177;
-- Returns CID = 21771749
```

### 8.3 Check if GCID exists in UserData

```sql
EXEC Apex.GetUserCid @GCID = 999999;
-- Empty result if GCID not found
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.GetUserCid | Type: Stored Procedure | Source: USABroker/Apex/Stored Procedures/Apex.GetUserCid.sql*
