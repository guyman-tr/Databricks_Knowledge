"""Build a single UNION ALL query that pulls (column, codepoint, Name) tuples
from all 41 resolved DWH_dbo.Dim_* dictionaries. Output is plain SQL written
to stdout so the operator can paste into the MCP runner."""
from __future__ import annotations

# (column_in_wikis, dim_table, id_col, name_col)
DIM_MAP: list[tuple[str, str, str, str]] = [
    ("AccountStatusID", "Dim_AccountStatus", "AccountStatusID", "AccountStatusName"),
    ("AccountTypeID", "Dim_AccountType", "AccountTypeID", "Name"),
    ("ActionTypeID", "Dim_ActionType", "ActionTypeID", "Name"),
    ("BonusTypeID", "Dim_BonusType", "BonusTypeID", "Name"),
    ("CardTypeID", "Dim_CardType", "CardTypeID", "CarTypeName"),
    ("CashoutFeeGroupID", "Dim_CashoutFeeGroup", "CashoutFeeGroupID", "CashoutFeeGroupName"),
    ("CashoutModeID", "Dim_CashoutMode", "CashoutModeID", "CashoutModeName"),
    ("CashoutStatusID", "Dim_CashoutStatus", "CashoutStatusID", "Name"),
    ("ClosePositionReasonID", "Dim_ClosePositionReason", "ClosePositionReasonID", "Name"),
    ("ContractTypeID", "Dim_ContractType", "ContractTypeID", "Name"),
    ("CountryID", "Dim_Country", "CountryID", "Name"),
    ("CreditTypeID", "Dim_CreditType", "CreditTypeID", "CreditTypeName"),
    ("CurrencyID", "Dim_Currency", "CurrencyID", "Name"),
    ("CustomerChangeTypeID", "Dim_CustomerChangeType", "CustomerChangeTypeID", "Name"),
    ("DocumentStatusID", "Dim_DocumentStatus", "DocumentStatusID", "DocumentStatusName"),
    ("EvMatchStatusID", "Dim_EvMatchStatus", "EvMatchStatusID", "EvMatchStatusName"),
    ("FundTypeID", "Dim_FundType", "FundTypeID", "FundTypeName"),
    ("FundingTypeID", "Dim_FundingType", "FundingTypeID", "Name"),
    ("GuruStatusID", "Dim_GuruStatus", "GuruStatusID", "GuruStatusName"),
    ("InstrumentID", "Dim_Instrument", "InstrumentID", "Name"),
    ("LabelID", "Dim_Label", "LabelID", "Name"),
    ("LanguageID", "Dim_Language", "LanguageID", "Name"),
    ("MifidCategorizationID", "Dim_MifidCategorization", "MifidCategorizationID", "Name"),
    ("MirrorTypeID", "Dim_MirrorType", "MirrorTypeID", "MirrorTypeName"),
    ("MoveMoneyReasonID", "Dim_MoveMoneyReason", "MoveMoneyReasonID", "MoveMoneyReason"),
    ("PaymentStatusID", "Dim_PaymentStatus", "PaymentStatusID", "Name"),
    ("PendingClosureStatusID", "Dim_PendingClosureStatus", "PendingClosureStatusID", "PendingClosureStatusName"),
    ("PhoneVerifiedID", "Dim_PhoneVerified", "PhoneVerifiedID", "PhoneVerifiedName"),
    ("PlatformID", "Dim_Platform", "PlatformID", "Platform"),
    ("PlatformTypeID", "Dim_PlatformType", "ProductID", "Platform"),
    ("PlayerLevelID", "Dim_PlayerLevel", "PlayerLevelID", "Name"),
    ("PlayerStatusID", "Dim_PlayerStatus", "PlayerStatusID", "Name"),
    ("ProductID", "Dim_Product", "ProductID", "Product"),
    ("RegulationID", "Dim_Regulation", "ID", "Name"),
    ("RiskClassificationID", "Dim_RiskClassification", "RiskClassificationID", "RiskClassificationName"),
    ("RiskManagementStatusID", "Dim_RiskManagementStatus", "RiskManagementStatusID", "Name"),
    ("RiskStatusID", "Dim_RiskStatus", "RiskStatusID", "Name"),
    ("ScreeningStatusID", "Dim_ScreeningStatus", "ScreeningStatusID", "Name"),
    ("SocialNetworkID", "Dim_SocialNetwork", "SocialNetworkID", "Name"),
    ("VerificationLevelID", "Dim_VerificationLevel", "ID", "Name"),
    ("WorldCheckID", "Dim_WorldCheck", "WorldCheckID", "WorldCheckName"),
]


def main() -> None:
    parts: list[str] = []
    for col, dim, id_col, name_col in DIM_MAP:
        parts.append(
            f"SELECT '{col}' AS column_name, "
            f"CAST([{id_col}] AS NVARCHAR(16)) AS codepoint, "
            f"CAST([{name_col}] AS NVARCHAR(256)) AS truth_name "
            f"FROM DWH_dbo.[{dim}]"
        )
    sql = "\nUNION ALL\n".join(parts) + "\nORDER BY column_name, codepoint;"
    print(sql)


if __name__ == "__main__":
    main()
