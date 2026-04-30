# MoneyBus.WithdrawGetList

> Retrieves multiple withdrawal records by a batch of IDs using the MoneyBus.IDs table-valued parameter, ordered by ID ascending.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns result set from Withdrawals filtered by ID list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.WithdrawGetList enables batch retrieval of multiple withdrawal records in a single database call. The caller populates a MoneyBus.IDs table-valued parameter with the withdrawal IDs to retrieve, and the procedure returns the matching rows from Withdrawals ordered by ID. This is more efficient than making individual WithdrawGet calls when multiple withdrawals need to be loaded.

Used by the withdrawal execution service (specifically the `prod-mbwithdrawex-msi-*` identities which have EXECUTE grants on both this procedure and the MoneyBus.IDs type) to load batches of withdrawals for processing or display.

---

## 2. Business Logic

No complex business logic. This is a batch PK lookup using IN (SELECT ID FROM @Ids).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Ids | MoneyBus.IDs (TVP) | READONLY | - | CODE-BACKED | Table-valued parameter containing the list of Withdrawals.ID values to retrieve. See [MoneyBus.IDs](../User Defined Types/MoneyBus.IDs.md). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Ids | MoneyBus.IDs | Parameter Type | Uses the IDs table type for batch input |
| (SELECT target) | MoneyBus.Withdrawals | Reader | Reads withdrawals matching the ID list |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.WithdrawGetList (procedure)
├── MoneyBus.Withdrawals (table) [SELECT FROM ... WHERE ID IN]
└── MoneyBus.IDs (type) [@Ids parameter]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Withdrawals | Table | SELECT FROM - reads matching withdrawals |
| MoneyBus.IDs | User Defined Type | @Ids READONLY parameter |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get multiple withdrawals by ID list
```sql
DECLARE @Ids MoneyBus.IDs;
INSERT INTO @Ids (ID) VALUES (773487), (773486), (773485);
EXEC MoneyBus.WithdrawGetList @Ids = @Ids;
```

### 8.2 Get all withdrawals for a customer (combining queries)
```sql
DECLARE @Ids MoneyBus.IDs;
INSERT INTO @Ids (ID)
SELECT ID FROM MoneyBus.Withdrawals WITH (NOLOCK) WHERE GCID = 12345;
EXEC MoneyBus.WithdrawGetList @Ids = @Ids;
```

### 8.3 Get recent in-process withdrawals
```sql
DECLARE @Ids MoneyBus.IDs;
INSERT INTO @Ids (ID)
SELECT ID FROM MoneyBus.Withdrawals WITH (NOLOCK) WHERE StatusID = 1;
EXEC MoneyBus.WithdrawGetList @Ids = @Ids;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.WithdrawGetList | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.WithdrawGetList.sql*
