# History.PlayerStatus

> Manual audit log capturing every BackOffice-initiated player status change, recording the old and new status, the manager who made the change, when it occurred, and a free-text reason comment.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | HistoryStatusID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No (on HISTORY filegroup) |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

History.PlayerStatus is a manual audit log for changes to a customer's player status (account access restrictions). Unlike SQL Server temporal tables, this table is written explicitly by Customer.SetStatus within a transaction that atomically updates Customer.Customer.PlayerStatusID and inserts a history row here.

Player status controls what a customer can do on the platform: whether they can log in, trade, deposit, withdraw, copy others, or chat. BackOffice managers change a customer's status for compliance, risk, fraud, or support reasons. Each change triggers a realtime kick message to the customer if they are currently online (e.g., kick login, kick chat, trade block notification).

The table contains 46,805 rows spanning March 2009 through March 2017. The data stopping in 2017 indicates this stored procedure path was superseded by a newer system or microservice after that date; this table serves as the historical record for the legacy period.

The table is stored on the HISTORY filegroup (separate from primary data) with TEXTIMAGE for the Comment varchar(max) column.

---

## 2. Business Logic

### 2.1 Status Change Audit Trail

**What**: Every time a BackOffice manager changes a customer's player status, the before/after state is recorded here.

**Columns/Parameters Involved**: `CID`, `OldPlayerStatusID`, `NewPlayerStatusID`, `ChangedBy`, `Occurred`, `Comment`

**Rules**:
- Written exclusively by Customer.SetStatus within a BEGIN/COMMIT TRANSACTION that also updates Customer.Customer.
- If the UPDATE or INSERT fails, the entire transaction rolls back - audit and live data are always in sync.
- OldPlayerStatusID is read from Customer.Customer before the update (`SELECT @OldPlayerStatus = PlayerStatusID`).
- Occurred is GETDATE() - local server time, not UTC.
- Comment is a required free-text reason provided by the manager. Short comments ("yy", "fg") are common in older data.
- OldPlayerStatusID = NewPlayerStatusID is valid: a manager can "re-set" the same status (e.g., to update Comment or trigger the kick message).

### 2.2 Player Status Values and Access Rights

**What**: NewPlayerStatusID determines the full set of access permissions applied after the change.

**Columns/Parameters Involved**: `NewPlayerStatusID`, `OldPlayerStatusID`

**Rules** (values from Dictionary.PlayerStatus):

| ID | Name | IsBlocked | CanLogin | CanTrade | CanDeposit | CanWithdraw |
|----|------|-----------|----------|----------|------------|-------------|
| 1 | Normal | No | Yes | Yes | Yes | Yes |
| 2 | Blocked | Yes | No | No | No | No |
| 3 | Chat Blocked | No | Yes | Yes | Yes | Yes |
| 4 | Blocked Upon Request | Yes | No | No | No | No |
| 5 | Warning | No | Yes | Yes | Yes | Yes |
| 6 | Blocked - Under Investigation | Yes | No | No | No | No |
| 7 | Scalpers Block | Yes | No | No | No | No |
| 8 | Blocked - PayPal Investigation | Yes | No | No | No | No |
| 9 | Trade & MIMO Blocked | No | Yes | No | No | No |
| 10 | Deposit Blocked | No | Yes | Yes | No | Yes |
| 11 | Social Index | No | Yes | Yes | No | No |
| 12 | Copy Block | No | Yes | Yes | Yes | Yes |
| 13 | Pending Verification | No | Yes | No | No | No |
| 14 | Blocked - Failed Verification | Yes | No | No | No | No |
| 15 | Block Deposit & Trading | No | Yes | No | No | No |

- `IsBlocked=true` statuses (2, 4, 6, 7, 8, 14) also update `dbo.STS_User.Blocked=1` for the customer's GCID.
- IsBlocked=true triggers MessageTemplate 14 (kick login) if customer is online.
- Status 3 (Chat Blocked) triggers MessageTemplate 15 (kick chat).
- Status 9 (Trade & MIMO Blocked) triggers MessageTemplate 17 (trade block).

### 2.3 Most Common Transitions (Historical)

**What**: The top status change patterns reveal enforcement workflows.

**Rules** (from 46,805 historical rows):
- Normal -> Trade & MIMO Blocked (9): 9,525 - most common action; partial restriction without full block
- Normal -> Blocked Upon Request (4): 7,448 - customer-requested account freeze
- Normal -> Blocked (2): 4,931 - full compliance/fraud block
- Trade & MIMO Blocked -> Normal (9->1): 4,788 - restriction lifted
- Blocked -> Blocked (2->2): 4,516 - re-application of same status (comment update or kick re-trigger)
- Normal -> Deposit Blocked (10): 1,419 - deposit-only restriction

---

## 3. Data Overview

| HistoryStatusID | CID | OldStatus | NewStatus | ChangedBy | Occurred | Comment |
|----------------|-----|-----------|-----------|-----------|----------|---------|
| 47848 | 28 | Trade & MIMO Blocked (9) | Normal (1) | ManagerID 723 | 2017-03-01 | "yy" |
| 47847 | 28 | Normal (1) | Trade & MIMO Blocked (9) | ManagerID 728 | 2017-03-01 | "fg" |
| 47846 | 28 | Blocked (2) | Normal (1) | ManagerID 723 | 2017-03-01 | "te" |

