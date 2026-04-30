# Trade.ClearGuarenteedSLTP_CIDBlacklist

> Re-enables guaranteed Stop Loss / Take Profit (SLTP) for a specific customer by updating their blacklist record to GuarenteedSLTP=1.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer being un-blacklisted) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ClearGuarenteedSLTP_CIDBlacklist restores a customer's ability to use guaranteed Stop Loss / Take Profit orders. When a customer is blacklisted from guaranteed SLTP (e.g., due to abuse or excessive triggered stops), this procedure reverses that restriction by setting GuarenteedSLTP=1 in the blacklist table.

This procedure is part of a set of three procedures managing the SLTP blacklist: Trade.SetGuarenteedSLTP_CIDBlacklist (adds to blacklist), Trade.GetGuarenteedSLTP_CIDBlacklist (reads blacklist status), and this procedure (clears/restores). The blacklist table Trade.GuarenteedSLTP_CIDBlacklist controls whether a customer can place guaranteed stop-loss or take-profit orders, which carry additional cost to eToro because they guarantee execution at the specified price regardless of slippage/gaps.

Created by Geri Reshef on 2016-11-01 (ticket #41586).

---

## 2. Business Logic

### 2.1 Blacklist Clearance

**What**: Restores guaranteed SLTP capability for a specific customer.

**Columns/Parameters Involved**: `@CID`, `GuarenteedSLTP`, `ModificationDate`

**Rules**:
- Sets GuarenteedSLTP = 1 (enabled/cleared) for the given CID
- Sets ModificationDate = GETDATE() to record when the clearance happened
- Does NOT delete the row - the record is preserved with an audit trail
- If no row exists for the CID, no error is raised (UPDATE affects 0 rows silently)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID (CID) whose guaranteed SLTP restriction is being cleared. Used as the WHERE clause filter on Trade.GuarenteedSLTP_CIDBlacklist. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Trade.GuarenteedSLTP_CIDBlacklist | UPDATE | Updates GuarenteedSLTP=1 and ModificationDate=GETDATE() for the specified CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external - operations/support) | - | EXEC | Called by operations/support staff to re-enable guaranteed SLTP for a customer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ClearGuarenteedSLTP_CIDBlacklist (procedure)
+-- Trade.GuarenteedSLTP_CIDBlacklist (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GuarenteedSLTP_CIDBlacklist | Table | UPDATE - sets GuarenteedSLTP=1 for the given CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none in SSDT) | - | Called externally by operations/support |

Related procedures (same blacklist family):
- Trade.SetGuarenteedSLTP_CIDBlacklist - adds customer to blacklist
- Trade.GetGuarenteedSLTP_CIDBlacklist - reads blacklist status

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No TRY/CATCH | Error handling | Simple UPDATE with no error handling |
| No transaction | Atomicity | Single UPDATE statement - inherently atomic |

---

## 8. Sample Queries

### 8.1 Check if a customer is blacklisted for guaranteed SLTP

```sql
SELECT CID, GuarenteedSLTP, ModificationDate
FROM   Trade.GuarenteedSLTP_CIDBlacklist WITH (NOLOCK)
WHERE  CID = 12345;
```

### 8.2 View all currently blacklisted customers

```sql
SELECT CID, GuarenteedSLTP, ModificationDate
FROM   Trade.GuarenteedSLTP_CIDBlacklist WITH (NOLOCK)
WHERE  GuarenteedSLTP = 0
ORDER BY ModificationDate DESC;
```

### 8.3 Clear guaranteed SLTP blacklist for a customer

```sql
EXEC Trade.ClearGuarenteedSLTP_CIDBlacklist @CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ClearGuarenteedSLTP_CIDBlacklist | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ClearGuarenteedSLTP_CIDBlacklist.sql*
