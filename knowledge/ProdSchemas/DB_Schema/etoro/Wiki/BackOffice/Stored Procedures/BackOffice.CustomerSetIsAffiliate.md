# BackOffice.CustomerSetIsAffiliate

> Sets the IsAffiliate flag on BackOffice.Customer for a given CID. Returns @@ERROR (0=success). Controls whether a customer is classified as an affiliate partner.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure marks a customer as an affiliate (or removes that designation) by setting the `IsAffiliate` flag on `BackOffice.Customer`.

Affiliate customers are eToro partners who refer other customers to the platform in exchange for commissions. The `IsAffiliate=1` flag triggers different business treatment: affiliate customers may have special fee structures, dedicated account managers (tracked via `AffiliateManagerID`), and access to affiliate reporting. The flag works in conjunction with `AffiliateManagerID` (set by `BackOffice.CustomerSetAffiliateManager`) to build the full affiliate relationship.

Uses legacy `RETURN @@ERROR` pattern - no TRY/CATCH. No CID existence check - silent no-op if not found.

---

## 2. Business Logic

### 2.1 Simple Boolean Flag Update

**What**: Sets IsAffiliate on a customer row. Returns @@ERROR.

**Rules**:
- UPDATE BackOffice.Customer SET IsAffiliate=@IsAffiliate WHERE CID=@CID
- SET @Error=@@ERROR; RETURN @Error
- @IsAffiliate=1: customer is an affiliate
- @IsAffiliate=0: customer is not an affiliate
- SET NOCOUNT ON: no row count messages
- No CID validation: silent no-op if not found

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. No existence check - silent no-op if not found in BackOffice.Customer. |
| 2 | @IsAffiliate | BIT | NO | - | CODE-BACKED | Affiliate flag. 1=customer is an affiliate partner (earns commissions for referrals). 0=not an affiliate. Written to BackOffice.Customer.IsAffiliate. |

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 3 | RETURN | INT | @@ERROR: 0=success, non-zero=SQL error code. Legacy pattern. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | UPDATE | Sets IsAffiliate flag |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice affiliate management | External | Direct call | Mark or unmark a customer as an affiliate partner |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerSetIsAffiliate (procedure)
|- BackOffice.Customer (table) [UPDATE: IsAffiliate]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE: IsAffiliate flag |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Affiliate management workflows | External | Grant or revoke affiliate status |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURN @@ERROR | Design | Legacy error-return pattern |
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| No CID validation | Design | Silent no-op if CID not found |
| Related field | Context | IsAffiliate=1 works with AffiliateManagerID (set by CustomerSetAffiliateManager) for full affiliate relationship |

---

## 8. Sample Queries

### 8.1 Mark a customer as an affiliate

```sql
DECLARE @Ret INT;
EXEC @Ret = BackOffice.CustomerSetIsAffiliate
    @CID = 12345,
    @IsAffiliate = 1;
SELECT @Ret AS ReturnCode; -- 0 = success
```

### 8.2 Check affiliate status

```sql
SELECT CID, IsAffiliate, AffiliateManagerID
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.CustomerSetIsAffiliate | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerSetIsAffiliate.sql*
