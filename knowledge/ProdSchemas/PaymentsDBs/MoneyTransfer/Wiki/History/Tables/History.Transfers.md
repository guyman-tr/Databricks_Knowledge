# History.Transfers

> System-versioned temporal history table that automatically captures every state change of money transfer records from Billing.Transfers, preserving a complete audit trail of the transfer lifecycle.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (System-Versioned Temporal History) |
| **Key Identifier** | No PK - rows identified by TransferID + StartTime/EndTime validity period |
| **Partition** | No |
| **Indexes** | 1 active (clustered) |

---

## 1. Business Meaning

History.Transfers is the SQL Server system-versioned temporal history table for Billing.Transfers. It stores the complete change history of every money transfer in the MoneyTransfer database. Each row represents a previous version of a transfer record - the state the record was in before it was modified. This enables point-in-time queries to reconstruct the exact state of any transfer at any moment in time.

Without this table, the system would only know the current state of each transfer. The history table provides full audit trail capabilities critical for financial compliance, dispute resolution, and debugging transfer processing issues. Every status change, routing update, and funding assignment is preserved with exact timestamps.

Data flows into this table automatically via SQL Server's SYSTEM_VERSIONING mechanism on Billing.Transfers. When any stored procedure (CreateTransfer, UpdateTransferStatus, SaveRoutingInfo, SaveTransferDestination, etc.) modifies a row in Billing.Transfers, SQL Server automatically copies the "before" state into History.Transfers with the appropriate StartTime/EndTime validity window. No application code writes directly to this table. The Monitoring.GetLastTransfersStatusesInPercentage SP reads from Billing.Transfers (joined with Dictionary.TransferStatus) for operational monitoring, and the history table supports ad-hoc temporal queries for audit and investigation.

---

## 2. Business Logic

### 2.1 Transfer Lifecycle State Machine

**What**: Each money transfer progresses through a defined set of states, and every state transition generates a history row.

**Columns/Parameters Involved**: `TransferStatusID`, `ModificationDate`, `Trace`

**Rules**:
- Transfers are created with TransferStatusID=0 (New) by Billing.CreateTransfer
- Status progresses through Init(1) -> Pending(2) -> Sent(9) -> Received(10) for successful transfers
- Failure branches: Technical(4), Cancel(7), Fail(8) can occur from intermediate states
- Once a transfer reaches status 10 (Received), Billing.UpdateTransferStatus blocks further updates (throws error 50000)
- Each status change generates a new history row preserving the previous state

**Diagram**:
```
New(0) --> Init(1) --> Pending(2) --> Sent(9) --> Received(10) [terminal success]
  |          |            |
  |          |            +--> Technical(4) [infrastructure failure]
  |          |            +--> Cancel(7) [user/system cancellation]
  |          |            +--> Fail(8) [business failure]
  |          |
  |          +--> Technical(4)
  |          +--> Cancel(7)
  |
  +--> Technical(4)
```

### 2.2 Progressive Column Population Pattern

**What**: Transfer records are not fully populated at creation - columns are set progressively by different stored procedures as the transfer moves through processing stages.

**Columns/Parameters Involved**: `InitFundingId`, `OriginFundingId`, `DestinationFundingId`, `OriginFundingData`, `DestinationFundingData`, `DepotId`, `CountryId`, `ExtTransactionId`

**Rules**:
- At creation (Billing.CreateTransfer): Only core fields are set (ReferenceID, CID, CurrencyID, FundingTypeIDs, Amount, ExReferenceID, TransferStatusID=0)
- Routing step (Billing.SaveRoutingInfo): DepotId and CountryId are set together
- Destination setup (Billing.SaveTransferDestination): DestinationFundingData is populated
- Origin setup (Billing.SaveTransferOrigin): OriginFundingData is populated
- Funding resolution: InitFundingId, OriginFundingId, DestinationFundingId are each set by their own dedicated SPs at different processing stages
- External reference (Billing.SaveExtTransactionId): ExtTransactionId is set when an external provider returns a transaction identifier
- Each progressive update generates a new history row, creating a timeline of how the transfer was assembled

**Diagram**:
```
CreateTransfer          SaveRoutingInfo     SaveTransferDestination    SaveTransferOrigin
[Core fields set]  -->  [DepotId,          --> [DestinationFundingData] --> [OriginFundingData]
[Status=0 New]          CountryId set]

SaveTransferInitFundingId   SaveTransferOriginFundingId   SaveTransferDestinationFundingId
[InitFundingId set]     --> [OriginFundingId set]      --> [DestinationFundingId set]

SaveExtTransactionId        UpdateTransferStatus
[ExtTransactionId set]  --> [Status progression: 0->1->2->9->10]
```

### 2.3 Temporal Versioning and Audit Trail

**What**: The Trace column captures which K8s pod and stored procedure made each change, providing a forensic audit trail.

