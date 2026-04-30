# dbo.DBA_CheckWrongDemoCIDinSTS

> DBA monitoring procedure that detects users whose Demo CID in CustomerIdentification doesn't match the actual Demo database, sending email alerts.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @recipients + @HoursOld + @NotLatestMinutes (input params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.DBA_CheckWrongDemoCIDinSTS is a DBA operational monitoring procedure that verifies Demo CID consistency. It checks recently registered users (configurable time window) by comparing the DemoCID stored in Customer.CustomerIdentification against the actual CID in the Demo database (via linked server). If mismatches are found, sends an alert email via sp_send_dbmail.

---

## 2. Business Logic

### 2.1 Demo CID Validation

**What**: Cross-database CID consistency check with email alerting.

**Columns/Parameters Involved**: `@HoursOld`, `@NotLatestMinutes`, `@recipients`

**Rules**:
- Selects users registered within the time window (default: last 10 hours, excluding last 15 minutes)
- Queries Demo linked server for actual CIDs by username
- Compares DemoCID from CustomerIdentification vs CID from Demo.Customer.CustomerStatic
- Sends email via sp_send_dbmail if mismatches found
- Returns silently if no issues

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @recipients | varchar(max) (IN) | YES | 'dba@etoro.com' | CODE-BACKED | Email recipients for alerts. |
| 2 | @HoursOld | int (IN) | YES | -10 | CODE-BACKED | How far back to check (hours). Negative = past. |
| 3 | @NotLatestMinutes | int (IN) | YES | -15 | CODE-BACKED | Exclude most recent minutes (allows replication lag). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.Real_Customer | SELECT FROM | Recently registered users |
| - | Customer.CustomerIdentification | SELECT FROM | DemoCID lookup |
| - | [Demo] linked server | EXECUTE AT | Demo CID verification |

### 5.2 Referenced By (other objects point to this)

DBA scheduled job.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.DBA_CheckWrongDemoCIDinSTS (procedure)
  +-- dbo.Real_Customer (synonym)
  +-- Customer.CustomerIdentification (table) [done]
  +-- [Demo] linked server (external)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Synonym | SELECT FROM |
| Customer.CustomerIdentification | Table | SELECT FROM |
| [Demo] linked server | External | EXECUTE AT for CID verification |

### 6.2 Objects That Depend On This

DBA SQL Agent job.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Run with defaults
```sql
EXEC dbo.DBA_CheckWrongDemoCIDinSTS
```

### 8.2 Check last 24 hours
```sql
EXEC dbo.DBA_CheckWrongDemoCIDinSTS @HoursOld = -24, @NotLatestMinutes = -30
```

### 8.3 Send to specific recipient
```sql
EXEC dbo.DBA_CheckWrongDemoCIDinSTS @recipients = 'myemail@etoro.com'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: dbo.DBA_CheckWrongDemoCIDinSTS | Type: Stored Procedure | Source: UserApiDB/UserApiDB/dbo/Stored Procedures/dbo.DBA_CheckWrongDemoCIDinSTS.sql*
