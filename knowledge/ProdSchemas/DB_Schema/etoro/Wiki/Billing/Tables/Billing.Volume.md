# Billing.Volume

> Payment volume limit configuration per payment service, payment type, and currency - defines Enforcement (soft limit) and Restrictions (hard limit) thresholds for deposit/payment volume control.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (PaymentServiceID, PaymentTypeID, CurrencyID) (INT composite, CLUSTERED PK) |
| **Partition** | No ([MAIN] filegroup) |
| **Indexes** | 4 (PK + 3 NCI on individual key columns) |
| **Temporal** | No |

---

## 1. Business Meaning

Billing.Volume defines the volume threshold configuration for each payment service/type/currency combination. Two thresholds are configured per row: Enforcement (soft limit - alert/warning level) and Restrictions (hard limit - block level). These controls allow the business to cap how much volume flows through specific payment channels per currency, preventing over-exposure to any single payment provider.

**32 rows** spread across multiple payment service/type/currency combinations. Sample values:
- PaymentServiceID=1, PaymentTypeID=1, CurrencyID=1 (USD): Enforcement=5,000, Restrictions=100,000
- PaymentServiceID=1, PaymentTypeID=1, CurrencyID=2 (EUR): Enforcement=5,000, Restrictions=1,000,000

The MAIN filegroup placement indicates transactional/operational data rather than configuration.

---

## 2. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentServiceID | INT | NO | - | CODE-BACKED | FK to Billing.PaymentService(PaymentServiceID). Identifies the payment service (processor/provider). Part of the composite PK. |
| 2 | PaymentTypeID | INT | NO | - | CODE-BACKED | FK to Dictionary.PaymentType(PaymentTypeID). Identifies the payment type (deposit, withdrawal, etc.). Part of the composite PK. |
| 3 | CurrencyID | INT | NO | - | CODE-BACKED | FK to Dictionary.Currency(CurrencyID). Identifies the currency for this volume limit. Part of the composite PK. 1=USD, 2=EUR, etc. |
| 4 | Enforcement | INT | NO | - | CODE-BACKED | Soft volume limit (enforcement/alert threshold). When processed volume exceeds this value, the system generates a warning or triggers monitoring. |
| 5 | Restrictions | INT | NO | - | CODE-BACKED | Hard volume limit (restriction/block threshold). When processed volume exceeds this value, further transactions are blocked. Restrictions > Enforcement (hard limit > soft limit). |

---

## 3. Relationships

### 3.1 References To

| Element | Related Object | Relationship Type |
|---------|---------------|-------------------|
| PaymentServiceID | Billing.PaymentService | FK (FK_BPMS_BVOL) |
| PaymentTypeID | Dictionary.PaymentType | FK (FK_DPMT_BVOL) |
| CurrencyID | Dictionary.Currency | FK (FK_DCUR_BVOL) |

---

## 4. Technical Details

| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| PK_BVOL | CLUSTERED PK | PaymentServiceID, PaymentTypeID, CurrencyID | Active |
| BVOL_CURRENCY | NCI | CurrencyID | Active |
| BVOL_PAYMENTSERVICE | NCI | PaymentServiceID | Active |
| BVOL_PAYMENTTYPE | NCI | PaymentTypeID | Active |

---

*Generated: 2026-03-17 | Quality: 7.5/10 | Phases: 7/11 | CODE-BACKED: 5 | Sources: 0*
*Object: Billing.Volume | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.Volume.sql*