**Columns/Parameters Involved**: `Trace`, `StartTime`, `EndTime`

**Rules**:
- StartTime/EndTime define the validity period of each version (when this state was "current" in Billing.Transfers)
- Trace is a JSON blob computed in Billing.Transfers containing: HostName (K8s pod), AppName, SUserName (DB login), SPID, DBName, ObjectName (the SP that made the change)
- In History, Trace is stored as a materialized value (not computed) preserving the exact trace at the time of the change
- The clustered index on (EndTime, StartTime) optimizes temporal queries (AS OF, FROM...TO)
- Multiple history rows for the same TransferID show the complete mutation timeline

---

## 3. Data Overview

| TransferID | CID | CurrencyID | TransferStatusID | Amount | Trace (ObjectName) | Meaning |
|---|---|---|---|---|---|---|
| 1 | 30259151 | 2 | 0 | 1000 | UpdateTransferStatus | First-ever transfer, initial creation captured as status was set to New(0). Trace shows the UpdateTransferStatus SP triggered the version. |
| 1 | 30259151 | 2 | 1 | 1000 | SaveTransferDestination | Same transfer progressed to Init(1), then destination data was saved - this version captures the state before the destination update. |
| 1 | 30259151 | 2 | 4 | 1000 | (empty) | Same transfer's final history row before reaching terminal Technical(4) failure state. Demonstrates a failed transfer lifecycle. |
| 4880000 | (redacted) | 2 | 10 | 50 | (from Billing) | A completed transfer (Received) with DepotId=166, CountryId=79, both InitFundingId and OriginFundingId populated - showing a fully-resolved successful transfer. |
| 4883223 | (redacted) | 2 | 2 | 100 | (from Billing) | A recent transfer still in Pending(2) state with DepotId=104, CountryId=100 - showing an in-progress transfer being assembled. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TransferID | int | NO | - | CODE-BACKED | Identity-generated primary key from Billing.Transfers. Assigned by SCOPE_IDENTITY() in Billing.CreateTransfer. Not unique in History - multiple rows per TransferID represent successive versions of the same transfer. |
| 2 | ReferenceID | uniqueidentifier | NO | - | CODE-BACKED | Application-generated GUID serving as the business key for the transfer. All SPs (UpdateTransferStatus, SaveRoutingInfo, SaveTransferDestination, etc.) use ReferenceID as the lookup key via @RefGuid parameter. Unique clustered index exists on Billing.Transfers. |
| 3 | CID | int | NO | - | CODE-BACKED | Customer ID - identifies the customer initiating the money transfer. Used by Billing.GetTransfersByCID to retrieve all transfers for a customer, and by Billing.GetDepotIdOfLastSuccessfulTransferByCid for routing decisions. Cross-database reference to the customer master. |
| 4 | CurrencyID | int | NO | - | CODE-BACKED | Currency denomination of the transfer amount. Set at creation via Billing.CreateTransfer @CurrencyID parameter. Observed values: 2 (most common), 3. References a currency lookup table external to this database. Indexed as part of IX_Billing_Transfers_CurrencyID_TransferStatusID_TransferID. |
| 5 | OriginFundingTypeID | int | NO | - | CODE-BACKED | Type identifier for the funding source (origin side of the transfer). Set at creation via Billing.CreateTransfer. Observed value: 38 (dominant in all samples). References a funding type lookup external to this database. |
| 6 | DestinationFundingTypeID | int | NO | - | CODE-BACKED | Type identifier for the funding destination. Set at creation via Billing.CreateTransfer. Observed value: 33 (dominant in all samples). References a funding type lookup external to this database. |
| 7 | Amount | money | NO | - | CODE-BACKED | Transfer amount in the currency specified by CurrencyID. Set at creation via Billing.CreateTransfer. Observed range: 20 to 8000 in samples. Immutable after creation - amount does not change during transfer processing. |
| 8 | OriginFundingData | nvarchar(max) | YES | - | CODE-BACKED | Serialized funding source details (e.g., account numbers, routing info). Set by Billing.SaveTransferOrigin after creation. Protected by dynamic data masking (default() function) - returns NULL to unprivileged users. Often NULL in early processing stages before origin is resolved. |
| 9 | DestinationFundingData | nvarchar(max) | YES | - | CODE-BACKED | Serialized funding destination details. Set by Billing.SaveTransferDestination after creation. Protected by dynamic data masking (default() function). Populated during the Init phase of transfer processing - shows as masked "xxxx" value in history for non-privileged access. |
| 10 | CreateDate | datetime2(7) | NO | - | CODE-BACKED | Timestamp when the transfer record was originally created. DEFAULT getutcdate() on Billing.Transfers. Immutable after creation - does not change across status updates. |
| 11 | ModificationDate | datetime2(7) | NO | - | CODE-BACKED | Timestamp of the last modification to the transfer record. DEFAULT getutcdate() on creation; automatically updated by trigger TR_Transfers_ModificationDate on Billing.Transfers after every UPDATE operation. |
| 12 | TransferStatusID | int | NO | - | VERIFIED | Transfer lifecycle state. FK to Dictionary.TransferStatus: 0=New (initial creation), 1=Init (processing started), 2=Pending (awaiting confirmation), 4=Technical (infrastructure error), 7=Cancel (cancelled), 8=Fail (business failure), 9=Sent (dispatched to provider), 10=Received (terminal success). See [Transfer Status](../../_glossary.md#transfer-status) for full business definitions. Billing.UpdateTransferStatus guards against updating past Received(10). (Dictionary.TransferStatus) |
| 13 | ExReferenceID | varchar(50) | YES | - | CODE-BACKED | External reference identifier assigned at creation via Billing.CreateTransfer. Can be updated via Billing.SaveExtRefId. Observed format: "TZ" prefix + first 16 hex chars of ReferenceID (e.g., "TZ658abad80986436f"). Indexed by IX_Transfer_ExReferenceID_Cover with wide INCLUDE for covering queries. |
| 14 | Trace | nvarchar(733) | NO | - | VERIFIED | Audit JSON blob capturing the execution context of the last modification. In Billing.Transfers this is a computed column: concat of HostName (K8s pod name), AppName (SqlClient), SUserName (DB user), SPID, DBName, ObjectName (stored procedure name). In History, stored as a materialized value preserving the exact trace at version time. The ObjectName field reveals which SP caused each state change (e.g., "UpdateTransferStatus", "SaveTransferDestination"). |
| 15 | StartTime | datetime2(7) | NO | - | CODE-BACKED | System-versioned period start timestamp. GENERATED ALWAYS AS ROW START on Billing.Transfers. Marks when this version of the row became the current version. In History, this is when the previous state began. |
| 16 | EndTime | datetime2(7) | NO | - | CODE-BACKED | System-versioned period end timestamp. GENERATED ALWAYS AS ROW END on Billing.Transfers. Marks when this version was superseded by a new version. Part of the clustered index (EndTime ASC, StartTime ASC) for efficient temporal range queries. |
| 17 | InitFundingId | int | YES | - | CODE-BACKED | Initial funding source identifier. Set by Billing.SaveTransferInitFundingId during transfer processing. Often NULL - only populated when the system identifies an initial funding source before the final origin is determined. When populated, sometimes equals OriginFundingId (suggesting the initial source became the final origin). |
| 18 | OriginFundingId | int | YES | - | CODE-BACKED | Resolved origin funding source identifier. Set by Billing.SaveTransferOriginFundingId after the origin funding method is confirmed. NULL during early processing stages; populated for transfers that progress to execution. For completed transfers (status=10), typically populated. |
| 19 | DestinationFundingId | int | YES | - | CODE-BACKED | Resolved destination funding identifier. Set by Billing.SaveTransferDestinationFundingId after destination is confirmed. Most consistently populated of the three FundingId columns - nearly always set for transfers that reach the Pending(2) state or beyond. |
| 20 | DepotId | int | YES | - | VERIFIED | Routing depot identifier. Set together with CountryId by Billing.SaveRoutingInfo. Billing.GetDepotIdOfLastSuccessfulTransferByCid and GetLastDepotIdForTransferStatusesByCid default to 104 via ISNULL(DepotId, 104), indicating 104 is the primary/default depot. Observed values: 104, 166. NULL in early data (column added after initial launch). |
| 21 | CountryId | int | YES | - | CODE-BACKED | Country identifier for routing purposes. Set together with DepotId by Billing.SaveRoutingInfo. Represents the customer's country relevant to the transfer routing decision. Observed values: 74, 79, 100, 102, 143, 218. NULL in early data (column added after initial launch). |
| 22 | ExtTransactionId | varchar(50) | YES | - | CODE-BACKED | External provider's transaction identifier. Set by Billing.SaveExtTransactionId when an external payment provider returns a transaction reference. Observed formats: 20-character and 32-character hex strings. NULL until the external provider processes the transfer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TransferStatusID | Dictionary.TransferStatus | Implicit Lookup | Maps to the transfer lifecycle status: 0=New, 1=Init, 2=Pending, 4=Technical, 7=Cancel, 8=Fail, 9=Sent, 10=Received |
| CurrencyID | (External DB) Currency lookup | Implicit Lookup | Currency denomination of the transfer. Referenced from an external database. |
| OriginFundingTypeID | (External DB) Funding type lookup | Implicit Lookup | Type of funding source. Referenced from an external database. |
| DestinationFundingTypeID | (External DB) Funding type lookup | Implicit Lookup | Type of funding destination. Referenced from an external database. |
| (entire table) | Billing.Transfers | System Versioning (History Table) | This table IS the temporal history for Billing.Transfers. Declared via SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[Transfers]). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Transfers | SYSTEM_VERSIONING | System Versioning | Billing.Transfers declares this table as its history table. Every UPDATE to Billing.Transfers automatically inserts a row here. |
| History.TransferStepsLog | TransferID | Implicit FK | Step-level logs reference the same TransferID to track granular processing steps for each transfer. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies. It is a leaf table automatically populated by SQL Server system versioning.

