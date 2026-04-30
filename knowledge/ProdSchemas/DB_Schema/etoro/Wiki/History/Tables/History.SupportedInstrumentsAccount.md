# History.SupportedInstrumentsAccount

> System-versioned temporal history table for Hedge.SupportedInstrumentsAccount, recording all past states of the instrument-to-liquidity-account support mappings - tracking which instruments have been enabled or disabled on each hedge liquidity account.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite temporal key (SysEndTime, SysStartTime) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime ASC, SysStartTime ASC) |

---

## 1. Business Meaning

This table is the **active system-versioned temporal history table** for `Hedge.SupportedInstrumentsAccount` (source declares `SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[SupportedInstrumentsAccount])`). SQL Server automatically archives superseded rows here when the supported instrument list for a liquidity account changes.

`Hedge.SupportedInstrumentsAccount` is the registry of which instruments each hedge liquidity account supports for trading. The composite PK is (LiquidityAccountID, InstrumentID) - each pair defines that a specific instrument can be traded/hedged through a specific liquidity account. When a new instrument is added to a liquidity account (or an existing one is removed), the change is captured here.

With **10,766 history rows** spanning August 2023 to June 2025 across **6 distinct liquidity accounts** and **5,239 distinct instruments**, this is an actively maintained configuration. Changes are made by named TRAD domain operators (TRAD\rivkaya, TRAD\moshezo, TRAD\michaelta, TRAD\avihayts).

Note: `TRG_T_SupportedInstrumentsAccount` performs a no-op self-update on INSERT for consistent temporal registration.

---

## 2. Business Logic

### 2.1 Instrument-Account Support Registry

**What**: Defines which instruments are tradeable/hedgeable on each liquidity account.

**Columns/Parameters Involved**: `LiquidityAccountID`, `InstrumentID`

**Rules**:
- PK in source: (LiquidityAccountID, InstrumentID) - each instrument-account pair is unique
- When an instrument is added to a liquidity account, a row is inserted with SysStartTime=NOW
- When an instrument is removed from a liquidity account, SQL Server archives the row to this history table and deletes from source
- The hedge system uses this table to determine routing eligibility: only instruments in Hedge.SupportedInstrumentsAccount can be routed to the corresponding liquidity account for hedging

---

## 3. Data Overview

| LiquidityAccountID | InstrumentID | DbLoginName | SysStartTime | SysEndTime | Meaning |
|---|---|---|---|---|---|
| 439 | 100001 | TRAD\rivkaya | 2024-12-18 | 2025-06-04 | Instrument 100001 was active on account 439 for ~6 months before being removed |
| 439 | 100001 | TRAD\moshezo | 2024-12-18 | 2024-12-18 | Same-second change: rapid update |
| 345 | 100000 | TRAD\michaelta | 2024-09-17 | 2024-09-17 | Brief mapping, replaced immediately |

Total: 10,766 rows | 6 distinct accounts | 5,239 distinct instruments | Aug 2023 - Jun 2025

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityAccountID | int | NO | - | CODE-BACKED | The hedge liquidity account. Composite PK with InstrumentID. Implicit FK to Trade.LiquidityAccounts. 6 distinct accounts in history: identifies which hedge provider account supports this instrument. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | The instrument that was supported on this liquidity account. Composite PK with LiquidityAccountID. Implicit FK to Trade.Instrument. 5,239 distinct instruments observed across all history rows. |
| 3 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | Computed in source as `suser_name()` - the operator or service that added/modified this mapping. Named TRAD domain users visible (TRAD\rivkaya, TRAD\moshezo, TRAD\michaelta, TRAD\avihayts) confirming manual configuration by ops team. |
| 4 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Computed in source as `CONVERT(varchar(500), context_info())` - application context at time of change. |
| 5 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | UTC instant when this instrument-account pairing became active. Automatically managed by SQL Server temporal system versioning. |
| 6 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | CODE-BACKED | UTC instant when this pairing was removed or superseded. Automatically set by SQL Server. Leading key of the clustered index. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (LiquidityAccountID, InstrumentID) | Hedge.SupportedInstrumentsAccount | Temporal History | Each row is a past state of the instrument-account support mapping. |
| LiquidityAccountID | Trade.LiquidityAccounts | Implicit FK | The liquidity account this instrument was supported on. |
| InstrumentID | Trade.Instrument | Implicit FK | The instrument that was added to or removed from the account. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.SupportedInstrumentsAccount | HISTORY_TABLE | Temporal History | Active source table; SQL Server archives expired rows here. |

---

## 6. Dependencies

No dependencies. Temporal history table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_SupportedInstrumentsAccount | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

Note: DATA_COMPRESSION = PAGE on both table and clustered index.

---

## 8. Sample Queries

### 8.1 View recent instrument-account support changes
```sql
SELECT
    LiquidityAccountID,
    InstrumentID,
    DbLoginName,
    SysStartTime AS AddedAt,
    SysEndTime AS RemovedAt,
    DATEDIFF(day, SysStartTime, SysEndTime) AS DaysActive
FROM [History].[SupportedInstrumentsAccount] WITH (NOLOCK)
ORDER BY SysEndTime DESC
```

### 8.2 Track all changes for a specific liquidity account
```sql
SELECT
    InstrumentID,
    DbLoginName,
    SysStartTime AS ValidFrom,
    SysEndTime AS ValidTo
FROM [History].[SupportedInstrumentsAccount] WITH (NOLOCK)
WHERE LiquidityAccountID = @LiquidityAccountID
ORDER BY SysStartTime ASC
```

### 8.3 Point-in-time supported instruments for an account
```sql
SELECT LiquidityAccountID, InstrumentID
FROM [Hedge].[SupportedInstrumentsAccount]
FOR SYSTEM_TIME AS OF @PointInTime
WHERE LiquidityAccountID = @LiquidityAccountID
ORDER BY InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.SupportedInstrumentsAccount | Type: Table | Source: etoro/etoro/History/Tables/History.SupportedInstrumentsAccount.sql*
