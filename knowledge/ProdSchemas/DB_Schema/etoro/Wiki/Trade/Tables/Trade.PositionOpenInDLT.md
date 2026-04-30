# Trade.PositionOpenInDLT

> Single-column flag table indicating which positions have been recorded on the Distributed Ledger Technology (blockchain) layer. Used by the crypto real-asset settlement flow.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | PositionID (bigint, PK) |
| **Partition** | No (DICTIONARY filegroup) |
| **Indexes** | 1 (PK CLUSTERED) |

---

## 1. Business Meaning

**WHAT**: Trade.PositionOpenInDLT is a minimal flag table with a single column, PositionID. A PositionID present in this table indicates that the position has been opened and recorded on the Distributed Ledger Technology (DLT) layer-i.e., the blockchain. This supports eToro's crypto real-asset flow where some positions represent actual on-chain holdings rather than synthetic CFDs.

**WHY**: Real-asset crypto positions require reconciliation between the trading database (Trade.PositionTbl) and the blockchain. When a position is opened on-chain, the system must record that fact so downstream processes (settlement, reporting, close flow) know the position exists in DLT. The table acts as a membership set: "these PositionIDs are on-chain." Without it, the system could not distinguish DLT-recorded positions from those pending or in-error.

**HOW**: Procedures in the crypto/DLT open flow (e.g., after successful on-chain position creation) INSERT the PositionID into this table. The close flow may check membership before closing on-chain. The table is on the DICTIONARY filegroup, appropriate for low-volume reference data. The live database has 0 rows, suggesting either no DLT positions have been opened recently in this environment or the feature is not yet active.

---

## 2. Business Logic

### 2.1 DLT Recorded Flag

**What**: Presence in the table means "position is recorded on DLT."

**Columns/Parameters Involved**: PositionID

**Rules**:
- If PositionID is in PositionOpenInDLT: position has been opened on the blockchain.
- If PositionID is not in the table: position may be pending, CFD, or non-DLT.
- No additional columns; the table is a pure membership set.

### 2.2 Integration with Position Lifecycle

**What**: INSERT occurs after successful DLT open; DELETE may occur on close or rollback.

**Rules**:
- Open flow: After DLT confirms position creation, INSERT PositionID.
- Close flow: May need to close on-chain first, then remove from table or leave for audit (design may vary).
- RootHedgeServerID in PositionTbl (e.g., 86 for DLT flow) may be used in conjunction with this table for close compatibility.

---

## 3. Data Overview

| PositionID | Meaning |
|------------|---------|
| (empty) | Table has 0 rows. No positions currently flagged as DLT-recorded. |

**Selection criteria**: Table is empty. When populated, each row would be a PositionID from Trade.PositionTbl that has been recorded on the DLT/blockchain.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | PK. FK to Trade.PositionTbl.PositionID. Indicates this position has been opened/recorded on DLT. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl | Implicit | The position recorded on DLT |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (DLT open flow) | INSERT | Writer | Inserts after on-chain position creation |
| (DLT close flow) | SELECT, possibly DELETE | Reader/Modifier | Checks membership for close logic |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionOpenInDLT (table)
└── Trade.PositionTbl (implicit via PositionID)
```

### 6.1 Objects This Depends On

No explicit FKs. Implicit: Trade.PositionTbl.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DLT open procedures | Procedure | INSERT after on-chain open |
| DLT close procedures | Procedure | SELECT to check if position is on-chain |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PositionOpenInDLT | CLUSTERED PK | PositionID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_PositionOpenInDLT | PRIMARY KEY | PositionID |

### 7.3 Filegroup

Table is on [DICTIONARY] filegroup.

---

## 8. Sample Queries

### 8.1 Check if position is on DLT
```sql
SELECT 1
FROM   Trade.PositionOpenInDLT d WITH (NOLOCK)
WHERE  d.PositionID = @PositionID;
```

### 8.2 All DLT-recorded positions
```sql
SELECT d.PositionID, p.CID, p.InstrumentID, p.Amount, p.InitDateTime
FROM   Trade.PositionOpenInDLT d WITH (NOLOCK)
       INNER JOIN Trade.PositionTbl p WITH (NOLOCK) ON d.PositionID = p.PositionID
WHERE  p.StatusID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 7.0/10 (Elements: 8/10, Logic: 6/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED*
*Object: Trade.PositionOpenInDLT | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.PositionOpenInDLT.sql*
