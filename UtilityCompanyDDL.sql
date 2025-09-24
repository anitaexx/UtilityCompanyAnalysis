---Creating 4 Tables---

--------------------------
---The Customer Table---
--------------------------
USE [UtilityCompany];
GO

CREATE TABLE DimCustomer (
	CustomerID INT IDENTITY(1,1) PRIMARY KEY,
	CreateDate DATE,
	CustomerType NVARCHAR(50),
	CCC	NVARCHAR(50),
	FirstName NVARCHAR(50),
	LastName NVARCHAR(50),
	DOB	DATE,
	BusinessNumber NVARCHAR(50) NULL,
	SSN	NVARCHAR(50) NULL,
	CompanyName NVARCHAR(50) NULL,	
	EmailID	NVARCHAR(100),
	PhoneNumber NVARCHAR(100),
	Address	NVARCHAR(100),
	City NVARCHAR(100),
	State NVARCHAR(50),
	Country NVARCHAR(50)
);

--------------------------
---Account Table---
--------------------------
USE [UtilityCompany];
GO

CREATE TABLE DimAccount (
	AccountID INT PRIMARY KEY,
	CreateDate DATE,
	CustomerID INT NOT NULL,
	CustomerType NVARCHAR(50),
	AccountNumber NVARCHAR(50),
	BillingAddress NVARCHAR(max),
	ServiceAddress NVARCHAR(max),
	ServiceType	NVARCHAR(100),
	RatePlan NVARCHAR(50),
	AccountStatus NVARCHAR(50),
	FOREIGN KEY (CustomerID) REFERENCES DimCustomer(CustomerID)
);

-------------------------------
---The Transction Type Table---
-------------------------------
USE [UtilityCompany];
GO

CREATE TABLE DimTransactionType (
    TransactionTypeID INT PRIMARY KEY,
    TransactionName NVARCHAR(50) -- Bill, Payment, Refund, Late Fee
);

INSERT INTO DimTransactionType (TransactionTypeID, TransactionName)
values
('1', 'Bill'),
('2', 'Payment'),
('3', 'Refund'),
('4', 'Late Fee')

---------------------------
---The Transaction Table---
---------------------------
USE [UtilityCompany];
GO
--DROP TABLE IF EXISTS DimAccounts;
--GO

CREATE TABLE FactUsage (
	TransactionID BIGINT PRIMARY KEY,
	CreatedDate DATE,
	CustomerID INT,
	AccountID INT,
--	AccountNumber NVARCHAR(50),
	TransactionTypeID INT,	
	TransactionAmount DECIMAL(12,2),
	UsageQuantity DECIMAL(12,2),
	TDUAmount DECIMAL(12,2),
	FOREIGN KEY (CustomerID) REFERENCES DimCustomer(CustomerID),
	FOREIGN KEY (AccountID) REFERENCES DimAccount(AccountID),
	FOREIGN KEY (TransactionTypeID) REFERENCES DimTransactionType(TransactionTypeID)
);

---altering table to include a dateId linked to Date table--
---ALTER TABLE FactUsage
---ADD CONSTRAINT FK_FactUsage_DimDate
---FOREIGN KEY (CreatedDate) REFERENCES DimDate(FullDate);


---Alterations for the file import ---
---ALTER TABLE DimCustomer
---ALTER COLUMN CCC NVARCHAR(50);
---ALTER TABLE DimCustomer
---ALTER COLUMN SSN NVARCHAR(20);
---ALTER TABLE DimCustomer
---ALTER COLUMN PhoneNumber NVARCHAR(100);
---ALTER TABLE DimAccount
---ALTER COLUMN BillingAddress NVARCHAR(max);
---ALTER TABLE DimAccount
---ALTER COLUMN ServiceAddress NVARCHAR(max);

---selecting tables to see the data---

Select * from dbo.FactUsage;
Select * from dbo.DimAccount;
Select * from dbo.DimCustomer;
Select * from dbo.DimTransactionType;
Select * from dbo.DimDate;


----mitake wiht table recreat--
--DROP TABLE DimCustomer
--DROP TABLE DimAccount
--DROP TABLE FactUsage
--DROP TABLE DimDate
--DROP TABLE DimTransactiontype

--ALTER TABLE DimCustomer
--DROP CONSTRAINT FK_DimCustomer_Date;

--alter table FactUsage 
--drop column AccountNumber

--alter table DimAccount
--drop column CustomerID

--alter table DimAccount
--drop column DateID

--alter table DimCustomer
--drop column DateID

---1. Adding DateID to each of our tables---
---2. Adding a foregin key constraint-------

--ALTER TABLE dbo.DimCustomer ---Customer
--ADD DateID INT;
--ALTER TABLE dbo.DimCustomer 
--ADD CONSTRAINT FK_DimCustomer_Date FOREIGN KEY (DateID) REFERENCES dbo.DimDate(DateID);

--ALTER TABLE dbo.DimAccount ---Account
--ADD DateID INT;
--ALTER TABLE dbo.DimAccount
--ADD CONSTRAINT FK_DimAccount_Date FOREIGN KEY (DateID) REFERENCES dbo.DimDate(DateID);

--ALTER TABLE dbo.FactUsage ---Usage
--ADD DateID INT;
--ALTER TABLE dbo.FactUsage
--ADD CONSTRAINT FK_FactUsage_Date FOREIGN KEY (DateID) REFERENCES dbo.DimDate(DateID);

---3. Populating the new DateID columns-----
--UPDATE a
--SET a.DateID = d.DateID
--FROM dbo.DimAccount a
--JOIN dbo.DimDate d
--	ON a.CreateDate = d.FullDate

--UPDATE f
--SET f.DateID = d.DateID
--FROM dbo.FactUsage f
--JOIN dbo.DimDate d
--	ON f.CreatedDate = d.FullDate

--UPDATE c
--SET c.DateID = d.DateID
--FROM dbo.DimCustomer c
--JOIN dbo.DimDate d
--	ON c.CreateDate = d.FullDate



--Disable the FK temporarily
--ALTER TABLE dbo.DimAccount NOCHECK CONSTRAINT FK__DimAccoun__Custo__1AD3FDA4;
--ALTER TABLE dbo.FactUsage NOCHECK CONSTRAINT FK__FactUsage__Custo__1F98B2C1;
--DELETE FROM dbo.DimCustomer;

---Enable the FK enforcemnt---
--ALTER TABLE dbo.DimAccount WITH CHECK CHECK CONSTRAINT FK__DimAccoun__Custo__1AD3FDA4;
--ALTER TABLE dbo.FactUsage WITH CHECK CHECK CONSTRAINT FK__FactUsage__Custo__1F98B2C1;

--ALTER TABLE FactUsage
--DROP CONSTRAINT FK__FactUsage__Custo__1F98B2C1;



---- System Query to get constraint name--
--SELECT 
--    name, 
--    parent_object_id 
--FROM sys.foreign_keys
--WHERE parent_object_id = OBJECT_ID('DimAccount');
