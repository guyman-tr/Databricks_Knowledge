# Trade.BSLUsersWhiteList

> Registry of customer accounts exempt from BSL (Bonus Stop Loss) margin call checks, protecting specific customers from automated liquidation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 (PK + 2 NC) |

---

## 1. Business Meaning

This table contains customers who are **exempt** from BSL (Bonus Stop Loss) margin call liquidation. When the BSL check runs (`Trade.InsertBSLMessagesIntoQueue`), it LEFT JOINs to this table and **excludes** any customer with a matching CID - their positions will not be liquidated even if equity falls below the threshold.

Whitelisting serves several business purposes: protecting customers during known system issues, exempting institutional accounts, honoring compliance decisions, or temporarily shielding customers during migration or dispute resolution. Each entry is linked to a CreditID, connecting the exemption to the financial event that warranted it.

Entries are added by `Trade.InsertIntoBSLUsersWhiteList` (with dedup check - only inserts if CID not already present) and removed by `Trade.DeleteFromBSLUsersWhiteList`. The table is actively used with ~9M+ entries, making it a high-volume component of the BSL system.

---

## 2. Business Logic

### 2.1 BSL Exemption via LEFT JOIN Exclusion

**What**: Whitelisted customers are excluded from BSL checks by a LEFT JOIN + IS NULL pattern.

**Columns/Parameters Involved**: `CID`

**Rules**:
- `InsertBSLMessagesIntoQueue` performs: `LEFT OUTER JOIN Trade.BSLUsersWhiteList WL ON TPOS.CID = WL.CID` then `WHERE WL.CID IS NULL`
- This means any customer with a row here is SKIPPED entirely - no warning, no liquidation
- The exemption is per-customer, not per-position
- Deduplication: `InsertIntoBSLUsersWhiteList` checks `IF NOT EXISTS` before inserting

### 2.2 Credit-Linked Exemption

**What**: Each whitelist entry is tied to a specific credit transaction.

**Columns/Parameters Involved**: `CID`, `CreditID`

**Rules**:
- CreditID links to the credit/financial event that triggered the whitelist entry
- Default CreditID = 0 when no specific credit is associated
- This allows auditing: which financial event caused the exemption

---

## 3. Data Overview

| CID | DateInserted | ID | CreditID | Meaning |
|-----|-------------|-----|----------|---------|
| 24984780 | 2026-03-14 15:07 | 9147655 | 2174671983 | Recently whitelisted customer - linked to a specific credit transaction, exempt from BSL liquidation |
| 25441106 | 2026-03-14 14:42 | 9147654 | 2174671982 | Another recent exemption - the high ID sequence suggests continuous automated whitelisting activity |
| 25441086 | 2026-03-14 14:41 | 9147651 | 2174671979 | Active whitelisting with CIDs in the 25M range - current customer accounts being protected |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer identifier exempt from BSL checks. Implicit FK to Customer.CustomerStatic. Checked via LEFT JOIN + IS NULL in BSL procedure. |
| 2 | DateInserted | datetime | NO | GETUTCDATE() | CODE-BACKED | UTC timestamp when the exemption was created. Auto-populated by DEFAULT constraint. Used for auditing when the whitelist entry was added. |
| 3 | ID | int IDENTITY(1,1) NOT FOR REPLICATION | NO | - | CODE-BACKED | Auto-generated surrogate key. NOT FOR REPLICATION prevents reseeding during database replication. |
| 4 | CreditID | bigint | NO | 0 | CODE-BACKED | Credit transaction ID that triggered this whitelist entry. Links to the financial event warranting the exemption. Default 0 when no specific credit is associated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit FK | Customer exempt from BSL liquidation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertBSLMessagesIntoQueue | CID | READER (LEFT JOIN exclusion) | BSL check procedure - skips whitelisted customers |
| Trade.InsertIntoBSLUsersWhiteList | CID | WRITER | Adds customer to whitelist with dedup check |
| Trade.DeleteFromBSLUsersWhiteList | CID | DELETER | Removes customer from whitelist |
| Trade.GetUsersFromBSLTables | CID | READER | Reports on BSL table contents |
| Trade.IsAccountInLiquidationWhitelist | CID | READER | Checks if a specific account is whitelisted |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertBSLMessagesIntoQueue | Stored Procedure | READER - LEFT JOIN exclusion in BSL check |
| Trade.InsertIntoBSLUsersWhiteList | Stored Procedure | WRITER - adds CID with dedup |
| Trade.DeleteFromBSLUsersWhiteList | Stored Procedure | DELETER - removes CID |
| Trade.IsAccountInLiquidationWhitelist | Stored Procedure | READER - existence check |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradeBSLUsersWhiteList | CLUSTERED PK | ID ASC | - | - | Active (FILLFACTOR=95) |
| IDX_TradeBSLUsersWhiteList_CID_CreditID | NC | CID ASC, CreditID ASC | - | - | Active (FILLFACTOR=95, PAGE compressed, MAIN fg) |
| IDX_TradeBSLUsersWhiteList_CreditID | NC | CreditID ASC | - | - | Active (FILLFACTOR=95, MAIN fg) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_TradeBSLUsersWhiteList_DateInserted | DEFAULT | GETUTCDATE() - auto-captures insertion timestamp |
| DF_TradeBSLUsersWhiteList_CreditID | DEFAULT | 0 - default when no specific credit event is associated |

---

## 8. Sample Queries

### 8.1 Check if a customer is BSL-exempt
```sql
SELECT  CID, DateInserted, CreditID
FROM    Trade.BSLUsersWhiteList WITH (NOLOCK)
WHERE   CID = @CID
```

### 8.2 Recent whitelist additions
```sql
SELECT  TOP 20 CID, DateInserted, CreditID
FROM    Trade.BSLUsersWhiteList WITH (NOLOCK)
ORDER BY DateInserted DESC
```

### 8.3 Count whitelist entries by date
```sql
SELECT  CAST(DateInserted AS DATE) AS DateAdded,
        COUNT(*) AS EntriesAdded
FROM    Trade.BSLUsersWhiteList WITH (NOLOCK)
WHERE   DateInserted >= DATEADD(DAY, -7, GETUTCDATE())
GROUP BY CAST(DateInserted AS DATE)
ORDER BY DateAdded DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| AI Generated: BSL (Bonus Stop Loss) Service Design Overview and Technical Details | Confluence | BSL whitelist exempts specific customers from margin call liquidation |

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.BSLUsersWhiteList | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.BSLUsersWhiteList.sql*
