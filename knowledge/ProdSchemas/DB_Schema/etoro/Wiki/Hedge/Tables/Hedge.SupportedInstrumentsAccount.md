# Hedge.SupportedInstrumentsAccount

> Per-account instrument allowlist for multi-account hedge servers, specifying which instruments each liquidity account is permitted to execute when a hedge server owns more than one account.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | (LiquidityAccountID, InstrumentID) - composite PK CLUSTERED |
| **Partition** | No (on [PRIMARY] filegroup, FILLFACTOR=90) |
| **Indexes** | 1 (PK only) |
| **Versioning** | SYSTEM_VERSIONING -> History.SupportedInstrumentsAccount |

---

## 1. Business Meaning

`Hedge.SupportedInstrumentsAccount` defines which instruments each liquidity account is allowed to execute. It acts as a **per-account instrument filter** used exclusively by the multi-account code path in `Hedge.GetHedgeSupportedInstruments`.

The critical routing logic in `GetHedgeSupportedInstruments` uses a **branch based on account count**:

- **Single-account server** (1 non-pricing account): Returns ALL instruments from `Trade.LiquidityProviderContracts` for that provider. `SupportedInstrumentsAccount` is NOT consulted. The full contract list is authoritative.
- **Multi-account server** (2+ non-pricing accounts): JOINs `SupportedInstrumentsAccount` to restrict each account to its configured instrument subset. This table IS the filter.

This design means the table is only operationally relevant for hedge servers with multiple liquidity accounts (e.g., OMS server HedgeServerID=8, which has both IM3 IM Pricing and IM4 IM Hedging accounts).

**Current data** (10,606 rows): 6 accounts configured across 5,239 distinct instruments.
- ZBFX accounts (8, 11): Broad coverage - 5,113 and 5,239 instruments respectively. These are legacy entries predating single-account optimization; ZBFX servers now run single-account paths so this data is carried but not actively used in routing.
- OMS IM accounts (2147, 2148): 126 instruments each - the IM-eligible instrument subset for institutional market routing.
- Talos (345) and DLT (439): 1 instrument each - highly specific routing for particular instruments.

History: 10,766 rows - slight turnover (instruments added/removed over time).

---

## 2. Business Logic

### 2.1 Multi-Account Instrument Routing

**What**: When a hedge server has multiple non-pricing accounts, `GetHedgeSupportedInstruments` uses this table to resolve which account handles which instrument.

**Columns/Parameters Involved**: `LiquidityAccountID`, `InstrumentID`

**Rules**:
- A row means: "account X is authorized to execute trades for instrument Y"
- The JOIN condition in multi-account path: `SIA.LiquidityAccountID = HSTLA.LiquidityAccountID AND LPC.InstrumentID = SIA.InstrumentID`
- This means an instrument must be both in the provider's contract list AND in this allowlist to be returned
- Instruments absent from this table for a given account are NOT routed to that account
- AccountTypeID=4 (IM Pricing accounts) are excluded from results in both single and multi-account paths

### 2.2 Single-Account Bypass

**What**: For single-account hedge servers, this table is completely bypassed.

**Rules**:
- `GetHedgeSupportedInstruments` first counts accounts: `SELECT COUNT(*) FROM HedgeServerToLiquidityAccount JOIN Accounts WHERE HedgeServerID=@HedgeServerID AND AccountTypeID!=4`
- If count=1: return `Trade.LiquidityProviderContracts` directly (full contract list)
- If count>1: JOIN through `SupportedInstrumentsAccount`
- This optimization avoids needing to maintain allowlist rows for every single-account server

### 2.3 GetAccountSupportedInstruments (Full Table Reader)

**What**: A separate procedure returns the full table content (excluding LiquidityAccountTypeID=4 pricing accounts) for use by other subsystems.

**Rules**:
- Returns: `(LiquidityAccountID, InstrumentID)` for all accounts where `LiquidityAccountTypeID!=4`
- No filtering by hedge server - returns all configured account/instrument pairs
- Used for bulk loading of account instrument mappings (e.g., risk systems, reporting)

---

## 3. Data Overview

| LiquidityAccountID | LiquidityAccountName | InstrumentCount | Usage |
|---|---|---|---|
| 8 | ZBFX Price1 Execution | 5,113 | Legacy - ZBFX now runs single-account path |
| 11 | ZBFX Price3 Execution | 5,239 | Legacy - ZBFX now runs single-account path |
| 345 | Talos Execution Hidden Prod Account | 1 | Specific instrument routing |
| 439 | DLT | 1 | Specific instrument routing |
| 2147 | OMS UAT IM3 IM Pricing | 126 | IM-eligible instrument subset |
| 2148 | OMS UAT IM4 IM Hedging | 126 | IM-eligible instrument subset |

