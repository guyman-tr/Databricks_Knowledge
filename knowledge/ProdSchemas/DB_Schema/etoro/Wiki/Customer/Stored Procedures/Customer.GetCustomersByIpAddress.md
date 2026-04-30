# Customer.GetCustomersByIpAddress

> Returns up to 200 GCIDs for customers who registered or were last seen with a specific IP address; used for fraud investigation and duplicate account detection.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ipAddress (IP to search for) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetCustomersByIpAddress is a fraud and compliance investigation tool. Given an IP address string, it returns up to 200 GCIDs of customers who have that IP stored in Customer.CustomerStatic.IP. Investigators use this to identify clusters of accounts created from the same IP - a common indicator of duplicate accounts, coordinated fraud, or VPN/proxy usage by customers trying to bypass geographic restrictions.

The IP column in CustomerStatic captures the registration or most-recently-known IP address of the customer. The procedure returns GCID (not CID) because GCID is the cross-product identity that links the same physical person's accounts across eToro's real and demo environments.

The TOP 200 cap prevents performance issues when many accounts share a NAT gateway, corporate proxy, or VPN exit node IP.

---

## 2. Business Logic

### 2.1 IP Address Matching

**What**: Exact string match on the stored IP address field.

**Columns/Parameters Involved**: `@ipAddress`, `IP`, `GCID`

**Rules**:
- Exact equality match: WHERE @ipAddress = IP (no wildcard or range support)
- IP is stored as varchar in CustomerStatic - no IP-range queries or CIDR matching
- TOP 200 cap: if more than 200 customers share the IP (common for corporate/VPN IPs), only 200 GCIDs are returned with no ordering guarantee
- Returns GCID (cross-product group ID), not CID - the caller can then look up full profiles by GCID

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ipAddress | varchar(15) | NO | - | CODE-BACKED | IPv4 address string to search for (e.g., '192.168.1.1'). Exact match - no wildcards. Max length 15 accommodates full IPv4 dotted-decimal notation (e.g., '255.255.255.255'). No IPv6 support (would require longer field). |

**Output result set:**

| Column | Source | Business Meaning |
|--------|--------|-----------------|
| GCID | Customer.CustomerStatic.GCID | Global Customer ID - cross-product identity linking real and demo accounts for the same physical person. Use GCID to look up related accounts across environments. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ipAddress | Customer.CustomerStatic.IP | Read (equality filter) | Searches the IP column for matching customers |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase (called directly by compliance tooling or BackOffice UI).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCustomersByIpAddress (procedure)
└── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Searches IP column, returns GCID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TOP 200 | Result cap | Limits output to 200 GCIDs; prevents full-scan result sets for shared IPs |
| varchar(15) | IPv4 only | Input type constrains to IPv4 addresses; IPv6 addresses would be truncated/not match |
| SET NOCOUNT ON | Performance | Suppresses row-count messages |

---

## 8. Sample Queries

### 8.1 Find customers sharing an IP address

```sql
EXEC Customer.GetCustomersByIpAddress @ipAddress = '192.168.1.1'
-- Returns up to 200 GCIDs for customers with this IP
```

### 8.2 Enrich results with customer details

```sql
CREATE TABLE #IpCustomers (GCID INT)
INSERT INTO #IpCustomers EXEC Customer.GetCustomersByIpAddress @ipAddress = '192.168.1.1'
SELECT ic.GCID, cs.CID, cs.UserName, cs.Registered, cs.PlayerStatusID
FROM #IpCustomers ic WITH (NOLOCK)
JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cs.GCID = ic.GCID
ORDER BY cs.Registered
DROP TABLE #IpCustomers
```

### 8.3 Check IP column values directly on CustomerStatic

```sql
SELECT TOP 10 CID, GCID, IP, Registered
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE IP = '192.168.1.1'
ORDER BY Registered
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8/10, Logic: 6/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetCustomersByIpAddress | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetCustomersByIpAddress.sql*
