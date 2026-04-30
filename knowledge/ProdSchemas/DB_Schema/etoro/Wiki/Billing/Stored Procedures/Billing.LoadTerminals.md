# Billing.LoadTerminals

> Data loader that returns all rows from Billing.Terminal, providing the billing engine with the complete registry of payment processing terminals linking protocols, payment types, and currencies.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full Billing.Terminal table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.LoadTerminals is a bulk data loader that returns all rows from Billing.Terminal. A terminal in the billing system is a specific processing configuration that combines a payment protocol, payment type (Deposit/Cashout/Refund), and currency into a named endpoint. For example, TerminalID=1 is "Xor Deposit" (ProtocolID=1, PaymentTypeID=1, CurrencyID=1=USD), and TerminalID=2 is "PayPal Express Checkout" (ProtocolID=2, PaymentTypeID=1).

The billing engine loads all terminals at startup to build its routing table: when a payment request arrives with a specific protocol + type + currency combination, the engine resolves the correct terminal and uses it for processing. The IsDefault flag identifies the primary terminal for a given protocol+type combination. ProcessedAmount and LastTransactionDate provide operational metrics on terminal activity.

---

## 2. Business Logic

### 2.1 Terminal Routing Lookup

**What**: Each terminal defines a named route for a specific protocol + payment type + currency combination.

**Columns/Parameters Involved**: (none - no parameters)

**Rules**:
- Returns all columns from Billing.Terminal via SELECT * WITH (NOLOCK).
- Key fields: TerminalID (PK), ProtocolID (payment implementation), PaymentTypeID (1=Deposit/2=Cashout/3=Refund), CurrencyID, TerminalName, IsDefault.
- IsDefault=1: primary terminal for this protocol and type - used when no currency-specific terminal matches.
- ProcessedAmount: cumulative transaction volume through this terminal (used for load tracking).
- LastTransactionDate: last time a transaction was routed through this terminal (initial sentinel value: 2000-01-01).
- Some terminals have CurrencyID=0 indicating multi-currency (not tied to a specific currency).

**Diagram**:
```
Payment Request: PayPal Deposit in USD
    |
    v
Billing.Terminal
  TerminalID=2  "PayPal Express Checkout"
  ProtocolID=2, PaymentTypeID=1, CurrencyID=1, IsDefault=1
    |
    v
Payment processed via PayPal Express Checkout protocol
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
| (SELECT *) | Billing.Terminal | READ | Reads all payment terminal configurations. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing Engine (BILLING_MANAGER role) | - | EXEC | Called during initialization to build the payment terminal routing table. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadTerminals (procedure)
└── Billing.Terminal (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Terminal | Table | SELECT * - reads all payment terminal configurations. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing Engine (BILLING_MANAGER) | Application | EXEC - loads terminal routing table at startup. |

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
EXEC Billing.LoadTerminals;
```

### 8.2 View default terminals per protocol and payment type
```sql
SELECT t.TerminalID, t.TerminalName, p.Name AS Protocol,
       pt.Name AS PaymentType, t.CurrencyID
FROM Billing.Terminal t WITH (NOLOCK)
INNER JOIN Dictionary.Protocol p WITH (NOLOCK)
    ON t.ProtocolID = p.ProtocolID
INNER JOIN Dictionary.PaymentType pt WITH (NOLOCK)
    ON t.PaymentTypeID = pt.PaymentTypeID
WHERE t.IsDefault = 1
ORDER BY t.ProtocolID;
```

### 8.3 Find terminals by protocol
```sql
SELECT TerminalID, TerminalName, PaymentTypeID, CurrencyID, IsDefault
FROM Billing.Terminal WITH (NOLOCK)
WHERE ProtocolID = 2
ORDER BY TerminalID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 10/10, Logic: 6/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadTerminals | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadTerminals.sql*