Total: 10,606 rows. History: 10,766 rows (instruments have been added/removed).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityAccountID | int | NO | - | CODE-BACKED | The liquidity account this allowlist entry applies to. Part of composite PK. Implicit reference to Trade.LiquidityAccounts (no FK constraint). 6 distinct account IDs configured: 8 (ZBFX P1), 11 (ZBFX P3), 345 (Talos Hidden), 439 (DLT), 2147 (OMS IM Pricing), 2148 (OMS IM Hedging). |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | The instrument this account is permitted to execute. Part of composite PK. Implicit reference to Trade.Instrument (no FK constraint). 5,239 distinct instruments configured. |
| 3 | DbLoginName | varchar(computed) | YES | suser_name() | CODE-BACKED | Computed audit column. SQL Server login executing the DML. |
| 4 | AppLoginName | varchar(computed) | YES | context_info() | CODE-BACKED | Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. |
| 5 | SysStartTime | datetime2(7) | NO | getutcdate() | VERIFIED | Temporal period start. UTC timestamp when this row version became active. |
| 6 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | VERIFIED | Temporal period end. 9999-12-31 for current rows. History in History.SupportedInstrumentsAccount. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints. LiquidityAccountID and InstrumentID are application-managed without explicit FK enforcement.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetHedgeSupportedInstruments | LiquidityAccountID, InstrumentID | READER (conditional) | JOINs this table only in multi-account mode; bypassed for single-account servers |
| Hedge.GetAccountSupportedInstruments | (table ref) | READER | Returns all (LiquidityAccountID, InstrumentID) pairs excluding LiquidityAccountTypeID=4 |
| History.SupportedInstrumentsAccount | (temporal) | Temporal History | Stores historical row versions via SYSTEM_VERSIONING |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.SupportedInstrumentsAccount (table)
  (no FK dependencies - leaf table)
```

---

### 6.1 Objects This Depends On

No FK dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetHedgeSupportedInstruments | Stored Procedure | READER (conditional) - used in multi-account code path only |
| Hedge.GetAccountSupportedInstruments | Stored Procedure | READER - full table scan excluding pricing accounts |
| History.SupportedInstrumentsAccount | Table | Temporal shadow table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_LiquidityAccountToInstrument | CLUSTERED PK | LiquidityAccountID ASC, InstrumentID ASC | - | - | Active (FILLFACTOR=90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_LiquidityAccountToInstrument | PRIMARY KEY | (LiquidityAccountID, InstrumentID) - one allowlist row per account/instrument pair |
| DF_SupportedInstrumentsAccount_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_SupportedInstrumentsAccount_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime, SysEndTime |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.SupportedInstrumentsAccount |

Note: No FK constraints on LiquidityAccountID or InstrumentID - application-managed integrity.

### 7.3 Triggers

| Trigger Name | Event | Action |
|-------------|-------|--------|
| TRG_T_SupportedInstrumentsAccount | INSERT | No-op self-UPDATE (SET LiquidityAccountID=LiquidityAccountID) to force temporal history capture on INSERT |

---

## 8. Sample Queries

### 8.1 View all account/instrument allowlist entries with names

```sql
SELECT
    sia.LiquidityAccountID,
    la.LiquidityAccountName,
    sia.InstrumentID,
    sia.SysStartTime
FROM Hedge.SupportedInstrumentsAccount sia WITH (NOLOCK)
JOIN Trade.LiquidityAccounts la WITH (NOLOCK)
    ON sia.LiquidityAccountID = la.LiquidityAccountID
ORDER BY sia.LiquidityAccountID, sia.InstrumentID
```

### 8.2 Count instruments per account

```sql
SELECT
    sia.LiquidityAccountID,
    la.LiquidityAccountName,
    COUNT(*) AS InstrumentCount
FROM Hedge.SupportedInstrumentsAccount sia WITH (NOLOCK)
JOIN Trade.LiquidityAccounts la WITH (NOLOCK)
    ON sia.LiquidityAccountID = la.LiquidityAccountID
GROUP BY sia.LiquidityAccountID, la.LiquidityAccountName
ORDER BY sia.LiquidityAccountID
```

### 8.3 Find instruments configured for one account but not another (asymmetric routing)

```sql
SELECT
    a.LiquidityAccountID AS AccountA,
    b.LiquidityAccountID AS AccountB,
    a.InstrumentID
FROM Hedge.SupportedInstrumentsAccount a WITH (NOLOCK)
LEFT JOIN Hedge.SupportedInstrumentsAccount b WITH (NOLOCK)
    ON a.InstrumentID = b.InstrumentID AND b.LiquidityAccountID = 2148
WHERE a.LiquidityAccountID = 2147  -- OMS IM3 vs IM4 comparison
  AND b.InstrumentID IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 files | Corrections: 0 applied*
*Object: Hedge.SupportedInstrumentsAccount | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.SupportedInstrumentsAccount.sql*
