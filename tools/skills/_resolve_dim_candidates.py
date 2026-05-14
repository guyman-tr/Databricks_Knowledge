"""Map every in-scope column from the audit CSV to its candidate Dim_ table.
Outputs a simple console summary of (column, dim_candidate, exists?)."""
from __future__ import annotations
import csv
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
AUDIT = REPO / "knowledge" / "_codepoint_claims_audit.csv"

# Hard-coded list of Dim_* tables in DWH_dbo, from the live INFORMATION_SCHEMA query.
KNOWN_DIMS = {
    "Dim_AccountStatus", "Dim_AccountType", "Dim_ActionType", "Dim_Affiliate",
    "Dim_AffiliateCostType", "Dim_BillingDepot", "Dim_BillingProtocolMIDSettingsID",
    "Dim_BonusType", "Dim_CalculationType", "Dim_Campaign", "Dim_CardType",
    "Dim_CashoutFeeGroup", "Dim_CashoutMode", "Dim_CashoutReason", "Dim_CashoutStatus",
    "Dim_Channel", "Dim_ClientWithdrawReason", "Dim_ClosePositionReason",
    "Dim_CompensationReason", "Dim_ContactType", "Dim_ContractType",
    "Dim_CostConfigurationId", "Dim_CostSubtype", "Dim_CostType", "Dim_Country",
    "Dim_CountryBin", "Dim_CountryIP", "Dim_CountryIPAnonymous",
    "Dim_CountryIPAnonymousProxyType", "Dim_CreditType", "Dim_Currency",
    "Dim_Customer", "Dim_CustomerChangeType", "Dim_Date", "Dim_Desk",
    "Dim_DocumentStatus", "Dim_EvMatchStatus", "Dim_ExchangeInfo",
    "Dim_ExecutionOperationType", "Dim_ExtendedUserField", "Dim_FTDPlatform",
    "Dim_FeeOperationTypes", "Dim_Fund", "Dim_FundType", "Dim_FundingType",
    "Dim_Funnel", "Dim_GuruStatus", "Dim_HistorySplitRatio", "Dim_Instrument",
    "Dim_Label", "Dim_Language", "Dim_Manager", "Dim_MifidCategorization",
    "Dim_Mirror", "Dim_MirrorType", "Dim_MoveMoneyReason", "Dim_PaymentStatus",
    "Dim_PendingClosureStatus", "Dim_PhoneVerified", "Dim_Platform",
    "Dim_PlatformType", "Dim_PlayerLevel", "Dim_PlayerStatus",
    "Dim_PlayerStatusReasons", "Dim_PlayerStatusSubReasons", "Dim_Position",
    "Dim_Product", "Dim_Range", "Dim_RedeemReason", "Dim_RedeemStatus",
    "Dim_Regulation", "Dim_RiskClassification", "Dim_RiskManagementStatus",
    "Dim_RiskStatus", "Dim_ScreeningStatus", "Dim_SocialNetwork",
    "Dim_State_and_Province", "Dim_ThreeDsResponseTypes", "Dim_VerificationLevel",
    "Dim_VerificationStatus", "Dim_WorldCheck",
}


def candidate_dim(col: str) -> str | None:
    if not col.lower().endswith("id"):
        return None
    base = col[:-2]
    if not base:
        return None
    return f"Dim_{base}"


def main() -> None:
    from collections import Counter
    cnt: Counter[str] = Counter()
    with AUDIT.open(encoding="utf-8") as f:
        for r in csv.DictReader(f):
            cnt[r["column"]] += 1

    resolved = []
    unresolved = []
    not_id_suffix = []
    for col, n in cnt.most_common():
        if not col.lower().endswith("id"):
            not_id_suffix.append((col, n))
            continue
        dim = candidate_dim(col)
        if dim in KNOWN_DIMS:
            resolved.append((col, dim, n))
        else:
            unresolved.append((col, dim, n))

    print(f"In-scope claims-bearing columns: {len(cnt)}")
    print(f"  Resolved to DWH_dbo.Dim_*:     {len(resolved)}   "
          f"({sum(n for _,_,n in resolved)} claims)")
    print(f"  Unresolved (no Dim_<X>):       {len(unresolved)} "
          f"({sum(n for _,_,n in unresolved)} claims)")
    print(f"  Not *ID suffix (skipped):      {len(not_id_suffix)} "
          f"({sum(n for _,n in not_id_suffix)} claims)")
    print()
    print("Resolved (column -> Dim, claim count):")
    for col, dim, n in resolved:
        print(f"  {col:<32} -> {dim:<32} {n}")
    print()
    print("Unresolved *ID columns (top 30):")
    for col, dim, n in unresolved[:30]:
        print(f"  {col:<32} (would need {dim}) {n}")
    print()
    print("Non-*ID columns asserting codepoint claims (top 20) -- "
          "label assertions on already-decoded values, low priority:")
    for col, n in not_id_suffix[:20]:
        print(f"  {col:<32} {n}")


if __name__ == "__main__":
    main()
