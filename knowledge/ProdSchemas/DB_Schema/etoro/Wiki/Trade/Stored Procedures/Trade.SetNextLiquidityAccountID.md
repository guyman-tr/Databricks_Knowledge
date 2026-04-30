# Trade.SetNextLiquidityAccountID

> Creates a paired "Obsolete - Use Hedge Account" liquidity account in both Trade.LiquidityAccounts and Hedge.Accounts, using gap-filling ID allocation and a parent provider stub, returning the new account ID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Return value = LiquidityAccountID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provisions a new liquidity account entry as a compatibility stub, simultaneously creating matching records in both the legacy `Trade.LiquidityAccounts` table and the newer `Hedge.Accounts` table. The dual-write ensures that both old and new infrastructure can reference the same account without inconsistency.

Like its sibling `Trade.SetNextLiquidityProviderID`, this procedure is part of a migration pattern: the liquidity account layer is being superseded by Hedge Accounts, but some older code still references LiquidityAccountID. The procedure creates paired stub rows (suffixed with " - Obsolete! Use Hedge Account") so legacy references don't break while the migration is in progress.

The procedure calls `Trade.SetNextLiquidityProviderID` to get/create the parent provider stub, then allocates the next available LiquidityAccountID using gap-filling logic (UPDLOCK/HOLDLOCK to prevent concurrent duplicates), inserts into both `Trade.LiquidityAccounts` and `Hedge.Accounts`, and returns the new account ID.

---

## 2. Business Logic

### 2.1 Dual-Write to Legacy + New Infrastructure

**What**: Every new account must exist in both Trade.LiquidityAccounts (legacy) and Hedge.Accounts (new) to maintain cross-system consistency.

**Columns/Parameters Involved**: `@AccountID`, `@ProviderID`, `@AccountType`, `@Name`

**Rules**:
- Trade.LiquidityAccounts: inserted with full legacy fields (LiquidityAccountID, Name, ProviderID, username/password empty, active=1, account type, rate source=0)
- Hedge.Accounts: inserted with the same @AccountID as ID, @Name (without the obsolete suffix), @ProviderTypeID, @AccountType, empty username, active=1
- Both INSERTs use the same @AccountID to keep the IDs in sync across both tables
- Account name in Trade.LiquidityAccounts: CONCAT(@Name, ' - Obsolete! Use Hedge Account')
- Account name in Hedge.Accounts: @Name (without suffix)

**Diagram**:
```
Trade.SetNextLiquidityProviderID(@ProviderTypeID)
  --> @ProviderID (get/create provider stub)

Gap-fill next LiquidityAccountID --> @AccountID

INSERT Trade.LiquidityAccounts (ID=@AccountID, Name=@Name+suffix, Provider=@ProviderID, ...)
INSERT Hedge.Accounts (ID=@AccountID, Name=@Name, ProviderTypeID=@ProviderTypeID, ...)

RETURN @AccountID
```

### 2.2 Concurrency-Safe Gap-Filling ID Allocation

**What**: Uses UPDLOCK + HOLDLOCK locking hints to prevent two concurrent executions from picking the same next ID.

**Columns/Parameters Involved**: `Trade.LiquidityAccounts.LiquidityAccountID`, `@AccountID`

**Rules**:
- MissingIDs CTE with UPDLOCK/HOLDLOCK on both self-join sides of Trade.LiquidityAccounts
- COALESCE(MIN(candidate), MAX(LiquidityAccountID)+1) - lowest gap first, then max+1
- All executed inside a transaction to make the gap-find and INSERT atomic
- candidate > 0 safety filter

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderTypeID | INT | NO | - | CODE-BACKED | Liquidity provider type ID. Passed to Trade.SetNextLiquidityProviderID to find/create the parent provider stub. Also stored in Hedge.Accounts.LiquidityProviderTypeID. |
| 2 | @Name | VARCHAR(256) | NO | - | CODE-BACKED | Human-readable account name. Stored as-is in Hedge.Accounts.Name; stored with " - Obsolete! Use Hedge Account" suffix in Trade.LiquidityAccounts.LiquidityAccountName. |
| 3 | @AccountType | INT | NO | - | CODE-BACKED | Account type identifier. Stored in Trade.LiquidityAccounts.LiquidityAccountTypeID and in Hedge.Accounts.AccountTypeID. |
| Return value | RETURN @AccountID | INT | NO | - | CODE-BACKED | The newly allocated LiquidityAccountID (= Hedge.Accounts.ID). Both tables receive the same ID for cross-system consistency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProviderTypeID | Trade.SetNextLiquidityProviderID | CALLER | Sub-procedure called to find/create the parent provider stub for @ProviderID |
| @AccountID | Trade.LiquidityAccounts | Writer | Inserts new stub account row with legacy fields |
| @AccountID | Hedge.Accounts | Writer | Inserts paired new-infrastructure account row with same ID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SetNextLiquidityAccountID (procedure)
├── Trade.SetNextLiquidityProviderID (procedure) [called to get/create parent provider]
│     └── Trade.LiquidityProviders (table)
├── Trade.LiquidityAccounts (table) [inserted into]
└── Hedge.Accounts (table) [inserted into]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SetNextLiquidityProviderID | Procedure | Called via EXEC @ProviderID = Trade.SetNextLiquidityProviderID to get parent provider |
| Trade.LiquidityAccounts | Table | Inserted into with legacy account fields (UPDLOCK/HOLDLOCK for concurrency-safe ID allocation) |
| Hedge.Accounts | Table | Inserted into with matching ID for cross-system consistency |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No callers found in Trade SP folder | - | Likely called by migration or provisioning scripts |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UPDLOCK/HOLDLOCK | Concurrency | Prevents concurrent calls from allocating the same LiquidityAccountID |
| Dual-write atomicity | Transaction | Both INSERTs run inside a single transaction; rolled back together on error |
| Account name convention | Business rule | Trade.LiquidityAccounts gets " - Obsolete! Use Hedge Account" suffix; Hedge.Accounts gets clean name |

---

## 8. Sample Queries

### 8.1 Create a new liquidity account stub

```sql
DECLARE @NewAccountID INT;
EXEC @NewAccountID = Trade.SetNextLiquidityAccountID
    @ProviderTypeID = 1,
    @Name = 'MyHedgeAccount',
    @AccountType = 2;
SELECT @NewAccountID AS NewAccountID;
```

### 8.2 Verify both tables have matching entries

```sql
SELECT la.LiquidityAccountID, la.LiquidityAccountName, la.LiquidityProviderID, la.IsActive
FROM Trade.LiquidityAccounts la WITH (NOLOCK)
WHERE la.LiquidityAccountName LIKE '%Obsolete%'
ORDER BY la.LiquidityAccountID DESC;

SELECT ha.ID, ha.Name, ha.LiquidityProviderTypeID, ha.AccountTypeID, ha.IsActive
FROM Hedge.Accounts ha WITH (NOLOCK)
ORDER BY ha.ID DESC;
```

### 8.3 Check gaps in LiquidityAccountID sequence

```sql
SELECT t1.LiquidityAccountID + 1 AS candidate
FROM Trade.LiquidityAccounts t1 WITH (NOLOCK)
LEFT JOIN Trade.LiquidityAccounts t2 WITH (NOLOCK)
    ON t1.LiquidityAccountID + 1 = t2.LiquidityAccountID
WHERE t2.LiquidityAccountID IS NULL
AND t1.LiquidityAccountID + 1 > 0
ORDER BY candidate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 direct external callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SetNextLiquidityAccountID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SetNextLiquidityAccountID.sql*
