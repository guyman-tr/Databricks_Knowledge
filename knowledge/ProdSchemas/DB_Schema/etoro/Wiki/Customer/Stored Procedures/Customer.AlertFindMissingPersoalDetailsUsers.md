# Customer.AlertFindMissingPersoalDetailsUsers

> Data quality alert check: returns 1 if any customer registered after 2019-03-05 has a City set but is missing FirstName or LastName, 0 if none found.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN value: 1 = anomaly found, 0 = clean |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.AlertFindMissingPersoalDetailsUsers` is a data quality health check procedure used by eToro's observability stack. It detects an anomalous registration state: customers who have a City populated (indicating partial profile completion) but are missing either FirstName or LastName - which should not occur under normal registration flows.

The procedure exists as a monitoring sentinel. When the registration pipeline or a KYC data enrichment process fails to populate name fields while city data was written successfully, this SP fires the alert. The Datadog and Coralogix monitoring accounts are granted EXECUTE permission, indicating they poll this SP on a schedule and raise an alert or log an event when the return value is 1.

The cutoff date `Registered > '20190305'` scopes the check to registrations from March 2019 onward, excluding legacy accounts where incomplete profiles were historically common. The commented-out `BirthDate='19000102'` condition indicates a placeholder birth date check was evaluated but removed (either because 1900-01-02 is not the current placeholder value, or because the name-missing check alone is sufficient signal).

---

## 2. Business Logic

### 2.1 Alert Condition

**What**: Detects customers with partial profile completion - city present but name missing.

**Columns/Parameters Involved**: `Customer.CustomerStatic.FirstName`, `Customer.CustomerStatic.LastName`, `Customer.CustomerStatic.City`, `Customer.CustomerStatic.Registered`

**Rules**:
- Condition: `(FirstName IS NULL OR LastName IS NULL) AND City IS NOT NULL AND Registered > '20190305'`
- Returns 1 via `IIF(@@RowCount > 0, 1, 0)` if at least one such customer exists
- Uses `SELECT TOP 1` - does not count or enumerate violating rows, only confirms existence
- Ordered by `Registered DESC` so the most recent violation is the one found first
- City IS NOT NULL distinguishes partially-complete profiles (some data was written) from totally empty registrations

**Diagram**:
```
Customer.CustomerStatic row:
  City = "London"         -> City IS NOT NULL  (YES)
  FirstName = NULL        -> FirstName IS NULL  (YES)
  Registered = 2024-01-15 -> > 20190305         (YES)
  --> Returns 1 (alert: incomplete registration detected)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (none) | - | - | - | - | This procedure takes no input parameters. |
| 2 | RETURN value | INT | NO | - | CODE-BACKED | 1 = at least one customer matching the anomaly condition exists (alert state). 0 = no such customers found (clean state). Derived via `IIF(@@RowCount > 0, 1, 0)` after the SELECT TOP 1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (scan) | Customer.CustomerStatic | Read | Scans for customers with City set but missing name fields, registered after 2019-03-05 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Datadog monitoring | EXECUTE grant | External caller | Polling health check - Datadog runs this SP to detect data quality anomalies |
| Coralogix monitoring | EXECUTE grant | External caller | Polling health check - Coralogix runs this SP as part of observability pipeline |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.AlertFindMissingPersoalDetailsUsers (procedure)
└── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Scanned for rows where (FirstName IS NULL OR LastName IS NULL) AND City IS NOT NULL AND Registered > '20190305' |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Datadog integration | External | Calls on schedule; RETURN 1 triggers an alert in Datadog dashboard |
| Coralogix integration | External | Calls on schedule; RETURN 1 triggers a log alert in Coralogix |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

Note: `Customer.CustomerStatic` has 16 indexes. The most likely to be used is the `Registered` index combined with a filter on nullability columns, though SQL Server may do a partial index scan depending on selectivity.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute the health check

```sql
DECLARE @AlertResult INT
EXEC @AlertResult = [Customer].[AlertFindMissingPersoalDetailsUsers]
SELECT @AlertResult AS AlertFired  -- 1=anomaly exists, 0=clean
```

### 8.2 Manually inspect the anomalous records

```sql
SELECT TOP 20
    CID,
    FirstName,
    LastName,
    City,
    Registered
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE (FirstName IS NULL OR LastName IS NULL)
AND City IS NOT NULL
AND Registered > '20190305'
ORDER BY Registered DESC
```

### 8.3 Count of anomalous records over time

```sql
SELECT
    CAST(Registered AS DATE) AS RegistrationDate,
    COUNT(*) AS MissingNameCount
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE (FirstName IS NULL OR LastName IS NULL)
AND City IS NOT NULL
AND Registered > '20190305'
GROUP BY CAST(Registered AS DATE)
ORDER BY RegistrationDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3 (1, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.AlertFindMissingPersoalDetailsUsers | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.AlertFindMissingPersoalDetailsUsers.sql*
