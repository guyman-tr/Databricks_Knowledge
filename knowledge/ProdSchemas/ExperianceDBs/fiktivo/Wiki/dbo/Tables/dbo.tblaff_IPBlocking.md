# dbo.tblaff_IPBlocking

> IP address blocklist for preventing fraudulent or abusive traffic from being counted in affiliate tracking metrics.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (1 clustered PK, 1 nonclustered on IPAddress) |

---

## 1. Business Meaning

This table stores IP addresses that should be blocked from affiliate tracking. When a click or impression originates from a blocked IP, it is excluded from affiliate metrics to prevent fraud (click fraud, self-clicking, competitor sabotage). Managed by admin users with Preferences_IPBlocking permission. Currently empty (0 rows) in this environment.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

Table is currently empty (0 rows).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Auto-incrementing identifier. |
| 2 | IPAddress | nvarchar(85) | NO | - | CODE-BACKED | IP address to block. Supports IPv4 and IPv6 formats (nvarchar(85) accommodates full IPv6). Indexed for fast lookup during traffic validation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_tblaff_IPBlocking | CLUSTERED PK | ID | - | - | Active |
| IPAddress | NC | IPAddress | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check if an IP is blocked
```sql
SELECT ID, IPAddress FROM dbo.tblaff_IPBlocking WITH (NOLOCK) WHERE IPAddress = '192.168.1.1'
```

### 8.2 List all blocked IPs
```sql
SELECT IPAddress FROM dbo.tblaff_IPBlocking WITH (NOLOCK) ORDER BY IPAddress
```

### 8.3 Count blocked IPs
```sql
SELECT COUNT(*) AS BlockedCount FROM dbo.tblaff_IPBlocking WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_IPBlocking | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_IPBlocking.sql*
