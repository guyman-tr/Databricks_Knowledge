# Hedge.ArchiveHedgeTables_SS

> Secondary-server archive orchestrator: same 5-step pipeline as Hedge.ArchiveHedgeTables, but routes CustomerOpenPositions and CustomerClosedPositions to DB_Logs database instead of local Hedge.Archive* procedures.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Orchestrator - Steps 2+5 route to DB_Logs.Hedge.Archive* (cross-DB) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.ArchiveHedgeTables_SS` is the secondary-server (SS) variant of the Hedge schema archiving orchestrator. It mirrors the 5-step pipeline of `Hedge.ArchiveHedgeTables` but redirects customer position archiving to the `DB_Logs` database.

The "SS" designation indicates this procedure runs on secondary servers where customer position data (CustomerOpenPositions and CustomerClosedPositions) should be archived into `DB_Logs.Hedge.*` tables rather than a local History schema. This separation exists because on secondary servers, the authoritative archive target for customer-facing position data resides in a separate `DB_Logs` database, while account-level data (AccountStatus, AccountOpenPositions, AccountClosedPositions) is still archived locally.

**Primary vs SS routing comparison:**

| Step | Table | ArchiveHedgeTables (Primary) | ArchiveHedgeTables_SS (Secondary) |
|------|-------|------------------------------|-----------------------------------|
| 1 | AccountStatus | Hedge.ArchiveAccountStatus (local) | Hedge.ArchiveAccountStatus (local) |
| 2 | CustomerOpenPositions | Hedge.ArchiveCustomerOpenPositions (local) | **DB_Logs.Hedge.ArchiveCustomerOpenPositions** |
| 3 | AccountOpenPositions | Hedge.ArchiveAccountOpenPositions (local) | Hedge.ArchiveAccountOpenPositions (local) |
| 4 | AccountClosedPositions | Hedge.ArchiveAccountClosedPositions (local) | Hedge.ArchiveAccountClosedPositions (local) |
| 5 | CustomerClosedPositions | Hedge.ArchiveCustomerClosedPositions (local) | **DB_Logs.Hedge.ArchiveCustomerClosedPositions** |

The watermark reads (SELECT MAX(OccurredAt)) are always from the LOCAL History schema, regardless of where the archive SP is routed.

---

## 2. Business Logic

### 2.1 Identical Interval-Aligned Date Window Calculation

**What**: Same DATEADD/DATEDIFF math as ArchiveHedgeTables for both @EndDate and per-table @StartDate.

**Rules**:
- `@EndDate` = floor of current time to nearest @IntervalInMinutes: epoch-anchored to '2010-01-01'
- `@StartDate` per step = ceiling of MAX(OccurredAt) from local History table
- If History table empty: defaults to '2010-01-01' epoch

### 2.2 Cross-DB Customer Position Routing (Steps 2 and 5)

**What**: Steps 2 and 5 invoke Archive procedures in the `DB_Logs` database via 3-part names, not local Hedge schema procedures.

**Rules**:
- Step 2: `EXEC DB_Logs.Hedge.ArchiveCustomerOpenPositions @StartDate, @EndDate, @IntervalInMinutes`
- Step 5: `EXEC DB_Logs.Hedge.ArchiveCustomerClosedPositions @StartDate, @EndDate, @IntervalInMinutes`
- Watermark for Step 2 is still read from local `History.CustomerOpenPositions`
- Watermark for Step 5 is still read from local `History.CustomerClosedPositions`
- Steps 1, 3, 4 call local `Hedge.Archive*` procedures identically to the primary variant

**Diagram**:
```
Hedge.ArchiveHedgeTables_SS(@IntervalInMinutes)
      |
      @EndDate = interval_floor(getdate(), @IntervalInMinutes)
      |
      Step 1: @StartDate = interval_ceil(MAX(OccurredAt) FROM History.AccountStatus)
              EXEC Hedge.ArchiveAccountStatus @StartDate, @EndDate, @IntervalInMinutes  [LOCAL]
      |
      Step 2: @StartDate = interval_ceil(MAX(OccurredAt) FROM History.CustomerOpenPositions)
              EXEC DB_Logs.Hedge.ArchiveCustomerOpenPositions ...                       [DB_Logs]
      |
      Step 3: EXEC Hedge.ArchiveAccountOpenPositions   (local - same as primary)
      Step 4: EXEC Hedge.ArchiveAccountClosedPositions (local - same as primary)
      |
      Step 5: @StartDate = interval_ceil(MAX(OccurredAt) FROM History.CustomerClosedPositions)
              EXEC DB_Logs.Hedge.ArchiveCustomerClosedPositions ...                     [DB_Logs]
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IntervalInMinutes | int | NO | - | CODE-BACKED | Archive window granularity in minutes (typically 15). Drives @EndDate floor and per-table @StartDate ceiling, identical to ArchiveHedgeTables. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | History.AccountStatus | Lookup | Reads MAX(OccurredAt) for AccountStatus watermark |
| (reads) | History.CustomerOpenPositions | Lookup | Reads MAX(OccurredAt) for CustomerOpenPositions watermark |
| (reads) | History.AccountOpenPositions | Lookup | Reads MAX(OccurredAt) for AccountOpenPositions watermark |
| (reads) | History.AccountClosedPositions | Lookup | Reads MAX(OccurredAt) for AccountClosedPositions watermark |
| (reads) | History.CustomerClosedPositions | Lookup | Reads MAX(OccurredAt) for CustomerClosedPositions watermark |
| (calls) | Hedge.ArchiveAccountStatus | Procedure call | Local archive for AccountStatus |
| (calls) | DB_Logs.Hedge.ArchiveCustomerOpenPositions | Procedure call | Cross-DB archive for CustomerOpenPositions |
| (calls) | Hedge.ArchiveAccountOpenPositions | Procedure call | Local archive for AccountOpenPositions |
| (calls) | Hedge.ArchiveAccountClosedPositions | Procedure call | Local archive for AccountClosedPositions |
| (calls) | DB_Logs.Hedge.ArchiveCustomerClosedPositions | Procedure call | Cross-DB archive for CustomerClosedPositions |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Invoked by a scheduled SQL Agent job on secondary servers. Companion to `Hedge.ArchiveHedgeTables` (primary server variant).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ArchiveHedgeTables_SS (procedure)
|- History.AccountStatus (table) - watermark read
|- History.CustomerOpenPositions (table) - watermark read
|- History.AccountOpenPositions (table) - watermark read
|- History.AccountClosedPositions (table) - watermark read
|- History.CustomerClosedPositions (table) - watermark read
|- Hedge.ArchiveAccountStatus (procedure) - local call
|- DB_Logs.Hedge.ArchiveCustomerOpenPositions (procedure) - cross-DB call
|- Hedge.ArchiveAccountOpenPositions (procedure) - local call
|- Hedge.ArchiveAccountClosedPositions (procedure) - local call
+-- DB_Logs.Hedge.ArchiveCustomerClosedPositions (procedure) - cross-DB call
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.AccountStatus | Table | SELECT MAX(OccurredAt) watermark |
| History.CustomerOpenPositions | Table | SELECT MAX(OccurredAt) watermark |
| History.AccountOpenPositions | Table | SELECT MAX(OccurredAt) watermark |
| History.AccountClosedPositions | Table | SELECT MAX(OccurredAt) watermark |
| History.CustomerClosedPositions | Table | SELECT MAX(OccurredAt) watermark |
| Hedge.ArchiveAccountStatus | Procedure | Local archive for AccountStatus data |
| DB_Logs.Hedge.ArchiveCustomerOpenPositions | Procedure | Cross-DB archive for customer open positions |
| Hedge.ArchiveAccountOpenPositions | Procedure | Local archive for AccountOpenPositions data |
| Hedge.ArchiveAccountClosedPositions | Procedure | Local archive for AccountClosedPositions data |
| DB_Logs.Hedge.ArchiveCustomerClosedPositions | Procedure | Cross-DB archive for customer closed positions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (SQL Agent archiving job - secondary server) | External | Calls with @IntervalInMinutes=15 on a schedule |
| Hedge.ArchiveHedgeTables | Procedure | Companion for primary server - same steps, local routing only |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- No transaction wrapper - each Archive* call is independent
- No error handling - if one step fails, subsequent steps do not run
- Watermark reads are always LOCAL (History schema), even for steps routing to DB_Logs
- Requires network/linked connectivity to DB_Logs database for steps 2 and 5

