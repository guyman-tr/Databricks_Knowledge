# Dictionary.Protocol

> Configuration table defining 45 payment protocols — each mapping a payment service provider (PSP) to a DLL implementation class, communication direction, and dynamic routing flag — forming the core of eToro's payment processing infrastructure.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ProtocolID (INT, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 3 (PK nonclustered + 2 NCI on PaymentServiceID, ProtocolDirectionID) |

---

## 1. Business Meaning

Dictionary.Protocol defines every payment integration endpoint available in the eToro billing system. Each protocol represents a specific PSP connection with its implementation DLL class, communication direction (Direct/Redirect), and whether it supports dynamic routing. This table is the central registry that the billing engine uses to route payment transactions to the correct payment processor.

The table is consumed by Billing.LoadProtocols (cache loader), Billing.ProtocolEdit (CRUD), Billing.GetCCProcessingBundle* (credit card routing), Billing.GetCountryProtocols (country-specific availability), and Billing.GetCCProtocolQuotas (quota management). It serves as an FK parent for Dictionary.ProtocolParameter, Dictionary.Response, Billing.ProtocolCountry, Billing.ProtocolByBin, Billing.Terminal, Billing.Depot, and Billing.QuotaManagement.

---

## 2. Business Logic

### 2.1 Protocol-to-PSP Mapping

**What**: Each protocol binds a payment service to a specific DLL implementation that handles the transaction flow.

**Columns/Parameters Involved**: `ProtocolID`, `PaymentServiceID`, `ClassKey`, `Name`

**Rules**:
- One PaymentService can have multiple protocols (e.g., PaymentServiceID=1 has Xor 1, Xor 2, GCSLocalBankWire, Barclay, WorldPay, Adyen, Checkout, etc.).
- The ClassKey identifies the .NET DLL class that processes transactions (e.g., "XorPaymentDll", "AdyenPaymentDll").
- Protocol IDs are not sequential (gaps exist: no 21, 38-39, 44).

### 2.2 Dynamic Routing

**What**: Some protocols support intelligent routing where the billing engine can dynamically select the best terminal/route.

**Columns/Parameters Involved**: `IsDynamicRouting`

**Rules**:
- **IsDynamicRouting = true**: WireCard (18), WorldPay (23), Adyen (31), Checkout (43), Proxy (40), IxopayNuvei (46) — the billing engine evaluates quotas, BIN routing, and country rules to pick the optimal terminal.
- **IsDynamicRouting = false/null**: Static routing — transactions go to a pre-configured terminal.

**Diagram**:
```
Payment Protocols (45 total)
├── Direction: Direct (39)
│   ├── Dynamic Routing: WireCard, WorldPay, Adyen, Checkout, Proxy, IxopayNuvei
│   └── Static: Xor, Wire Transfer, Neteller, AliPay, WeChat, CryptoWallet, etc.
│
└── Direction: Redirect (6)
    └── PayPal Express, MoneyBookers, Ixopay, Tink
```

---

## 3. Data Overview

