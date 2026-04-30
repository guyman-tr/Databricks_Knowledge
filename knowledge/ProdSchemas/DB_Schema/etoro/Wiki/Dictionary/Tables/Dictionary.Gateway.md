# Dictionary.Gateway

> Lookup table defining external payment gateway providers — third-party payment processing services used for deposit and withdrawal routing in specific markets.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | GatewayID (INT, CLUSTERED PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.Gateway defines the external payment gateway providers that eToro integrates with for processing deposits and withdrawals in specific markets or payment methods. A gateway is a third-party payment processor that handles the actual money transfer between the customer's payment method and eToro's accounts.

This table exists because eToro operates globally and needs multiple payment gateway integrations to support various markets and payment methods. Different gateways specialize in different regions and payment types — Zotapay handles certain Asian and emerging market payments, EzeeBill specializes in bank transfers in specific jurisdictions, and Inatec provides payment processing for additional markets. The gateway selection determines the payment routing path and the available payment methods for customers in specific countries.

GatewayID is referenced by Dictionary.Response (which maps gateway response codes) and potentially by billing tables that track which gateway processed a specific transaction.

---

## 2. Business Logic

### 2.1 Payment Gateway Selection

**What**: Each gateway represents a distinct third-party payment processor with specific market coverage.

**Columns/Parameters Involved**: `GatewayID`, `Name`

**Rules**:
- **Zotapay (1)**: Payment processing gateway — handles deposits and withdrawals, particularly in markets requiring localized payment methods
- **EzeeBill (2)**: Bank transfer specialist gateway — processes bank-based payment transactions in specific jurisdictions
- **Inatec (3)**: Additional payment gateway integration for expanded market coverage

---

## 3. Data Overview

| GatewayID | Name | Meaning |
|---|---|---|
| 1 | Zotapay | Third-party payment gateway specializing in emerging market payment methods. Handles credit card, bank transfer, and alternative payment method processing. Used for deposit/withdrawal routing in regions where eToro's primary payment processors don't have coverage. |
| 2 | EzeeBill | Bank transfer payment gateway focusing on wire transfer and bank-to-bank payment processing. Used for jurisdictions where bank transfers are the preferred or required payment method. |
| 3 | Inatec | Additional payment processing gateway extending eToro's global payment coverage. Provides alternative routing options for transaction processing in specific markets. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GatewayID | int | NO | - | VERIFIED | Primary key identifying the payment gateway provider. 1=Zotapay, 2=EzeeBill, 3=Inatec. Referenced by Dictionary.Response for gateway-specific response code mapping. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable name of the payment gateway provider. Used in billing reports, payment routing configuration, and BackOffice transaction displays. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.Response | GatewayID | Implicit Lookup | Maps gateway-specific response codes to human-readable descriptions |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Response | Table | References GatewayID to map response codes per gateway |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_Gateway_GatewayID | CLUSTERED PK | GatewayID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_Gateway_GatewayID | PRIMARY KEY | Unique gateway identifier |

---

## 8. Sample Queries

### 8.1 List all payment gateways
```sql
SELECT  GatewayID,
        Name
FROM    [Dictionary].[Gateway] WITH (NOLOCK)
ORDER BY GatewayID;
```

### 8.2 Find response codes for a specific gateway
```sql
SELECT  r.ResponseCode,
        r.Description,
        g.Name AS GatewayName
FROM    [Dictionary].[Response] r WITH (NOLOCK)
JOIN    [Dictionary].[Gateway] g WITH (NOLOCK)
        ON r.GatewayID = g.GatewayID
WHERE   g.GatewayID = @GatewayID
ORDER BY r.ResponseCode;
```

### 8.3 Count response codes per gateway
```sql
SELECT  g.Name          AS GatewayName,
        COUNT(*)        AS ResponseCodeCount
FROM    [Dictionary].[Response] r WITH (NOLOCK)
JOIN    [Dictionary].[Gateway] g WITH (NOLOCK)
        ON r.GatewayID = g.GatewayID
GROUP BY g.Name
ORDER BY ResponseCodeCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Gateway | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Gateway.sql*
