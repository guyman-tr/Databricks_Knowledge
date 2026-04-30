# Billing.LoadProtocols

> Data loader that returns all rows from Dictionary.Protocol, providing the billing engine with the complete registry of payment processing protocols and their gateway configurations.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full Dictionary.Protocol table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.LoadProtocols is a bulk data loader that returns all rows from Dictionary.Protocol. Dictionary.Protocol is the central registry of payment processing protocols available in the eToro billing system. Each row represents one payment integration: a specific payment method (credit card, PayPal, wire transfer, Neteller, etc.) implemented via a specific software class (ClassKey) and direction (Direct/Redirect).

This procedure is part of the billing engine's initialization sequence. Loading all protocols at startup allows the engine to instantly resolve which class to instantiate and how to route each payment without database queries during transaction processing. The IsDynamicRouting flag identifies which credit card protocols participate in the monthly volume-based routing algorithm (used by Billing.MonthlyQuota and related procedures).

Key protocols in production include: 1=Xor1 (legacy CC), 2=PayPal Express Checkout, 6=Wire Transfer, 7=Neteller, 18=WireCard, 23=WorldPay, 43=Checkout.com, 46=IxopayNuvei.

---

## 2. Business Logic

### 2.1 Protocol Registry and Dynamic Routing Flag

**What**: Dictionary.Protocol defines every payment integration and whether it participates in dynamic CC routing.

**Columns/Parameters Involved**: (none - no parameters)

**Rules**:
- Returns all columns from Dictionary.Protocol via SELECT * WITH (NOLOCK).
- Key fields per row: ProtocolID, PaymentServiceID (parent service), ProtocolDirectionID (Direct/Redirect), Name, ClassKey (DLL class name), IsDynamicRouting.
- IsDynamicRouting=1: protocol participates in monthly volume-based routing (Billing.MonthlyQuota tracks volumes for these). Currently: WorldPay(23), Checkout(43), IxopayNuvei(46).
- IsDynamicRouting=0: fixed routing - all traffic for this depot goes to this protocol regardless of volume.
- ClassKey maps to the billing engine's plugin DLL, e.g., "PayPalPaymentDll", "XorPaymentDll", "WireTransferPaymentDll".

**Diagram**:
```
Dictionary.Protocol
  ProtocolID=2  Name="PayPal Express Checkout"  ClassKey="PayPalPaymentDll"
                ProtocolDirectionID=2 (Redirect) IsDynamicRouting=0
  ProtocolID=23 Name="WorldPay"                 ClassKey="WorldPayDll"
                ProtocolDirectionID=1 (Direct)   IsDynamicRouting=1 <- volume-tracked
  ProtocolID=43 Name="Checkout"                 ClassKey="CheckoutDll"
                ProtocolDirectionID=1 (Direct)   IsDynamicRouting=1 <- volume-tracked
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
| (SELECT *) | Dictionary.Protocol | READ | Reads all payment protocol definitions including IsDynamicRouting flag. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing Engine (BILLING_MANAGER role) | - | EXEC | Called during initialization to cache payment protocol registry. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadProtocols (procedure)
└── Dictionary.Protocol (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Protocol | Table | SELECT * - reads all payment processing protocol definitions. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing Engine (BILLING_MANAGER) | Application | EXEC - loads protocol registry at startup for payment routing. |

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
EXEC Billing.LoadProtocols;
```

### 8.2 View all dynamic routing protocols (participate in monthly volume balancing)
```sql
SELECT ProtocolID, Name, ClassKey
FROM Dictionary.Protocol WITH (NOLOCK)
WHERE IsDynamicRouting = 1
ORDER BY ProtocolID;
```

### 8.3 Protocols with their service and direction
```sql
SELECT p.ProtocolID, p.Name AS ProtocolName,
       ps.Name AS ServiceName, pd.Name AS Direction
FROM Dictionary.Protocol p WITH (NOLOCK)
INNER JOIN Billing.PaymentService ps WITH (NOLOCK)
    ON p.PaymentServiceID = ps.PaymentServiceID
INNER JOIN Dictionary.ProtocolDirection pd WITH (NOLOCK)
    ON p.ProtocolDirectionID = pd.ProtocolDirectionID
ORDER BY p.ProtocolID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadProtocols | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadProtocols.sql*
