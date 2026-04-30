# Trade.AccountLiquidationSaga

> Tracks the progress of an active account liquidation process for a customer, recording which step the saga has reached and how it was initiated.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | CID (PK, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

This table implements a **saga pattern** for account liquidation - the multi-step process of closing all positions, settling balances, and shutting down a customer's trading account. Each row represents one *active* liquidation in progress. The primary key is CID, meaning only one liquidation process can be active per customer at any time.

Account liquidation can be triggered in two ways: **manually** by compliance/operations staff, or **automatically** by the BSL (Bonus Stop Loss) system when a customer's equity falls below a threshold. Without this table, there would be no way to track where a multi-step liquidation process stands, risking partial execution or duplicate processing.

Data enters via `Trade.PersistAccountLiquidationSaga`, which performs a MERGE (upsert) - inserting a new saga if none exists for the CID, or updating the `CurrentStepIndex` if the saga is already in progress. When liquidation completes, `Trade.ArchiveAccountLiquidationSaga` atomically deletes the row and inserts it into `History.AccountLiquidationSaga` with a `CloseTime` timestamp. The table being empty (0 rows at time of documentation) is the normal state - it means no liquidations are currently in progress.

---

## 2. Business Logic

### 2.1 Saga Lifecycle (Upsert + Archive Pattern)

**What**: The table acts as a state machine where each customer can have at most one active saga, progressing through numbered steps until completion or archival.

**Columns/Parameters Involved**: `CID`, `CurrentStepIndex`, `CreateTime`, `LastModify`

**Rules**:
- A customer can only have ONE active liquidation at a time (CID is the PK)
- `PersistAccountLiquidationSaga` uses MERGE: first call INSERTs, subsequent calls UPDATE `CurrentStepIndex`
- `LastModify` updates to `GETUTCDATE()` on every step progression
- When the saga completes, `ArchiveAccountLiquidationSaga` DELETEs the row and OUTPUTs it to `History.AccountLiquidationSaga`

**Diagram**:
```
[No Active Saga]
       |
       | PersistAccountLiquidationSaga (INSERT)
       v
[Active Saga: Step 0] --Persist(UPDATE)--> [Step 1] --Persist(UPDATE)--> [Step N]
       |                                                                    |
       |              ArchiveAccountLiquidationSaga (DELETE + OUTPUT)        |
       +--------------------------------------------------------------------+
       v
[History.AccountLiquidationSaga] (permanent record with CloseTime)
```

### 2.2 Trigger Source Tracking

**What**: Every liquidation records whether it was initiated by a human operator or by an automated system, enabling audit trails and operational dashboards.

**Columns/Parameters Involved**: `AccountLiquidationAcionTypeID`, `InitialRequestGuid`

**Rules**:
- `AccountLiquidationAcionTypeID` = 1 (Manual): compliance or ops staff triggered the liquidation
- `AccountLiquidationAcionTypeID` = 2 (BSL): the Bonus Stop Loss automated system triggered it
- `InitialRequestGuid` correlates the saga to the originating service request for distributed tracing

---

## 3. Data Overview

The table is currently empty (0 active liquidations). This is normal - rows only exist while a liquidation is in progress. Completed liquidations are archived to `History.AccountLiquidationSaga`.

Representative data pattern (from History table structure):

| CID | CurrentStepIndex | AccountLiquidationAcionTypeID | InitialRequestGuid | Meaning |
|-----|-----------------|-------------------------------|-------------------|---------|
| 12345 | 3 | 1 | abc-def-... | A manual liquidation in progress at step 3 - compliance initiated this account closure |
| 67890 | 0 | 2 | ghi-jkl-... | A BSL-triggered liquidation just started (step 0) - customer equity dropped below threshold |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer identifier - the account being liquidated. One active liquidation per customer (PK enforces uniqueness). References `Customer.CustomerStatic.CID`. |
| 2 | CreateTime | datetime | NO | - | CODE-BACKED | UTC timestamp when the liquidation saga was first created. Set to `GETUTCDATE()` on INSERT by `PersistAccountLiquidationSaga`. Never updated after initial creation. |
| 3 | CurrentStepIndex | int | NO | - | CODE-BACKED | Zero-based index tracking how far the multi-step liquidation has progressed. Starts at the value passed by the caller on INSERT, then updated on each subsequent step via `PersistAccountLiquidationSaga` MERGE UPDATE. Mapped to `LastStepIndex` when archived to History. |
| 4 | AccountLiquidationAcionTypeID | int | NO | - | VERIFIED | How the liquidation was initiated: 1=Manual (compliance/ops staff triggered), 2=BSL (Bonus Stop Loss automated system triggered). Source: `Dictionary.AccountLiquidationActionType`. Note: column name has a typo ("Acion" instead of "Action") preserved from the original DDL. |
| 5 | InitialRequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Correlation identifier linking this saga to the originating service request. Used for distributed tracing across microservices. NULL when no correlation was provided by the caller. |
| 6 | LastModify | datetime | NO | - | CODE-BACKED | UTC timestamp of the most recent saga update. Set to `GETUTCDATE()` on both INSERT and UPDATE by `PersistAccountLiquidationSaga`. Allows monitoring for stale/stuck liquidation processes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (explicit) | The customer account undergoing liquidation |
| AccountLiquidationAcionTypeID | Dictionary.AccountLiquidationActionType | FK (explicit) | Lookup for how the liquidation was initiated (Manual or BSL) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.AccountLiquidationSaga | CID | Archive target | Completed sagas are moved here with a CloseTime via OUTPUT clause |
| Trade.PersistAccountLiquidationSaga | @CID | WRITER (MERGE) | Creates or updates the active saga row |
| Trade.ArchiveAccountLiquidationSaga | @CID | DELETER | Removes the completed saga and archives to History |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.AccountLiquidationSaga (table)
├── Customer.CustomerStatic (table) [FK target]
└── Dictionary.AccountLiquidationActionType (table) [FK target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK target for CID |
| Dictionary.AccountLiquidationActionType | Table | FK target for AccountLiquidationAcionTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PersistAccountLiquidationSaga | Stored Procedure | WRITER - MERGE upsert to create/update saga |
| Trade.ArchiveAccountLiquidationSaga | Stored Procedure | DELETER - DELETE with OUTPUT to History |
| History.AccountLiquidationSaga | Table | Archive destination for completed sagas |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradeAccountLiquidationSaga | CLUSTERED PK | CID ASC | - | - | Active (FILLFACTOR=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_TradeAccountLiquidationSag_AccountLiquidationActionType | FK | AccountLiquidationAcionTypeID -> Dictionary.AccountLiquidationActionType(ActionTypeID). Ensures only valid liquidation trigger types are recorded. |
| FK_TradeAccountLiquidationSaga_CID | FK | CID -> Customer.CustomerStatic(CID). Ensures the customer exists in the system. |

---

## 8. Sample Queries

### 8.1 Check if a customer has an active liquidation
```sql
SELECT  als.CID,
        als.CurrentStepIndex,
        alat.Description AS TriggerType,
        als.CreateTime,
        als.LastModify
FROM    Trade.AccountLiquidationSaga als WITH (NOLOCK)
JOIN    Dictionary.AccountLiquidationActionType alat WITH (NOLOCK)
        ON als.AccountLiquidationAcionTypeID = alat.ActionTypeID
WHERE   als.CID = @CID
```

### 8.2 Find stale/stuck liquidation sagas (no progress in 1 hour)
```sql
SELECT  als.CID,
        als.CurrentStepIndex,
        als.CreateTime,
        als.LastModify,
        DATEDIFF(MINUTE, als.LastModify, GETUTCDATE()) AS MinutesSinceLastUpdate
FROM    Trade.AccountLiquidationSaga als WITH (NOLOCK)
WHERE   DATEDIFF(MINUTE, als.LastModify, GETUTCDATE()) > 60
ORDER BY als.LastModify ASC
```

### 8.3 View completed liquidations from History with trigger type
```sql
SELECT  h.CID,
        h.LastStepIndex,
        alat.Description AS TriggerType,
        h.CreateTime,
        h.CloseTime,
        DATEDIFF(MINUTE, h.CreateTime, h.CloseTime) AS DurationMinutes
FROM    History.AccountLiquidationSaga h WITH (NOLOCK)
JOIN    Dictionary.AccountLiquidationActionType alat WITH (NOLOCK)
        ON h.AccountLiquidationAcionTypeID = alat.ActionTypeID
ORDER BY h.CloseTime DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| ALS to AKS Migration Executive Status Report | Confluence | Account Liquidation Service (ALS) is being migrated to AKS, confirming this is an active microservice-backed saga |

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.AccountLiquidationSaga | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.AccountLiquidationSaga.sql*
