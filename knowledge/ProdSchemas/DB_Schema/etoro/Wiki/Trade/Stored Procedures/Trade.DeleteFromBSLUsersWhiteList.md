# Trade.DeleteFromBSLUsersWhiteList

> Removes a customer from the BSL (Best Execution/Smart Execution) whitelist and archives the deleted record to History in a single atomic OUTPUT operation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer to remove from BSL whitelist) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DeleteFromBSLUsersWhiteList removes a customer from the Trade.BSLUsersWhiteList table, which controls which customers are eligible for BSL (Best Execution/Smart Execution) routing. BSL is a trade execution optimization system that routes orders to the most favorable execution venue. Customers on the whitelist receive BSL treatment; removing them reverts to standard execution routing.

This procedure exists to provide a clean delete-with-archive in a single statement. The DELETE...OUTPUT INTO pattern simultaneously removes the row from Trade and inserts the CID and DateInserted into History.BSLUsersWhiteList, creating an audit trail of when customers were added/removed from BSL eligibility.

Data flow: The caller provides a CID. The DELETE removes the row from Trade.BSLUsersWhiteList and in the same statement OUTPUTs the deleted CID and DateInserted into History.BSLUsersWhiteList. This is called from the application layer via TradingUserRepository.cs in trading-shared.

---

## 2. Business Logic

### 2.1 Atomic Delete-and-Archive

**What**: Single-statement delete with OUTPUT captures the removed record for audit.

**Columns/Parameters Involved**: `@CID`, `CID`, `DateInserted`

**Rules**:
- DELETE...OUTPUT DELETED.CID, DELETED.DateInserted INTO History.BSLUsersWhiteList
- No separate SELECT or MERGE needed - the OUTPUT clause handles archival
- If the CID doesn't exist, zero rows affected (no error raised)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | Customer identifier to remove from the BSL whitelist. The deleted record (CID + DateInserted) is automatically archived to History.BSLUsersWhiteList. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Trade.BSLUsersWhiteList | DELETER | Removes the row matching this CID |
| (OUTPUT) | History.BSLUsersWhiteList | WRITER | Archives deleted CID and DateInserted via OUTPUT INTO |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| TradingUserRepository.cs | SqlCommand | Application Caller | Called from trading-shared to remove customers from BSL eligibility (Source: trading-shared) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteFromBSLUsersWhiteList (procedure)
+-- Trade.BSLUsersWhiteList (table)
+-- History.BSLUsersWhiteList (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.BSLUsersWhiteList | Table | DELETE target |
| History.BSLUsersWhiteList | Table | Archive target via OUTPUT INTO |

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

### 8.1 Remove a customer from BSL whitelist

```sql
EXEC Trade.DeleteFromBSLUsersWhiteList @CID = 12345
```

### 8.2 Check current BSL whitelist

```sql
SELECT  CID, DateInserted
FROM    Trade.BSLUsersWhiteList WITH (NOLOCK)
ORDER BY DateInserted DESC
```

### 8.3 Check BSL removal history

```sql
SELECT  TOP 10 CID, DateInserted
FROM    History.BSLUsersWhiteList WITH (NOLOCK)
ORDER BY DateInserted DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 1 files | Corrections: 0 applied*
*Object: Trade.DeleteFromBSLUsersWhiteList | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteFromBSLUsersWhiteList.sql*
