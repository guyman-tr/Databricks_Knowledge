# Billing.Transfers

> Core transactional table storing all money transfer records between funding sources (e.g., IBAN bank accounts and eToro Trading accounts), tracking each transfer from creation through processing to final resolution.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | TransferID (int, IDENTITY, NONCLUSTERED PK), ReferenceID (uniqueidentifier, UNIQUE CLUSTERED) |
| **Partition** | No |
| **Indexes** | 4 active |

---

## 1. Business Meaning

Billing.Transfers is the central transactional table in the MoneyTransfer database, recording every money transfer between funding sources. Each row represents a single transfer operation - typically moving funds between a customer's bank account (IBAN) and their eToro Trading account. The table tracks the origin and destination funding types, the amount, the currency, and the evolving status of the transfer through its lifecycle.

This table is the backbone of the MoneyTransfer billing system. Without it, the platform would have no record of fund movements between banking and trading domains. Every deposit, withdrawal, and internal transfer initiated through the MoneyBus payment orchestration pipeline is recorded here. The MoneyBusAdapter service communicates with banking providers and updates transfer records through the Billing stored procedures.

Transfers are created by `Billing.CreateTransfer` with an initial status of New(0). As the transfer progresses through the payment pipeline, individual stored procedures update specific fields: `SaveRoutingInfo` sets DepotId/CountryId, `SaveTransferOrigin`/`SaveTransferDestination` set the masked funding data, various `SaveTransfer*FundingId` procedures set funding identifiers, and `UpdateTransferStatus` advances the status through the lifecycle. The system versioning with `History.Transfers` preserves a complete audit trail of every change. The `Monitoring.GetLastTransfersStatusesInPercentage` procedure reports on status distributions for operational health monitoring.

---

## 2. Business Logic

### 2.1 Transfer Lifecycle

**What**: Each transfer progresses through a defined set of states from creation to terminal resolution.

**Columns/Parameters Involved**: `TransferStatusID`, `CreateDate`, `ModificationDate`

**Rules**:
- Transfers are created with TransferStatusID = 0 (New) by `CreateTransfer`
- The happy path progresses: New(0) -> Init(1) -> Pending(2) -> Sent(9) -> Received(10)
- Failure states: Technical(4), Cancel(7), Fail(8) branch from intermediate states
- Status 10 (Received) is a hard terminal state - `UpdateTransferStatus` throws error 50000 if a transfer is already Received, preventing accidental reopening
- ModificationDate is auto-updated by trigger `TR_Transfers_ModificationDate` on every UPDATE, providing the latest change timestamp
- Statuses 9 (Sent) and 10 (Received) are treated as "success" for customer-facing queries

**Diagram**:
```
CreateTransfer (INSERT, Status=0)
       |
       v
    New(0) --> Init(1) --> Pending(2) --> Sent(9) --> Received(10) [TERMINAL]
                  |            |
                  +--> Cancel(7)
                  |            |
                  |            +--> Technical(4)
                  |
                  +--> Fail(8)

Each status transition: UpdateTransferStatus(RefGuid, StatusID)
ModificationDate auto-updated by trigger on every UPDATE
System versioning captures full history in History.Transfers
```

### 2.2 Multi-Step Field Population Pattern

**What**: Transfer records are populated incrementally across multiple stored procedure calls as the transfer progresses through the pipeline, rather than in a single INSERT.

**Columns/Parameters Involved**: `OriginFundingData`, `DestinationFundingData`, `InitFundingId`, `OriginFundingId`, `DestinationFundingId`, `DepotId`, `CountryId`, `ExReferenceID`, `ExtTransactionId`

