# Billing.UpdateCountryBin

> Sets the SupportsAFT (Account Funding Transaction) capability flag on a specific BIN code, routing the update to Dictionary.CountryBin6 (6-digit BINs) or Dictionary.CountryBin8 (8-digit BINs) based on the numeric range of the BIN code.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BinCode - targets Dictionary.CountryBin6 OR Dictionary.CountryBin8 based on digit count |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpdateCountryBin` is the routing service's procedure for updating the AFT (Account Funding Transaction) capability flag on a payment card BIN code. AFT is a Visa/Mastercard push-to-card mechanism that allows funds to be sent directly to a card as the receiving account - used for push payouts, withdrawal reversals, and account funding transfers. Not all card BINs support receiving AFT transactions, and this flag governs whether the routing service can use this channel for a given card.

The procedure routes the update to the correct BIN table based on the digit length of the BIN code:
- **6-digit BINs** (100000-999999): `Dictionary.CountryBin6` - the legacy 6-digit Bank Identification Number standard
- **8-digit BINs** (10000000-99999999): `Dictionary.CountryBin8` - the newer 8-digit BIN standard (ISO 7812 extended)

This split reflects the industry migration from 6-digit to 8-digit BINs. The procedure handles both transparently via range checks. Both target tables are temporal (SYSTEM_VERSIONING = ON), so every change is automatically versioned in `History.CountryBin` and `History.CountryBin8` respectively.

Called by the RoutingUser role, confirming this is used by the payment routing service. The same RoutingUser also has SELECT on `Billing.AftRouting`, indicating that after updating BIN-level AFT support, the routing service consults the per-country/card-type/regulation routing matrix in `Billing.AftRouting` to select the correct depot for AFT payouts.

---

## 2. Business Logic

### 2.1 BIN Length-Based Table Routing

**What**: The procedure selects the target BIN table (CountryBin6 vs CountryBin8) based on the numeric range of @BinCode, matching the two established BIN length standards.

**Columns/Parameters Involved**: `@BinCode`, `@SupportsAFT`, `Dictionary.CountryBin6.SupportsAFT`, `Dictionary.CountryBin8.SupportsAFT`

**Rules**:
- `@BinCode >= 100000 AND @BinCode <= 999999` (6 digits): UPDATE `Dictionary.CountryBin6 SET SupportsAFT = @SupportsAFT WHERE BinCode = @BinCode`
- `@BinCode >= 10000000 AND @BinCode <= 99999999` (8 digits): UPDATE `Dictionary.CountryBin8 SET SupportsAFT = @SupportsAFT WHERE BinCode = @BinCode`
- The two IF branches are mutually exclusive by numeric range (no BIN can be both 6 and 8 digits)
- A BIN code outside both ranges (7 digits, or any other length) silently affects 0 rows in both tables - no error raised
- No transaction wrapping: each UPDATE executes independently (safe since only one can match)
- Both target tables enforce their range via CHECK constraints (`BinCode < 10000000` on CountryBin6, `BinCode >= 10000000` on CountryBin8)

**Diagram**:
```
RoutingUser calls: EXEC UpdateCountryBin @BinCode=415900, @SupportsAFT=1
  |
  IF 100000 <= 415900 <= 999999 -> TRUE (6-digit BIN)
    UPDATE Dictionary.CountryBin6 SET SupportsAFT=1 WHERE BinCode=415900
    -> Versioned in History.CountryBin automatically (temporal table)

RoutingUser calls: EXEC UpdateCountryBin @BinCode=41590012, @SupportsAFT=1
  |
  IF 100000 <= 41590012 <= 999999 -> FALSE
  IF 10000000 <= 41590012 <= 99999999 -> TRUE (8-digit BIN)
    UPDATE Dictionary.CountryBin8 SET SupportsAFT=1 WHERE BinCode=41590012
    -> Versioned in History.CountryBin8 automatically (temporal table)
    Note: CountryBin8 also has granular AFTCrossBorder and AFTDomestic columns
          (not updated by this procedure - updated separately)
