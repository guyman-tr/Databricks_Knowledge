# Price.PCSToLiquidityAccount

> Configuration table that maps Price Calculation Service (PCS) instance IDs to liquidity account IDs, defining which market data accounts are assigned to each PCS process instance for price routing and rate source configuration.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | (PCSID, LiquidityAccountID) - composite CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 (PK clustered composite) |

---

## 1. Business Meaning

PCSToLiquidityAccount maps Price Calculation Service (PCS) instance IDs to the liquidity accounts those instances are responsible for pricing. A PCS is a process instance (likely a microservice or service worker) that calculates prices for a subset of instruments; each PCS instance is assigned one or more liquidity accounts from which it sources market data. This table is the assignment registry: it declares which liquidity accounts are "allocated" to which PCS instance.

With only 5 rows (PCSID 1-5, each mapped to one liquidity account), this table reflects a small fixed topology of PCS instances. The composite PK on (PCSID, LiquidityAccountID) technically allows a PCS to be assigned multiple accounts, but the current data shows a 1:1 relationship for all 5 instances.

Key downstream uses:
- `Price.GetPriceAccounts` view: uses a LEFT JOIN to flag each LiquidityAccount as `IsAllocated=1` (appears here) or `IsAllocated=0` (not assigned to any PCS)
- `Price.GetRateSourceConfiguration` view: multi-hop join through this table -> LiquidityAccountToInstrument -> LiquidityAccounts -> Instrument, building the full chain of PCS -> LiquidityAccount -> Instrument -> AccountRateSourceID with PriceServerID
- `Price.CleanUnmappedInstrumentRateSources` proc: uses this table to clean stale instrument-to-rate-source mappings

System versioning tracks all changes in `History.PCSToLiquidityAccount`. Three ASM-generated audit triggers (Delete/Insert/Update) write detailed change records to `History.AuditHistory`. A fourth ASM no-op trigger (`Tr_T_LiquidityProviders_INSERT`) performs a self-update on INSERT - standard pattern for temporal table refresh.

PCSID has NO FK constraint in the database - PCS instances are likely defined in an external configuration system, not the database.

---

## 2. Business Logic

### 2.1 PCS-to-Account Assignment

**What**: Each PCS instance is assigned one or more liquidity accounts. The composite PK allows one PCS to serve multiple accounts, though current data shows 1:1.

**Columns/Parameters Involved**: `PCSID`, `LiquidityAccountID`

**Rules**:
- Composite PK (PCSID, LiquidityAccountID) prevents duplicate assignments of the same (PCS, account) pair
- PCSID has no FK constraint - PCS instance IDs are managed externally (application configuration)
- LiquidityAccountID FK-validated against Trade.LiquidityAccounts

### 2.2 Allocation Status via GetPriceAccounts

**What**: The view `Price.GetPriceAccounts` uses this table to show whether each active liquidity account is currently allocated to any PCS instance.

**Columns/Parameters Involved**: `LiquidityAccountID`

**Rules**:
- `GetPriceAccounts` LEFT JOINs this table: `CASE isnull(PTLA.LiquidityAccountID, -1) WHEN -1 THEN 0 ELSE 1 END as IsAllocated`
- Active, non-type-2 liquidity accounts with no row here -> IsAllocated=0 (available but unassigned)
- Active accounts with a row here -> IsAllocated=1 (currently assigned to a PCS)

### 2.3 Rate Source Configuration via GetRateSourceConfiguration

**What**: The view `Price.GetRateSourceConfiguration` chains this table through LiquidityAccountToInstrument to produce the full instrument-to-PCS rate routing map.

**Columns/Parameters Involved**: `PCSID` (via LiquidityAccountID chain)

**Rules**:
- Join chain: PCSToLiquidityAccount -> LiquidityAccountToInstrument (on LiquidityAccountID) -> LiquidityAccounts (on LiquidityAccountID) -> Instrument (RIGHT JOIN on InstrumentID)
- Output: PriceServerID, AccountRateSourceID, InstrumentID
- WHERE PriceServerID IS NOT NULL - excludes unassigned instruments
- Result represents the active assignment of instruments to rate sources via PCS instances

---

## 3. Data Overview

| PCSID | LiquidityAccountID | Meaning |
|---|---|---|
| 1 | 103 | PCS instance 1 is assigned to LiquidityAccount 103 |
| 2 | 7 | PCS instance 2 is assigned to LiquidityAccount 7 |
| 3 | 5 | PCS instance 3 is assigned to LiquidityAccount 5 |
| 4 | 295 | PCS instance 4 is assigned to LiquidityAccount 295 |
| 5 | 102 | PCS instance 5 is assigned to LiquidityAccount 102 |

