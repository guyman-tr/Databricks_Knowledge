# History.BSL_MIMOSnapShotsOld

> Retired shard of BSL MIMO (Balance Stop Loss Multi-Instrument Multi-Order) equity snapshots, structurally identical to History.BSL_MIMOSnapShotsPartition - the original generation before the partition table replaced it.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (ID, Occurred) - composite PK CLUSTERED |
| **Partition** | Yes - EndMonth scheme, partitioned on Occurred |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.BSL_MIMOSnapShotsOld is the legacy predecessor to History.BSL_MIMOSnapShotsPartition. Both tables store point-in-time snapshots of MIMO (Multi-Instrument Multi-Order) credit calculations captured during Balance Stop Loss (BSL) equity monitoring runs - eToro's automated system that evaluates customer account equity across all open positions and triggers warnings or closures when equity falls below thresholds.

For each BSL execution, this table records the MIMO credit event, associated credit change, position, price rate, and Bid/Ask prices at the time of the snapshot. This enables post-execution equity verification and audit reconstruction.

The "Old" designation indicates this was the first generation of the table, later replaced by History.BSL_MIMOSnapShotsPartition when the partition architecture was re-designed. The IDENTITY seed at 11,717,500,000 (same as the Partition table) suggests both tables were in concurrent use or the seed was carried over during migration. The EndMonth partition scheme distributes records across monthly partitions by Occurred date. No procedures in the current codebase reference this table directly - it is archived data from the BSL legacy era.

---

## 2. Business Logic

### 2.1 BSL Snapshot Pattern

**What**: Each row is one position's MIMO credit state captured during a BSL evaluation run.

See [History.BSL_MIMOSnapShotsPartition](History.BSL_MIMOSnapShotsPartition.md) Section 2.1 for the full BSL execution snapshot pattern - identical logic applies.

**Columns/Parameters Involved**: `MimoCreditID`, `BSLChangeCreditID`, `PositionID`, `PriceRateID`, `Bid`, `Ask`, `Occurred`

**Rules**:
- One row per position per BSL execution run
- Bid/Ask captured at the exact moment of evaluation for equity reconstruction
- NOT FOR REPLICATION flag on IDENTITY prevents re-seeding during replication

---

## 3. Data Overview

| ID | MimoCreditID | PositionID | Bid | Ask | Occurred | Meaning |
|----|-------------|-----------|-----|-----|----------|---------|
| (archived data) | - | - | - | - | - | Contains BSL snapshot records from the legacy era before History.BSL_MIMOSnapShotsPartition replaced this table. Current environment may show 0 rows if data was migrated or purged. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint IDENTITY(11717500000,1) NOT FOR REPLICATION | NO | - | CODE-BACKED | Surrogate primary key with IDENTITY seeded at 11,717,500,000. NOT FOR REPLICATION ensures no identity re-generation during replication. PK component with Occurred. Same semantics as History.BSL_MIMOSnapShotsPartition.ID. |
| 2 | MimoCreditID | bigint | NO | - | CODE-BACKED | MIMO credit calculation active for this position at snapshot time. Links to History.ActiveCredit CreditID. Same semantics as History.BSL_MIMOSnapShotsPartition.MimoCreditID. |
| 3 | BSLChangeCreditID | bigint | NO | - | CODE-BACKED | The credit change event that triggered recording this snapshot. Same semantics as History.BSL_MIMOSnapShotsPartition.BSLChangeCreditID. |
| 4 | PositionID | int | NO | - | CODE-BACKED | Trading position evaluated in this BSL snapshot. Implicit FK to position tables. Same semantics as History.BSL_MIMOSnapShotsPartition.PositionID. |
| 5 | PriceRateID | bigint | NO | - | CODE-BACKED | Price rate record used for equity calculation at snapshot time. Same semantics as History.BSL_MIMOSnapShotsPartition.PriceRateID. |
| 6 | Bid | decimal(16,8) | NO | - | CODE-BACKED | Instrument bid price at BSL check time. 8 decimal places for pip-level precision. Same semantics as History.BSL_MIMOSnapShotsPartition.Bid. |
| 7 | Ask | decimal(16,8) | NO | - | CODE-BACKED | Instrument ask price at BSL check time. Same semantics as History.BSL_MIMOSnapShotsPartition.Ask. |
| 8 | Occurred | datetime | NO | getdate() | CODE-BACKED | Server timestamp when snapshot was recorded. Default = getdate() (local server time). PK component and partition key (EndMonth scheme). Same semantics as History.BSL_MIMOSnapShotsPartition.Occurred. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MimoCreditID | History.ActiveCredit (CreditID) | Implicit | MIMO credit event active at snapshot time |
| PositionID | Trade.PositionTbl / History.Position | Implicit | Position evaluated in this BSL snapshot |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none found) | - | - | No active procedures reference this table. It is purely archival. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BSL_MIMOSnapShotsOld (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found. Succeeded by History.BSL_MIMOSnapShotsPartition.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryBSLMIMOSnapShots_new | CLUSTERED PK | ID ASC, Occurred ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryBSLMIMOSnapShots_new | PRIMARY KEY CLUSTERED | (ID, Occurred) composite, FILLFACTOR=95 |
| DF_BSL_MIMOSnapShotsNEW | DEFAULT | Occurred = getdate() |

---

## 8. Sample Queries

### 8.1 Get MIMO snapshots for a specific position from the legacy era
```sql
SELECT ID, MimoCreditID, BSLChangeCreditID, PositionID, PriceRateID, Bid, Ask, Occurred
FROM History.BSL_MIMOSnapShotsOld WITH (NOLOCK)
WHERE PositionID = 12345678
ORDER BY Occurred DESC;
```

### 8.2 Check data range in the archive
```sql
SELECT COUNT(*) AS RowCount, MIN(Occurred) AS Earliest, MAX(Occurred) AS Latest
FROM History.BSL_MIMOSnapShotsOld WITH (NOLOCK);
```

### 8.3 Lookup by MIMO credit ID
```sql
SELECT ID, PositionID, Bid, Ask, Occurred
FROM History.BSL_MIMOSnapShotsOld WITH (NOLOCK)
WHERE MimoCreditID = 123456789
ORDER BY Occurred ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.0/10 (Elements: 9.0/10, Logic: 7.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 active | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BSL_MIMOSnapShotsOld | Type: Table | Source: etoro/etoro/History/Tables/History.BSL_MIMOSnapShotsOld.sql*
