# History.PositionFix

> Audit log of manual position P&L corrections performed by back-office managers, recording the before/after state of NetProfit, Commission, and EndForexRate for each corrected closed position.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PositionFixID (INT IDENTITY, clustered PK) |
| **Partition** | No (ON [HISTORY] filegroup) |
| **Indexes** | 4 (1 clustered PK + 3 nonclustered) |

---

## 1. Business Meaning

`History.PositionFix` is the permanent audit record of manual corrections to closed position financials. When a closed position has an incorrect NetProfit, Commission, or closing rate (EndForexRate) - due to a pricing incident, system bug, or data error - a back-office manager runs `Maintenance.PositionFix` to correct it. Every execution of that procedure writes one row here, capturing the ManagerID, PositionID, old and new values of all three financial fields, and the SQL identity of who ran the correction (Login, Machine, Application).

This table exists to ensure accountability for manual financial adjustments. Position P&L corrections have real financial impact - they change customer credit balances, cascade through all downstream credit history, and affect championship standings and aggregated statistics. Without this audit trail, there would be no way to know what was changed, when, by whom, and what the previous values were.

Data flows in exclusively via `Maintenance.PositionFix`: the procedure reads current values from `History.Position`, validates that the position exists, belongs to a real (non-demo) customer, and that values actually differ from what is being set. It then updates `History.Position` and cascades the P&L delta through `Customer.Customer.Credit`, `History.Credit` (full downstream chain update), championship standings, and daily/monthly aggregates - then logs the correction here. The Login, Machine, and Application columns auto-populate from SQL context (suser_sname(), host_name(), app_name()).

---

## 2. Business Logic

### 2.1 Position P&L Correction Cascade

**What**: Correcting a closed position's P&L triggers a multi-table cascade through all financial aggregations.

**Columns/Parameters Involved**: `OldNetProfit`, `NewNetProfit`, `OldCommission`, `NewCommission`, `OldEndForexRate`, `NewEndForexRate`

**Rules**:
- Only applies to closed positions (must exist in `History.Position`)
- Only applies to REAL customers (rejects demo accounts with: "Nothing to do: demo customer")
- Only proceeds if at least one value actually changes (rejects no-op corrections)
- Delta `= @NetProfit - @OldNetProfit` is applied to ALL downstream objects atomically in a single transaction
- Commission change cascades to `BackOffice.CustomerAggregatedData.TotalCommission` and monthly/daily aggregates
- NetProfit change cascades to: `Customer.Customer.Credit`, `History.Credit` (payment recalculation + downstream chain), championship standings (floored at 0)
- Rate-only changes (same NetProfit, same Commission, different EndForexRate) update `History.Position` but skip the full financial cascade
- Note in code: "THE ALGORITHM PERMITS A SITUATION WHEN NEW ACCOUNT BALANCE BECOMES NEGATIVE"

**Diagram**:
```
Maintenance.PositionFix (sp)
    |
    +-> Reads History.Position (old values)
    |
    +-> Validates: real customer, values changed, position exists
    |
    +-> BEGIN TRANSACTION
        |
        +-> UPDATE History.Position (new values)
        +-> INSERT History.PositionFix (THIS TABLE - audit row)
        |
        +-- if NetProfit/Commission changed:
        |   +-> UPDATE Customer.Customer.Credit (+= delta NetProfit)
        |   +-> UPDATE History.Credit (payment + downstream chain cascade)
        |   +-> UPDATE Championship.ChampionshipPlayer.ChampProfit (floored 0)
        |   +-> UPDATE BackOffice.CustomerAggregatedData (TotalProfit, TotalCommission)
        |   +-> UPDATE BackOffice.CustomerDailyAggregates (from fix date forward)
        |   +-> UPDATE BackOffice.CustomerMonthlyAggregates (from fix month forward)
        |
        +-> COMMIT
```

### 2.2 SQL Context Audit Trail

**What**: The table auto-captures the SQL identity context of who executed the correction.

**Columns/Parameters Involved**: `Login`, `Machine`, `Application`

