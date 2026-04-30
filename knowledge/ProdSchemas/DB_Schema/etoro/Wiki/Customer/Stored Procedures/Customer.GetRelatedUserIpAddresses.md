# Customer.GetRelatedUserIpAddresses

> Returns up to 200 GCIDs of customers who registered or were last seen using a given IP address, used for fraud detection and account linkage analysis.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ipAddress; returns GCID list (max 200) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetRelatedUserIpAddresses finds all eToro customers associated with a specific IP address, using the IP stored in Customer.CustomerStatic. It is part of the "User SYNC New SPs" group (per DDL comment), meaning it supports the UserSync service that keeps customer data synchronized across systems.

The primary use case is fraud and duplicate account detection: when multiple accounts share an IP address they may be owned by the same person (violating one-account-per-person rules) or be part of a coordinated fraud operation. The TOP 200 cap prevents excessive result sets from large shared IPs (NAT gateways, corporate networks, VPNs).

Only GCID is returned, not full customer details - callers must join additional tables if customer details are needed.

---

## 2. Business Logic

### 2.1 IP-Based Customer Lookup

**What**: Returns GCIDs of all customers whose stored IP matches the input.

**Columns/Parameters Involved**: `@ipAddress`, `GCID`, `IP`

**Rules**:
- `SELECT TOP 200 GCID FROM Customer.CustomerStatic WHERE @ipAddress = [IP]`
- IP comparison is exact string match (no CIDR/subnet matching)
- @ipAddress is varchar(15) - supports IPv4 addresses (max 15 chars: "255.255.255.255")
- TOP 200 cap prevents excessive results for shared IPs (VPNs, university networks, etc.)
- No ordering specified: result order is non-deterministic
- Returns only GCID - callers must do additional lookups for customer details

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ipAddress | varchar(15) | NO | - | CODE-BACKED | Input: IPv4 address to look up. Matched against Customer.CustomerStatic.IP column via exact string comparison. Max length 15 chars (dotted decimal notation). |
| 2 | GCID | int (output) | NO | - | CODE-BACKED | Group Customer ID of each matching customer. May return 0 to 200 rows. Callers must join to Customer.Customer or Customer.CustomerStatic for additional details. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ipAddress | Customer.CustomerStatic | FROM + WHERE filter | IP column lookup; CustomerStatic stores the customer's registered or last-seen IP |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRelatedUserIpAddresses (procedure)
`-- Customer.CustomerStatic (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FROM - IP column lookup to find associated GCIDs |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TOP 200 cap | Performance guard | Limits results for shared IPs (VPNs, NAT). Result order is non-deterministic without ORDER BY. |
| varchar(15) limit | Data type | IPv4 only; IPv6 addresses (up to 39 chars) are not supported |
| Exact match | Matching | No subnet or CIDR range matching - only exact IP string match |

---

## 8. Sample Queries

### 8.1 Find all customers from an IP address
```sql
EXEC Customer.GetRelatedUserIpAddresses @ipAddress = '192.168.1.100';
```

### 8.2 Direct query equivalent
```sql
SELECT TOP 200 GCID
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE IP = '192.168.1.100';
```

### 8.3 Get full customer details for IP-related accounts
```sql
SELECT cs.GCID, c.UserName, c.Email, cs.IP, cs.RegistrationDate
FROM Customer.CustomerStatic cs WITH (NOLOCK)
INNER JOIN Customer.Customer c WITH (NOLOCK) ON cs.CID = c.CID
WHERE cs.IP = '192.168.1.100'
ORDER BY cs.RegistrationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 9/10, Logic: 6/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetRelatedUserIpAddresses | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetRelatedUserIpAddresses.sql*
