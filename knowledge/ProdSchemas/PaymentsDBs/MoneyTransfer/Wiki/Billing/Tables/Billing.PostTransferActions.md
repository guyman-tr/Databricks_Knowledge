# Billing.PostTransferActions

> Records follow-up actions that occur after a primary money transfer is initiated, such as secondary fund movements, notifications, or reconciliation steps, each tracked with its own status and payload.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | PostTransferActionID (int, IDENTITY, NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (PK + ReferenceID) |

---

## 1. Business Meaning

Billing.PostTransferActions stores follow-up operations that are triggered after a primary money transfer (stored in Billing.Transfers) has been initiated. Each post-transfer action represents a secondary operation - such as a downstream fund movement to a specific funding type, a notification, or a reconciliation step - that must be tracked independently from the main transfer.

This table enables the system to decouple the primary transfer lifecycle from its post-processing steps. A single transfer can generate one or more post-transfer actions, each with its own status (PostTransferStatusID) and payload. This separation allows post-processing to proceed asynchronously and fail independently without blocking the main transfer.

Post-transfer actions are created by `Billing.CreatePostTransfer`, which links the action to a parent transfer via TransferID and associates it with a ReferenceID for lookup. The payload (masked PII) and status can be independently updated via `UpdatePostTransferPayload` and `UpdatePostTransferStatus`. The `GetPostTransfer` procedure retrieves all actions for a given ReferenceID. Both MIMO (external monitoring) and MoneyTransferUser service accounts have SELECT access.

---

## 2. Business Logic

### 2.1 Post-Transfer Action Lifecycle

**What**: Each post-transfer action progresses through its own status lifecycle independently from the parent transfer.

**Columns/Parameters Involved**: `PostTransferStatusID`, `PostTransferActionTypeID`, `CreateDate`

**Rules**:
- Actions are created with a caller-specified PostTransferStatusID (typically 1) and PostTransferActionTypeID (default 1)
- PostTransferStatusID values observed in live data: 1 and 2 (Dictionary.PostTransferStatus is empty - values are application-managed)
- PostTransferActionTypeID defaults to 1 via constraint DF_PostTransferActions_PostTransferActionTypeID - all sample data shows value 1
- Status is updated independently via `UpdatePostTransferStatus`, allowing the action to progress regardless of the parent transfer's state
- No trigger exists for tracking modification time - CreateDate is the only timestamp

### 2.2 Transfer-to-Action Relationship

**What**: Post-transfer actions are linked to parent transfers through both TransferID and ReferenceID, enabling lookup from either direction.

**Columns/Parameters Involved**: `TransferID`, `ReferenceID`, `PostTransferActionID`

**Rules**:
- TransferID links to `Billing.Transfers.TransferID` (no explicit FK constraint)
- ReferenceID is indexed (IX_Billing_PostTransferActions) and used by GetPostTransfer, UpdatePostTransferPayload, and UpdatePostTransferStatus as the primary lookup key
- ReferenceID may match the parent transfer's ReferenceID or be a unique action-specific GUID
- A single transfer can have multiple post-transfer actions (one-to-many relationship)

---

## 3. Data Overview

| PostTransferActionID | TransferID | FundingTypeID | PostTransferStatusID | PostTransferActionTypeID | Meaning |
|---|---|---|---|---|---|
| 2591822 | 4883299 | 33 | 2 | 1 | A completed post-transfer action (status 2) for a recent transfer. FundingTypeID 33 matches the common destination funding type in Billing.Transfers, suggesting this action processes the destination side of the transfer. |
| 2591820 | 4883282 | 33 | 1 | 1 | A post-transfer action still in its initial state (status 1) - processing has not yet completed. Same funding type pattern. |
| 2591818 | 4883268 | 33 | 2 | 1 | A completed post-transfer action linked to transfer 4883268 (a 400 EUR transfer). Status 2 indicates the post-transfer processing finished. |
| 2591815 | 4883228 | 33 | 1 | 1 | An action in initial state for an older transfer in the same batch, showing the mix of completed and pending actions in the active pipeline. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PostTransferActionID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key (NONCLUSTERED). Unique identifier for each post-transfer action. Current values in the ~2.59M range. |
| 2 | TransferID | int | NO | - | VERIFIED | Foreign key to `Billing.Transfers.TransferID` (implicit, no constraint). Links this action to its parent transfer. Set by `CreatePostTransfer`. Every action must be associated with an existing transfer. |
| 3 | ReferenceID | uniqueidentifier | YES | - | CODE-BACKED | Business reference GUID for this action. Indexed (IX_Billing_PostTransferActions) for lookup performance. Used as the primary lookup key by `GetPostTransfer`, `UpdatePostTransferPayload`, and `UpdatePostTransferStatus`. May correspond to the parent transfer's ReferenceID or be action-specific. |
| 4 | Payload | nvarchar(max) | YES | - | CODE-BACKED | Masked (Dynamic Data Masking: default()) JSON or structured data containing the action's operational details. Contains PII. Set by `CreatePostTransfer` and can be updated by `UpdatePostTransferPayload`. The content depends on the action type and may include funding instrument details, provider responses, or processing metadata. |
| 5 | FundingTypeID | int | NO | - | CODE-BACKED | Type of funding instrument associated with this action. No lookup table in this database. Sample data consistently shows value 33 (matching the DestinationFundingTypeID pattern in Billing.Transfers), suggesting most post-transfer actions relate to destination-side processing. |
| 6 | PostTransferStatusID | int | NO | - | CODE-BACKED | Lifecycle status of this post-transfer action. Implicit reference to Dictionary.PostTransferStatus (currently empty). Observed values: 1 (initial/in-progress), 2 (completed). Set by `CreatePostTransfer`, updated by `UpdatePostTransferStatus`. See [Post Transfer Status](../../_glossary.md#post-transfer-status). |
| 7 | CreateDate | datetime2(7) | NO | GETUTCDATE() | CODE-BACKED | UTC timestamp of action creation. Set automatically via DEFAULT constraint. No modification timestamp exists - status changes are tracked only by value, not by when they occurred. |
| 8 | PostTransferActionTypeID | int | NO | 1 | CODE-BACKED | Type classification for the post-transfer action. Defaults to 1 via constraint DF_PostTransferActions_PostTransferActionTypeID. All observed data shows value 1, suggesting only one action type is currently in use. No lookup table exists in this database. Set by `CreatePostTransfer`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TransferID | Billing.Transfers | Implicit FK | Parent transfer that triggered this post-transfer action |
| PostTransferStatusID | Dictionary.PostTransferStatus | Implicit FK (Lookup) | Action status - table is empty; values 1 and 2 are application-managed |
| FundingTypeID | External (FundingType) | External Reference | Funding type managed by application layer |
| PostTransferActionTypeID | External (ActionType) | External Reference | Action type managed by application layer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CreatePostTransfer | (INSERT) | Writer | Creates new post-transfer action records |
| Billing.GetPostTransfer | (SELECT) | Reader | Retrieves actions by ReferenceID |
| Billing.UpdatePostTransferPayload | (UPDATE) | Modifier | Updates Payload by ReferenceID |
| Billing.UpdatePostTransferStatus | (UPDATE) | Modifier | Updates PostTransferStatusID by ReferenceID |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (no FROM/JOIN in CREATE TABLE).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CreatePostTransfer | Stored Procedure | WRITER - inserts new post-transfer actions |
| Billing.GetPostTransfer | Stored Procedure | READER - retrieves actions by ReferenceID |
| Billing.UpdatePostTransferPayload | Stored Procedure | MODIFIER - updates Payload content |
| Billing.UpdatePostTransferStatus | Stored Procedure | MODIFIER - advances action status |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | NC PK | PostTransferActionID ASC | - | - | Active |
| IX_Billing_PostTransferActions | NC | ReferenceID ASC | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (unnamed) | DEFAULT | CreateDate = GETUTCDATE() - auto-stamps creation in UTC |
| DF_PostTransferActions_PostTransferActionTypeID | DEFAULT | PostTransferActionTypeID = 1 - default action type |

---

## 8. Sample Queries

### 8.1 Get all post-transfer actions for a reference
```sql
SELECT PostTransferActionID, TransferID, ReferenceID, Payload,
       FundingTypeID, PostTransferStatusID, PostTransferActionTypeID
FROM Billing.PostTransferActions WITH (NOLOCK)
WHERE ReferenceID = @ReferenceID
```

### 8.2 Find pending post-transfer actions for recent transfers
```sql
SELECT pta.PostTransferActionID, pta.TransferID, pta.PostTransferStatusID,
       pta.CreateDate, t.CID, t.Amount
FROM Billing.PostTransferActions pta WITH (NOLOCK)
JOIN Billing.Transfers t WITH (NOLOCK) ON pta.TransferID = t.TransferID
WHERE pta.PostTransferStatusID = 1
  AND pta.CreateDate >= DATEADD(HOUR, -1, GETUTCDATE())
ORDER BY pta.PostTransferActionID DESC
```

### 8.3 Count actions by status and type
```sql
SELECT PostTransferStatusID, PostTransferActionTypeID,
       COUNT(*) AS ActionCount
FROM Billing.PostTransferActions WITH (NOLOCK)
WHERE PostTransferActionID > (SELECT MAX(PostTransferActionID) - 10000 FROM Billing.PostTransferActions WITH (NOLOCK))
GROUP BY PostTransferStatusID, PostTransferActionTypeID
ORDER BY ActionCount DESC
```

---

## 9. Atlassian Knowledge Sources

No dedicated Atlassian sources found for this object. Architecture context inherited from [Internal Transfer - Banking - LLD](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/12756353039) via Billing.Transfers documentation.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PostTransferActions | Type: Table | Source: MoneyTransfer/Billing/Tables/Billing.PostTransferActions.sql*