46,805 rows | Oldest: 2009-03-15 | Newest: 2017-03-01 | Data is historical (no new writes since 2017)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HistoryStatusID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate PK. Monotonically increasing with Occurred. NOT FOR REPLICATION prevents identity gaps during SQL replication. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer whose status changed. FK to Customer.CustomerStatic (FK_CCST_HPLS). Required - every status change is customer-specific. |
| 3 | OldPlayerStatusID | int | NO | - | CODE-BACKED | The customer's player status before this change. FK to Dictionary.PlayerStatus (FK_DPLS_HPLS_OLD). Read from Customer.Customer within the same transaction. |
| 4 | NewPlayerStatusID | int | NO | - | CODE-BACKED | The customer's player status after this change. FK to Dictionary.PlayerStatus (FK_DPLS_HPLS_NEW). Values: 1=Normal, 2=Blocked, 3=Chat Blocked, 4=Blocked Upon Request, 5=Warning, 6=Blocked-UnderInvestigation, 7=Scalpers Block, 8=Blocked-PayPalInvestigation, 9=Trade&MIMOBlocked, 10=DepositBlocked, 11=SocialIndex, 12=CopyBlock, 13=PendingVerification, 14=Blocked-FailedVerification, 15=BlockDeposit&Trading. |
| 5 | ChangedBy | int | NO | - | CODE-BACKED | BackOffice manager who initiated the change. FK to BackOffice.Manager (FK_BMNG_HPLS). Passed as @ManagerID to Customer.SetStatus. Always a human manager action. |
| 6 | Occurred | datetime | NO | - | CODE-BACKED | Server local datetime (GETDATE()) when the status change was applied. Note: not UTC. For the 2009-2017 period this table covers, the offset from UTC depends on server timezone. |
| 7 | Comment | varchar(max) | NO | - | CODE-BACKED | Free-text reason for the status change provided by the BackOffice manager. Required (NOT NULL) but unconstrained in length. Short values ("yy", "fg") are common in older data. Stored on HISTORY filegroup via TEXTIMAGE_ON. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (FK_CCST_HPLS) | The customer whose status was changed. |
| OldPlayerStatusID | Dictionary.PlayerStatus | FK (FK_DPLS_HPLS_OLD) | Player status before this change. |
| NewPlayerStatusID | Dictionary.PlayerStatus | FK (FK_DPLS_HPLS_NEW) | Player status after this change. |
| ChangedBy | BackOffice.Manager | FK (FK_BMNG_HPLS) | BackOffice manager who performed the change. |

### 5.2 Referenced By (other objects point to this)

No procedures query this table in the current codebase. It serves as a historical record for the 2009-2017 period.

---

## 6. Dependencies

### 6.0 Dependency Chain

`Customer.CustomerStatic` <- CID FK (enforced)
`Dictionary.PlayerStatus` <- OldPlayerStatusID/NewPlayerStatusID FK (enforced)
`BackOffice.Manager` <- ChangedBy FK (enforced)

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK - validates that CID is a known customer |
| Dictionary.PlayerStatus | Table | FK (x2) - validates OldPlayerStatusID and NewPlayerStatusID |
| BackOffice.Manager | Table | FK - validates ChangedBy is a known manager |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetStatus | Stored Procedure | WRITER - inserts history row within the same transaction as updating Customer.Customer.PlayerStatusID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HPLS | CLUSTERED PK | HistoryStatusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HPLS | PRIMARY KEY | Unique per history row |
| FK_CCST_HPLS | FOREIGN KEY | CID -> Customer.CustomerStatic |
| FK_DPLS_HPLS_OLD | FOREIGN KEY | OldPlayerStatusID -> Dictionary.PlayerStatus |
| FK_DPLS_HPLS_NEW | FOREIGN KEY | NewPlayerStatusID -> Dictionary.PlayerStatus |
| FK_BMNG_HPLS | FOREIGN KEY | ChangedBy -> BackOffice.Manager |

### 7.3 Storage

| Property | Value |
|----------|-------|
| Filegroup | HISTORY |
| TEXTIMAGE filegroup | HISTORY (for Comment varchar(max)) |
| NOT FOR REPLICATION | Applied to IDENTITY - prevents identity skipping during replication |

---

## 8. Sample Queries

### 8.1 Get full status history for a customer

```sql
SELECT h.HistoryStatusID, h.CID, old_s.Name AS OldStatus, new_s.Name AS NewStatus,
       h.ChangedBy, h.Occurred, LEFT(h.Comment, 200) AS Comment
FROM History.PlayerStatus h WITH (NOLOCK)
JOIN Dictionary.PlayerStatus old_s WITH (NOLOCK) ON old_s.PlayerStatusID = h.OldPlayerStatusID
JOIN Dictionary.PlayerStatus new_s WITH (NOLOCK) ON new_s.PlayerStatusID = h.NewPlayerStatusID
WHERE h.CID = 12345
ORDER BY h.Occurred;
```

### 8.2 Count status changes by transition type

```sql
SELECT old_s.Name AS FromStatus, new_s.Name AS ToStatus, COUNT(*) AS ChangeCount
FROM History.PlayerStatus h WITH (NOLOCK)
JOIN Dictionary.PlayerStatus old_s WITH (NOLOCK) ON old_s.PlayerStatusID = h.OldPlayerStatusID
JOIN Dictionary.PlayerStatus new_s WITH (NOLOCK) ON new_s.PlayerStatusID = h.NewPlayerStatusID
GROUP BY old_s.Name, new_s.Name
ORDER BY ChangeCount DESC;
```

### 8.3 Find all block actions by a specific manager

```sql
SELECT h.HistoryStatusID, h.CID, ps.Name AS NewStatus, h.Occurred, h.Comment
FROM History.PlayerStatus h WITH (NOLOCK)
JOIN Dictionary.PlayerStatus ps WITH (NOLOCK) ON ps.PlayerStatusID = h.NewPlayerStatusID
WHERE h.ChangedBy = 723
  AND ps.IsBlocked = 1
ORDER BY h.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PlayerStatus | Type: Table | Source: etoro/etoro/History/Tables/History.PlayerStatus.sql*