```

### 2.2 AFT Routing Integration

**What**: The `SupportsAFT` flag set by this procedure is one input to the AFT routing decision. The routing service combines BIN-level AFT support (`Dictionary.CountryBin6/8.SupportsAFT`) with the per-country/card-type/regulation routing matrix (`Billing.AftRouting`) to determine whether and how to route a payout via AFT.

**Rules**:
- `SupportsAFT = 1`: this BIN can receive AFT transactions; the routing service may use AFT push-to-card for payouts to this card
- `SupportsAFT = 0`: this BIN does not support AFT; routing service uses alternative payout channels (wire, e-wallet, etc.)
- `SupportsAFT = NULL`: AFT capability unknown - treated as unsupported by routing logic

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BinCode | INT | NO | - | CODE-BACKED | The Bank Identification Number (BIN) to update. Numeric range determines target table: 100000-999999 -> Dictionary.CountryBin6 (6-digit BIN); 10000000-99999999 -> Dictionary.CountryBin8 (8-digit BIN). Values outside these ranges silently no-op. |
| 2 | @SupportsAFT | BIT | NO | - | CODE-BACKED | Whether this BIN supports Account Funding Transactions (push-to-card payouts). 1=AFT supported (card can receive push payouts); 0=AFT not supported; NULL=unknown. Written to `SupportsAFT` column in the resolved BIN table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WHERE BinCode (6-digit path) | Dictionary.CountryBin6 | UPDATE (cross-schema) | Sets SupportsAFT for BINs in the 100000-999999 range (6-digit BIN standard) |
| WHERE BinCode (8-digit path) | Dictionary.CountryBin8 | UPDATE (cross-schema) | Sets SupportsAFT for BINs in the 10000000-99999999 range (8-digit BIN standard) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Routing service | @BinCode, @SupportsAFT | EXEC (RoutingUser role) | Called when updating BIN-level AFT capability, e.g. after receiving updated BIN data from card networks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateCountryBin (procedure)
|- Dictionary.CountryBin6 (table) - UPDATE (6-digit BIN path)
|   |- History.CountryBin (temporal history table) - auto-versioned
|
`- Dictionary.CountryBin8 (table) - UPDATE (8-digit BIN path)
    `- History.CountryBin8 (temporal history table) - auto-versioned
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CountryBin6 | Table | UPDATE - sets SupportsAFT WHERE BinCode in 6-digit range (100000-999999) |
| Dictionary.CountryBin8 | Table | UPDATE - sets SupportsAFT WHERE BinCode in 8-digit range (10000000-99999999) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found in SSDT. | - | Called externally by routing service (RoutingUser role). The routing service uses the updated SupportsAFT flag together with Billing.AftRouting to make AFT payout routing decisions. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Note: `Dictionary.CountryBin6` has `IX_DCNB_Bincode` NONCLUSTERED on `BinCode INCLUDE (CardCategory)` supporting the WHERE clause. Both tables have clustered PKs on `(CountryID, BinCode)` / `(BinCode, CountryID)`.

### 7.2 Constraints

N/A for stored procedure. Key constraints on target tables:
- `CHK_CountryBin6`: `BinCode < 10000000` (enforces 6-digit-max range)
- `CHK_CountryBin8`: `BinCode >= 10000000` (enforces 8-digit-min range)
- Both tables: SYSTEM_VERSIONING = ON (temporal) - every UPDATE is automatically tracked in History schema

---

## 8. Sample Queries

### 8.1 Enable AFT for a 6-digit BIN
```sql
-- Mark a 6-digit BIN as AFT-capable
EXEC Billing.UpdateCountryBin @BinCode = 415900, @SupportsAFT = 1;
```

### 8.2 Disable AFT for an 8-digit BIN
```sql
-- Mark an 8-digit BIN as not supporting AFT
EXEC Billing.UpdateCountryBin @BinCode = 41590012, @SupportsAFT = 0;
```

### 8.3 Check current AFT support status for a BIN
```sql
-- For 6-digit BINs
SELECT BinCode, SupportsAFT, IssuingBank, CardTypeID, CountryID
FROM Dictionary.CountryBin6 WITH (NOLOCK)
WHERE BinCode = 415900;

-- For 8-digit BINs
SELECT BinCode, SupportsAFT, AFTDomestic, AFTCrossBorder, IssuingBank, CardTypeID, CountryID
FROM Dictionary.CountryBin8 WITH (NOLOCK)
WHERE BinCode = 41590012;
```

### 8.4 Find all AFT-capable BINs
```sql
SELECT 'CountryBin6' AS Source, BinCode, IssuingBank, CountryID
FROM Dictionary.CountryBin6 WITH (NOLOCK)
WHERE SupportsAFT = 1
UNION ALL
SELECT 'CountryBin8', BinCode, IssuingBank, CountryID
FROM Dictionary.CountryBin8 WITH (NOLOCK)
WHERE SupportsAFT = 1
ORDER BY BinCode;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UpdateCountryBin | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateCountryBin.sql*
