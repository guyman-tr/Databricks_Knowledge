# Customer.GetMiscData

> Performs a bundle of registration-support lookups in a single call: resolves IP to country, looks up state ID by name, fetches the default cashout fee group, and checks whether an affiliate ID is valid.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @affiliateId, @regIp, @countryId, @state inputs; returns 4-column scalar result |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetMiscData is a registration-flow helper procedure that bundles four distinct lookups into one database round-trip. Rather than making four separate calls, the registration service calls this single procedure to get everything it needs before creating a new customer account.

The procedure does not read from any Customer schema table - it is entirely focused on resolving external reference data: IP geolocation, state/province identity, default financial configuration, and affiliate partner validity.

This SP is called by the SQL_UserSyncAPI database user, which handles user synchronization and registration flows. The name "GetMiscData" reflects its nature as an aggregation of miscellaneous but related registration inputs.

---

## 2. Business Logic

### 2.1 IP-to-Country Resolution

**What**: Converts the registration IP address into a country ID for geo-targeting and compliance.

**Columns/Parameters Involved**: `@regIp`, `CountryIdByIP`

**Rules**:
- Delegates to `[Internal].[GetCountryIDByIP](@regIp)` via EXEC call (cross-schema, Internal schema)
- Result stored in @regCountryId and returned as CountryIdByIP
- Used to detect country of origin for fraud analysis (compare with declared CountryID)
- This is the same mechanism that populates Customer.CustomerStatic.CountryIDByIP at registration

### 2.2 State/Province ID Lookup

**What**: Resolves a US state or province name string to a numeric StateID.

**Columns/Parameters Involved**: `@state`, `@countryId`, `StateId`

**Rules**:
- Looks up Dictionary.State WHERE UPPER(Name) = UPPER(@state) AND CountryID = @countryId
- Case-insensitive name match (UPPER on both sides)
- @state and @countryId are optional (both default to NULL) - if NULL, StateId returns NULL
- Used for US customers where the state is required for tax and regulatory purposes

### 2.3 Default Cashout Fee Group

**What**: Returns the default cashout fee group ID for use in new account setup.

**Columns/Parameters Involved**: `DefaultCashoutGroupId`

**Rules**:
- SELECT TOP 1 from Trade.CashoutRange WHERE IsDefault = 1
- Returns the CashoutFeeGroupID of the default row
- Used when registering a new customer to assign them to the standard cashout fee tier
- If no default row exists in Trade.CashoutRange, returns NULL

### 2.4 Affiliate Validation

**What**: Checks whether the provided affiliate ID exists in BackOffice.Affiliate.

**Columns/Parameters Involved**: `@affiliateId`, `AffiliateExists`

**Rules**:
- IF EXISTS (SELECT 1 FROM BackOffice.Affiliate WHERE AffiliateID = @affiliateId) THEN 1 ELSE 0
- Returns BIT: 1 = affiliate exists and is valid, 0 = affiliate not found
- Used to validate the affiliate referral code before completing registration
- Invalid affiliate IDs fail quietly (AffiliateExists=0) rather than raising an error

**Diagram**:
```
@affiliateId, @regIp, @countryId, @state
        |
        v
[Internal].[GetCountryIDByIP](@regIp)  -> @regCountryId
Dictionary.State (Name, CountryID)      -> @stateId
Trade.CashoutRange (IsDefault=1)        -> @defaultCashoutGroupID
BackOffice.Affiliate (AffiliateID)      -> @affiliateExists (BIT)
        |
        v
SELECT @affiliateExists, @stateId, @regCountryId, @defaultCashoutGroupID
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @affiliateId | INT | NO | - | CODE-BACKED | Input: Affiliate/partner ID to validate. Checked against BackOffice.Affiliate.AffiliateID. If 0 or not found, AffiliateExists returns 0. |
| 2 | @regIp | VARCHAR(20) | NO | - | CODE-BACKED | Input: Registration IP address of the new user. Passed to Internal.GetCountryIDByIP to resolve to a country ID. Used for geo-targeting and fraud detection. |
| 3 | @countryId | INT | YES | NULL | CODE-BACKED | Input: Declared country of residence (optional). Combined with @state to look up the numeric StateID from Dictionary.State. |
| 4 | @state | VARCHAR(20) | YES | NULL | CODE-BACKED | Input: State or province name string (optional). Matched case-insensitively against Dictionary.State.Name. Only meaningful for US customers. |
| 5 | AffiliateExists | BIT (output) | NO | - | CODE-BACKED | 1 if @affiliateId exists in BackOffice.Affiliate; 0 if not found. Used by registration to validate the referring affiliate before completing sign-up. |
| 6 | StateId | INT (output) | YES | - | CODE-BACKED | Numeric state/province ID from Dictionary.State matching @state name and @countryId. NULL if @state or @countryId is NULL, or if no match found. Maps to Customer.CustomerStatic.StateID. |
| 7 | CountryIdByIP | INT (output) | YES | - | CODE-BACKED | Country ID resolved from @regIp by Internal.GetCountryIDByIP. Stored at registration as Customer.CustomerStatic.CountryIDByIP. NULL if IP cannot be resolved. FK to Dictionary.Country. |
| 8 | DefaultCashoutGroupId | INT (output) | YES | - | CODE-BACKED | CashoutFeeGroupID of the default cashout configuration from Trade.CashoutRange (IsDefault=1). Assigned to new customers as their cashout fee tier. NULL if no default row configured. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @regIp | Internal.GetCountryIDByIP | EXEC (cross-schema proc call) | IP geolocation - resolves IP to country ID |
| @state / @countryId | Dictionary.State | Lookup | State name resolution by country |
| DefaultCashoutGroupId | Trade.CashoutRange | Lookup (IsDefault=1) | Default cashout fee group for new customers |
| @affiliateId | BackOffice.Affiliate | Existence check | Validates affiliate ID before registration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_UserSyncAPI (DB role) | - | GRANT EXECUTE | Called by user sync/registration service during account creation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetMiscData (procedure)
├── Internal.GetCountryIDByIP (procedure - cross-schema)
├── Dictionary.State (table - cross-schema)
├── Trade.CashoutRange (table - cross-schema)
└── BackOffice.Affiliate (table - cross-schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetCountryIDByIP | Stored Procedure | EXEC to resolve IP address to country ID |
| Dictionary.State | Table | Lookup: state name -> StateID for given country |
| Trade.CashoutRange | Table | Lookup: default cashout fee group ID |
| BackOffice.Affiliate | Table | Existence check for affiliate ID validation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_UserSyncAPI | DB Role/User | EXECUTE permission granted - called during registration flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Behavior | Suppresses row count messages - reduces network traffic for the caller |

---

## 8. Sample Queries

### 8.1 Get misc registration data for a US customer with affiliate
```sql
EXEC Customer.GetMiscData
    @affiliateId = 1234,
    @regIp = '192.168.1.100',
    @countryId = 234,   -- US
    @state = 'California';
```

### 8.2 Get misc data without state (non-US customer)
```sql
EXEC Customer.GetMiscData
    @affiliateId = 0,
    @regIp = '91.108.4.0',
    @countryId = NULL,
    @state = NULL;
-- Returns StateId=NULL, CountryIdByIP from IP geolocation, AffiliateExists=0
```

### 8.3 Verify default cashout group directly
```sql
SELECT TOP 1 CashoutFeeGroupID
FROM Trade.CashoutRange WITH (NOLOCK)
WHERE IsDefault = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetMiscData | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetMiscData.sql*
