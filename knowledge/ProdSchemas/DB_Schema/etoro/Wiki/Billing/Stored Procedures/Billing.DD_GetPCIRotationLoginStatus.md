# Billing.DD_GetPCIRotationLoginStatus

> DataDog monitoring check that returns 1 when the PCI_Rotation SQL Server login is currently enabled, alerting the security team if this privileged account is left active outside of scheduled encryption key rotation windows.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1-row result: value (1=login enabled/alert, 0=login disabled/OK) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DD_GetPCIRotationLoginStatus` is a DataDog synthetic monitor procedure (DBAD-17, initial version September 2022). It checks the `sys.sql_logins` system catalog to determine whether the `PCI_Rotation` SQL Server login account is currently enabled or disabled, and returns `value=1` (alert) when the login is ENABLED.

The `PCI_Rotation` SQL login is a privileged account used exclusively during PCI DSS encryption key rotation jobs. During a rotation, this login must be enabled so the rotation service can connect and re-encrypt credit card data in `Billing.Funding`. Outside of rotation windows, this login should be DISABLED as a security control - a privileged credential with access to plaintext payment data should not be active when not actively in use.

The alert logic is intentionally inverted relative to most DD_ monitors: `value=1` does NOT mean "something bad happened to the data" - it means "a privileged login is active that should not be". DataDog alerting on `value=1` triggers the security or DBA team to verify whether a rotation is legitimately in progress or if the login was forgotten to be disabled after a previous rotation.

This procedure is closely related to the other PCI rotation monitors (`DD_CheckPCIRotationOldFundings`, `DD_CheckPCIRotationUnProcessedFundings`) which monitor the state of the rotation data itself - this monitor watches the access credential.

---

## 2. Business Logic

### 2.1 Privileged Login State Check

**What**: Checks whether the PCI_Rotation login is in the expected disabled state (secure posture) or has been left enabled (potential security gap).

**Columns/Parameters Involved**: `sys.sql_logins.name`, `sys.sql_logins.is_disabled`

**Rules**:
- No parameters - monitors exactly one named login: `'PCI_Rotation'`
- `is_disabled = 0` (SQL Server convention for "NOT disabled" = enabled) -> `value=1` (alert: login is active)
- `is_disabled = 1` (SQL Server convention for "IS disabled" = disabled) -> `value=0` (OK: login is inactive)
- The CASE expression inverts the SQL Server `is_disabled` flag to produce an intuitive alert signal
- Alert interpretation: if DataDog fires on this monitor, someone should verify whether a PCI rotation is actively running; if not, the DBA team should immediately disable the login

**Diagram**:
```
sys.sql_logins WHERE name = 'PCI_Rotation'
          |
    is_disabled = ?
          |
    +-----+-----+
    |             |
   = 1            = 0
(disabled)     (enabled)
    |               |
  value=0         value=1  <-- Alert: PCI_Rotation login is active
  (expected       (check if rotation is in progress;
  secure state)    disable if not)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | value (output) | INT | NO | - | CODE-BACKED | Security status flag: 1 = the PCI_Rotation SQL Server login is ENABLED (potential security concern - login should only be active during scheduled rotation windows); 0 = the PCI_Rotation login is DISABLED (expected secure state). DataDog alerts on value=1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PCI_Rotation login check | sys.sql_logins | System Catalog Read | Reads the SQL Server system catalog to check the enabled/disabled state of the named PCI_Rotation login. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called externally by DataDog synthetic monitors.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DD_GetPCIRotationLoginStatus (procedure)
└── sys.sql_logins (system catalog - not a user object)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| sys.sql_logins | System Catalog | Reads is_disabled flag for the 'PCI_Rotation' named login to determine its current state |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DataDog Synthetic Monitor | External | Calls this procedure on a schedule to verify the PCI_Rotation login is disabled outside of rotation windows |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Run the DataDog check

```sql
EXEC Billing.DD_GetPCIRotationLoginStatus;
-- value=0: PCI_Rotation login is disabled (normal/secure)
-- value=1: PCI_Rotation login is enabled (verify rotation is in progress)
```

### 8.2 Check current PCI_Rotation login state with details

```sql
SELECT s.name,
       s.is_disabled,
       s.create_date,
       s.modify_date,
       CASE s.is_disabled WHEN 1 THEN 'DISABLED (secure)' ELSE 'ENABLED (check rotation)' END AS StatusDescription
FROM sys.sql_logins AS s WITH (NOLOCK)
WHERE s.name = 'PCI_Rotation';
```

### 8.3 Check all PCI rotation monitor statuses together

```sql
-- Check login status
EXEC Billing.DD_GetPCIRotationLoginStatus;

-- Check for stalled rotation records (>24h unprocessed)
EXEC Billing.DD_CheckPCIRotationOldFundings;

-- Check backlog volume (>= 3000 unprocessed)
EXEC Billing.DD_CheckPCIRotationUnProcessedFundings;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DD_GetPCIRotationLoginStatus | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DD_GetPCIRotationLoginStatus.sql*
