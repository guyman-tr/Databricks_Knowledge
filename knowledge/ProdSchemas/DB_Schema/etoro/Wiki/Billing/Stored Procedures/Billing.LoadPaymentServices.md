# Billing.LoadPaymentServices

> Returns all rows from Billing.PaymentService - a startup cache loader for the payment reporting service configuration table (5 rows defining provider report portal URLs and credentials).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT * FROM Billing.PaymentService |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.LoadPaymentServices` is a startup cache loader for the payment reporting service configuration. The billing service loads this at startup to populate the configuration for external payment reporting integrations - the portal URLs and API credentials used to pull transaction status reports from payment providers (PayPal, wire transfer services, the googess payment aggregator, etc.).

`Billing.PaymentService` holds 5 rows representing eToro's configured payment reporting integrations. Unlike the payment processing configuration (Billing.Depot/ProtocolMIDSettings), this table is specifically for the reconciliation/reporting side: back-office portals used to check transaction statuses and download settlement files.

---

## 2. Business Logic

### 2.1 Full Payment Service Configuration Load

**What**: SELECT * with no filter - returns all rows and all columns from Billing.PaymentService.

**Rules**:
- No parameters; no filtering; WITH (NOLOCK)
- 5 rows covering configured payment reporting services
- Returns report portal URLs and credentials (ReportUserName, ReportPassword) - sensitive fields
- RETURN 0 signals success

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

### Output Columns

All columns from `Billing.PaymentService` (5 rows): PaymentServiceID (IDENTITY PK), PaymentServiceName, ReportURL, ReportUserName, ReportPassword (credentials - handle securely), PaymentServiceStatusID. Live data: googess, PayPal, Test, Wire services.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Billing.PaymentService | READ | Payment reporting service configuration (5 rows; includes portal credentials) |

### 5.2 Referenced By (other objects point to this)

Called from the billing application at startup for payment service configuration cache population.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadPaymentServices (procedure)
└── Billing.PaymentService (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.PaymentService | Table | Payment reporting service configuration; 5 rows including report portal credentials |

### 6.2 Objects That Depend On This

No dependents found within the Billing schema stored procedures.

---

## 7. Technical Details

**Implementation notes**:
- `SET NOCOUNT ON` + `RETURN 0`; `WITH (NOLOCK)`
- Returns payment provider credentials (ReportUserName, ReportPassword) - ensure callers handle this data securely and do not log full result sets
- Part of the Load* family of startup cache loaders

---

## 8. Sample Queries

### 8.1 View payment services (without credentials)
```sql
SELECT PaymentServiceID, PaymentServiceName, PaymentServiceStatusID, ReportURL
FROM Billing.PaymentService WITH (NOLOCK)
ORDER BY PaymentServiceID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 8/10, Logic: 7/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadPaymentServices | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadPaymentServices.sql*