| ProtocolID | Name | ClassKey | Direction | Dynamic | Meaning |
|---|---|---|---|---|---|
| 1 | Xor 1 | XorPaymentDll | Direct | No | Primary Xor credit card processing endpoint |
| 2 | PayPal Express Checkout | PayPalPaymentDll | Redirect | No | PayPal browser redirect payment flow |
| 18 | WireCard | WireCardPaymentDll | Direct | Yes | WireCard with dynamic terminal routing |
| 31 | Adyen | AdyenPaymentDll | Direct | Yes | Adyen payment gateway with dynamic routing |
| 43 | Checkout | CheckoutPaymentDll | Direct | Yes | Checkout.com integration with smart routing |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProtocolID | int | NO | - | VERIFIED | Primary key identifying the payment protocol. Values 1-49 (with gaps). Referenced by ProtocolParameter, Response, Billing.Terminal, Billing.Depot, and multiple billing procedures. |
| 2 | PaymentServiceID | int | NO | - | VERIFIED | FK → Billing.PaymentService. Identifies which PSP backs this protocol. Multiple protocols can share a PaymentServiceID. Indexed for lookup performance. |
| 3 | ProtocolDirectionID | int | NO | - | VERIFIED | FK → Dictionary.ProtocolDirection. 1=Direct (server-to-server), 2=Redirect (browser redirect). Indexed for lookup. |
| 4 | Name | varchar(50) | NO | - | VERIFIED | Human-readable protocol label (e.g., "Adyen", "PayPal Express Checkout"). Used in admin UI and billing logs. |
| 5 | ClassKey | varchar(50) | NO | - | VERIFIED | .NET DLL class identifier used by the billing engine to instantiate the correct payment processor (e.g., "AdyenPaymentDll"). Multiple protocols can share a ClassKey (e.g., ACHCrossRiver and ACHSilvergate both use "ACHPaymentDll"). |
| 6 | IsDynamicRouting | bit | YES | - | VERIFIED | When true, the billing engine uses BIN routing, quota management, and country rules to dynamically select the optimal terminal. Null treated as false. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Referenced Object | Element | FK Constraint | Description |
|-------------------|---------|---------------|-------------|
| Billing.PaymentService | PaymentServiceID | FK_BPMS_DPRT (NOCHECK) | The payment service provider backing this protocol |
| Dictionary.ProtocolDirection | ProtocolDirectionID | FK_DPRD_DPRT | Communication direction (Direct/Redirect) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.ProtocolParameter | ProtocolID | FK (FK_DPRT_DPRP) | Protocol-specific configuration parameters |
| Dictionary.Response | ProtocolID | FK (FK_DPRT_DRES) | Response code mappings per protocol |
| Billing.Terminal | ProtocolID | Implicit | Terminal configurations per protocol |
| Billing.Depot | ProtocolID | Implicit | Payment depot associations |
| Billing.ProtocolCountry | ProtocolID | Implicit | Country availability rules |
| Billing.ProtocolByBin | ProtocolID | Implicit | BIN-based routing rules |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.Protocol
├── Billing.PaymentService (FK)
└── Dictionary.ProtocolDirection (FK)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.PaymentService | Table | FK — payment service provider |
| Dictionary.ProtocolDirection | Table | FK — communication direction |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ProtocolParameter | Table | FK — protocol config parameters |
| Dictionary.Response | Table | FK — response code mappings |
| Billing.LoadProtocols | Stored Procedure | Reader — caches all protocols |
| Billing.ProtocolEdit | Stored Procedure | Modifier — CRUD operations |
| Billing.GetCCProcessingBundle | Stored Procedure | Reader — credit card routing |
| Billing.GetCCProcessingBundleByBin | Stored Procedure | Reader — BIN-based routing |
| Billing.GetCountryProtocols | Stored Procedure | Reader — country availability |
| Billing.GetCCProtocolQuotas | Stored Procedure | Reader — quota management |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BPRT | NONCLUSTERED PK | ProtocolID ASC | - | - | Active (FF=90) |
| DPRT_PAYMENTSERVICE | NONCLUSTERED | PaymentServiceID ASC | - | - | Active (FF=90) |
| DPRT_PROTOCOLDIRECTION | NONCLUSTERED | ProtocolDirectionID ASC | - | - | Active (FF=90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BPRT | PRIMARY KEY | Unique protocol identifier |
| FK_BPMS_DPRT | FOREIGN KEY (NOCHECK) | ProtocolID → Billing.PaymentService |
| FK_DPRD_DPRT | FOREIGN KEY | ProtocolDirectionID → Dictionary.ProtocolDirection |

---

## 8. Sample Queries

### 8.1 List all protocols with direction
```sql
SELECT  p.ProtocolID,
        p.Name,
        p.ClassKey,
        pd.Name AS Direction,
        p.IsDynamicRouting
FROM    [Dictionary].[Protocol] p WITH (NOLOCK)
JOIN    [Dictionary].[ProtocolDirection] pd WITH (NOLOCK) ON p.ProtocolDirectionID = pd.ProtocolDirectionID
ORDER BY p.ProtocolID;
```

### 8.2 Find dynamic routing protocols
```sql
SELECT  ProtocolID,
        Name,
        ClassKey
FROM    [Dictionary].[Protocol] WITH (NOLOCK)
WHERE   IsDynamicRouting = 1;
```

### 8.3 Count protocols per payment service
```sql
SELECT  PaymentServiceID,
        COUNT(*) AS ProtocolCount
FROM    [Dictionary].[Protocol] WITH (NOLOCK)
GROUP BY PaymentServiceID
ORDER BY ProtocolCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Protocol | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Protocol.sql*
