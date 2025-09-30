USE UtilityCompany
GO

--Flag customers who are recorded as Residential but whose accounts are Commercial or Small Commercial
--data inconsistency 

--SELECT 
--	 C.CustomerID
--	,C.CustomerType
--	,A.AccountID
--	,A.CustomerType AS AccountType
--FROM DimCustomer C
--JOIN FactUsage F on C.CustomerID = F.CustomerID
--JOIN DimAccount A on A.AccountID = F.AccountID
--WHERE C.CustomerType = 'Residential'
--AND A.CustomerType IN ('Commercial', 'Small Commercial')


--Inactive accounts with recent activity
--List accounts marked as AccountStatus = 'Inactive' but still having usage transactions.

SELECT 
	 C.CustomerID
	,C.CustomerType
	,A.AccountID
	,F.UsageQuantity
FROM DimCustomer C
JOIN FactUsage F on C.CustomerID = F.CustomerID
JOIN DimAccount A on A.AccountID = F.AccountID
WHERE A.AccountStatus = 'Inactive';

--Limtation to creating dataset
--Data should include Transcations from yhe past for inactive accounts
--We could get TotalAmount (owed) and sell to 3rd party collections


--Same customer, multiple accounts
--Only Samll Commercial and Commercial can have multiple accounts according to poilicy

SELECT 
	 C.CustomerID
	,COUNT(DISTINCT A.AccountID) AS NumOfAccounts
FROM DimCustomer C
JOIN FactUsage F on C.CustomerID = F.CustomerID
JOIN DimAccount A on A.AccountID = F.AccountID
WHERE C.CustomerType IN ('Residential')
GROUP BY C.CustomerID
HAVING COUNT(DISTINCT A.AccountID) >1;

---Residents can just sign up they dont have to go through a long process like Commercial
--This can cause fraudlent sign ups
--Find Resi customers who have more than 1 account
--In this query we have more details because we use subquery

SELECT DISTINCT
      C.[CustomerID]
     ,C.[FirstName]
     ,C.[LastName]
     ,C.[SSN]
     ,C.[EmailID]
	 ,A.[AccountID]
     ,A.[CustomerType]
     ,A.[AccountNumber]
     ,A.[BillingAddress]
     ,A.[ServiceAddress]
     ,A.[RatePlan]
     ,A.[AccountStatus]
	 ,AB.NumOfAccounts
FROM [DimCustomer] C
JOIN [FactUsage] F on C.CustomerID= F.CustomerID
JOIN [DimAccount] A on A.AccountID = F.AccountID
JOIN(
SELECT 
	 C2.CustomerID
	,COUNT(DISTINCT A2.AccountID) AS NumOfAccounts
FROM DimCustomer C2
JOIN FactUsage F2 on C2.CustomerID = F2.CustomerID
JOIN DimAccount A2 on A2.AccountID = F2.AccountID
WHERE C2.CustomerType IN ('Residential')
GROUP BY C2.CustomerID
HAVING  COUNT(DISTINCT A2.AccountID) > 1)
AS AB ON C.CustomerID = AB.CustomerID;

--we can assume that a customer might have 2 service addresses and are paying bills of both
--we can flag them becasue only small commerical and commercial should be able to do this
--However a service address should not have more than 1 account linked in any case, due to fraud and escaping bills

SELECT DISTINCT
	  A.[ServiceAddress]
	  ,C.[CustomerID]
	  ,C.[CustomerType]
      ,STRING_AGG(A.AccountID, ',') AS AccountIDs
FROM [DimAccount] A
JOIN [DimCustomer] C on A.CustomerID = C.CustomerID
JOIN(
SELECT 
	 ServiceAddress
FROM DimAccount
GROUP BY ServiceAddress
HAVING COUNT (DISTINCT AccountID ) > 1
) AS AC ON A.ServiceAddress = AC.ServiceAddress
GROUP BY 
	  A.[ServiceAddress]
	  ,C.[CustomerId]
	  ,c.[CustomerType]
ORDER BY A.ServiceAddress , CustomerID;

--while two customers could be in the same complex so have 2 cutsomers and 2 accounts 
--1 customer shouldnt have the same address on 2 accounts .. this is fraud 
--FRAUD

