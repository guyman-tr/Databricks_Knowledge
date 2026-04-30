# History.AccountUserInfo

> Audit history table storing temporal snapshots of Customer.AccountUserInfo changes, populated by triggers on INSERT/UPDATE/DELETE.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | CustomerVersionID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (PK + NC on GCID,CustomerVersionID DESC) |

---

## 1. Business Meaning

History.AccountUserInfo stores a complete temporal audit trail of all changes to user account configuration. Each row is a snapshot of the Customer.AccountUserInfo record at a point in time, bounded by ValidFrom and ValidTo timestamps. When a change occurs, the trigger closes the current row (sets ValidTo) and inserts a new one. The Trace column captures the connection context (host, app, login) for audit purposes.

This table is critical for compliance reporting and investigating account configuration changes (label reassignment, guru status changes, account type transitions). Customer.GetVerificationLevelChangesHistory and similar SPs query this table.

---

## 2. Business Logic

### 2.1 Temporal Snapshot Pattern

**What**: Each row represents the state of a user's account config during a time window.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo`, `CustomerVersionID`

**Rules**:
- ValidFrom = when this version became active
- ValidTo = when this version was superseded (or '3000-01-01' for current)
- Latest version for a GCID: MAX(CustomerVersionID) or ValidTo = '3000-01-01'
- Populated by triggers on Customer.AccountUserInfo (INSERT trigger DISABLED, UPDATE trigger ENABLED, DELETE trigger DISABLED)

---

## 3. Data Overview

N/A - large audit history table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CustomerVersionID | int (IDENTITY) | NO | - | CODE-BACKED | Primary key. Auto-incrementing version identifier. |
| 2 | ValidFrom | datetime | NO | - | CODE-BACKED | When this snapshot became the active version. |
| 3 | ValidTo | datetime | NO | - | CODE-BACKED | When this snapshot was superseded. '3000-01-01' = current version. |
| 4 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. Multiple rows per GCID (one per change). |
| 5 | SerialID | int | YES | - | CODE-BACKED | Affiliate/serial ID at this point in time. |
| 6 | LabelID | int | NO | - | CODE-BACKED | White-label brand ID at this point. See Customer.AccountUserInfo for value details. |
| 7 | TradeLevelID | int | NO | - | CODE-BACKED | Trade UI level at this point. |
| 8 | CurrencyID | int | NO | - | CODE-BACKED | Account base currency at this point. |
| 9 | PendingClosureStatusID | tinyint | YES | - | CODE-BACKED | Closure status at this point. |
| 10 | AccountStatusID | tinyint | YES | - | CODE-BACKED | Account operational status at this point. |
| 11 | AccountTypeID | tinyint | NO | - | CODE-BACKED | Account type at this point. |
| 12 | MasterAccountCID | int | YES | - | CODE-BACKED | Master account CID at this point. |
| 13 | ManagerID | int | YES | - | CODE-BACKED | Account manager CID at this point. |
| 14 | GuruStatusID | int | YES | - | CODE-BACKED | Popular Investor tier at this point. See [Guru Status](_glossary.md#guru-status). |
| 15 | Trace | varchar(max) | YES | JSON | CODE-BACKED | Connection audit context: HostName, AppName, SUserName, OriginalLogin, SPID, DBName, ObjectName. Default: computed JSON. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no explicit FK constraints (history tables avoid FKs for insert performance).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.AccountUserInfo triggers | GCID | Trigger writes | INSERT/UPDATE/DELETE triggers populate this table |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

Populated by triggers on Customer.AccountUserInfo.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryAccountUserInfo | CLUSTERED PK | CustomerVersionID | - | - | Active |
| Idx_HistoryAccount_GCID_CustomerVersionID | NONCLUSTERED | GCID ASC, CustomerVersionID DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Df_HistoryAccountUserInfo_Trace | DEFAULT | JSON with HostName, AppName, SUserName, OriginalLogin, SPID, DBName, ObjectName |

---

## 8. Sample Queries

### 8.1 Full account history for a user
```sql
SELECT CustomerVersionID, ValidFrom, ValidTo, LabelID, TradeLevelID, GuruStatusID
FROM History.AccountUserInfo WITH (NOLOCK) WHERE GCID = @GCID ORDER BY CustomerVersionID DESC
```

### 8.2 Current version
```sql
SELECT * FROM History.AccountUserInfo WITH (NOLOCK) WHERE GCID = @GCID AND ValidTo = '3000-01-01'
```

### 8.3 Guru status change history
```sql
SELECT ValidFrom, ValidTo, GuruStatusID, gs.Name AS GuruTier
FROM History.AccountUserInfo h WITH (NOLOCK)
LEFT JOIN Dictionary.GuruStatus gs WITH (NOLOCK) ON h.GuruStatusID = gs.GuruStatusID
WHERE h.GCID = @GCID ORDER BY h.ValidFrom
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: History.AccountUserInfo | Type: Table | Source: UserApiDB/UserApiDB/History/Tables/History.AccountUserInfo.sql*