---

## 8. Sample Queries

### 8.1 Execute: Run secondary-server archive for 15-minute windows

```sql
EXEC Hedge.ArchiveHedgeTables_SS @IntervalInMinutes = 15
```

### 8.2 Compare: Check which variant applies (primary vs SS)

```sql
-- Check if local CustomerOpenPositions archive proc exists (primary server)
SELECT OBJECT_ID('Hedge.ArchiveCustomerOpenPositions') AS LocalProcExists

-- Check if DB_Logs is accessible (SS server)
SELECT TOP 1 1 AS DB_LogsAccessible FROM DB_Logs.Hedge.ArchiveCustomerOpenPositions  -- will error if not accessible
```

### 8.3 Monitor: Check archive lag on SS server

```sql
SELECT
    'History.CustomerOpenPositions' AS Table_Name,
    MAX(OccurredAt) AS LastArchived,
    DATEDIFF(MINUTE, MAX(OccurredAt), GETUTCDATE()) AS LagMinutes
FROM History.CustomerOpenPositions WITH (NOLOCK)
UNION ALL
SELECT 'History.CustomerClosedPositions', MAX(OccurredAt), DATEDIFF(MINUTE, MAX(OccurredAt), GETUTCDATE())
FROM History.CustomerClosedPositions WITH (NOLOCK)
ORDER BY LagMinutes DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.9/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ArchiveHedgeTables_SS | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.ArchiveHedgeTables_SS.sql*
