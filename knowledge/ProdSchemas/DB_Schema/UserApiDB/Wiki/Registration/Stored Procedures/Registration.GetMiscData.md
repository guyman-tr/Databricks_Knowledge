# Registration.GetMiscData

> Gathers miscellaneous registration data: affiliate validation, state lookup, IP-to-country, and default cashout group.

| Property | Value |
|----------|-------|
| **Schema** | Registration |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @affiliateId + @regIp + @countryId + @state (input params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Registration.GetMiscData collects several pieces of data needed during registration: (1) resolves IP to country via CountryIDByIP synonym, (2) looks up StateID from state name, (3) finds default cashout fee group, (4) checks if affiliate exists. Returns all four values in a single result set. Used by the registration service to populate derived fields.

---

## 2. Business Logic

### 2.1 Multi-Source Data Collection

**Rules**:
- CountryIDByIP: EXEC @regCountryId = CountryIDByIP @regIp (synonym to external function)
- StateID: lookup by UPPER(Name) + CountryID from dbo.State
- CashoutGroupID: TOP 1 from CashoutRange WHERE IsDefault=1
- AffiliateExists: EXISTS check on Real_Affiliate

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @affiliateId | int (IN) | NO | - | CODE-BACKED | Affiliate to validate. |
| 2 | @regIp | varchar(20) (IN) | NO | - | CODE-BACKED | Registration IP for geo-detection. |
| 3 | @countryId | int (IN) | YES | NULL | CODE-BACKED | Declared country for state lookup. |
| 4 | @state | varchar(20) (IN) | YES | NULL | CODE-BACKED | State name for StateID resolution. |

Output: AffiliateExists (bit), StateId (int), CountryIdByIP (int), DefaultCashoutGroupId (int).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.CountryIDByIP | EXEC (synonym) | IP-to-country |
| - | dbo.State | SELECT FROM (synonym) | State lookup |
| - | dbo.CashoutRange | SELECT FROM (synonym) | Default cashout group |
| - | dbo.Real_Affiliate | EXISTS (synonym) | Affiliate validation |

### 5.2 Referenced By (other objects point to this)

Registration service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Registration.GetMiscData (procedure)
  +-- dbo.CountryIDByIP (synonym)
  +-- dbo.State (synonym)
  +-- dbo.CashoutRange (synonym)
  +-- dbo.Real_Affiliate (synonym)
```

### 6.1 Objects This Depends On

4 dbo synonyms (all external).

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

### 8.1 Get misc registration data
```sql
EXEC Registration.GetMiscData @affiliateId = 100, @regIp = '192.168.1.1', @countryId = 44, @state = 'London'
```

### 8.2 Without state
```sql
EXEC Registration.GetMiscData @affiliateId = 100, @regIp = '192.168.1.1'
```

### 8.3 Check result
```sql
DECLARE @R TABLE (AffiliateExists BIT, StateId INT, CountryIdByIP INT, DefaultCashoutGroupId INT)
INSERT INTO @R EXEC Registration.GetMiscData @affiliateId = 100, @regIp = '10.0.0.1'
SELECT * FROM @R
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Registration.GetMiscData | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Registration/Stored Procedures/Registration.GetMiscData.sql*
