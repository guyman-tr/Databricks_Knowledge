# Dictionary.ProtocolDirection

> Lookup table defining 2 payment protocol communication directions — Direct (server-to-server) and Redirect (browser redirect) — for eToro's billing payment processing.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ProtocolDirectionID (INT, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 (PK nonclustered + unique on Name) |

---

## 1. Business Meaning

Dictionary.ProtocolDirection classifies payment protocols by their communication pattern with external payment service providers. "Direct" means the eToro server communicates directly with the PSP's API (server-to-server), while "Redirect" means the customer's browser is redirected to the PSP's hosted payment page.

This table is referenced by Dictionary.Protocol (FK_DPRD_DPRT) and loaded into the billing cache via Billing.LoadProtocolDirections. The direction affects the user experience — Direct protocols keep the user on eToro's payment page, while Redirect protocols temporarily send them to an external hosted page.

---

## 2. Business Logic

### 2.1 Communication Patterns

**What**: Each protocol direction defines how payment data flows between eToro and the payment provider.

**Columns/Parameters Involved**: `ProtocolDirectionID`, `Name`

**Rules**:
- **1 = Direct** — Server-to-server API communication. Card details are sent from eToro's server to the PSP. Most credit card protocols (Xor, WorldPay, Adyen, Checkout) use this direction. The majority of protocols (39 of 45) use Direct.
- **2 = Redirect** — Browser redirect to the PSP's hosted payment page. The customer leaves eToro temporarily. Used by PayPal Express Checkout, MoneyBookers/Skrill, Ixopay, and Tink.
- The direction is set per protocol at configuration time and doesn't change.

**Diagram**:
```
Payment Protocol Directions
├── 1 = Direct (39 protocols)
│   └── eToro Server ──API──▶ PSP Server
│       (user stays on eToro page)
│
└── 2 = Redirect (6 protocols)
    └── User Browser ──redirect──▶ PSP Hosted Page
        (user temporarily leaves eToro)
```

---

## 3. Data Overview

| ProtocolDirectionID | Name | Meaning |
|---|---|---|
| 1 | Direct | Server-to-server API integration. eToro sends payment data directly to the PSP without browser redirect. Used by the majority of payment protocols. |
| 2 | Redirect | Browser redirect integration. Customer is redirected to the PSP's hosted payment page. Used by PayPal Express, MoneyBookers, Ixopay, Tink. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProtocolDirectionID | int | NO | - | VERIFIED | Primary key. 1=Direct, 2=Redirect. Referenced by Dictionary.Protocol via FK. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Communication direction label. Unique index enforces no duplicates. Cached by Billing.LoadProtocolDirections. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.Protocol | ProtocolDirectionID | FK (FK_DPRD_DPRT) | Each payment protocol has one direction |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Protocol | Table | FK — references this for protocol communication direction |
| Billing.LoadProtocolDirections | Stored Procedure | Reader — caches all protocol directions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DPTD | NONCLUSTERED PK | ProtocolDirectionID ASC | - | - | Active (FF=90) |
| DPTD_NAME | UNIQUE NONCLUSTERED | Name ASC | - | - | Active (FF=90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DPTD | PRIMARY KEY | Unique direction identifier |
| DPTD_NAME | UNIQUE INDEX | Prevents duplicate direction names |

---

## 8. Sample Queries

### 8.1 List all protocol directions
```sql
SELECT  ProtocolDirectionID,
        Name
FROM    [Dictionary].[ProtocolDirection] WITH (NOLOCK)
ORDER BY ProtocolDirectionID;
```

### 8.2 Count protocols by direction
```sql
SELECT  pd.Name AS Direction,
        COUNT(*) AS ProtocolCount
FROM    [Dictionary].[Protocol] p WITH (NOLOCK)
JOIN    [Dictionary].[ProtocolDirection] pd WITH (NOLOCK) ON p.ProtocolDirectionID = pd.ProtocolDirectionID
GROUP BY pd.Name;
```

### 8.3 List redirect-type protocols
```sql
SELECT  p.ProtocolID,
        p.Name AS ProtocolName,
        p.ClassKey
FROM    [Dictionary].[Protocol] p WITH (NOLOCK)
JOIN    [Dictionary].[ProtocolDirection] pd WITH (NOLOCK) ON p.ProtocolDirectionID = pd.ProtocolDirectionID
WHERE   pd.Name = 'Redirect';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ProtocolDirection | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ProtocolDirection.sql*
