# Billing.LoadProtocolDirections

> Data loader that returns all rows from Dictionary.ProtocolDirection, providing the billing engine with the two payment flow direction types: Direct and Redirect.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full Dictionary.ProtocolDirection table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.LoadProtocolDirections is a bulk data loader that returns all rows from Dictionary.ProtocolDirection. This small reference table defines the two modes in which payment protocols interact with customers: 1=Direct (payment is processed in-page without leaving the eToro platform) and 2=Redirect (customer is sent to the payment provider's external page to complete payment).

This distinction controls how the billing frontend presents the payment UI and how the billing engine handles the payment flow. Direct protocols (e.g., XOR credit card processing) collect card details within eToro's page. Redirect protocols (e.g., PayPal Express Checkout, MoneyBookers/Skrill) send the customer to the provider's site and handle the return callback.

---

## 2. Business Logic

### 2.1 Payment Flow Direction Classification

**What**: Classifies payment protocols by how customer interaction happens during payment.

**Columns/Parameters Involved**: (none - no parameters)

**Rules**:
- Returns all 2 rows from Dictionary.ProtocolDirection via SELECT * WITH (NOLOCK).
- 1=Direct: payment processed within eToro's page (no redirect). Credit card protocols typically use this.
- 2=Redirect: customer redirected to external provider site. PayPal, MoneyBookers, iDEAL use this.
- Dictionary.Protocol.ProtocolDirectionID references this table to classify each payment protocol.

**Diagram**:
```
ProtocolDirectionID=1 (Direct)
  Customer stays on eToro page
  Card details collected inline
  e.g., XOR, WorldPay, Checkout

ProtocolDirectionID=2 (Redirect)
  Customer sent to provider site
  Returns via callback URL
  e.g., PayPal, MoneyBookers, iDEAL
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (no input parameters) | - | - | - | - | - | This procedure takes no parameters. |
| RETURN | int | NO | - | CODE-BACKED | Returns 0 on successful execution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT *) | Dictionary.ProtocolDirection | READ | Reads both protocol direction definitions. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing Engine (BILLING_MANAGER role) | - | EXEC | Called during initialization to cache protocol direction definitions. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadProtocolDirections (procedure)
└── Dictionary.ProtocolDirection (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ProtocolDirection | Table | SELECT * - reads all 2 direction types. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing Engine (BILLING_MANAGER) | Application | EXEC - loads direction definitions at startup. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the loader
```sql
EXEC Billing.LoadProtocolDirections;
```

### 8.2 Query directions with their associated protocols
```sql
SELECT pd.ProtocolDirectionID, pd.Name AS Direction,
       p.ProtocolID, p.Name AS ProtocolName
FROM Dictionary.ProtocolDirection pd WITH (NOLOCK)
INNER JOIN Dictionary.Protocol p WITH (NOLOCK)
    ON pd.ProtocolDirectionID = p.ProtocolDirectionID
ORDER BY pd.ProtocolDirectionID, p.ProtocolID;
```

### 8.3 Count protocols per direction
```sql
SELECT pd.Name AS Direction, COUNT(p.ProtocolID) AS ProtocolCount
FROM Dictionary.ProtocolDirection pd WITH (NOLOCK)
LEFT JOIN Dictionary.Protocol p WITH (NOLOCK)
    ON pd.ProtocolDirectionID = p.ProtocolDirectionID
GROUP BY pd.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 10/10, Logic: 6/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadProtocolDirections | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadProtocolDirections.sql*
