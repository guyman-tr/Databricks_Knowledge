# History.CES_UpdateExposures

> Audit log for manual CES (Currency Exposure Service) exposure update operations - records who applied a directional exposure adjustment to an instrument on a hedge server, and whether it was an open or closed position update.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID - IDENTITY(1,2) bigint, no PK constraint (heap) |
| **Partition** | No |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

History.CES_UpdateExposures logs each manual or programmatic call to update Currency Exposure Service (CES) exposure data for a specific instrument. CES tracks the net hedge exposure for each instrument across all positions. When exposure needs to be corrected or adjusted (e.g., after a data inconsistency or reconciliation), the update is recorded here for auditability.

Each row captures: who made the update (DBUserName, AppUserName), which instrument (InstrumentID), the exposure amount (Amount), direction (IsBuy), which hedge server (HedgeServerID), and whether it was an open or closed position exposure (IsOpen).

Only 3 rows exist in the current environment (IDs 1, 3, 5 - IDENTITY step=2 confirms odd-only), all from May 2025 by user "moshezo" (TRAD\moshezo). Instruments 7 and 8 with Amount=100, IsBuy=true, IsOpen=false. This is an infrequent administrative operation.

Sister table: History.CES_ReloadExposures captures full exposure reloads; this table captures incremental/targeted updates.

---

## 2. Business Logic

### 2.1 CES Exposure Update Audit

**What**: Logs a directed exposure adjustment to the CES hedge exposure data.

**Columns/Parameters Involved**: `InstrumentID`, `Amount`, `IsBuy`, `HedgeServerID`, `IsOpen`, `AppUserName`, `DBUserName`

**Rules**:
- Written via History.CES_LogUpdateExposures(@AppUserName, @InstrumentID, @Amount, @IsBuy, @HedgeServerID, @IsOpen)
- IsBuy=1: long (buy) direction exposure update; IsBuy=0: short (sell) direction
- IsOpen=1: update affects open position exposure; IsOpen=0: update affects closed position exposure
- Amount: the size of the exposure adjustment (decimal 16,6 = supports both large notional and fractional units)

---

## 3. Data Overview

| ID | Occurred | AppUserName | InstrumentID | Amount | IsBuy | HedgeServerID | IsOpen |
|----|----------|------------|-------------|--------|-------|--------------|--------|
| 1 | 2025-05-27 11:48 | moshezo | 7 | 100 | true | 8 | false |
| 3 | 2025-05-27 11:49 | moshezo | 8 | 100 | true | 8 | false |
| 5 | 2025-05-27 11:52 | moshezo | 8 | 100 | true | 8 | false |

3 rows total | All from 2025-05-27 | Single user | IDENTITY(1,2) = odd-only IDs (1,3,5)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint IDENTITY(1,2) | NO | - | VERIFIED | Surrogate row ID. IDENTITY seed=1, step=2 - produces odd-only IDs (1,3,5,...). No PK constraint - heap table. |
| 2 | Occurred | datetime | YES | GETUTCDATE() | VERIFIED | UTC timestamp when the exposure update was logged. Default = GETUTCDATE(). |
| 3 | DBUserName | nvarchar(255) | YES | - | VERIFIED | SQL Server login name at call time. Populated via SUSER_NAME() in History.CES_LogUpdateExposures. Observed: "TRAD\moshezo". |
| 4 | AppUserName | nvarchar(255) | YES | - | VERIFIED | Application-level user name passed as parameter. Identifies the system or operator that initiated the update. |
| 5 | InstrumentID | int | YES | - | VERIFIED | The financial instrument whose CES exposure was updated. Implicit FK to History.Instrument. |
| 6 | Amount | decimal(16,6) | YES | - | VERIFIED | The exposure adjustment amount. Supports large notional amounts (16 digits total, 6 decimal places). |
| 7 | IsBuy | bit | YES | - | VERIFIED | Direction of the exposure: 1=long (buy), 0=short (sell). Determines which side of the exposure is being adjusted. |
| 8 | HedgeServerID | int | YES | - | VERIFIED | ID of the hedge server for which the exposure is updated. Implicit FK to History.HedgeServer. Observed: HedgeServerID=8. |
| 9 | IsOpen | bit | YES | - | VERIFIED | Whether the update applies to open positions (1) or closed positions (0). Observed: IsOpen=false (all rows). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | History.Instrument | Implicit | The instrument whose exposure was updated. |
| HedgeServerID | History.HedgeServer | Implicit | The hedge server context for this exposure update. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.CES_LogUpdateExposures | AppUserName, InstrumentID, Amount, IsBuy, HedgeServerID, IsOpen | Writer | Sole writer. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CES_UpdateExposures (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.CES_LogUpdateExposures | Stored Procedure | Writer - logs CES exposure update events |

---

## 7. Technical Details

### 7.1 Indexes

None. Table is a heap.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_HistoryCES_UpdateExposures | DEFAULT | Occurred = GETUTCDATE() |

---

## 8. Sample Queries

### 8.1 Get all exposure update audit records
```sql
SELECT ID, Occurred, DBUserName, AppUserName, InstrumentID,
       Amount, IsBuy, HedgeServerID, IsOpen
FROM History.CES_UpdateExposures WITH (NOLOCK)
ORDER BY Occurred DESC;
```

### 8.2 Get exposure updates for a specific instrument
```sql
SELECT ID, Occurred, AppUserName, Amount, IsBuy, HedgeServerID, IsOpen
FROM History.CES_UpdateExposures WITH (NOLOCK)
WHERE InstrumentID = 8
ORDER BY Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9.5/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 9 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CES_UpdateExposures | Type: Table | Source: etoro/etoro/History/Tables/History.CES_UpdateExposures.sql*