SELECT  A.ServiceAddress
       ,C.CustomerID
       ,C.CustomerType
       ,STRING_AGG(A.AccountID, ',') AS AccountIDs
FROM DimAccount A
JOIN DimCustomer C 
    ON A.CustomerID = C.CustomerID
GROUP BY 
		 A.ServiceAddress
		,C.CustomerID
		,C.CustomerType
HAVING COUNT(DISTINCT A.AccountID) > 1 
ORDER BY A.ServiceAddress;


--REFUND ABUSE
--Find customers where the total Refund amount > total Payment (Refund Abuse)
--Find customers where the total Refund amount = total Payment (Whole Payment refunded)
--Find customers where the total Refund amount < total Payment (Partial Refund)
--Refunds are claimed when overcharged by usage --> Partial Refund

SELECT 
     A.AccountID
    ,A.ServiceAddress
    ,A.CustomerID
	,CONCAT(D.MonthName,' ',D.Year) AS FullDate
    ,SUM(CASE WHEN F.TransactionTypeID = 2 THEN F.TransactionAmount + F.TDUAmount ELSE 0 END) AS TotalPayments
    ,SUM(CASE WHEN F.TransactionTypeID = 3 THEN F.TransactionAmount + F.TDUAmount ELSE 0 END) AS TotalRefunds
    ,CASE 
        WHEN SUM(CASE WHEN F.TransactionTypeID = 3 THEN F.TransactionAmount + F.TDUAmount ELSE 0 END) 
             > SUM(CASE WHEN F.TransactionTypeID = 2 THEN F.TransactionAmount + F.TDUAmount ELSE 0 END) 
             THEN 'Refund Abuse Flag'
        WHEN SUM(CASE WHEN F.TransactionTypeID = 2 THEN F.TransactionAmount + F.TDUAmount ELSE 0 END) 
             = SUM(CASE WHEN F.TransactionTypeID = 3 THEN F.TransactionAmount + F.TDUAmount ELSE 0 END) 
             THEN 'Payment Refund'
        ELSE 'Partial Refund'
    END AS RefundAudit
FROM FactUsage F
JOIN DimAccount A ON F.AccountID = A.AccountID
JOIN DimDate D ON F.DateID = D.DateID
WHERE F.TransactionTypeID IN (2, 3)
GROUP BY 
    A.AccountID, A.ServiceAddress, A.CustomerID, CONCAT(D.MonthName,' ',D.Year)
HAVING 
	SUM(CASE WHEN F.TransactionTypeID = 3 THEN F.TransactionAmount + F.TDUAmount ELSE 0 END) > 0
ORDER BY 
   FullDate ASC;


--Companies with Outstanding Balances > $1000
--Balance = Total Billed + Late Fees – Total Payments – Total Refunds (include TDU with all)
--There is no TDU with Late Fees
--TDU are charged by the Energy Supplier/ This company is a retailer 

SELECT 
    C.[CustomerID]
   ,CONCAT(C.FirstName,' ',C.LastName) AS FullName
   ,C.[CustomerType] 
   ,CASE WHEN C.[CompanyName] = '' THEN 'RESIDENT' ELSE C.[CompanyName] END AS CompanyName -- catching any data inconsistency
   ,C.PhoneNumber
   ,C.EmailID
   ,COUNT(DISTINCT A.AccountID) AS NumOfAccounts

   ,SUM(CASE WHEN F.[TransactionTypeID] = 1 THEN F.TransactionAmount + F.TDUAmount ELSE 0 END) AS TotalBilled
   ,SUM(CASE WHEN F.[TransactionTypeID] = 2 THEN F.TransactionAmount + F.TDUAmount ELSE 0 END) AS TotalPayments
   ,SUM(CASE WHEN F.[TransactionTypeID] = 3 THEN F.TransactionAmount + F.TDUAmount ELSE 0 END) AS TotalRefunds
   ,SUM(CASE WHEN F.[TransactionTypeID] = 4 THEN F.TransactionAmount ELSE 0 END) AS TotalLateFees
   
   ,SUM(CASE WHEN F.[TransactionTypeID]  = 1 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END)
   -SUM(CASE WHEN F.[TransactionTypeID]  = 2THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END) 
   -SUM(CASE WHEN F.[TransactionTypeID]  = 3 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END)
   +SUM(CASE WHEN F.[TransactionTypeID]  = 4 THEN F.[TransactionAmount] ELSE 0 END) AS AmountDue

