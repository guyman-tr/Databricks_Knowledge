# Customer.GetCustomerTrackingInformation

> Returns the affiliate and acquisition tracking fields (SerialID, SubSerialID, OriginalCID, OriginalProviderID) for a customer; used to reconstruct the acquisition funnel and affiliate attribution chain.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer to query) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetCustomerTrackingInformation retrieves the four affiliate and acquisition attribution fields from Customer.Customer for a given CID. These fields collectively describe how and through whom a customer was acquired: which affiliate channel (SerialID), which sub-affiliate (SubSerialID), which referring customer (OriginalCID), and which provider (OriginalProviderID).

The procedure is used by systems that need to reconstruct the customer acquisition funnel - for affiliate commission calculation, fraud analysis (detecting referral loops), compliance investigations, or CRM enrichment.

---

## 2. Business Logic

### 2.1 Acquisition Attribution Fields

**What**: Four fields capture the full affiliate and customer referral attribution chain.

**Columns/Parameters Involved**: `SerialID`, `SubSerialID`, `OriginalCID`, `OriginalProviderID`

**Rules**:
- SerialID: the affiliate/IB (Introducing Broker) serial number that acquired this customer. From BackOffice.Affiliate via AffiliateID linkage.
- SubSerialID: sub-affiliate or sub-IB channel within the primary affiliate's network
- OriginalCID: the CID of the customer who referred this customer (0 or self-CID = no referrer)
- OriginalProviderID: the provider ID at time of acquisition (1 = self/direct; > 1 = affiliate provider)
- These four fields together fully reconstruct "who brought this customer to eToro"

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID to retrieve tracking information for. Returns 0 rows if CID not found. |

**Output result set:**

| Column | Source | Business Meaning |
|--------|--------|-----------------|
| SerialID | Customer.Customer.SerialID | Affiliate/IB serial number that acquired this customer. Maps to BackOffice.Affiliate. 0 or NULL = no affiliate (direct registration). Also used as AffiliateID in some contexts. |
| SubSerialID | Customer.Customer.SubSerialID | Sub-affiliate or sub-IB channel code within the primary affiliate's network. More granular than SerialID for multi-tier affiliate structures. |
| OriginalCID | Customer.Customer.OriginalCID | CID of the customer who referred this customer (refer-a-friend). 0 = no referrer; same as CID = self-referral (pre-affiliate-program era). |
| OriginalProviderID | Customer.Customer.OriginalProviderID | Provider ID at time of first acquisition. 1 = direct registration (no external provider); > 1 = acquired through an affiliate provider. Combined with OriginalCID to fully identify the acquisition source. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Read | Retrieves acquisition tracking fields for the customer |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCustomerTrackingInformation (procedure)
└── Customer.Customer (view)
      └── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | Source of SerialID, SubSerialID, OriginalCID, OriginalProviderID filtered by CID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. No NULL guard or error handling.

---

## 8. Sample Queries

### 8.1 Get acquisition tracking data for a customer

```sql
EXEC Customer.GetCustomerTrackingInformation @CID = 12345678
```

### 8.2 Direct query equivalent

```sql
SELECT SerialID, SubSerialID, OriginalCID, OriginalProviderID
FROM Customer.Customer WITH (NOLOCK)
WHERE CID = 12345678
```

### 8.3 Find all customers acquired by the same affiliate

```sql
SELECT CID, SerialID, SubSerialID, OriginalCID, OriginalProviderID
FROM Customer.Customer WITH (NOLOCK)
WHERE SerialID = (
    SELECT SerialID FROM Customer.Customer WITH (NOLOCK) WHERE CID = 12345678
)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 9/10, Logic: 6/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetCustomerTrackingInformation | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetCustomerTrackingInformation.sql*