**Rules**:
- CreateTransfer sets core fields: ReferenceID, CID, CurrencyID, FundingTypeIDs, Amount, TransferStatusID, ExReferenceID
- SaveRoutingInfo sets DepotId + CountryId (routing/geography info determined after creation)
- SaveTransferOrigin/SaveTransferDestination set the masked funding data (bank account details, PII-protected)
- SaveTransferInitFundingId/SaveTransferOriginFundingId/SaveTransferDestinationFundingId set the funding identifiers from the payment provider
- SaveExtRefId/SaveExtTransactionId update external reference identifiers from the provider
- All updates are keyed by ReferenceID (the unique clustered index), not TransferID

### 2.3 Funding Source Pair Model

**What**: Each transfer defines an origin and destination funding source, identified by type and optional data/ID fields.

**Columns/Parameters Involved**: `OriginFundingTypeID`, `DestinationFundingTypeID`, `OriginFundingData`, `DestinationFundingData`, `OriginFundingId`, `DestinationFundingId`, `InitFundingId`

**Rules**:
- OriginFundingTypeID identifies the type of the source (e.g., 38 = common in recent data)
- DestinationFundingTypeID identifies the type of the destination (e.g., 33 = common in recent data)
- FundingData columns contain masked PII (bank account details, card info) using SQL Server Dynamic Data Masking
- FundingId columns hold provider-assigned numeric identifiers for the funding instruments
- InitFundingId appears to track the initial funding instrument before routing decisions

---

## 3. Data Overview

