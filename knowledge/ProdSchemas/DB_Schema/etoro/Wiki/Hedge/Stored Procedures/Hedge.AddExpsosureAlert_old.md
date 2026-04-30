# Hedge.AddExpsosureAlert_old

> Linked-server variant of AddExpsosureAlert that writes to the remote [AO-REAL-DB] server's etoro.Hedge.ExposureAlerts table via a 4-part name.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes to [AO-REAL-DB].etoro.Hedge.ExposureAlerts via 4-part linked-server name |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.AddExpsosureAlert_old` is the linked-server (remote) variant of `Hedge.AddExpsosureAlert`. It uses a 4-part name `[AO-REAL-DB].etoro.Hedge.ExposureAlerts` to write alerts to a remote SQL Server instance identified as `[AO-REAL-DB]`. The `_old` suffix indicates this was the original (oldest) implementation, predating the local and cross-DB variants.

The "AO-REAL-DB" linked server likely refers to an "Always-On" or "Active-Operational" real database - the primary production database that the hedge monitoring would write to from a secondary/reporting server. This pattern was common before SQL Server AlwaysOn Availability Groups, when teams used linked servers to write from secondary instances back to the primary.

Per the `Hedge.ExposureAlerts` table documentation, this table is a legacy archive from 2014. This procedure is inactive.

See `Hedge.AddExpsosureAlert` for full business context on the ExposureAlerts table and the three-variant architecture.

---

## 2. Business Logic

### 2.1 Remote Linked-Server Write

**What**: Functionally identical to AddExpsosureAlert but targets a remote linked server.

**Rules**:
- INSERT target: `[AO-REAL-DB].etoro.Hedge.ExposureAlerts` (4-part: server.database.schema.table)
- Requires `[AO-REAL-DB]` to be a configured linked server on the current SQL Server instance
- `SCOPE_IDENTITY()` returns the identity from the remote server's inserted row
- No BEGIN/END block (unlike the _Child variant) - single-statement procedure body

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AlertID | int OUTPUT | YES | - | CODE-BACKED | Returns the IDENTITY value of the newly inserted row on the remote server. |
| 2 | @NotificationTime | datetime | NO | - | CODE-BACKED | Alert trigger timestamp. See Hedge.AddExpsosureAlert for details. |
| 3 | @AlertTypeID | INT | NO | - | CODE-BACKED | Alert type: 1=Failed TP/SL hedge close, 2/3=Fractional lot discrepancy. |
| 4 | @HedgeServerID | int | NO | - | CODE-BACKED | Hedge server that raised the alert. FK to Trade.HedgeServer. |
| 5 | @InstrumentID | int | NO | - | CODE-BACKED | Financial instrument involved. FK to Trade.Instrument. |
| 6 | @UnitAmount | decimal(13,2) | NO | - | CODE-BACKED | Unit quantity involved in the alert. |
| 7 | @IsBuy | bit | NO | - | CODE-BACKED | Direction: 1=Buy/Long, 0=Sell/Short. |
| 8 | @Description | varchar(300) | NO | - | CODE-BACKED | Free-text alert description. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (writes to) | [AO-REAL-DB].etoro.Hedge.ExposureAlerts | INSERT via 4-part linked-server name | Remote production database write |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Legacy - inactive since 2014.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.AddExpsosureAlert_old (procedure)
└── [AO-REAL-DB].etoro.Hedge.ExposureAlerts (table - remote linked server)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [AO-REAL-DB].etoro.Hedge.ExposureAlerts | Table | INSERT target via 4-part linked-server reference |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Legacy hedge engine on secondary server) | External | Called to write alerts to the AO-REAL-DB production server |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Requires `[AO-REAL-DB]` linked server configured on the current SQL Server instance
- No BEGIN/END block - single INSERT statement
- Distributed transaction considerations apply for linked server inserts (MSDTC may be required)

---

## 8. Sample Queries

### 8.1 Execute: Insert alert to linked-server ExposureAlerts

```sql
DECLARE @NewAlertID INT
EXEC Hedge.AddExpsosureAlert_old
    @AlertID          = @NewAlertID OUTPUT,
    @NotificationTime = GETUTCDATE(),
    @AlertTypeID      = 1,
    @HedgeServerID    = 1,
    @InstrumentID     = 5,
    @UnitAmount       = 1.00,
    @IsBuy            = 1,
    @Description      = 'Failed TP hedge close - remote write'
SELECT @NewAlertID AS NewAlertID
```

### 8.2 Query: Check if linked server is available

```sql
SELECT * FROM sys.servers WHERE name = 'AO-REAL-DB'
```

### 8.3 Query: Alerts across all three targets (where accessible)

```sql
SELECT 'Local' AS Target, AlertID, NotificationTime FROM Hedge.ExposureAlerts WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.2/10 (Elements: 9.0/10, Logic: 7.0/10, Relationships: 7.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.AddExpsosureAlert_old | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.AddExpsosureAlert_old.sql*