5 total rows. Current topology: 5 PCS instances, each assigned to one distinct liquidity account.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PCSID | int | NOT NULL | - | VERIFIED | Part 1 of composite PK. The Price Calculation Service instance identifier. Each PCS is a distinct process/worker that calculates prices for its assigned liquidity accounts. No FK constraint - PCSID values are managed externally (application config). Current range: 1-5. |
| 2 | LiquidityAccountID | int | NOT NULL | - | VERIFIED | Part 2 of composite PK. FK to Trade.LiquidityAccounts. The liquidity account assigned to this PCS instance. The account's AccountRateSourceID (from Trade.LiquidityAccounts) identifies the market data feed. Used by GetRateSourceConfiguration to resolve the full PCS -> instrument -> rate source chain. (Trade.LiquidityAccounts) |
| 3 | DbLoginName | varchar (computed) | NOT NULL | suser_name() | CODE-BACKED | Computed: SQL Server login of last row modifier. Auto-set on DML. |
| 4 | AppLoginName | varchar(500) (computed) | YES | context_info() | CODE-BACKED | Computed: application identity from context_info(). Populated when calling service sets CONTEXT_INFO before DML. |
| 5 | SysStartTime | datetime2(7) | NOT NULL | getutcdate() | CODE-BACKED | Temporal period start. Auto-managed by SQL Server system versioning. |
| 6 | SysEndTime | datetime2(7) | NOT NULL | '9999-12-31 23:59:59.9999999' | CODE-BACKED | Temporal period end. Historical row versions in History.PCSToLiquidityAccount. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityAccountID | Trade.LiquidityAccounts | FK (FK_PCSToLiquidityAccount_LiquidityAccountID) | The liquidity account assigned to this PCS instance |
| PCSID | (external) | No FK | PCS instances managed externally; no DB-level FK |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.GetPriceAccounts | LiquidityAccountID | LEFT JOIN | Flags liquidity accounts as IsAllocated=1 (appears here) or IsAllocated=0 |
| Price.GetRateSourceConfiguration | LiquidityAccountID | JOIN source | Chains via LiquidityAccountToInstrument to build full PCS->instrument->rate-source map |
| Price.CleanUnmappedInstrumentRateSources | LiquidityAccountID | READER | Used to identify active allocations when cleaning stale instrument-rate-source mappings |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.PCSToLiquidityAccount (table)
|- Trade.LiquidityAccounts (table, FK target - leaf)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityAccounts | Table | FK target - LiquidityAccountID must reference a valid liquidity account |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.GetPriceAccounts | View | LEFT JOIN - determines IsAllocated flag for each liquidity account |
| Price.GetRateSourceConfiguration | View | JOIN source - builds full instrument-to-rate-source-via-PCS configuration map |
| Price.CleanUnmappedInstrumentRateSources | Stored Procedure | READER - uses allocation data when cleaning stale mappings |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PCSToLiquidityAccount | CLUSTERED PK | PCSID ASC, LiquidityAccountID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_PCSToLiquidityAccount | PRIMARY KEY | Composite PK - one assignment per (PCS instance, liquidity account) pair |
| FK_PCSToLiquidityAccount_LiquidityAccountID | FK | LiquidityAccountID -> Trade.LiquidityAccounts(LiquidityAccountID) |
| DF_PCSToLiquidityAccount_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_PCSToLiquidityAccount_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| SYSTEM_VERSIONING = ON | Temporal | Full history in History.PCSToLiquidityAccount |
| AuditDelete_Price_PCSToLiquidityAccount | TRIGGER (DELETE) | ASM audit: writes deleted PCSID and LiquidityAccountID to History.AuditHistory with operation='D' |
| AuditInsert_Price_PCSToLiquidityAccount | TRIGGER (INSERT) | ASM audit: writes inserted PCSID and LiquidityAccountID to History.AuditHistory with operation='I' |
| AuditUpdate_Price_PCSToLiquidityAccount | TRIGGER (UPDATE) | ASM audit: writes changed values to History.AuditHistory with operation='U' |
| Tr_T_LiquidityProviders_INSERT | TRIGGER (INSERT) | ASM no-op: self-update on LiquidityAccountID after insert (temporal refresh pattern) |

---

## 8. Sample Queries

### 8.1 View all PCS-to-account assignments with account names

```sql
SELECT
    P.PCSID,
    P.LiquidityAccountID,
    LA.LiquidityAccountName,
    LA.AccountRateSourceID,
    P.SysStartTime AS AssignedSince
FROM Price.PCSToLiquidityAccount P WITH (NOLOCK)
JOIN Trade.LiquidityAccounts LA WITH (NOLOCK)
    ON LA.LiquidityAccountID = P.LiquidityAccountID
ORDER BY P.PCSID;
```

### 8.2 Check which liquidity accounts are allocated (vs available)

```sql
SELECT
    LA.LiquidityAccountID,
    LA.LiquidityAccountName,
    CASE isnull(P.LiquidityAccountID, -1) WHEN -1 THEN 'Unallocated' ELSE 'Allocated' END AS AllocationStatus,
    P.PCSID
FROM Trade.LiquidityAccounts LA WITH (NOLOCK)
LEFT JOIN Price.PCSToLiquidityAccount P WITH (NOLOCK)
    ON P.LiquidityAccountID = LA.LiquidityAccountID
WHERE LA.IsActive = 1 AND LA.LiquidityAccountTypeID <> 2
ORDER BY AllocationStatus, LA.LiquidityAccountID;
```

### 8.3 View full rate source configuration chain (PCS -> instrument)

```sql
SELECT * FROM Price.GetRateSourceConfiguration WITH (NOLOCK)
ORDER BY InstrumentID;
```

### 8.4 View change history for PCS assignments (temporal)

```sql
SELECT
    PCSID,
    LiquidityAccountID,
    DbLoginName,
    AppLoginName,
    SysStartTime,
    SysEndTime
FROM Price.PCSToLiquidityAccount
FOR SYSTEM_TIME ALL
ORDER BY PCSID, SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.PCSToLiquidityAccount | Type: Table | Source: etoro/etoro/Price/Tables/Price.PCSToLiquidityAccount.sql*
