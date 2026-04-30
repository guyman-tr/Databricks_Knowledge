# Hedge.ActiveHedgingAccounts

> Hedge engine's active-state overlay for liquidity accounts, tracking which Trade.LiquidityAccounts are currently enabled for hedge execution without modifying the shared accounts table.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | LiquidityAccountID (int, FK to Trade.LiquidityAccounts, PK CLUSTERED) |
| **Partition** | No (on [PRIMARY] filegroup, FILLFACTOR=100) |
| **Indexes** | 1 (PK only) |
| **Versioning** | None (no temporal SYSTEM_VERSIONING) |

---

## 1. Business Meaning

`Hedge.ActiveHedgingAccounts` maintains the hedge engine's view of which liquidity accounts are currently active for hedging operations. It acts as an overlay on `Trade.LiquidityAccounts`: rather than modifying the shared platform-wide accounts table, the hedge engine tracks its own active/inactive state per account in this dedicated table.

This separation allows the hedge system to enable or disable accounts from its routing without affecting the broader platform. The `UpdateActiveHedgingAccounts` procedure uses a MERGE statement with a table-valued parameter (`Hedge.ActiveAccountMapping`) to perform bulk upserts - the hedge engine sends its current account state snapshot and the table is synchronized accordingly.

Key differences from `Hedge.Accounts`:
- References `Trade.LiquidityAccounts` (the full platform-wide account registry) vs `Hedge.Accounts` (hedge-specific account details with FIX credentials)
- Has 15 rows vs 13 in `Hedge.Accounts`, including additional accounts like Talos Hidden Prod, DLT Impersonation accounts, and Trafix UAT
- Has no temporal versioning - IsActive changes are not historically tracked
- IsActive=0 accounts are retained in the table (ZBFX Price1, Price3 are inactive)

---

## 2. Business Logic

### 2.1 Account Activation State

**What**: Each row records whether a specific liquidity account is currently participating in hedge routing.

**Columns/Parameters Involved**: `LiquidityAccountID`, `IsActive`

**Rules**:
- `IsActive=1`: account is active and eligible for hedge order routing
- `IsActive=0`: account is disabled from hedging; no new orders routed through it (2 accounts currently inactive: ZBFX Price1 ID=8, ZBFX Price3 ID=11)
- Not all `Trade.LiquidityAccounts` rows appear here - only those relevant to the hedge engine
- Rows are maintained via MERGE (not INSERT/DELETE), so inactive accounts stay in the table

### 2.2 Bulk State Update Pattern

**What**: `UpdateActiveHedgingAccounts` receives the full desired state as a TVP and performs a bulk MERGE.

**Columns/Parameters Involved**: `LiquidityAccountID`, `IsActive`

**Rules**:
- The MERGE updates IsActive for existing accounts and inserts new ones
- Source is `Hedge.ActiveAccountMapping` (a User Defined Type - TVP)
- Does NOT delete rows for accounts absent from the source - only updates matched rows or inserts new ones
- This is a write-optimized table: no triggers, no temporal tracking

---

## 3. Data Overview

| LiquidityAccountID | LiquidityAccountName | IsActive | Meaning |
|---|---|---|---|
| 8 | ZBFX Price1 Execution | 0 | Currently disabled from hedge routing |
| 10 | ZBFX Price2 Execution | 1 | Active ZBFX execution stream |
| 11 | ZBFX Price3 Execution | 0 | Currently disabled from hedge routing |
| 345 | Talos Execution Hidden Prod Account | 1 | Active Talos production account |
| 346 | Talos | 1 | Active Talos account |
| 439 | DLT | 1 | Active DLT account |
| 2145 | Trafix UAT | 1 | Active TRAFIX UAT account |
| 2147 | OMS UAT IM3 IM Pricing | 1 | Active OMS pricing account |
| 2148 | OMS UAT IM4 IM Hedging | 1 | Active OMS hedging account |
| 2150 | OMS UAT DMA Virtu | 1 | Active OMS DMA Virtu path |
| 2151 | OMS UAT DMA Marex | 1 | Active OMS DMA Marex path |
| 2152 | OMS UAT DMA JPM | 1 | Active OMS DMA JPMorgan path |
| 12566 | MM Direct STG | 1 | Active MM Direct staging account |
| 439114 | DLT Impersonation Price1 Execution | 1 | Active DLT impersonation account |
| 439400 | DLT Impersonation Price3 Execution | 1 | Active DLT impersonation account |

Total: 15 rows (13 active, 2 inactive).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityAccountID | int | NO | - | VERIFIED | Primary key and FK to Trade.LiquidityAccounts(LiquidityAccountID). References the platform-wide liquidity account registry. The IDs correspond to the same accounts tracked in Hedge.Accounts (same ID namespace). |
| 2 | IsActive | bit | NO | - | VERIFIED | Whether this account is currently participating in hedge routing. 1=active (eligible for order routing), 0=inactive (disabled from hedging). 13 of 15 current accounts are active. Managed via MERGE by UpdateActiveHedgingAccounts. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityAccountID | Trade.LiquidityAccounts | FK (FK_ActiveHedgingAccount__LiquidityAccounts) | Each row governs the hedge-active state of a platform liquidity account |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.UpdateActiveHedgingAccounts | (target table) | WRITER | MERGE-based bulk upsert; synchronizes the active state from a TVP snapshot |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ActiveHedgingAccounts (table)
  └── Trade.LiquidityAccounts (table) [FK - LiquidityAccountID]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityAccounts | Table | FK_ActiveHedgingAccount__LiquidityAccounts - every account must exist in the platform's liquidity account registry |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.UpdateActiveHedgingAccounts | Stored Procedure | WRITER - MERGE upserts the active state per account |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ActiveHedgingAccounts | CLUSTERED PK | LiquidityAccountID ASC | - | - | Active (FILLFACTOR=100) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ActiveHedgingAccounts | PRIMARY KEY | LiquidityAccountID - one active-state row per account |
| FK_ActiveHedgingAccount__LiquidityAccounts | FOREIGN KEY | LiquidityAccountID must reference Trade.LiquidityAccounts(LiquidityAccountID) |

Note: No temporal SYSTEM_VERSIONING and no DML triggers - this is a simple operational state table managed via MERGE.

---

## 8. Sample Queries

### 8.1 View all active hedging accounts with names

```sql
SELECT
    aha.LiquidityAccountID,
    la.LiquidityAccountName,
    aha.IsActive
FROM Hedge.ActiveHedgingAccounts aha WITH (NOLOCK)
JOIN Trade.LiquidityAccounts la WITH (NOLOCK)
    ON aha.LiquidityAccountID = la.LiquidityAccountID
ORDER BY aha.IsActive DESC, aha.LiquidityAccountID
```

### 8.2 Find accounts in Trade.LiquidityAccounts that are not in ActiveHedgingAccounts

```sql
SELECT la.LiquidityAccountID, la.LiquidityAccountName
FROM Trade.LiquidityAccounts la WITH (NOLOCK)
WHERE NOT EXISTS (
    SELECT 1 FROM Hedge.ActiveHedgingAccounts aha WITH (NOLOCK)
    WHERE aha.LiquidityAccountID = la.LiquidityAccountID
)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 files | Corrections: 0 applied*
*Object: Hedge.ActiveHedgingAccounts | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.ActiveHedgingAccounts.sql*
