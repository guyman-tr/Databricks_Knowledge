# Registration.GetRegistrationIpInfo

> Returns a user's registration IP address and whether it appears on the IP blacklist for fraud detection.

| Property | Value |
|----------|-------|
| **Schema** | Registration |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Registration.GetRegistrationIpInfo retrieves the IP address used during registration and checks if it's on the registration IP blacklist. Used for post-registration fraud screening - flagging accounts registered from known bad IPs.

---

## 2. Business Logic

### 2.1 IP Blacklist Check

**Rules**:
- Step 1: Get registration IP from Real_Customer for the GCID
- Step 2: Check if IP exists in RegistrationIpBlacklist
- Returns: Ip (varchar) + IsInBlackList (bit)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int (IN) | NO | - | CODE-BACKED | User to check. |

Output: Ip (varchar), IsInBlackList (bit).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.Real_Customer | SELECT FROM (synonym) | Registration IP |
| - | dbo.RegistrationIpBlacklist | EXISTS (synonym) | Blacklist check |

### 5.2 Referenced By (other objects point to this)

Fraud detection service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Registration.GetRegistrationIpInfo (procedure)
  +-- dbo.Real_Customer (synonym)
  +-- dbo.RegistrationIpBlacklist (synonym)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Synonym | SELECT FROM |
| dbo.RegistrationIpBlacklist | Synonym | EXISTS check |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check IP info
```sql
EXEC Registration.GetRegistrationIpInfo @gcid = 12345
```

### 8.2 Verify blacklist
```sql
DECLARE @R TABLE (Ip VARCHAR(30), IsInBlackList BIT)
INSERT INTO @R EXEC Registration.GetRegistrationIpInfo @gcid = 12345
SELECT * FROM @R
```

### 8.3 Direct equivalent
```sql
DECLARE @Ip VARCHAR(30)
SELECT @Ip = IP FROM Real_Customer WITH (NOLOCK) WHERE GCID = 12345
SELECT @Ip AS Ip, CASE WHEN EXISTS (SELECT 1 FROM RegistrationIpBlacklist WHERE IPAddress = @Ip) THEN 1 ELSE 0 END AS IsInBlackList
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Registration.GetRegistrationIpInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Registration/Stored Procedures/Registration.GetRegistrationIpInfo.sql*
