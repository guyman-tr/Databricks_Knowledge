# Hedge.CheckAccountUsernameExists

> Looks up a liquidity provider account by username, returning LiquidityAccountID and Username if a matching account exists in both Trade.LiquidityAccounts and Hedge.Accounts.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT-only - JOIN Trade.LiquidityAccounts with Hedge.Accounts on LiquidityAccountID=ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.CheckAccountUsernameExists` is a validation/lookup procedure that determines whether a given username corresponds to a registered liquidity provider account that is also listed in the Hedge.Accounts registry.

The dual-table join is the key design decision: it does NOT simply check `Trade.LiquidityAccounts` alone, but requires the account to also exist in `Hedge.Accounts`. `Hedge.Accounts` is the registry of eToro's physical trading accounts at external liquidity providers - accounts that the hedge engine actually uses. An LP account in Trade.LiquidityAccounts that is not in Hedge.Accounts would be a non-active or unregistered hedge account.

This makes the procedure a "hedge-registered account" existence check by username, rather than a general LP account lookup. If the username is not found or the account is not registered in the Hedge.Accounts registry, the procedure returns an empty result set (0 rows).

Typical use: the hedge engine or configuration service validates that a username being configured or connected actually corresponds to a known, hedge-registered LP account before granting access or establishing a connection.

---

## 2. Business Logic

### 2.1 Dual-Table Existence Check

**What**: JOIN ensures the username exists in both the LP account registry (Trade.LiquidityAccounts) AND the Hedge account registry (Hedge.Accounts).

**Columns/Parameters Involved**: `@Username`, `TLA.LiquidityAccountID`, `HA.ID`

**Rules**:
- JOIN condition: `TLA.LiquidityAccountID = HA.ID` - maps Trade LP account ID to Hedge account ID
- Filter: `WHERE TLA.Username = @Username` (case sensitivity depends on server collation)
- Returns: `LiquidityAccountID` and `Username` from Trade.LiquidityAccounts
- If @Username matches no LP account: 0 rows
- If @Username matches an LP account NOT in Hedge.Accounts: 0 rows (INNER JOIN excludes it)
- If @Username matches a registered hedge account: 1 row (Username per LP account should be unique)

**Diagram**:
```
Hedge.CheckAccountUsernameExists(@Username)
      |
      SELECT LiquidityAccountID, TLA.Username
      FROM Trade.LiquidityAccounts TLA
      JOIN Hedge.Accounts HA ON TLA.LiquidityAccountID = HA.ID
      WHERE TLA.Username = @Username
      |
      -> 0 rows: username not found or account not hedge-registered
      -> 1 row:  {LiquidityAccountID, Username} of the matching hedge account
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Username | varchar(256) | NO | - | CODE-BACKED | LP account username to look up. Matched against Trade.LiquidityAccounts.Username. Case sensitivity depends on server collation. Typically the API username used to authenticate with the liquidity provider. |

**Output columns:**

| Column | Source | Description |
|--------|--------|-------------|
| LiquidityAccountID | Trade.LiquidityAccounts | The LP account ID that matches the username AND is registered in Hedge.Accounts |
| Username | Trade.LiquidityAccounts | The matched username (echoed back, useful for confirmation) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TLA | Trade.LiquidityAccounts | SELECT | Source of Username and LiquidityAccountID |
| HA | Hedge.Accounts | JOIN filter | Ensures account is registered in the Hedge engine registry |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Called by the hedge engine or configuration service to validate LP account credentials.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.CheckAccountUsernameExists (procedure)
|- Trade.LiquidityAccounts (table) - username lookup + LiquidityAccountID
+-- Hedge.Accounts (table) - hedge registry filter
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityAccounts | Table | SELECT LiquidityAccountID, Username WHERE Username = @Username |
| Hedge.Accounts | Table | INNER JOIN on ID = LiquidityAccountID - filters to hedge-registered accounts only |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Hedge engine / config service) | External | Validates LP account username before connection or configuration |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- No SET NOCOUNT ON - row count emitted to caller
- No TRY/CATCH - errors propagate naturally
- No WITH (NOLOCK) - reads are consistent (appropriate for a validation query)
- IsActive flag on Hedge.Accounts is NOT filtered - inactive hedge accounts still pass the check
- Returns all matching rows, though Username should be unique per LP account

---

## 8. Sample Queries

### 8.1 Execute: Check if username 'zbfx_acct1' is a registered hedge account

```sql
EXEC Hedge.CheckAccountUsernameExists @Username = 'zbfx_acct1'
-- Returns: LiquidityAccountID, Username (or empty if not found/not registered)
```

### 8.2 Verify: Manual check for the same logic

```sql
SELECT
    TLA.LiquidityAccountID,
    TLA.Username
FROM Trade.LiquidityAccounts TLA
JOIN Hedge.Accounts HA ON TLA.LiquidityAccountID = HA.ID
WHERE TLA.Username = 'zbfx_acct1'
```

### 8.3 Diagnose: Username exists in LiquidityAccounts but not in Hedge.Accounts

```sql
-- Find LP accounts with username match that are NOT hedge-registered
SELECT TLA.LiquidityAccountID, TLA.Username
FROM Trade.LiquidityAccounts TLA
WHERE TLA.Username = 'zbfx_acct1'
  AND NOT EXISTS (SELECT 1 FROM Hedge.Accounts HA WHERE HA.ID = TLA.LiquidityAccountID)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.CheckAccountUsernameExists | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.CheckAccountUsernameExists.sql*