| TransferID | CID | CurrencyID | Amount | TransferStatusID | DepotId | CountryId | Meaning |
|---|---|---|---|---|---|---|---|
| 4883277 | 43445343 | 2 | 50.00 | 1 (Init) | 104 | 143 | A recently created transfer of 50 units in currency 2 (EUR), currently initializing. Customer routed to depot 104, country 143. No external transaction ID yet - provider processing hasn't started. |
| 4883274 | 11030996 | 2 | 350.00 | 2 (Pending) | 166 | 191 | A 350 EUR transfer in Pending state at depot 166, country 191. Has both InitFundingId and DestinationFundingId populated and an ExtTransactionId, indicating the provider has accepted the transfer. |
| 4883271 | 34701433 | 3 | 1000.00 | 2 (Pending) | 104 | 218 | A 1000-unit transfer in currency 3 (GBP), pending at depot 104 for country 218. Shows a different currency option available in the system. |
| 4883270 | 43154926 | 2 | 10000.00 | 2 (Pending) | 104 | 191 | A large 10,000 EUR transfer - demonstrates the range of amounts. Same depot 104 / country 191 routing pattern. |
| 4883268 | 34384640 | 2 | 400.00 | 2 (Pending) | 104 | 191 | A 400 EUR transfer with a ~15 second gap between CreateDate and ModificationDate, showing the typical processing delay as the transfer moves through pipeline stages. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TransferID | int | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing unique identifier for each transfer. NONCLUSTERED PK. Used as a secondary lookup key and in range-based monitoring queries (`GetLastTransfersStatusesInPercentage` scans by TransferID ranges). Current values in the ~4.88M range. |
| 2 | ReferenceID | uniqueidentifier | NO | - | VERIFIED | Application-generated GUID serving as the primary business key for each transfer. UNIQUE CLUSTERED index makes it the physical sort order. All UPDATE operations (SaveRoutingInfo, SaveTransferOrigin, UpdateTransferStatus, etc.) locate records by ReferenceID via WHERE clause. More reliable than TransferID for cross-service correlation. |
| 3 | CID | int | NO | - | CODE-BACKED | Customer identifier - the user who initiated or owns the transfer. Used for customer-scoped queries: `GetTransfersByCID`, `GetDepotIdOfLastSuccessfulTransferByCid`, `GetLastSuccessTransferDataByCid`. Indexed for performance (IX_Billing_Transfers_CID). References an external customer system. |
| 4 | CurrencyID | int | NO | - | CODE-BACKED | Currency of the transfer amount. No Dictionary table exists in this database; values are managed externally. Sample data shows 2 (likely EUR) and 3 (likely GBP) as common values. Part of composite index IX_Billing_Transfers_CurrencyID_TransferStatusID_TransferID. |
| 5 | OriginFundingTypeID | int | NO | - | CODE-BACKED | Type classification for the source/origin funding instrument. No lookup table in this database; values managed by the MoneyBus/MoneyBusAdapter application layer. Sample data shows 38 as the dominant value. Paired with DestinationFundingTypeID to define the transfer direction (e.g., bank-to-trading, trading-to-bank). |
| 6 | DestinationFundingTypeID | int | NO | - | CODE-BACKED | Type classification for the destination funding instrument. No lookup table in this database. Sample data shows 33 as the dominant value. Together with OriginFundingTypeID defines the transfer flow direction. |
| 7 | Amount | money | NO | - | VERIFIED | Transfer amount in the currency specified by CurrencyID. Set at creation time and not modified afterward. Observed range in sample: 50 to 10,000. Stored as SQL Server `money` type (4 decimal places). |
| 8 | OriginFundingData | nvarchar(max) | YES | - | CODE-BACKED | Masked (Dynamic Data Masking: default()) JSON or structured data containing the origin funding instrument details (bank account number, card details, etc.). Contains PII - masked for non-privileged users. Set by `Billing.SaveTransferOrigin`. NULL until the origin funding data is captured. |
| 9 | DestinationFundingData | nvarchar(max) | YES | - | CODE-BACKED | Masked (Dynamic Data Masking: default()) JSON or structured data containing the destination funding instrument details. Contains PII. Set by `Billing.SaveTransferDestination`. NULL until destination data is captured. |
| 10 | CreateDate | datetime2(7) | NO | GETUTCDATE() | VERIFIED | UTC timestamp of transfer creation. Set automatically on INSERT via DEFAULT constraint. Never modified after creation. Used in monitoring queries to scope transfers by time window. |
| 11 | ModificationDate | datetime2(7) | NO | GETUTCDATE() | VERIFIED | UTC timestamp of the most recent modification. Initialized to GETUTCDATE() on INSERT, then auto-updated by trigger `TR_Transfers_ModificationDate` on every UPDATE operation. The gap between CreateDate and ModificationDate indicates processing duration. |
| 12 | TransferStatusID | int | NO | - | VERIFIED | Current lifecycle state of the transfer. Implicit FK to Dictionary.TransferStatus: 0=New, 1=Init, 2=Pending, 4=Technical, 7=Cancel, 8=Fail, 9=Sent, 10=Received. See [Transfer Status](../../_glossary.md#transfer-status) for full business definitions. Set to 0 on INSERT by CreateTransfer; updated by UpdateTransferStatus. Status 10 is a hard terminal state. Part of composite index with CurrencyID and TransferID. |
| 13 | ExReferenceID | varchar(50) | YES | - | CODE-BACKED | External reference ID - a provider-facing identifier for the transfer. Prefix pattern observed: "TZ" and "TK" followed by a GUID fragment (lowercase, no hyphens). Set at creation time and can be updated by `SaveExtRefId`. Covered by index IX_Transfer_ExReferenceID_Cover for lookups via `GetTransferByExReference`. |
| 14 | Trace | (computed) | - | - | CODE-BACKED | Computed column (not persisted) generating a JSON diagnostic string containing HostName, AppName, SUserName, SPID, DBName, and ObjectName at query time. Formula: `CONCAT('{"HostName": "',host_name(),'","AppName": "',app_name(),...}')`. Used for debugging to identify which connection/process last read the row. |
| 15 | StartTime | datetime2(7) | NO | - | CODE-BACKED | System versioning row start time (HIDDEN). Automatically managed by SQL Server temporal tables. Marks when this version of the row became current. Not visible in normal SELECT queries. |
| 16 | EndTime | datetime2(7) | NO | - | CODE-BACKED | System versioning row end time (HIDDEN). Automatically managed by SQL Server temporal tables. Set to `9999-12-31` for current rows; set to the modification timestamp when a row is superseded. Not visible in normal SELECT queries. |
| 17 | InitFundingId | int | YES | - | CODE-BACKED | Initial funding instrument identifier assigned early in the transfer pipeline, before origin/destination routing is finalized. Set by `SaveTransferInitFundingId`. Often NULL - populated only when the initial funding instrument differs from the final origin/destination. |
| 18 | OriginFundingId | int | YES | - | CODE-BACKED | Provider-assigned numeric identifier for the origin funding instrument (bank account, card, wallet). Set by `SaveTransferOriginFundingId`. NULL in most recent sample data, suggesting it may be populated only for certain transfer types or providers. |
| 19 | DestinationFundingId | int | YES | - | CODE-BACKED | Provider-assigned numeric identifier for the destination funding instrument. Set by `SaveTransferDestinationFundingId`. More frequently populated than OriginFundingId in sample data. |
| 20 | DepotId | int | YES | - | VERIFIED | Depot/data center identifier determining which processing infrastructure handles this transfer. Set by `SaveRoutingInfo`. Common values: 104 and 166. Default fallback value is 104 (used by `GetDepotIdOfLastSuccessfulTransferByCid` when DepotId is NULL). Determines routing for regional processing. |
| 21 | CountryId | int | YES | - | CODE-BACKED | Country identifier for the customer or transfer jurisdiction. Set by `SaveRoutingInfo` alongside DepotId. Observed values: 74, 112, 143, 191, 218. References an external country lookup. Used for regional routing and compliance. |
| 22 | ExtTransactionId | varchar(50) | YES | - | CODE-BACKED | External transaction identifier from the payment provider. Set by `SaveExtTransactionId`. Can be GUID-format (with hyphens removed) or shorter hex strings, depending on the provider. NULL until the provider assigns a transaction reference. Returned by `GetTransferByReferenceID`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TransferStatusID | Dictionary.TransferStatus | Implicit FK (Lookup) | Transfer lifecycle state: 0=New, 1=Init, 2=Pending, 4=Technical, 7=Cancel, 8=Fail, 9=Sent, 10=Received |
| CID | External (Customer system) | External Reference | Customer identifier managed outside this database |
| CurrencyID | External (Currency lookup) | External Reference | Currency code, no Dictionary table in this DB |
| OriginFundingTypeID | External (FundingType) | External Reference | Funding type managed by application layer |
| DestinationFundingTypeID | External (FundingType) | External Reference | Funding type managed by application layer |
| CountryId | External (Country lookup) | External Reference | Country identifier managed outside this database |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.PostTransferActions | TransferID | Implicit FK | Post-transfer follow-up actions linked to this transfer |
| History.Transfers | (system versioning) | Temporal History | Automatic system-versioned history table preserving all row changes |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.PostTransferActions | Table | TransferID references this table (implicit FK) |
| History.Transfers | Table | System-versioned history table (automatic) |
| Billing.CreateTransfer | Stored Procedure | WRITER - inserts new transfer records |
| Billing.UpdateTransferStatus | Stored Procedure | MODIFIER - advances transfer status with terminal state guard |
| Billing.SaveRoutingInfo | Stored Procedure | MODIFIER - sets DepotId and CountryId |
| Billing.SaveTransferOrigin | Stored Procedure | MODIFIER - sets OriginFundingData |
| Billing.SaveTransferDestination | Stored Procedure | MODIFIER - sets DestinationFundingData |
| Billing.SaveTransferInitFundingId | Stored Procedure | MODIFIER - sets InitFundingId |
| Billing.SaveTransferOriginFundingId | Stored Procedure | MODIFIER - sets OriginFundingId |
| Billing.SaveTransferDestinationFundingId | Stored Procedure | MODIFIER - sets DestinationFundingId |
| Billing.SaveExtRefId | Stored Procedure | MODIFIER - updates ExReferenceID |
| Billing.SaveExtTransactionId | Stored Procedure | MODIFIER - sets ExtTransactionId |
| Billing.GetTransferByReferenceID | Stored Procedure | READER - retrieves transfer by business key |
| Billing.GetTransferByExReference | Stored Procedure | READER - retrieves transfer by provider reference |
| Billing.GetTransfersByCID | Stored Procedure | READER - lists all transfers for a customer |
| Billing.GetDepotIdOfLastSuccessfulTransferByCid | Stored Procedure | READER - finds last successful depot |
| Billing.GetLastDepotIdForTransferStatusesByCid | Stored Procedure | READER - finds last depot for allowed statuses |
| Billing.GetLastSuccessTransferDataByCid | Stored Procedure | READER - finds last success transfer metadata |
| Monitoring.GetLastTransfersStatusesInPercentage | Stored Procedure | READER - JOINs to Dictionary.TransferStatus for status distribution |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Transfers | NC PK | TransferID ASC | - | - | Active |
| UQ_Transfer_ReferenceID | CLUSTERED UNIQUE | ReferenceID ASC | - | - | Active |
| IX_Billing_Transfers_CID | NC | CID ASC | - | - | Active (PAGE compressed) |
| IX_Billing_Transfers_CurrencyID_TransferStatusID_TransferID | NC | CurrencyID, TransferStatusID, TransferID ASC | - | - | Active (PAGE compressed) |
| IX_Transfer_ExReferenceID_Cover | NC | ExReferenceID ASC | TransferID, ReferenceID, TransferStatusID, OriginFundingData, DestinationFundingData, CID, Amount, OriginFundingTypeID, DestinationFundingTypeID, CurrencyID, CreateDate, ModificationDate | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Transfers | PRIMARY KEY (NC) | TransferID - unique identity for each transfer |
| UQ_Transfer_ReferenceID | UNIQUE CLUSTERED | ReferenceID - ensures no duplicate business keys; clustered for optimal lookup performance since most queries use ReferenceID |
| (unnamed) | DEFAULT | CreateDate = GETUTCDATE() - auto-stamps creation in UTC |
| (unnamed) | DEFAULT | ModificationDate = GETUTCDATE() - initial modification timestamp |
| TR_Transfers_ModificationDate | TRIGGER (AFTER UPDATE) | Auto-updates ModificationDate to GETUTCDATE() on every UPDATE, ensuring accurate last-modified tracking |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.Transfers - preserves full audit trail of all row changes with StartTime/EndTime |

---

## 8. Sample Queries

### 8.1 Get a transfer by its business reference
```sql
SELECT TransferID, ReferenceID, CID, Amount, CurrencyID,
       TransferStatusID, CreateDate, ModificationDate, DepotId
FROM Billing.Transfers WITH (NOLOCK)
WHERE ReferenceID = @ReferenceID
```

### 8.2 Get all transfers for a customer with status names
```sql
SELECT t.TransferID, t.ReferenceID, t.Amount, t.CurrencyID,
       ts.Name AS StatusName, t.CreateDate, t.ModificationDate
FROM Billing.Transfers t WITH (NOLOCK)
JOIN Dictionary.TransferStatus ts WITH (NOLOCK) ON t.TransferStatusID = ts.ID
WHERE t.CID = @CID
ORDER BY t.TransferID DESC
```

### 8.3 Find the last successful depot for a customer
```sql
SELECT TOP 1 ISNULL(DepotId, 104) AS DepotId
FROM Billing.Transfers WITH (NOLOCK)
WHERE CID = @CID AND TransferStatusID = 10
ORDER BY TransferID DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Internal Transfer - Banking - LLD](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/12756353039) | Confluence | Architecture context: MoneyBus orchestrates transfers via MoneyBusAdapter; FlowId determines transfer type (e.g., InternalTransfer); Hold/Credit/Abort pattern for IBAN-to-Trading transfers. Linked to epic MONPROG-2942. |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 19 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.Transfers | Type: Table | Source: MoneyTransfer/Billing/Tables/Billing.Transfers.sql*
