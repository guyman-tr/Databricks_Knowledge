# Hedge.GetAccountSupportedInstruments

> Returns the list of (LiquidityAccountID, InstrumentID) pairs for all active non-pricing liquidity accounts, providing the instrument support configuration used by hedge routing logic.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full active account instrument configuration |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the complete list of instruments supported by each active liquidity account, filtering out OMS IM Pricing accounts (`LiquidityAccountTypeID != 4`). The result is used by the hedge engine to understand which instruments each liquidity account can execute on, for multi-account server routing decisions.

The procedure JOINs `Hedge.SupportedInstrumentsAccount` (the per-account instrument allowlist) with `Trade.LiquidityAccounts` to apply the account type filter. The `LiquidityAccountTypeID != 4` filter explicitly excludes OMS Initial Margin Pricing accounts - these accounts exist for pricing calculations only and should not appear in the hedge instrument routing table.

The procedure runs with `SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED` (equivalent to `WITH (NOLOCK)` on all tables), reflecting its use on a high-frequency call path where dirty reads are acceptable for configuration data.

---

## 2. Business Logic

### 2.1 Pricing Account Exclusion

**What**: OMS IM Pricing accounts (AccountTypeID=4) are excluded from the result so the caller only sees genuine execution accounts.

**Columns/Parameters Involved**: `LiquidityAccountTypeID` in `Trade.LiquidityAccounts`

**Rules**:
- `WHERE tla.LiquidityAccountTypeID != 4` - removes OMS IM Pricing accounts
- AccountTypeID=4 accounts provide pricing/margin data only - they are not valid execution accounts
- This filter mirrors the same exclusion logic used in `GetHedgeServerInfo`, `GetHedgeServerMetaData`, and other routing queries across the Hedge schema
- All other account types (execution accounts, etc.) are included regardless of whether they are active

### 2.2 SupportedInstrumentsAccount as the Instrument Allowlist

**What**: The result is driven by `Hedge.SupportedInstrumentsAccount`, which defines the per-account instrument subset for multi-account hedge servers.

**Rules**:
- Only (LiquidityAccountID, InstrumentID) pairs recorded in `Hedge.SupportedInstrumentsAccount` are returned
- This table is the authoritative per-account instrument filter for multi-account hedge servers
- Single-account hedge servers use `Trade.LiquidityProviderContracts` instead (see `GetHedgeSupportedInstruments`)
- The JOIN to `Trade.LiquidityAccounts` is solely to apply the `LiquidityAccountTypeID != 4` filter - no additional columns from LiquidityAccounts are returned

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | CODE-BACKED | No input parameters. Returns the full instrument allowlist for all non-OMS-pricing liquidity accounts by joining `Hedge.SupportedInstrumentsAccount` with `Trade.LiquidityAccounts` and filtering out AccountTypeID=4 accounts. |

**Output Columns** (returned result set):

| Column | Source | Description |
|--------|--------|-------------|
| LiquidityAccountID | Hedge.SupportedInstrumentsAccount | The liquidity account ID (matches `Trade.LiquidityAccounts.LiquidityAccountID`) |
| InstrumentID | Hedge.SupportedInstrumentsAccount | The instrument this account is allowed to execute |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Hedge.SupportedInstrumentsAccount | JOIN (INNER) | Provides the per-account instrument allowlist |
| JOIN filter | Trade.LiquidityAccounts | JOIN (INNER) on LiquidityAccountID | Used to filter out OMS pricing accounts (LiquidityAccountTypeID != 4) |

### 5.2 Referenced By (other objects point to this)

No SQL-level callers detected. The procedure is likely called by the hedge engine application to load its instrument routing configuration at startup or on refresh.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetAccountSupportedInstruments (procedure)
├── Hedge.SupportedInstrumentsAccount (table) - instrument allowlist source
└── Trade.LiquidityAccounts (table) - account type filter
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.SupportedInstrumentsAccount | Table | INNER JOIN - source of (LiquidityAccountID, InstrumentID) pairs |
| Trade.LiquidityAccounts | Table | INNER JOIN on LiquidityAccountID - filter applied: LiquidityAccountTypeID != 4 (exclude OMS pricing accounts) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| READ UNCOMMITTED | Isolation | `SET TRAN ISOLATION LEVEL READ UNCOMMITTED` - dirty reads allowed for configuration query |
| No NOLOCK hints | Note | Despite READ UNCOMMITTED isolation level, the query doesn't use explicit WITH (NOLOCK) hints - the isolation level applies globally to the session |

---

## 8. Sample Queries

### 8.1 Equivalent query (with explicit NOLOCK)

```sql
SELECT si.LiquidityAccountID, si.InstrumentID
FROM Hedge.SupportedInstrumentsAccount si WITH (NOLOCK)
INNER JOIN Trade.LiquidityAccounts tla WITH (NOLOCK)
    ON si.LiquidityAccountID = tla.LiquidityAccountID
WHERE tla.LiquidityAccountTypeID != 4
ORDER BY si.LiquidityAccountID, si.InstrumentID
```

### 8.2 Count instruments per account

```sql
SELECT si.LiquidityAccountID,
       tla.LiquidityAccountName,
       tla.LiquidityAccountTypeID,
       COUNT(*) AS InstrumentCount
FROM Hedge.SupportedInstrumentsAccount si WITH (NOLOCK)
INNER JOIN Trade.LiquidityAccounts tla WITH (NOLOCK)
    ON si.LiquidityAccountID = tla.LiquidityAccountID
WHERE tla.LiquidityAccountTypeID != 4
GROUP BY si.LiquidityAccountID, tla.LiquidityAccountName, tla.LiquidityAccountTypeID
ORDER BY InstrumentCount DESC
```

### 8.3 Verify pricing accounts are excluded

```sql
SELECT tla.LiquidityAccountID, tla.LiquidityAccountName, tla.LiquidityAccountTypeID
FROM Trade.LiquidityAccounts tla WITH (NOLOCK)
WHERE tla.LiquidityAccountTypeID = 4
  AND EXISTS (
    SELECT 1 FROM Hedge.SupportedInstrumentsAccount si WITH (NOLOCK)
    WHERE si.LiquidityAccountID = tla.LiquidityAccountID
  )
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetAccountSupportedInstruments | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetAccountSupportedInstruments.sql*