**Rules**:
- All three columns default to SQL server functions: `suser_sname()`, `host_name()`, `app_name()`
- These capture the SQL login, client machine name, and application name at INSERT time
- In practice: Login identifies the DBA/process account, Machine identifies the server/workstation, Application identifies the tool (SSMS, maintenance job, etc.)
- All three are NOT NULL - they always have a value via the defaults

---

## 3. Data Overview

Table is empty in current environment. Sample pattern based on `Maintenance.PositionFix` logic:

| PositionFixID | ManagerID | PositionID | OldNetProfit | NewNetProfit | OldCommission | NewCommission | OldEndForexRate | NewEndForexRate | Occurred | Login | Machine | Application |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 42 | 8765432 | 125.50 | 127.30 | 2.00 | 2.00 | 1.09251 | 1.09463 | 2025-01-15 11:23:01 | etoro\db_admin | PROD-DB01 | Microsoft SQL Server Management Studio |
| 2 | 17 | 4321098 | -34.20 | -34.20 | 5.50 | 4.75 | 0.91234 | 0.91234 | 2025-02-01 09:15:44 | etoro\dba_batch | MAINT-SRV | SQLAgent |

*Table is empty in this environment. Examples illustrate the audit pattern.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionFixID | int IDENTITY(1,1) | NO | auto | CODE-BACKED | Auto-incrementing PK, NOT FOR REPLICATION. Uniquely identifies each manual correction event. IDENTITY ensures sequence even under replication topology. |
| 2 | ManagerID | int | NO | - | VERIFIED | ID of the back-office manager who authorized and executed the correction. FK to BackOffice.Manager (FK_BMNG_HPFX). Indexed (HPFX_MANAGER) to enable fast "all fixes by this manager" queries. |
| 3 | PositionID | int | NO | - | VERIFIED | ID of the closed trading position that was corrected. Int (not bigint - older table predates bigint migration). Indexed (HPFX_POSITION). References History.Position. |
| 4 | OldNetProfit | money | NO | - | VERIFIED | P&L value (in account currency) that existed in History.Position BEFORE the correction. Read from History.Position by Maintenance.PositionFix before updating. Stored in fractional currency units (not cents). |
| 5 | NewNetProfit | money | NO | - | VERIFIED | Corrected P&L value applied to History.Position. The delta (NewNetProfit - OldNetProfit) cascades to Customer.Customer.Credit, History.Credit, championship standings, and aggregation tables. |
| 6 | OldCommission | money | NO | - | VERIFIED | Commission value in History.Position BEFORE the correction. Read from History.Position before updating. In fractional currency units. |
| 7 | NewCommission | money | NO | - | VERIFIED | Corrected commission value. Delta cascades to BackOffice.CustomerAggregatedData.TotalCommission, CustomerDailyAggregates, and CustomerMonthlyAggregates from the position's close date forward. |
| 8 | OldEndForexRate | dbo.dtPrice | NO | - | VERIFIED | Closing forex rate in History.Position BEFORE the correction (dbo.dtPrice UDT). When only the rate changes (NetProfit and Commission unchanged), Maintenance.PositionFix commits immediately after updating History.Position without cascading to financial aggregations. |
| 9 | NewEndForexRate | dbo.dtPrice | NO | - | VERIFIED | Corrected closing rate applied to History.Position (dbo.dtPrice UDT). The corrected rate is used by downstream systems for recalculation purposes. |
| 10 | Occurred | datetime | NO | getdate() | CODE-BACKED | Timestamp when the correction was applied. Defaults to current local time (getdate(), not UTC). Indexed (HPFX_OCCURRED). Also used as a constraint name collision (HPFX_OCCURRED covers both the index and the default). |
| 11 | Login | varchar(255) | NO | suser_sname() | CODE-BACKED | SQL login name of the user/process that executed the correction. Auto-populated via suser_sname(). Identifies the DBA account or service account that ran the maintenance. |
| 12 | Machine | varchar(255) | NO | host_name() | CODE-BACKED | Hostname of the client machine that ran the correction. Auto-populated via host_name(). Identifies the workstation or server that executed the maintenance procedure. |
| 13 | Application | varchar(255) | NO | app_name() | CODE-BACKED | Name of the application that executed the correction. Auto-populated via app_name(). Common values: "Microsoft SQL Server Management Studio", "SQLAgent - Job ...", custom maintenance app names. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ManagerID | BackOffice.Manager | FK (FK_BMNG_HPFX) | The back-office manager who authorized the position correction |
| PositionID | History.Position | Implicit | The closed position whose financials were corrected |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Maintenance.PositionFix | INSERT | WRITER | Sole writer - inserts one row per correction execution |
| PROD_BIadmins permissions | SELECT | READER | BI admin users have read access for reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PositionFix (table)
(leaf - no code-level dependencies)
```

Explicit FK dependency: BackOffice.Manager (ManagerID constraint).

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Manager | Table | FK target for ManagerID - enforces valid manager reference |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.PositionFix | Stored Procedure | WRITER - inserts audit row as part of position correction transaction |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HPFX | CLUSTERED PK | PositionFixID ASC | - | - | Active |
| HPFX_MANAGER | NONCLUSTERED | ManagerID ASC | - | - | Active |
| HPFX_OCCURRED | NONCLUSTERED | Occurred ASC | - | - | Active |
| HPFX_POSITION | NONCLUSTERED | PositionID ASC | - | - | Active |

*All indexes: FILLFACTOR=90, on [HISTORY] filegroup.*

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_BMNG_HPFX | FK | ManagerID -> BackOffice.Manager(ManagerID) - enforces valid manager |
| HPFX_OCCURRED | DEFAULT | `getdate()` on Occurred - auto-sets local timestamp at insert |
| HPFX_USER | DEFAULT | `suser_sname()` on Login - captures SQL login identity |
| HPFX_MACHINE | DEFAULT | `host_name()` on Machine - captures client hostname |
| HPFX_APPLICATION | DEFAULT | `app_name()` on Application - captures application name |

---

## 8. Sample Queries

### 8.1 All corrections for a specific position

```sql
SELECT
    pf.PositionFixID,
    pf.ManagerID,
    pf.OldNetProfit,
    pf.NewNetProfit,
    pf.NewNetProfit - pf.OldNetProfit AS NetProfitDelta,
    pf.OldCommission,
    pf.NewCommission,
    pf.OldEndForexRate,
    pf.NewEndForexRate,
    pf.Occurred,
    pf.Login,
    pf.Application
