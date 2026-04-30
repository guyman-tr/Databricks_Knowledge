# Trade.InsertIntoBSLUsersWhiteList

> Idempotent INSERT that adds a customer to the BSL (Bonus Stop Loss) exemption whitelist - skips the insert if the CID is already present, ensuring the customer will be excluded from automated BSL margin call liquidation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - matches CID in Trade.BSLUsersWhiteList |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertIntoBSLUsersWhiteList is the registration endpoint for the BSL (Bonus Stop Loss) customer exemption list. It adds a single customer (by CID) to Trade.BSLUsersWhiteList, which excludes them from automated margin call liquidation. The procedure is idempotent: if the CID already exists in the whitelist, the INSERT is silently skipped with no error.

BSL (Bonus Stop Loss) is eToro's automated liquidation mechanism that fires when a customer's equity falls below the stop-loss threshold. Customers on the whitelist are excluded from this check via a LEFT JOIN + IS NULL pattern in Trade.InsertBSLMessagesIntoQueue. Being on the whitelist means the customer's positions will NOT be liquidated by the automated BSL process even if equity drops below threshold.

Business use cases for whitelisting: protecting customers during known system issues, exempting institutional or VIP accounts, honoring compliance decisions, or temporarily shielding customers during migrations or dispute resolution.

The companion deletion procedure is Trade.DeleteFromBSLUsersWhiteList for removing entries.

---

## 2. Business Logic

### 2.1 Idempotent Guard - IF NOT EXISTS

**What**: The procedure is safe to call multiple times for the same CID without creating duplicate entries or raising errors.

**Columns/Parameters Involved**: `@CID`, `Trade.BSLUsersWhiteList.CID`

**Rules**:
- `IF NOT EXISTS (SELECT * FROM Trade.BSLUsersWhiteList WHERE CID = @CID)` guards the INSERT.
- If CID already in whitelist: NO-OP. Silent skip. No error returned.
- If CID not in whitelist: INSERT (CID, DateInserted=GETUTCDATE()).
- DateInserted uses GETUTCDATE() (UTC, not local), consistent with eToro's UTC-first timestamp policy.
- No return value or output parameter - callers cannot distinguish "inserted" vs "already existed" from the procedure's return.

**Diagram**:
```
EXEC InsertIntoBSLUsersWhiteList @CID = 12345
         |
         v
   IF NOT EXISTS? (CID in BSLUsersWhiteList)
         |
   YES - new CID  --> INSERT (CID=12345, DateInserted=GETUTCDATE())
         |
   NO  - exists   --> NO-OP (silent skip)
         |
         v
   Trade.BSLUsersWhiteList
         |
         v
   Trade.InsertBSLMessagesIntoQueue:
     LEFT JOIN BSLUsersWhiteList ON CID
     WHERE BSLUsersWhiteList.CID IS NULL
     --> Customer 12345 EXCLUDED from BSL liquidation
```

### 2.2 BSL Exemption Effect

**What**: Presence in Trade.BSLUsersWhiteList causes Trade.InsertBSLMessagesIntoQueue to exclude this customer from BSL margin calls.

**Rules**:
- Trade.InsertBSLMessagesIntoQueue uses LEFT JOIN + IS NULL to build the queue of customers to liquidate.
- Any CID in this whitelist is filtered out before queue insertion - they receive no BSL margin call message.
- The exemption is per-customer (not per-position or per-account). All positions of the customer are protected.
- There is no expiry date on the whitelist entry - it remains active until explicitly deleted via Trade.DeleteFromBSLUsersWhiteList.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer identifier to add to the BSL exemption whitelist. Must be a valid CID from Customer.Customer. The procedure does not validate CID existence - passing a non-existent CID will insert a dangling row. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID check | Trade.BSLUsersWhiteList | Read (IF NOT EXISTS) | Checks for existing CID before inserting |
| @CID insert | Trade.BSLUsersWhiteList | Write (INSERT) | Adds CID to BSL exemption list with UTC timestamp |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by back-office operations workflows when granting BSL exemptions to customers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertIntoBSLUsersWhiteList (procedure)
+-- Trade.BSLUsersWhiteList (table) - dedup check + INSERT target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.BSLUsersWhiteList | Table | IF NOT EXISTS check + INSERT target for exemption row |

### 6.2 Objects That Depend On This

No dependents found in stored procedures. Called externally by BSL administration tooling.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IF NOT EXISTS guard | Deduplication | Prevents duplicate CID rows; safe to call multiple times |
| SET NOCOUNT ON | Performance | Suppresses row-count messages - callers receive no rowcount signal |
| Auto-commit | Transaction | No explicit transaction; INSERT is a single atomic statement |

---

## 8. Sample Queries

### 8.1 Whitelist a customer for BSL exemption

```sql
EXEC Trade.InsertIntoBSLUsersWhiteList @CID = 12345
```

### 8.2 Verify whitelist status after insert

```sql
SELECT ID, CID, DateInserted
FROM   Trade.BSLUsersWhiteList WITH (NOLOCK)
WHERE  CID = 12345;
```

### 8.3 Check if a customer is currently on the whitelist

```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM Trade.BSLUsersWhiteList WITH (NOLOCK) WHERE CID = 12345
) THEN 'Whitelisted (BSL exempt)' ELSE 'Not whitelisted' END AS BSLStatus;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertIntoBSLUsersWhiteList | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertIntoBSLUsersWhiteList.sql*
