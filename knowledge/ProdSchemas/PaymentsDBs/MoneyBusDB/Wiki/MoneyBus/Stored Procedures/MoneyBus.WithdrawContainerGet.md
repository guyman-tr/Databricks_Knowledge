# MoneyBus.WithdrawContainerGet

> Retrieves a withdrawal's SAGA container by WithdrawID, returning the full execution state JSON for pipeline resumption.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single row from WithdrawContainers by WithdrawID (clustered PK) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.WithdrawContainerGet reads a withdrawal's SAGA execution state container. The withdrawal pipeline calls this when resuming processing (after a service restart, timeout, or async callback) to load the full execution context including the executing plan name, last completed step, and withdrawal details from the ContainerData JSON.

Clustered PK lookup on WithdrawContainers.WithdrawID for optimal single-row retrieval.

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
| 1 | @WithdrawID | bigint | NO | - | CODE-BACKED | The withdrawal whose container to retrieve. Maps to WithdrawContainers.WithdrawID (clustered PK). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT target) | MoneyBus.WithdrawContainers | Reader | Reads the SAGA container for the given withdrawal |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.WithdrawContainerGet (procedure)
└── MoneyBus.WithdrawContainers (table) [SELECT FROM]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.WithdrawContainers | Table | SELECT FROM - reads container by WithdrawID |

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

### 8.1 Get withdrawal container
```sql
EXEC MoneyBus.WithdrawContainerGet @WithdrawID = 773487;
```

### 8.2 Direct equivalent
```sql
SELECT * FROM MoneyBus.WithdrawContainers WITH (NOLOCK) WHERE WithdrawID = 773487;
```

### 8.3 Get with withdrawal status context
```sql
SELECT wc.*, w.StatusID, w.StatusReasonID
FROM MoneyBus.WithdrawContainers wc WITH (NOLOCK)
JOIN MoneyBus.Withdrawals w WITH (NOLOCK) ON w.ID = wc.WithdrawID
WHERE wc.WithdrawID = 773487;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.WithdrawContainerGet | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.WithdrawContainerGet.sql*