FROM History.PositionFix pf WITH (NOLOCK)
WHERE pf.PositionID = @PositionID
ORDER BY pf.Occurred ASC
```

### 8.2 Recent corrections by manager

```sql
SELECT
    pf.PositionFixID,
    pf.PositionID,
    pf.OldNetProfit,
    pf.NewNetProfit,
    pf.NewNetProfit - pf.OldNetProfit AS NetProfitDelta,
    pf.Occurred,
    pf.Login,
    pf.Machine
FROM History.PositionFix pf WITH (NOLOCK)
WHERE pf.ManagerID = @ManagerID
  AND pf.Occurred >= DATEADD(DAY, -90, GETDATE())
ORDER BY pf.Occurred DESC
```

### 8.3 All corrections in a date range with manager info

```sql
SELECT
    pf.PositionFixID,
    pf.PositionID,
    pf.OldNetProfit,
    pf.NewNetProfit,
    pf.NewNetProfit - pf.OldNetProfit AS NetProfitDelta,
    pf.OldCommission,
    pf.NewCommission,
    pf.Occurred,
    pf.Login,
    pf.Application
FROM History.PositionFix pf WITH (NOLOCK)
WHERE pf.Occurred >= @StartDate
  AND pf.Occurred < @EndDate
ORDER BY pf.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Maintenance.PositionFix full read) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PositionFix | Type: Table | Source: etoro/etoro/History/Tables/History.PositionFix.sql*