### 6.1 Objects This Depends On

No dependencies. This table has no explicit FK constraints, computed column functions, or UDT references. It is populated entirely by the SQL Server system versioning mechanism from Billing.Transfers.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Transfers | Table | Parent temporal table - declares History.Transfers as HISTORY_TABLE via SYSTEM_VERSIONING |
| MIMO (user) | Permission | GRANT SELECT on History.TransferStepsLog to MIMO user (read access for monitoring) |

Indirect consumers (via Billing.Transfers system versioning - these SPs cause history rows to be generated):

| Object | Type | Category | How Used |
|--------|------|----------|----------|
| Billing.CreateTransfer | Stored Procedure | WRITER | INSERT into Billing.Transfers creates the first version |
| Billing.UpdateTransferStatus | Stored Procedure | MODIFIER | Status progression generates history rows |
| Billing.SaveRoutingInfo | Stored Procedure | MODIFIER | DepotId/CountryId updates generate history rows |
| Billing.SaveTransferDestination | Stored Procedure | MODIFIER | DestinationFundingData updates generate history rows |
| Billing.SaveTransferOrigin | Stored Procedure | MODIFIER | OriginFundingData updates generate history rows |
| Billing.SaveTransferInitFundingId | Stored Procedure | MODIFIER | InitFundingId updates generate history rows |
| Billing.SaveTransferOriginFundingId | Stored Procedure | MODIFIER | OriginFundingId updates generate history rows |
| Billing.SaveTransferDestinationFundingId | Stored Procedure | MODIFIER | DestinationFundingId updates generate history rows |
| Billing.SaveExtRefId | Stored Procedure | MODIFIER | ExReferenceID updates generate history rows |
| Billing.SaveExtTransactionId | Stored Procedure | MODIFIER | ExtTransactionId updates generate history rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_Transfers | CLUSTERED | EndTime ASC, StartTime ASC | - | - | Active |

