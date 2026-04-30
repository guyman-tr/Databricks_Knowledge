# Billing.GetScheduledTaskRabbitMqFtdEntitiesRemote

> AlwaysOn-aware variant of the RabbitMQ FTD batch-fetch procedure: reads FTD deposit data from a secondary replica (via NOLOCK) then executes the TaskState UPDATE on the primary Read-Write server using dynamic SQL through the AO-REAL-DB linked server, ensuring writes land on the correct node in an AlwaysOn Availability Group topology.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MaxEntitiesToFetch (batch cap); returns one row per claimed FTD deposit |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetScheduledTaskRabbitMqFtdEntitiesRemote is the AlwaysOn-topology variant of the RabbitMQ FTD scheduled task batch-fetch procedure. It was created as part of PAYUS-2570 (Shay Oren, 28 Feb 2020) to handle the scenario where the scheduled task worker connects to a secondary (read-only) AlwaysOn replica for performance but must still write task state updates to the primary Read-Write server.

The challenge this procedure solves: in SQL Server AlwaysOn Availability Groups, secondary replicas are read-only - DML (INSERT/UPDATE/DELETE) cannot be executed against them directly. But the scheduler may run against a secondary for read scalability. The solution is to execute the `UPDATE Billing.ScheduledTaskState SET TaskState=3` via dynamic SQL (`sp_executesql`) through a linked server named `AO-REAL-DB`, which points to the primary Read-Write node. This ensures the claim (marking rows as In Progress) is always committed on the primary and replicated to all secondaries.

This is identical in output to `Billing.GetScheduledTaskRabbitMqFtdEntities` - same result set, same filters, same two-stage population. The only structural difference is the final UPDATE mechanism.

---

## 2. Business Logic

### 2.1 AlwaysOn Remote UPDATE Pattern

**What**: The TaskState UPDATE is routed to the primary server via dynamic SQL through a linked server to handle AlwaysOn secondary replica restrictions.

**Columns/Parameters Involved**: `@server`, `@db`, `@cmd`, linked server `AO-REAL-DB`

**Rules**:
- Reads all data locally (NOLOCK) - compatible with secondary replica
- After data assembly, builds a dynamic SQL string for the UPDATE:
  `CONCAT('UPDATE STS SET TaskState=3, Created=GetDate() FROM ', @server, @db, 'Billing.ScheduledTaskState STS INNER JOIN #PostDepositTask PDT ON STS.DepositID = PDT.DepositID WHERE STS.TaskID = 2')`
- `@server` = `'[AO-REAL-DB].'` from `sys.servers WHERE name = 'AO-REAL-DB'` - the linked server name of the primary AG node
- `@db` = `DB_NAME() + '.'` - same database name, but on the remote primary
- The fully qualified object reference pattern `[LinkedServer].[Database].[Schema].[Table]` routes the DML to the primary
- Executes via `EXECUTE sp_executesql @cmd` - the dynamic SQL runs in the linked server context

**Diagram**:
```
Secondary Replica (reads)           Primary Replica (writes)
+-- NOLOCK reads                    |
+-- #STS pre-select                 |
+-- INSERT #PostDepositTask         |
+-- UPDATE GCID + MopCountry        |
+-- SELECT from #PostDepositTask    |
+-- Build @cmd with AO-REAL-DB     --> sp_executesql @cmd
    prefix                         --> UPDATE [AO-REAL-DB].[etoro].
                                       Billing.ScheduledTaskState
                                       SET TaskState=3
```

### 2.2 FTD Data Logic (Inherited)

**What**: Identical filtering and data assembly as `GetScheduledTaskRabbitMqFtdEntities`.

**Rules** (same as parent procedure):
- TaskState=0, TaskID=2, PaymentStatusID=2, within 7 days
- IsFTD=1 applied in Stage 2 JOIN
- MopCountry: PayPal XML -> BIN -> customer fallback
- GCID + MopCountry fallback in Stage 2 UPDATE on #PostDepositTask (local temp table - OK on secondary)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxEntitiesToFetch | INT | YES | -1 | CODE-BACKED | Batch size cap. -1 = unlimited (2147483647). Controls TOP in INSERT SELECT. |
| - | DepositID | INT | NO | - | CODE-BACKED | Primary key of the qualifying FTD deposit from Billing.Deposit. |
| - | IsFTD | BIT | NO | - | CODE-BACKED | Always 1 - filtered by IsFTD=1 condition in Stage 2 JOIN. |
| - | GCID | INT | YES | - | CODE-BACKED | Global customer ID from Customer.CustomerStatic (Stage 2). |
| - | PaymentStatusID | INT | NO | - | CODE-BACKED | Always 2 (Approved). Filtered in #STS and Stage 2. |
| - | CID | INT | NO | - | CODE-BACKED | Customer ID of the depositor. |
| - | FundingTypeID | INT | NO | - | CODE-BACKED | Payment method type from Billing.Funding. |
| - | IsRefundable | BIT | YES | - | CODE-BACKED | Whether the funding type supports refunds. From Dictionary.FundingType. |
| - | MopCountry | VARCHAR(50) | YES | - | CODE-BACKED | Method of Payment Country. PayPal XML -> BIN country -> customer country fallback. |
| - | BankName | VARCHAR(100) | YES | - | CODE-BACKED | Issuing bank from Dictionary.CountryBin. NULL for non-card methods. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TaskID=2, TaskState=0 | Billing.ScheduledTaskState | SELECT (local) + UPDATE (remote via AO-REAL-DB) | Reads pending rows locally; claims via remote UPDATE on primary |
| DepositID | Billing.Deposit | JOIN (local) | IsFTD filter + data source |
| FundingID | Billing.Funding | JOIN (local) | FundingTypeID + XML data |
| FundingTypeID | Dictionary.FundingType | JOIN (local) | IsRefundable |
| FundingData | Dictionary.CountryBin | LEFT JOIN (local) | BIN-to-country lookup |
| CountryID | Dictionary.Country | LEFT JOIN (local) | Country name |
| CID | Customer.CustomerStatic | JOIN (local, Stage 2) | GCID + fallback country |
| AO-REAL-DB | sys.servers (linked server) | DYNAMIC SQL | Routes TaskState UPDATE to Read-Write primary server |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Scheduler service (AlwaysOn deployment) | @MaxEntitiesToFetch | EXEC | Called when the scheduler worker runs against a secondary replica that cannot write |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetScheduledTaskRabbitMqFtdEntitiesRemote (procedure)
+-- Billing.ScheduledTaskState (table) [local read + remote write via AO-REAL-DB]
+-- Billing.Deposit (table)
+-- Billing.Funding (table)
+-- Dictionary.FundingType (table)
+-- Dictionary.CountryBin (table)
+-- Dictionary.Country (table)
+-- Customer.CustomerStatic (table)
+-- AO-REAL-DB (linked server) [routes UPDATE to primary AG node]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ScheduledTaskState | Table | Local read (TaskState=0, TaskID=2); remote UPDATE (TaskState=3) via AO-REAL-DB |
| Billing.Deposit | Table | FTD filter + data |
| Billing.Funding | Table | Payment method details |
| Dictionary.FundingType | Table | IsRefundable |
| Dictionary.CountryBin | Table | BIN lookup |
| Dictionary.Country | Table | Country names |
| Customer.CustomerStatic | Table | GCID + country fallback (Stage 2) |
| AO-REAL-DB | Linked Server | Primary AG node - target for remote UPDATE via sp_executesql |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Scheduler service (AlwaysOn-aware) | External | Production caller when reads come from secondary replica |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| AO-REAL-DB linked server | Infrastructure dependency | If linked server AO-REAL-DB is unavailable, the UPDATE will fail; rows remain at TaskState=0 and will be re-processed next call |
| Dynamic SQL TaskState update | Design | The UPDATE uses `Created = GetDate()` (local time) not GETUTCDATE() - consistent with the standard non-remote version |
| Temp table scope | Technical | #PostDepositTask is created locally; the remote UPDATE only touches ScheduledTaskState, joining to the local temp table |
| PAYUS-2570 | Change history | Created to support AlwaysOn topology where the scheduler runs on secondaries |

---

## 8. Sample Queries

### 8.1 Execute in AlwaysOn-aware context

```sql
-- When running against a secondary replica in an AG
EXEC [Billing].[GetScheduledTaskRabbitMqFtdEntitiesRemote] @MaxEntitiesToFetch = 100
-- Reads data locally (NOLOCK-compatible with secondary)
-- Routes UPDATE to primary via AO-REAL-DB linked server
```

### 8.2 Verify the linked server exists

```sql
SELECT name, product, provider, data_source
FROM sys.servers WITH (NOLOCK)
WHERE name = 'AO-REAL-DB'
```

### 8.3 Compare TaskState queue with non-remote version output

```sql
-- Check what's pending for TaskID=2 on both replicas
SELECT TaskState, COUNT(*) AS Cnt
FROM [Billing].[ScheduledTaskState] WITH (NOLOCK)
WHERE TaskID = 2
GROUP BY TaskState
ORDER BY TaskState
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetScheduledTaskRabbitMqFtdEntitiesRemote | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetScheduledTaskRabbitMqFtdEntitiesRemote.sql*
