# Billing.PaymentService

> Configuration table for external payment reporting services (e.g., PayPal, Wire, googess); stores the report portal URL and credentials used to retrieve transaction status reports from each provider.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | PaymentServiceID (PRIMARY KEY NONCLUSTERED, IDENTITY) |
| **Row Count** | 5 rows |
| **Partition** | N/A - filegroup MAIN |
| **Indexes** | 1 - PK NONCLUSTERED on PaymentServiceID; 1 - NC on PaymentServiceStatusID |

---

## 1. Business Meaning

`Billing.PaymentService` stores the configuration for external payment reporting integrations - the portals that eToro uses to pull transaction status reports from payment providers. Each row defines one payment service with its report URL and API credentials (`ReportUserName`, `ReportPassword`).

This is distinct from the payment processing configuration (stored in `Billing.Depot`/`Billing.ProtocolMIDSettings`): `PaymentService` is specifically for the **reporting/reconciliation** side - the back-office service used to look up transaction statuses, download settlement files, or check payment provider dashboards.

Live data shows 5 services: googess (a payment aggregator), PayPal, a Test service, a Wire (bank transfer) service, and one more - all with `PaymentServiceStatusIDs` indicating active or inactive status.

The table is loaded into the application cache at startup via `Billing.LoadPaymentServices` and edited via `Billing.PaymentServiceEdit`.

---

## 2. Business Logic

### 2.1 Payment Reporting Integration

**What**: Defines the connection parameters for accessing each payment provider's reporting portal to retrieve transaction status updates.

**Columns Involved**: `ReportUrl`, `ReportUserName`, `ReportPassword`, `PaymentServiceStatusID`

**Rules**:
- `PaymentServiceStatusID` controls whether the service is active: inactive services are not polled for reports
- `ReportUrl` is the endpoint the back-office reporting job connects to
- `ReportUserName` / `ReportPassword`: API or web portal credentials for authentication (not PCI-sensitive card data; these are admin/reporting credentials)
- Referenced by `Billing.Volume` table (tracks processed volumes per payment service)
- `Billing.ProtocolEdit` updates payment service links when a protocol's configuration changes

---

## 3. Data Overview

| PaymentServiceID | Name | StatusID |
|-----------------|------|----------|
| 1 | googess | 1 |
| 2 | PayPal | 2 |
| 3 | Test | 3 |
| 4 | Wire | 1-3 |
| 5 | (5th service) | varies |

*Note: Exact name/status values from live data sample. Status IDs 1-3 from Dictionary.PaymentServiceStatus (environment-specific labels: Test/test2/test3 observed in sample, likely Active/Inactive/Testing in production meaning).*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentServiceID | int | NO | IDENTITY(1,1) | CODE-BACKED | Internal primary key. Auto-generated. Referenced by `Billing.Volume` to track processed volume per payment service. NOT FOR REPLICATION. |
| 2 | PaymentServiceStatusID | int | NO | - | CODE-BACKED | Status of this payment service integration. FK to `Dictionary.PaymentServiceStatus`. Controls whether this service is active and polled. Indexed (BPMS_PAYMENTSERVICESTATUS) for filtering by status. |
| 3 | Name | varchar(50) | NO | - | CODE-BACKED | Display name of the payment service (e.g., 'PayPal', 'googess', 'Wire'). Used in admin dashboards and reporting UIs to identify the service. |
| 4 | ReportUrl | varchar(250) | NO | - | CODE-BACKED | URL of the payment provider's reporting portal or API endpoint. The back-office reporting job connects here to retrieve transaction status and settlement data. |
| 5 | ReportUserName | varchar(50) | NO | - | CODE-BACKED | Username/API key for authenticating to the payment provider's reporting portal. Administrative credential (not customer payment data). |
| 6 | ReportPassword | varchar(32) | NO | - | CODE-BACKED | Password for authenticating to the payment provider's reporting portal. Limited to 32 characters. Administrative credential. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentServiceStatusID | Dictionary.PaymentServiceStatus | FK (FK_DPSS_BPMS) | Status of this payment service |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Volume | PaymentServiceID | FK (implicit) | Tracks processed volume per service |
| Billing.LoadPaymentServices | - | Read | Loads full table into application cache at startup |
| Billing.PaymentServiceEdit | PaymentServiceID | Write | Updates service configuration |
| Billing.ProtocolEdit | PaymentServiceID | Related | Protocol configuration may reference payment service |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PaymentService
  -> Dictionary.PaymentServiceStatus
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PaymentServiceStatus | Table | FK on PaymentServiceStatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Volume | Table | FK on PaymentServiceID - volume tracking per service |
| Billing.LoadPaymentServices | Stored Procedure | Full table scan for application cache loading |
| Billing.PaymentServiceEdit | Stored Procedure | Updates service configuration |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Notes |
|-----------|------|-------------|-----------------|--------|-------|
| PK_BPMS | NONCLUSTERED PK | PaymentServiceID ASC | - | - | Active; FILLFACTOR=90; heap table |
| BPMS_PAYMENTSERVICESTATUS | NC | PaymentServiceStatusID ASC | - | - | Active; FILLFACTOR=90 |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BPMS | PRIMARY KEY NONCLUSTERED (PaymentServiceID) | One row per service |
| FK_DPSS_BPMS | FOREIGN KEY PaymentServiceStatusID -> Dictionary.PaymentServiceStatus | Status must be valid |

---

## 8. Sample Queries

### 8.1 View all payment services with status

```sql
SELECT
    ps.PaymentServiceID,
    ps.Name,
    ps.ReportUrl,
    pss.Name AS StatusName
FROM Billing.PaymentService ps WITH (NOLOCK)
JOIN Dictionary.PaymentServiceStatus pss WITH (NOLOCK) ON pss.PaymentServiceStatusID = ps.PaymentServiceStatusID
ORDER BY ps.PaymentServiceID
```

### 8.2 View volume processed per service

```sql
SELECT
    ps.Name AS ServiceName,
    v.Year,
    v.Month,
    v.Amount AS Volume
FROM Billing.Volume v WITH (NOLOCK)
JOIN Billing.PaymentService ps WITH (NOLOCK) ON ps.PaymentServiceID = v.PaymentServiceID
ORDER BY v.Year DESC, v.Month DESC, ps.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PaymentService | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.PaymentService.sql*
