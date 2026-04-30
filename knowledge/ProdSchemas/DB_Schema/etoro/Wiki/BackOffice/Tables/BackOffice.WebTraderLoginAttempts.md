# BackOffice.WebTraderLoginAttempts

> Legacy log of back-office managers accessing customer accounts via the WebTrader interface, recording the CID, manager, timestamp, and IP. No new data since 2014.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | PK_WebTraderLoginAttempts: LoginID IDENTITY (CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 (1 clustered PK + 2 nonclustered) |

---

## 1. Business Meaning

`BackOffice.WebTraderLoginAttempts` recorded when a back-office manager accessed a customer's trading interface (WebTrader) on behalf of that customer. "WebTrader" refers to the web-based trading platform where managers could view or operate a customer's account for support or compliance purposes. Each time a manager performed this action, the SP `BackOffice.LoginWebTrader` inserted a row with the customer ID, manager ID, timestamp, and the internal IP from which the action was taken.

The table is a security audit log. The IP addresses in live data are all internal (10.20.10.x range), confirming these were back-office staff actions from the eToro corporate network, not external customer logins.

Live data: 917 rows (LoginIDs 1-917), with the last entry dated 2014-03-10. The WebTrader impersonation/access feature has since been replaced by other tools or this specific action is no longer logged here. The two NC indexes optimize for the most common query patterns: by Manager+CID+Time (manager activity reports) and by CID+Time (customer access history).

---

## 2. Business Logic

### 2.1 Manager WebTrader Access Logging

**What**: Records each instance of a back-office manager accessing a customer's WebTrader interface.

**Columns/Parameters Involved**: `CID`, `ManagerID`, `TimeStamp`, `IP`

**Rules**:
- Written exclusively by `BackOffice.LoginWebTrader` SP.
- One row per manager access event.
- `IP` is the internal corporate IP of the manager's workstation (10.x.x.x).
- `ManagerID` may be 0 for system/automated accesses (based on WithdrawApproval patterns where ManagerID=0 appears for automated processes).
- No delete mechanism - rows accumulate as an immutable audit log.

---

## 3. Data Overview

| Column | Observed Values |
|--------|----------------|
| Total rows | 917 |
| LoginID range | 1 to 917 |
| Date range | Legacy - last entry 2014-03-10 |
| IP pattern | All internal: 10.20.10.x |
| ManagerID examples | 602, 701 (active managers in 2014) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LoginID | bigint IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate PK. Auto-incremented. NOT FOR REPLICATION. Uniquely identifies each access event. Only 917 rows exist (table is legacy). |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID of the account being accessed. FK to Customer.CustomerStatic.CID. The customer whose WebTrader interface the manager is viewing/operating. Indexed (Idx_CID_TimeStamp). |
| 3 | ManagerID | int | YES | - | CODE-BACKED | FK (logical) to BackOffice.Manager.ManagerID. The back-office manager performing the access. Indexed (IDX_BOWTLA_ManagerID). NULL-able in DDL but in practice populated. |
| 4 | TimeStamp | datetime | YES | - | CODE-BACKED | Wall-clock datetime of the access event. Set to GETDATE() by the LoginWebTrader SP. Last live value: 2014-03-10. |
| 5 | IP | varchar(50) | YES | - | CODE-BACKED | IPv4 address of the manager's workstation at time of access. All live values are internal corporate IPs (10.20.10.x range). Confirms these are staff actions, not customer logins. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic.CID | FK (FK_WebTraderLoginAttempts_Customer) | Customer whose account was accessed |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.LoginWebTrader | INSERT | Writer | Logs each manager WebTrader access event |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.WebTraderLoginAttempts (table)
+-- Customer.CustomerStatic (table) [FK_WebTraderLoginAttempts_Customer]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK: CID must be a valid customer |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.LoginWebTrader | Stored Procedure | Writes access log entries |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_WebTraderLoginAttempts | CLUSTERED PK | LoginID ASC | - | - | Active |
| IDX_BOWTLA_ManagerID | NONCLUSTERED | ManagerID ASC, CID ASC, TimeStamp ASC (FILLFACTOR=90) | - | - | Active (on HISTORY filegroup) |
| Idx_CID_TimeStamp | NONCLUSTERED | CID ASC, TimeStamp ASC (FILLFACTOR=90) | ManagerID, IP | - | Active (on HISTORY filegroup) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_WebTraderLoginAttempts_Customer | FK | CID -> Customer.CustomerStatic |

---

## 8. Sample Queries

### 8.1 Get WebTrader access history for a specific customer

```sql
SELECT LoginID, CID, ManagerID, TimeStamp, IP
FROM BackOffice.WebTraderLoginAttempts WITH (NOLOCK)
WHERE CID = 99999
ORDER BY TimeStamp DESC;
```

### 8.2 Get manager access activity log

```sql
SELECT LoginID, CID, ManagerID, TimeStamp, IP
FROM BackOffice.WebTraderLoginAttempts WITH (NOLOCK)
WHERE ManagerID = 701
ORDER BY TimeStamp DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, Live Data, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.WebTraderLoginAttempts | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.WebTraderLoginAttempts.sql*
