# BackOffice.MirrorUniqueTraders

> Tracks the set of unique Popular Investors (traders) that each customer has ever copied, providing a de-duplicated list of copy-trading relationships by CID pair.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | PK_MirrorUniqueTraders: CID + ParentCID (CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (clustered PK on CID + ParentCID) |

---

## 1. Business Meaning

`BackOffice.MirrorUniqueTraders` records each unique (copier CID, copied trader CID) pair in eToro's CopyTrader system. "Mirror" is eToro's internal term for copy-trading. Where `MirrorComulative` holds aggregate statistics per copier, this table holds the actual set of traders each customer has copied - one row per unique pairing. If a customer stops copying a trader and then starts again, the pairing still exists as a single row (the uniqueness is enforced by the PK).

This table exists to support queries like "how many distinct traders has this customer copied?" (answerable via COUNT on CID) and "which customers have copied this particular Popular Investor?" (answerable via query on ParentCID). It provides the normalized detail behind the `NumOfUniqueCopiedTraders` aggregate in `MirrorComulative`.

Data is populated by a background aggregation job, evidenced by the `RunTime` column with a `GETDATE()` default. The job inserts new CID/ParentCID pairs as copy relationships are initiated and may run on a scheduled basis to keep the table consistent with the live trading data.

---

## 2. Business Logic

### 2.1 Unique Copier-to-Trader Pairing

**What**: Each row represents a unique historical fact: customer CID has at some point copied trader ParentCID.

**Columns/Parameters Involved**: `CID`, `ParentCID`, `RunTime`

**Rules**:
- The composite PK (CID, ParentCID) ensures each pair appears at most once.
- A row persists even after the copy relationship ends - the table records the historical fact of ever having copied.
- `RunTime` records when the background job inserted this row (not when the copy relationship started).
- CID = the follower/copier. ParentCID = the leader/Popular Investor being copied.

**Diagram**:
```
Customer (CID=1000) has copied:
  ParentCID=500  -> Popular Investor A (row 1)
  ParentCID=750  -> Popular Investor B (row 2)
  ParentCID=500  -> copies PI-A again (no new row - PK prevents duplicate)

Result: 2 rows, NumOfUniqueCopiedTraders = 2
```

---

## 3. Data Overview

Table is currently empty in the connected environment. Based on schema design:

| CID | ParentCID | RunTime | Meaning |
|-----|-----------|---------|---------|
| (example) | 500 | 2025-01-10 08:00 | CID copied Popular Investor with CID=500 at some point |
| (example) | 750 | 2025-03-22 08:00 | CID also copied Popular Investor with CID=750 |
| (example2) | 500 | 2025-02-15 08:00 | A different customer also copied CID=500 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | NAME-INFERRED | Customer ID of the follower/copier - the customer who copied the trader. Part of the composite PK. References Customer.Customer.CID. |
| 2 | ParentCID | int | NO | - | NAME-INFERRED | Customer ID of the leader/Popular Investor being copied. "Parent" refers to the copy-trade parent in the mirror relationship hierarchy. Part of the composite PK. |
| 3 | RunTime | datetime | YES | GETDATE() | CODE-BACKED | Timestamp when the background aggregation job inserted this row. Reflects when the unique pairing was first recorded, not necessarily when the copy relationship began. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer.CID | Implicit | Identifies the copying customer |
| ParentCID | Customer.Customer.CID | Implicit | Identifies the copied Popular Investor (also a customer) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (leaf table).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in BackOffice schema procedures or views.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MirrorUniqueTraders | CLUSTERED PK | CID ASC, ParentCID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DFMirrorUniqueTraders_RunTime | DEFAULT | RunTime defaults to GETDATE() |

---

## 8. Sample Queries

### 8.1 List all unique traders copied by a specific customer

```sql
SELECT CID, ParentCID, RunTime
FROM BackOffice.MirrorUniqueTraders WITH (NOLOCK)
WHERE CID = 99999
ORDER BY RunTime;
```

### 8.2 Find all customers who have copied a specific Popular Investor

```sql
SELECT CID, ParentCID
FROM BackOffice.MirrorUniqueTraders WITH (NOLOCK)
WHERE ParentCID = 500
ORDER BY CID;
```

### 8.3 Count unique traders copied per customer (top active copiers)

```sql
SELECT CID, COUNT(*) AS UniqueTradersCopied
FROM BackOffice.MirrorUniqueTraders WITH (NOLOCK)
GROUP BY CID
ORDER BY UniqueTradersCopied DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.7/10 (Elements: 7.5/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 4/11 (DDL, Live Data, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.MirrorUniqueTraders | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.MirrorUniqueTraders.sql*
