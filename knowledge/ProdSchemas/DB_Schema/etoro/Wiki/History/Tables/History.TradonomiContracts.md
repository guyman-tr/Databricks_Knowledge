# History.TradonomiContracts

> SQL Server system-versioned temporal history table for Trade.TradonomiContracts - stores superseded Tradonomi CFD contract configurations per instrument, with dual audit trail via both temporal versioning and ASM-generated triggers writing to History.AuditHistory.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No - stored on [PRIMARY] with PAGE compression |
| **Indexes** | 1 active (CLUSTERED on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

History.TradonomiContracts is the temporal history backing table for Trade.TradonomiContracts, which defines Tradonomi contracts - CFD (Contract for Difference) agreements between eToro and a counterparty (Tradonomi/liquidity provider) covering specific instruments for a defined period.

Each Tradonomi contract specifies which instrument is covered (InstrumentID), whether it is currently active (IsActive), its validity window (FromDate to ToDate), and an identifying description. When a contract is added, modified, or removed in Trade.TradonomiContracts, SQL Server system-versioning archives the old row here.

Notably, Trade.TradonomiContracts has both SQL Server temporal versioning AND ASM (Automatic Schema Management) audit triggers that write to History.AuditHistory - providing two independent audit trails for contract changes. This suggests that Tradonomi contract changes are subject to strict regulatory/compliance audit requirements.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Changes to Tradonomi contract configurations produce history rows here with SysStartTime/SysEndTime period boundaries.

**Columns/Parameters Involved**: `ContractID`, `InstrumentID`, `IsActive`, `FromDate`, `ToDate`, `Description`, `SysStartTime`, `SysEndTime`

**Rules**:
- SysStartTime = when this contract configuration version became active
- SysEndTime = when it was superseded
- A contract's history would show: initial creation, any IsActive toggle, any date range changes
- FromDate and ToDate in the contract define the validity window for the CFD agreement (business dates, not temporal period)
- DbLoginName = suser_name() (SQL login); AppLoginName = context_info() (application identity)

### 2.2 Dual Audit Trail

**What**: Changes to Trade.TradonomiContracts are recorded in BOTH this temporal history table AND History.AuditHistory (via ASM triggers).

**Columns/Parameters Involved**: All business columns (ContractID, InstrumentID, IsActive, FromDate, ToDate)

**Rules**:
- This table: stores FULL ROW snapshots with period timestamps (SQL Server managed)
- History.AuditHistory: stores per-column change records (I=Insert, U=Update, D=Delete) with user context
- Both audit trails exist simultaneously for each change - AuditHistory provides column-level diff, this table provides point-in-time full state
- IsActive toggling (activate/deactivate a contract) generates entries in both audit mechanisms

---

## 3. Data Overview

Table is typically empty in non-production environments. Production accumulates rows as Tradonomi contracts are negotiated, activated, and expired.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ContractID | INT | NO | - | CODE-BACKED | Unique identifier of the Tradonomi contract (PK in source table). Allows linking history rows to the current or other historical versions of the same contract. |
| 2 | InstrumentID | INT | NO | - | CODE-BACKED | The financial instrument covered by this Tradonomi contract (FK to Trade.Instrument in source). Identifies which instrument's CFD arrangement changed. |
| 3 | IsActive | TINYINT | NO | - | CODE-BACKED | Whether this contract was active at time SysStartTime: 0=inactive, 1=active. History rows show when contracts were activated or deactivated. |
| 4 | FromDate | DATETIME | NO | - | CODE-BACKED | Business start date of the Tradonomi contract's validity window. Not the same as SysStartTime (which is the temporal row version timestamp). |
| 5 | ToDate | DATETIME | NO | - | CODE-BACKED | Business end date of the contract's validity window. After this date the contract has expired even if IsActive=1. |
| 6 | Description | VARCHAR(150) | YES | NULL | CODE-BACKED | Human-readable contract identifier. UNIQUE constraint in source table (UC_Description). Allows identifying contracts by name rather than ContractID. |
| 7 | DbLoginName | NVARCHAR(128) | YES | NULL | CODE-BACKED | SQL Server login that made the change (suser_name() at DML time). Preserved for change attribution. |
| 8 | AppLoginName | VARCHAR(500) | YES | NULL | CODE-BACKED | Application login from context_info() at DML time. Identifies calling service or admin tool. |
| 9 | SysStartTime | DATETIME2(7) | NO | - | CODE-BACKED | UTC timestamp when this contract version became active. SQL Server system-versioning managed. |
| 10 | SysEndTime | DATETIME2(7) | NO | - | CODE-BACKED | UTC timestamp when this contract version was superseded. Clustered index leading column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ContractID | Trade.TradonomiContracts | Temporal (parent) | Each row is a historical version of a Trade.TradonomiContracts row. |
| InstrumentID | Trade.Instrument | Temporal (inherited) | Historical snapshot of which instrument the contract covered. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.TradonomiContracts | SYSTEM_VERSIONING | Temporal parent | Writes superseded contract versions here automatically. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.TradonomiContracts (table)
  (leaf - temporal history table)
```

### 6.1 Objects This Depends On

No hard DDL dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.TradonomiContracts | Table | Temporal parent - writes superseded contract versions automatically |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_TradonomiContracts | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (PAGE compression) |

### 7.2 Constraints

None. Temporal history tables have no PK, FK, or CHECK constraints.

---

## 8. Sample Queries

### 8.1 View all Tradonomi contract versions for a specific contract
```sql
SELECT h.ContractID, h.InstrumentID, h.IsActive, h.FromDate, h.ToDate, h.Description,
       h.SysStartTime, h.SysEndTime, h.DbLoginName
FROM History.TradonomiContracts h WITH (NOLOCK)
WHERE h.ContractID = 1
ORDER BY h.SysStartTime;
```

### 8.2 Find when a contract was deactivated
```sql
SELECT h.ContractID, h.Description, h.IsActive, h.SysStartTime AS DeactivatedAt, h.DbLoginName
FROM History.TradonomiContracts h WITH (NOLOCK)
WHERE h.IsActive = 0
ORDER BY h.SysStartTime DESC;
```

### 8.3 View contracts active as of a specific date
```sql
SELECT tc.ContractID, tc.InstrumentID, tc.IsActive, tc.FromDate, tc.ToDate, tc.Description
FROM Trade.TradonomiContracts
FOR SYSTEM_TIME AS OF '2024-06-01T00:00:00'
WHERE IsActive = 1
ORDER BY tc.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 (temporal - SQL Server managed) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.TradonomiContracts | Type: Table | Source: etoro/etoro/History/Tables/History.TradonomiContracts.sql*
