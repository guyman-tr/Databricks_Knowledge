# MoneyBus.ContainerGet

> Retrieves a transaction's SAGA container by TransactionID, returning the full execution state JSON for pipeline resumption.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single row from Containers by TransactionID (clustered PK) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.ContainerGet reads a transaction's SAGA execution state container. The transaction pipeline calls this when resuming processing (after a service restart, timeout, or async callback) to load the full execution context including the user identity, request message, and pipeline progress from the ContainerData JSON.

This is a clustered PK lookup on Containers.TransactionID, providing optimal single-row retrieval.

---

## 2. Business Logic

No complex business logic. Simple PK lookup.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TransactionID | bigint | NO | - | CODE-BACKED | The transaction whose container to retrieve. Maps to Containers.TransactionID (clustered PK). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT target) | MoneyBus.Containers | Reader | Reads the SAGA container for the given transaction |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.ContainerGet (procedure)
└── MoneyBus.Containers (table) [SELECT FROM]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Containers | Table | SELECT FROM - reads container by TransactionID |

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

### 8.1 Get container for a transaction
```sql
EXEC MoneyBus.ContainerGet @TransactionID = 7747200;
```

### 8.2 Get container with transaction context
```sql
DECLARE @result TABLE (ID bigint, TransactionID bigint, Created datetime, Modified datetime, ContainerData nvarchar(max));
INSERT INTO @result EXEC MoneyBus.ContainerGet @TransactionID = 7747200;
SELECT r.*, t.StatusID, t.StatusReasonID
FROM @result r
JOIN MoneyBus.Transactions t WITH (NOLOCK) ON t.ID = r.TransactionID AND t.PartitionCol = r.TransactionID % 100;
```

### 8.3 Direct equivalent
```sql
SELECT * FROM MoneyBus.Containers WITH (NOLOCK) WHERE TransactionID = 7747200;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.ContainerGet | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.ContainerGet.sql*
