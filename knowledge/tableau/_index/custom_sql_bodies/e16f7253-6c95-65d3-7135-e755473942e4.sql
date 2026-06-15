SELECT
    d.CID as CID_Deposits,
    d.PaymentDate as PaymentDate_Deposits,
    d.Amount as Amount_Deposits,
    d.DepositID as DepositID_Deposits -- Include a unique ID if available to ensure accurate counts
FROM
    main.billing.bronze_etoro_billing_deposit d
WHERE
    d.PaymentStatusID = 2 -- Successful deposits only
    AND d.Amount > 0
    AND paymentdate>= '2025-05-01'