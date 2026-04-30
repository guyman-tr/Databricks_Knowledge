# History.RiskNotification

> Log of risk notifications generated for blocked customer data events, storing the notification type and XML payload for each risk alert that occurred.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | RiskNotificationID (IDENTITY, CLUSTERED PK) |
| **Partition** | No (stored on HISTORY filegroup) |
| **Indexes** | 2 active (CLUSTERED PK on RiskNotificationID, NONCLUSTERED on BlockedDataTypeID) |

---

## 1. Business Meaning

This table stores historical risk notification events, each representing a moment when the system generated a risk alert related to a specific type of blocked customer data. The FK to `Dictionary.BlockedDataType` identifies what kind of data triggered the notification (e.g., a blocked email, credit card, username, or PayPal account), and `NotificationBody` carries the full notification content as XML.

The table is designed to audit risk alerts sent when the risk/compliance system flags or blocks certain customer data patterns. Each row represents one notification event, timestamped via `Occurred`.

The table currently has 0 rows in production and no stored procedures reference it, indicating it is inactive or deprecated. It may have been an early implementation of a risk alerting pipeline that was later replaced by a different mechanism.

---

## 2. Business Logic

No complex business logic patterns detected. See individual element descriptions in Section 4.

### 2.1 Blocked Data Type Classification

**What**: Each notification is categorized by the type of customer data that triggered the risk alert.

**Columns/Parameters Involved**: `BlockedDataTypeID`

**Rules**:
- FK to Dictionary.BlockedDataType: 1=User Name, 2=Email, 3=OriginalCID, 4=Credit Card, 5=Pay Pal Email
- Each type represents a different compliance/fraud vector that risk systems monitor
- The XML NotificationBody carries the specific details appropriate for each type

---

## 3. Data Overview

The table has no rows in production. No representative rows available.

| RiskNotificationID | BlockedDataTypeID | NotificationBody | Occurred | Meaning |
|---|---|---|---|---|
| (no rows) | - | - | - | Table is empty; risk notification system not active or replaced |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RiskNotificationID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate primary key, auto-incremented. NOT FOR REPLICATION indicates this table participates in a replication topology where identity is not re-generated on subscribers. Uniquely identifies each risk notification event. |
| 2 | BlockedDataTypeID | int | NO | - | VERIFIED | Type of blocked customer data that triggered this notification. FK to Dictionary.BlockedDataType. Values: 1=User Name, 2=Email, 3=OriginalCID (original customer ID, used in fraud scenarios), 4=Credit Card, 5=Pay Pal Email. Indexed (HRNT_BLOCKEDDATA) for filtering notifications by type. |
| 3 | NotificationBody | xml | NO | - | NAME-INFERRED | The full notification content as XML. Contains the details of the risk alert - what data was blocked, what action was taken, and contextual information. Stored in the HISTORY filegroup with TEXTIMAGE_ON. Schema of the XML is not defined in DDL (no XML schema collection). |
| 4 | Occurred | datetime | NO | getdate() | CODE-BACKED | Timestamp of when the risk notification was generated, defaulting to current server time on INSERT. Stored on HISTORY filegroup along with the rest of the table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BlockedDataTypeID | Dictionary.BlockedDataType | FK | Type of blocked customer data: 1=User Name, 2=Email, 3=OriginalCID, 4=Credit Card, 5=Pay Pal Email. |

### 5.2 Referenced By (other objects point to this)

No stored procedures, views, or functions reference this table. It is not consumed by any active code in the SSDT repo.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.RiskNotification (table)
  (leaf - no code-level dependencies)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.BlockedDataType | Table | FK constraint on BlockedDataTypeID - validates the notification type. |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HRNT | CLUSTERED PK | RiskNotificationID ASC | - | - | Active |
| HRNT_BLOCKEDDATA | NONCLUSTERED | BlockedDataTypeID ASC | - | - | Active |

Note: Table and TEXTIMAGE (XML) data stored on HISTORY filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HRNT | PRIMARY KEY | Uniqueness on RiskNotificationID. CLUSTERED on HISTORY filegroup. FILLFACTOR=90. |
| HRNT_OCCURRED | DEFAULT | Occurred defaults to getdate() on INSERT. |
| FK_DBDT_HRNT | FOREIGN KEY | BlockedDataTypeID references Dictionary.BlockedDataType. |

---

## 8. Sample Queries

### 8.1 Check if any notifications exist
```sql
SELECT TOP 10
    RiskNotificationID,
    BlockedDataTypeID,
    Occurred
FROM [History].[RiskNotification] WITH (NOLOCK)
ORDER BY Occurred DESC
```

### 8.2 Query notifications by blocked data type with label
```sql
SELECT
    rn.RiskNotificationID,
    dbd.Name AS BlockedDataType,
    rn.NotificationBody,
    rn.Occurred
FROM [History].[RiskNotification] rn WITH (NOLOCK)
JOIN [Dictionary].[BlockedDataType] dbd WITH (NOLOCK)
    ON dbd.BlockedDataTypeID = rn.BlockedDataTypeID
WHERE rn.BlockedDataTypeID = @BlockedDataTypeID
ORDER BY rn.Occurred DESC
```

### 8.3 Count notifications by type and date
```sql
SELECT
    dbd.Name AS BlockedDataType,
    CAST(rn.Occurred AS DATE) AS EventDate,
    COUNT(*) AS NotificationCount
FROM [History].[RiskNotification] rn WITH (NOLOCK)
JOIN [Dictionary].[BlockedDataType] dbd WITH (NOLOCK)
    ON dbd.BlockedDataTypeID = rn.BlockedDataTypeID
GROUP BY dbd.Name, CAST(rn.Occurred AS DATE)
ORDER BY EventDate DESC, NotificationCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.5/10 (Elements: 7.5/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.RiskNotification | Type: Table | Source: etoro/etoro/History/Tables/History.RiskNotification.sql*