FROM FactUsage F
JOIN DimAccount A ON F.[AccountID] = A.[AccountID]
JOIN DimCustomer C ON A.[CustomerID] = C.[CustomerID]
WHERE C.[CustomerType] IN ('Small Commercial', 'Commercial') 
AND C.[CCC] = 'N'
GROUP BY 
     C.[CustomerID]
	,C.[FirstName]
	,C.[LastName]
	,C.[CompanyName]
	,C.[CustomerType]
	,C.[PhoneNumber]
	,C.[EmailID]
HAVING 
    SUM(CASE WHEN F.[TransactionTypeID]  = 1 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END)
   -SUM(CASE WHEN F.[TransactionTypeID]  = 2 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END) 
   -SUM(CASE WHEN F.[TransactionTypeID]  = 3 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END)
   +SUM(CASE WHEN F.[TransactionTypeID]  = 4 THEN F.[TransactionAmount]  ELSE 0 END) 
 > 1000

ORDER BY AmountDue DESC;

--RESIDENTS with Outstanding balance > $100 HAT ARE NOT CCC

SELECT 
    C.[CustomerID]
   ,CONCAT(C.FirstName,' ',C.LastName) AS FullName
   ,C.[CustomerType] 
   ,C.PhoneNumber
   ,C.EmailID
   ,COUNT(DISTINCT A.AccountID) AS NumOfAccounts

   ,SUM(CASE WHEN F.[TransactionTypeID] = 1 THEN F.TransactionAmount + F.TDUAmount ELSE 0 END) AS TotalBilled
   ,SUM(CASE WHEN F.[TransactionTypeID] = 2 THEN F.TransactionAmount + F.TDUAmount ELSE 0 END) AS TotalPayments
   ,SUM(CASE WHEN F.[TransactionTypeID] = 3 THEN F.TransactionAmount + F.TDUAmount ELSE 0 END) AS TotalRefunds
   ,SUM(CASE WHEN F.[TransactionTypeID] = 4 THEN F.TransactionAmount ELSE 0 END) AS TotalLateFees
   
   ,SUM(CASE WHEN F.[TransactionTypeID]  = 1 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END)
   -SUM(CASE WHEN F.[TransactionTypeID]  = 2 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END) 
   -SUM(CASE WHEN F.[TransactionTypeID]  = 3 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END)
   +SUM(CASE WHEN F.[TransactionTypeID]  = 4 THEN F.[TransactionAmount] ELSE 0 END) AS AmountDue

FROM FactUsage F
JOIN DimAccount A ON F.[AccountID] = A.[AccountID]
JOIN DimCustomer C ON A.[CustomerID] = C.[CustomerID]
WHERE C.[CustomerType] IN ('Residential') 
AND C.[CCC] = 'N'
GROUP BY 
     C.[CustomerID]
	,C.[FirstName]
	,C.[LastName]
	,C.[CompanyName]
	,C.[CustomerType]
	,C.[PhoneNumber]
	,C.[EmailID]
HAVING 
    SUM(CASE WHEN F.[TransactionTypeID]  = 1 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END)
   -SUM(CASE WHEN F.[TransactionTypeID]  = 2 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END) 
   -SUM(CASE WHEN F.[TransactionTypeID]  = 3 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END)
   +SUM(CASE WHEN F.[TransactionTypeID]  = 4 THEN F.[TransactionAmount] ELSE 0 END)
 > 100
ORDER BY AmountDue DESC;

