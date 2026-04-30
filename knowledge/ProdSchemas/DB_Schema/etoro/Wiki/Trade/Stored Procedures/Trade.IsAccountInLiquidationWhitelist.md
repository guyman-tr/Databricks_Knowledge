# Trade.IsAccountInLiquidationWhitelist

> Returns a count (0 or 1+) indicating whether a customer account is present in the BSL liquidation whitelist (Trade.BSLUsersWhiteList), which exempts the account from automated BSL margin call liquidation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - the customer to check |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.IsAccountInLiquidationWhitelist checks whether a specific customer (CID) is registered in the BSL (Bonus Stop Loss) liquidation exemption whitelist. Accounts on the whitelist are excluded from automated BSL margin call liquidation - they will not have positions force-closed even if their equity falls below the BSL threshold.

The whitelist is used to protect specific customers from automated liquidation: accounts under compliance review, institutional accounts, accounts experiencing known platform issues, or customers in active dispute resolution. This procedure is the read-side predicate for that registry, returning a COUNT(*) that evaluates to 0 (not whitelisted) or 1+ (whitelisted). Callers check whether the returned value is > 0 to determine exemption status.

Data flow: Liquidation check services query this procedure before initiating BSL liquidation for a CID. Write operations (add/remove) are handled by Trade.InsertIntoBSLUsersWhiteList and Trade.DeleteFromBSLUsersWhiteList.

---

## 2. Business Logic

### 2.1 Whitelist Membership Check

**What**: COUNT(*) on Trade.BSLUsersWhiteList for the given CID.

**Columns/Parameters Involved**: `@CID`, `Trade.BSLUsersWhiteList.CID`

**Rules**:
- SELECT COUNT(*) WHERE CID = @CID.
- Returns 0 if CID is not in the whitelist (not exempt).
- Returns 1 if CID is in the whitelist (exempt from BSL liquidation).
- Could theoretically return > 1 but the table has a deduplication check via Trade.InsertIntoBSLUsersWhiteList, so duplicate entries are prevented under normal operations.
- No transaction, no error handling - pure read query.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | The customer ID to check for whitelist membership. FK to Customer.Customer. |
| RS.1 | IsAccountInLiquidationWhitelist | int | NO | - | CODE-BACKED | Output. COUNT(*) of matching rows in Trade.BSLUsersWhiteList. 0 = not whitelisted (subject to BSL liquidation). 1 = whitelisted (exempt from BSL liquidation). Values > 1 indicate unexpected duplicates. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT COUNT(*) | Trade.BSLUsersWhiteList | Reader | Checks membership of @CID in the BSL exemption whitelist |

### 5.2 Referenced By (other objects point to this)

Not discovered in SQL codebase. Called by BSL liquidation orchestration services to check exemption status before initiating margin calls.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.IsAccountInLiquidationWhitelist (procedure)
└── Trade.BSLUsersWhiteList (table) - whitelist membership check
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.BSLUsersWhiteList | Table | COUNT(*) WHERE CID = @CID to check exemption status |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BSL liquidation service | External (Application) | Calls to check whether a CID is exempt from BSL margin call liquidation |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages |
| COUNT(*) return | Design | Returns scalar count rather than boolean; callers evaluate > 0 for exemption. Consistent with other Is* predicate procedures in the BSL subsystem. |

---

## 8. Sample Queries

### 8.1 Check if a CID is on the whitelist

```sql
EXEC Trade.IsAccountInLiquidationWhitelist @CID = 12345;
-- Returns IsAccountInLiquidationWhitelist = 0 (not exempt) or 1 (exempt)
```

### 8.2 View current whitelist entries for a CID

```sql
SELECT ID, CID, CreditID
FROM Trade.BSLUsersWhiteList WITH (NOLOCK)
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.IsAccountInLiquidationWhitelist | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.IsAccountInLiquidationWhitelist.sql*
