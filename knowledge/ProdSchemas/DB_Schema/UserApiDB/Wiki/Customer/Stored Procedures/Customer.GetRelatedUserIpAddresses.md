# Customer.GetRelatedUserIpAddresses

> Finds up to 200 customers who registered from the same IP address - fraud detection for multi-account creation from a single location.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TOP 200 GCIDs matching the IP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetRelatedUserIpAddresses identifies customers who share the same registration IP address. This is a fraud detection tool - multiple accounts created from the same IP address may indicate a single user operating multiple accounts, or an organized fraud ring operating from the same location.

The procedure returns up to 200 matching GCIDs from dbo.Real_Customer. The TOP 200 limit prevents excessive result sets for IPs used by large organizations or VPNs.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple exact IP match with TOP 200 limit.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ipAddress | varchar(15) | NO | - | CODE-BACKED | IPv4 address to search for (e.g., '192.168.1.1'). |
| 2 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID of customer who registered from this IP. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ipAddress | dbo.Real_Customer.IP | Exact match | Registration IP matching |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | IP-based fraud detection |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRelatedUserIpAddresses (procedure)
+-- dbo.Real_Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | FROM - IP address exact match |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called by application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find accounts from same IP
```sql
EXEC Customer.GetRelatedUserIpAddresses @ipAddress = '203.0.113.42'
```

### 8.2 Direct query equivalent
```sql
SELECT TOP 200 GCID FROM dbo.Real_Customer WITH (NOLOCK) WHERE IP = '203.0.113.42'
```

### 8.3 Count accounts from an IP
```sql
SELECT COUNT(*) FROM dbo.Real_Customer WITH (NOLOCK) WHERE IP = '203.0.113.42'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetRelatedUserIpAddresses | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetRelatedUserIpAddresses.sql*
