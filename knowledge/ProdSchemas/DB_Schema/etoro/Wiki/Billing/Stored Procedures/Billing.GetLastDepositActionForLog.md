# Billing.GetLastDepositActionForLog

> Returns the most recent deposit action and its associated log entry ID for a given deposit - the TOP 1 companion to GetLastDepositAction that adds the cross-database DepositLog reference.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositID - returns the single most recent action with its log entry |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetLastDepositActionForLog` retrieves the single most recent deposit action for a given deposit, paired with the associated log entry ID from `History.DepositLog` (a cross-database synonym pointing to `DB_Logs.History.DepositLog`).

This procedure serves log-linking use cases: given a deposit, find the latest action and the corresponding log row that captured the raw payment provider payload for that action. The `DepositLogID` returned can be used to look up the full provider response in the DB_Logs database.

The LEFT JOIN (not INNER JOIN) means `DepositLogID` can be NULL - not every deposit action necessarily generates a log entry (e.g., internal status changes without a provider API call may create an action row but no log row). The TOP(1) with ORDER BY DepositActionID DESC ensures only the most recent action is returned.

Created by Inna 29/08/2021 (PAYUS-3661) alongside `GetLastDepositAction` and `GetLastDepositActionWithResponseCode` - the three procedures form a family for deposit troubleshooting. EXECUTE is granted to `DepositUser`.

---

## 2. Business Logic

### 2.1 Most Recent Action with Log Reference

**What**: Returns the single most recent `History.DepositAction` record for the deposit, with the `DepositLogID` from the log synonym if one exists.

**Columns/Parameters Involved**: `@DepositID`, `DepositActionID`, `DepositLogID`

**Rules**:
- TOP(1) - strictly one row returned
- ORDER BY DepositActionID DESC - most recent action (DepositActionID is IDENTITY, DESC = newest first)
- LEFT JOIN `History.DepositLog` on `DepositActionID` - links the action to its raw log entry
- `DepositLogID` can be NULL if no log row exists for this action
- `History.DepositLog` is a SYNONYM: `CREATE SYNONYM [History].[DepositLog] FOR [DB_Logs].[History].[DepositLog]` - the actual data lives in a separate logging database

**Diagram**:
```
@DepositID -> History.DepositAction (clustered by DepositID)
              ORDER BY DepositActionID DESC
              TOP(1)
              LEFT JOIN History.DepositLog (synonym -> DB_Logs.History.DepositLog)
                        ON DepositActionID = DepositActionID

Returns: { DepositActionID, DepositLogID [nullable] }
```

### 2.2 Comparison with Sister Procedures

**What**: Three procedures share `@DepositID` input and `History.DepositAction` source but serve different purposes.

| Procedure | TOP | Filter | Output |
|-----------|-----|--------|--------|
| `GetLastDepositAction` | None (all rows) | None beyond DepositID | DepositActionID, ResponseID, PaymentStatusID |
| `GetLastDepositActionForLog` | TOP(1) | None beyond DepositID | DepositActionID, DepositLogID (cross-DB) |
| `GetLastDepositActionWithResponseCode` | TOP 1 | ResponseID IS NOT NULL | DepositActionID, ResponseID, PaymentStatusID |

`GetLastDepositActionForLog` is unique in joining to the cross-database log synonym - it is the bridge between the transactional DB and the logging DB.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INT | NO | - | CODE-BACKED | The deposit to retrieve the latest action for. FK to Billing.Deposit.DepositID. |

### Output Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | DepositActionID | int | NO | - | CODE-BACKED | Identity PK of the most recent action record. Highest value = newest action for this deposit. |
| 3 | DepositLogID | int | YES | NULL | CODE-BACKED | PK of the log entry in DB_Logs.History.DepositLog that captured the raw provider payload for this action. NULL if no log entry exists (e.g., action was an internal status change with no provider API call). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| da (FROM) | History.DepositAction | Direct Read | Most recent action record for the given deposit |
| dl (LEFT JOIN) | History.DepositLog (synonym) | Cross-DB Read via Synonym | Log entry linking the action to raw provider payload in DB_Logs database. DepositLogID is nullable - not every action has a log entry. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DepositUser (permissions) | EXECUTE grant | Permission | Deposit processing service role. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetLastDepositActionForLog (procedure)
├── History.DepositAction (table) - direct table in this DB
└── History.DepositLog (synonym) -> DB_Logs.History.DepositLog (cross-database)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.DepositAction | Table | FROM - most recent action record for @DepositID, ordered by DepositActionID DESC |
| History.DepositLog | Synonym | LEFT JOIN - links action to log entry in DB_Logs.History.DepositLog |

### 6.2 Objects That Depend On This

No dependents found in the SQL layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get the latest action and log entry for a deposit

```sql
EXEC Billing.GetLastDepositActionForLog @DepositID = 7654321
-- Returns one row: DepositActionID + DepositLogID (NULL if no log entry)
```

### 8.2 Equivalent ad-hoc query

```sql
SELECT TOP(1)
    da.DepositActionID,
    dl.DepositLogID
FROM History.DepositAction da WITH (NOLOCK)
LEFT JOIN History.DepositLog dl WITH (NOLOCK)
    ON da.DepositActionID = dl.DepositActionID
WHERE da.DepositID = 7654321
ORDER BY da.DepositActionID DESC
```

### 8.3 Check whether a deposit's latest action has a log entry

```sql
DECLARE @ActionID INT, @LogID INT
EXEC Billing.GetLastDepositActionForLog @DepositID = 7654321
-- If DepositLogID is NULL: latest action has no log row (internal state change, no provider call)
-- If DepositLogID is not NULL: use it to look up raw payload in DB_Logs.History.DepositLog
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetLastDepositActionForLog | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetLastDepositActionForLog.sql*
