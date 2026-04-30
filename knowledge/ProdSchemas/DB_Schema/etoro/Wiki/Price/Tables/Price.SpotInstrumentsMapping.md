# Price.SpotInstrumentsMapping

> Legacy predecessor to Price.SpotInstrumentMapping - stores spot-to-futures instrument roll mappings without temporal versioning or computed audit columns; currently empty and superseded by the newer SpotInstrumentMapping table.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentID, SpotLiquidityAccountID) - composite CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 (PK clustered composite) |

---

## 1. Business Meaning

SpotInstrumentsMapping is the legacy version of `Price.SpotInstrumentMapping`. Both tables have identical columns and the same composite PK structure `(InstrumentID, SpotLiquidityAccountID)`, defining the spot-to-futures roll chain for futures contract expiry handling (see SpotInstrumentMapping for the full business context).

The key differences from the newer table:
- **No temporal versioning** (no SYSTEM_VERSIONING, no SysStartTime/SysEndTime)
- **No computed audit columns** (no DbLoginName/AppLoginName)
- **No partition scheme** (PRIMARY vs MAIN)
- **No ASM trigger**
- **No consumers**: Not referenced by any stored procedures or views in the Price schema SSDT repo

The table is empty (0 rows) and appears to be a migration artifact - the older table was preserved when a new version with temporal auditing was created. All active functionality uses `Price.SpotInstrumentMapping`.

---

## 2. Business Logic

### 2.1 Identical Structure to SpotInstrumentMapping (Legacy)

**What**: Same spot-to-futures roll mapping as SpotInstrumentMapping but without temporal auditing. Not actively used.

**Columns/Parameters Involved**: `InstrumentID`, `SpotLiquidityAccountID`, `FutureLiquidityAccountID`, `FirstNextInstrumentId`, `SecondNextInstrumentId`

**Rules**:
- Same FK constraints and same PK structure as SpotInstrumentMapping
- No procedures reference this table - all active roll logic uses SpotInstrumentMapping
- For business rules, see Price.SpotInstrumentMapping

---

## 3. Data Overview

The table is currently empty (0 rows).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | VERIFIED | Part 1 of composite PK. FK to Trade.Instrument. Identical to SpotInstrumentMapping.InstrumentID. (Trade.Instrument) |
| 2 | SpotLiquidityAccountID | int | NOT NULL | - | VERIFIED | Part 2 of composite PK. FK to Trade.LiquidityAccounts. The spot liquidity account. (Trade.LiquidityAccounts) |
| 3 | FutureLiquidityAccountID | int | NOT NULL | - | VERIFIED | FK to Trade.LiquidityAccounts. The futures liquidity account. (Trade.LiquidityAccounts) |
| 4 | FirstNextInstrumentId | int | NOT NULL | - | VERIFIED | The instrument ID of the first upcoming futures contract. No FK constraint. |
| 5 | SecondNextInstrumentId | int | NOT NULL | - | VERIFIED | The instrument ID of the second upcoming futures contract. No FK constraint. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK (FK_SpotInstrumentsMapping_InstrumentID) | The spot instrument |
| SpotLiquidityAccountID | Trade.LiquidityAccounts | FK (FK_SpotInstrumentsMapping_SpotAccountId) | The spot liquidity account |
| FutureLiquidityAccountID | Trade.LiquidityAccounts | FK (FK_SpotInstrumentsMapping_AccountId) | The futures liquidity account |

### 5.2 Referenced By (other objects point to this)

No dependents found. This legacy table is not referenced by any stored procedures or views.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.SpotInstrumentsMapping (table - legacy)
|- Trade.Instrument (table, FK target - leaf)
|- Trade.LiquidityAccounts (table, FK target - leaf, x2)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK target |
| Trade.LiquidityAccounts | Table | FK target (x2) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SpotInstrumentsMapping | CLUSTERED PK | InstrumentID ASC, SpotLiquidityAccountID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_SpotInstrumentsMapping | PRIMARY KEY | One roll mapping per (instrument, spot account) |
| FK_SpotInstrumentsMapping_InstrumentID | FK | InstrumentID -> Trade.Instrument(InstrumentID) |
| FK_SpotInstrumentsMapping_SpotAccountId | FK | SpotLiquidityAccountID -> Trade.LiquidityAccounts(LiquidityAccountID) |
| FK_SpotInstrumentsMapping_AccountId | FK | FutureLiquidityAccountID -> Trade.LiquidityAccounts(LiquidityAccountID) |

No temporal versioning, no computed audit columns, no partition scheme.

---

## 8. Sample Queries

### 8.1 Compare with active SpotInstrumentMapping table

```sql
-- Check if any rows exist in this legacy table vs the active one
SELECT 'Legacy (SpotInstrumentsMapping)' AS Tbl, COUNT(*) AS Cnt FROM Price.SpotInstrumentsMapping WITH (NOLOCK)
UNION ALL
SELECT 'Active (SpotInstrumentMapping)', COUNT(*) FROM Price.SpotInstrumentMapping WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 9/10, Logic: 6/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 4, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.SpotInstrumentsMapping | Type: Table | Source: etoro/etoro/Price/Tables/Price.SpotInstrumentsMapping.sql*