--Critical Care with late fees
--Critical Care customers should ideally not have service interruptions. 
--Find all Critical Care Residential customers who were ever charged a Late Fee.
--Waive Late Fee

 SELECT  C.[CustomerID]
		,CONCAT(C.FirstName,' ',C.LastName) AS FullName
		,C.[CustomerType] 
		,CASE WHEN C.[CompanyName] = '' THEN 'RESIDENT' ELSE C.[CompanyName] END AS CompanyName
		,C.[PhoneNumber]
		,C.[EmailID]		
		,C.[CCC]
		,SUM(CASE WHEN F.[TransactionTypeID] = 4 THEN F.TransactionAmount + F.TDUAmount ELSE 0 END) AS TotalLateFees
FROM FactUsage F
JOIN DimCustomer C ON F.[CustomerID] = C.[CustomerID]
WHERE C.[CCC] = 'Y'
GROUP BY C.[CustomerID]
		,C.[FirstName]
		,C.[LastName]
		,C.[CustomerType] 
		,C.[CompanyName]
		,C.[PhoneNumber]
		,C.[EmailID]		
		,C.[CCC]
HAVING SUM(CASE WHEN F.[TransactionTypeID] = 4 THEN F.TransactionAmount + F.TDUAmount ELSE 0 END) > 0

--Critical Care total TDU charges
--Company Charges Bill + TDU 
--We can submit to enrgy provider and get the reimbursed 

SELECT C.CustomerID
	  ,CONCAT(C.FirstName,' ',C.LastName) AS FullName
--    ,C.EmailID
      ,C.PhoneNumber
      ,SUM(CASE WHEN F.TransactionTypeID = 1 THEN F.TDUAmount ELSE 0 END) AS TotalTDUCharged
      ,SUM(CASE WHEN F.TransactionTypeID = 2 THEN F.TDUAmount ELSE 0 END) AS TotalTDUPaid
      ,SUM(CASE WHEN F.TransactionTypeID = 1 THEN F.TDUAmount ELSE 0 END)
    -  SUM(CASE WHEN F.TransactionTypeID = 2 THEN F.TDUAmount ELSE 0 END) AS TDUVariance
FROM FactUsage F
JOIN DimAccount A ON F.AccountID = A.AccountID
JOIN DimCustomer C ON A.CustomerID = C.CustomerID
WHERE C.[CCC] = 'Y'  
GROUP BY 
    C.CustomerID,
    C.FirstName,
    C.LastName,
--	C.EmailID,
    C.PhoneNumber
HAVING       
	   SUM(CASE WHEN F.TransactionTypeID = 1 THEN F.TDUAmount ELSE 0 END)
    -  SUM(CASE WHEN F.TransactionTypeID = 2 THEN F.TDUAmount ELSE 0 END) > 0
ORDER BY TotalTDUCharged DESC;


--WE WANT TO SEE OUR TOP 5 CONSUMERS 
SELECT  CustomerID
       ,CONCAT(FirstName,' ',LastName) AS FullName
       ,CompanyName
       ,TotalConsumption
       ,AmountDue
FROM (
    SELECT 
        C.CustomerID
       ,C.FirstName
       ,C.LastName
       ,C.CompanyName
       ,SUM(F.UsageQuantity) AS TotalConsumption
       ,SUM(CASE WHEN F.[TransactionTypeID]  = 1 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END)
       -SUM(CASE WHEN F.[TransactionTypeID]  = 2 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END) 
       -SUM(CASE WHEN F.[TransactionTypeID]  = 3 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END)
       +SUM(CASE WHEN F.[TransactionTypeID]  = 4 THEN F.[TransactionAmount] + F.TDUAmount ELSE 0 END) AS AmountDue
       ,RANK() OVER (ORDER BY SUM(F.UsageQuantity) DESC) AS ConsumptionRank
    FROM FactUsage F
    JOIN DimAccount A ON F.AccountID = A.AccountID
    JOIN DimCustomer C ON A.CustomerID = C.CustomerID
    WHERE F.TransactionTypeID = 1   -- only billed usage
    GROUP BY 
        C.CustomerID,
        C.FirstName,
        C.LastName,
        C.CompanyName
) AS R1
WHERE ConsumptionRank <= 5
ORDER BY ConsumptionRank Desc;


--Late payment detection (using dates)
--Find transactions where the CreateDate is later than the billing DateID (simulating overdue payments).
--30 days , 60 days, 90 daysand over 90 days simulating an aging  report  **Never Paid a bill


