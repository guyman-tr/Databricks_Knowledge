# Apex.SaveOptionsEligibility

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveOptionsEligibility.sql`  
**Author:** Oleksandr Litvinov  
**Created:** 2022-05-05  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveOptionsEligibility` records or updates a customer's options-trading eligibility determination. Eligibility is distinct from appropriateness: appropriateness tests the customer's knowledge, while eligibility evaluates whether the customer meets the regulatory and business criteria to be offered options products (e.g., account type, residency, regulatory restrictions). The procedure also handles product-specific eligibility for stocks and crypto options.

It is called by the eligibility-assessment service when the platform determines or updates a customer's entitlement to trade options, or when product-line eligibility needs to be updated independently.

---

## 2. Parameters

| Parameter | Type | Nullable | Default | Description |
|-----------|------|----------|---------|-------------|
| `@GCID` | `int` | No | — | Global Customer ID. |
| `@EligibilityStatusID` | `int` | No | — | Overall options eligibility status code. |
| `@EligibilityStatusReasonID` | `int` | No | — | Reason code for the eligibility decision. |
| `@ApplicationName` | `nvarchar(50)` | No | — | Service name performing the update. |
| `@StocksElegibilityStatusID` | `int` | Yes | `NULL` | Eligibility status specific to stocks options. |
| `@CryptoElegibilityStatusID` | `int` | Yes | `NULL` | Eligibility status specific to crypto options. |

---

## 3. Result Sets

None. Write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `Options` | `Apex` | SELECT (EXISTS check, no NOLOCK) + UPDATE or INSERT | Creates the row on first write if it does not exist. |

---

## 5. Logic Flow

1. `IF EXISTS (SELECT 1 FROM Apex.Options WHERE GCID = @GCID)` (no NOLOCK — reads committed state):
   - **True:** UPDATE eligibility fields using `ISNULL(@param, existing_value)`.
   - **False:** INSERT with eligibility fields set and all other status/appropriateness fields defaulted to `0`.
2. `@StocksElegibilityStatusID` and `@CryptoElegibilityStatusID` are optional — NULL means "preserve current value" on UPDATE or "insert NULL" on INSERT.

---

## 6. Error Handling

No explicit error handling. Standard SQL Server exceptions propagate.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.Options` | Table | Options profile store |
| `Apex.GetOptions` | Stored Procedure | Reads the row written here |
| `Apex.SaveOptionsAppropriateness` | Stored Procedure | Writes appropriateness fields to the same row |
| `Apex.SaveOptionsStatus` | Stored Procedure | Writes status fields to the same row |

---

## 8. Usage Notes

- Unlike `SaveOptionsAppropriateness`, this procedure reads `Apex.Options` **without** a `NOLOCK` hint in the EXISTS check, ensuring it reads committed eligibility state. This is appropriate when eligibility decisions must be made on authoritative data.
- `StocksElegibilityStatusID` and `CryptoElegibilityStatusID` are nullable parameters; callers that only deal with general options eligibility can omit them (pass NULL) and the existing product-specific values will be preserved.
- When this procedure creates a new `Options` row, appropriateness fields are initialised to `0`. `SaveOptionsAppropriateness` should be called subsequently to populate those fields.
- Note the spelling "Elegibility" (typo) in the column names `StocksElegibilityStatusID` and `CryptoElegibilityStatusID` — this matches the database schema and must be preserved in all references.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveOptionsEligibility.sql` | Quality Score: 8.5/10*
