# History.ManualIsSettled

> Audit log recording every manual override of the IsSettled flag on positions, capturing which position was changed, who changed it, when, and what the new value was.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK on ID) |

---

## 1. Business Meaning

History.ManualIsSettled records every manual change to the IsSettled flag on trading positions. IsSettled is a legacy flag that distinguishes real stock positions (IsSettled=1) from CFD positions (IsSettled=0). In the early days of eToro's stock trading, settlement status was sometimes manually corrected by operations or DBA staff when positions were incorrectly classified or when post-trade adjustments were needed.

Each row captures the position affected, the new value set, the database identity of who performed the change (DoneBy = suser_sname()), and the UTC timestamp. Because this is a manual admin operation rather than a system-driven process, no stored procedure writer was found in the codebase - changes are likely applied via direct SQL or an internal DBA tool that relies on the SQL Server login identity for accountability.

With 0 rows in the test environment and no stored procedure references, this table sees infrequent use and may represent a legacy operational process that is rarely or no longer triggered in production.

---

## 2. Business Logic

### 2.1 IsSettled Flag - Real Stock vs CFD Classification

**What**: The NewValue column records the value that IsSettled was changed TO, enabling reconstruction of the full override history for any position.

**Columns/Parameters Involved**: `PositionID`, `NewValue`, `DoneBy`, `Occurred`

**Rules**:
- NewValue=0: position reclassified as CFD (not a real stock position)
- NewValue=1: position reclassified as real stock (settled position, physical delivery)
- Only the new value is stored (no OldValue column) - the prior state must be inferred from the sequence of rows or from Trade.PositionTbl directly
- DoneBy is captured automatically via DEFAULT suser_sname() - the SQL Server login making the change is recorded without requiring the caller to supply it
- Occurred defaults to getutcdate() (UTC), consistent with the rest of the History schema's UTC conventions

### 2.2 Accountability Model - DBA/Operator Identity Capture

**What**: The combination of DoneBy (SQL Server login) and Occurred provides a minimal but complete audit trail for manual interventions, identifying who acted and when without requiring application-layer session context.

**Columns/Parameters Involved**: `DoneBy`, `Occurred`

**Rules**:
- DoneBy is varchar(35), which accommodates typical SQL Server login names (e.g., "ETOROAdmin", "dba_ops", "BOUser_prod")
- Because there is no AppName or HostName column (unlike History.ManagerToPermission), the identity capture is limited to the database login only
- A sequence of rows with the same PositionID traces the full manual intervention history for that position

---

## 3. Data Overview

No data in test environment (0 rows). In production, rows represent manual IsSettled corrections performed by DBA or operations staff. Representative example:

| ID | PositionID | Occurred | DoneBy | NewValue | Meaning |
|----|-----------|----------|--------|----------|---------|
| 1 | 987654321 | 2023-11-14 08:22:11 | ETOROAdmin | 1 | Position reclassified as real stock (IsSettled=1). Admin operation during stock settlement reconciliation. |
| 2 | 987654322 | 2023-11-14 08:22:15 | ETOROAdmin | 1 | Batch reclassification - multiple positions corrected in same session. Same DoneBy and near-identical timestamp. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate key. CLUSTERED PK - sequential ID ordering reflects chronological order of manual overrides. FILLFACTOR=95 and PAGE compression indicate append-only usage with no updates or deletes expected. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | The trading position whose IsSettled flag was manually overridden. References Trade.PositionTbl.PositionID (no FK enforced - history must persist even if the position is closed or archived). bigint matches Trade.PositionTbl.PositionID type. |
| 3 | Occurred | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp when the manual override was applied. DEFAULT getutcdate() - consistent with UTC convention for History schema operational tables (contrast with trigger-based tables that use getdate() local time). NOT NULL - the default ensures every row has a timestamp. |
| 4 | DoneBy | varchar(35) | NO | suser_sname() | CODE-BACKED | The SQL Server login name of the session that performed the IsSettled change. DEFAULT suser_sname() captures the DB login identity automatically without requiring the caller to supply it. varchar(35) - sufficient for SQL Server login names. Provides operator accountability for manual interventions. |
| 5 | NewValue | tinyint | NO | - | CODE-BACKED | The value that IsSettled was set TO by this manual override. 0=position reclassified as CFD (not settled/not real stock), 1=position reclassified as real stock (settled). tinyint appropriate for a boolean-like flag. Only the new value is stored; the previous value must be inferred from prior rows for the same PositionID or from Trade.PositionTbl. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl | Implicit | References the trading position whose IsSettled flag was changed. No FK enforced - history rows persist after positions are archived. |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views found that reference this table. Manual writes via direct SQL or internal tooling.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ManualIsSettled (table)
  - No code-level dependencies (leaf table)
  - Source: Direct SQL writes by DBA/operations staff
```

### 6.1 Objects This Depends On

No dependencies. Free-standing audit log table.

### 6.2 Objects That Depend On This

No stored procedures or application code references found in the SSDT codebase.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryManualIsSettled | CLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryManualIsSettled | PRIMARY KEY | Clustered PK on ID |
| DF_HistoryManualIsSettled_Occurred | DEFAULT | Occurred = getutcdate() |
| DF_HistoryManualIsSettled_DoneBy | DEFAULT | DoneBy = suser_sname() |

FILLFACTOR: 95% - high fill for append-only table. PAGE compression applied.

---

## 8. Sample Queries

### 8.1 Get all manual IsSettled overrides for a specific position

```sql
SELECT
    ID,
    PositionID,
    Occurred,
    DoneBy,
    CASE NewValue WHEN 1 THEN 'Real Stock (Settled)' ELSE 'CFD (Not Settled)' END AS NewIsSettled
FROM [History].[ManualIsSettled] WITH (NOLOCK)
WHERE PositionID = @PositionID
ORDER BY Occurred ASC
```

### 8.2 Audit all manual overrides by operator in a date range

```sql
SELECT
    DoneBy,
    COUNT(*) AS OverrideCount,
    MIN(Occurred) AS FirstOverride,
    MAX(Occurred) AS LastOverride,
    SUM(CASE WHEN NewValue = 1 THEN 1 ELSE 0 END) AS SetToSettled,
    SUM(CASE WHEN NewValue = 0 THEN 1 ELSE 0 END) AS SetToCFD
FROM [History].[ManualIsSettled] WITH (NOLOCK)
WHERE Occurred >= DATEADD(DAY, -30, GETUTCDATE())
GROUP BY DoneBy
ORDER BY OverrideCount DESC
```

### 8.3 Find positions with multiple manual overrides (repeated adjustments)

```sql
SELECT
    PositionID,
    COUNT(*) AS OverrideCount,
    MIN(Occurred) AS FirstOverride,
    MAX(Occurred) AS LastOverride,
    MIN(NewValue) AS MinNewValue,
    MAX(NewValue) AS MaxNewValue
FROM [History].[ManualIsSettled] WITH (NOLOCK)
GROUP BY PositionID
HAVING COUNT(*) > 1
ORDER BY OverrideCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (no SP references found) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.ManualIsSettled | Type: Table | Source: etoro/etoro/History/Tables/History.ManualIsSettled.sql*