The clustered index on (EndTime, StartTime) is the standard pattern for temporal history tables - it enables efficient temporal range queries (FOR SYSTEM_TIME AS OF, FROM...TO, BETWEEN...AND) and the `ORDER BY EndTime DESC` pattern used to retrieve recent versions.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page-level compression to reduce storage footprint of this high-volume history table |
| MASKED (OriginFundingData) | Dynamic Data Masking | default() mask - returns NULL to non-privileged users for PII protection |
| MASKED (DestinationFundingData) | Dynamic Data Masking | default() mask - returns NULL to non-privileged users for PII protection |

---

## 8. Sample Queries

### 8.1 Reconstruct the full mutation history of a specific transfer
```sql
SELECT TransferID, TransferStatusID, ModificationDate,
       JSON_VALUE(Trace, '$.ObjectName') AS ModifyingSP,
       StartTime, EndTime,
       DepotId, CountryId, DestinationFundingId
FROM History.Transfers WITH (NOLOCK)
WHERE TransferID = 1
ORDER BY StartTime ASC
```

### 8.2 Find what a transfer looked like at a specific point in time
```sql
SELECT h.*
FROM History.Transfers h WITH (NOLOCK)
WHERE h.TransferID = 4880000
  AND h.StartTime <= '2026-04-14 12:00:00'
  AND h.EndTime > '2026-04-14 12:00:00'
```

### 8.3 Recent transfer status changes with human-readable status names
```sql
SELECT TOP 20
       h.TransferID, h.ReferenceID,
       ds.Name AS StatusName, h.TransferStatusID,
       h.Amount, h.CurrencyID,
       JSON_VALUE(h.Trace, '$.ObjectName') AS ChangedBy,
       h.StartTime, h.EndTime
FROM History.Transfers h WITH (NOLOCK)
JOIN Dictionary.TransferStatus ds WITH (NOLOCK) ON ds.ID = h.TransferStatusID
ORDER BY h.EndTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Searches for "History.Transfers", "Billing.Transfers", and "MoneyTransfer" in the configured TRAD space (DB folder) returned no dedicated documentation pages. General "money transfer" search returned operational procedure pages not related to the database schema.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11 (9B skipped - no app repos)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 12 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Transfers | Type: Table (System-Versioned Temporal History) | Source: MoneyTransfer/History/Tables/History.Transfers.sql*
