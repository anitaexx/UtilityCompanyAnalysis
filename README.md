🧾 README.md
Utility Company Data Analysis

By Anita Eimiakhena (anitaexx)

📊 Project Overview

The Utility Company Analysis project demonstrates end-to-end data analytics — from data modeling and transformation using SQL and Python, to visualization and KPI tracking in Power BI.
This simulation replicates a real-world utility company’s data environment, focusing on billing accuracy, data consistency, customer segmentation, and aging reports for decision support.

🎯 Business Objectives

Flag inconsistent data: Identify customers labeled as Residential in DimCustomer but with Commercial accounts in DimAccount.
Inactive accounts with recent activity: Detect inactive accounts still recording usage transactions.
Duplicate or shared accounts: Find customers with multiple accounts or identical service addresses.
Refund abuse detection: Highlight customers with total refunds greater than payments.
Outstanding balance tracking: Calculate and flag customers with balances exceeding $1,000.
Aging report: Generate 30/60/90/90+ day outstanding reports.
Critical care compliance: Identify critical care customers charged late fees or eligible for TDU reimbursements.

🧠 Key Insights & Impact

Improved data quality by detecting inconsistencies across customer and account dimensions.
Automated aging report generation for faster finance reviews.
Built SQL scripts for ETL and data validation.
Created an interactive Power BI dashboard to visualize KPIs: late fees, outstanding balances, and refund ratios.
Leveraged Python automation to generate and update CSV datasets dynamically.

⚙️ Tech Stack
Tool	Purpose
SQL Server	Database creation, DDL/DML operations, KPI queries
Python (Pandas, Faker)	Synthetic data generation and ETL scripting
Power BI	Dashboard and KPI reporting
Excel	Data validation and aging analysis
Git & GitHub	Version control and portfolio hosting

📂 Project Files

File	Description

UtilityCompanyDDL.sql	Database schema creation (Dim/Fact tables)
UtilityCompanyDML.sql	Insert and transformation queries
UtilityCompanyAgingReport.sql	Aging calculation and outstanding balance logic
DimAccountGeneration.py	Python script to generate synthetic account data
FactUsageGeneration.py	Python script to generate usage transaction data
DimAccount.csv, DimCustomer.csv, FactUsage.csv	Raw and transformed datasets
UtilityCompanypbix.Report / .SemanticModel / .pbip	Power BI project files
.gitignore	Excluded files for version control

📈 Power BI Dashboard Highlights

Customer Overview: Residential vs. Commercial segmentation
Refund & Payment Summary: Trends by customer type
Critical Care KPI Tracker: Monitoring TDU reimbursements and late fees

🚀 How to Reproduce

Clone this repository:
git clone https://github.com/anitaexx/UtilityCompanyAnalysis.git
Run the SQL scripts in order:
UtilityCompanyDDL.sql
UtilityCompanyDML.sql
UtilityCompanyAgingReport.sql
Execute Python scripts to populate CSVs.

Open the Power BI report (UtilityCompanypbix.pbip) and connect to the data model.

💡 Future Improvements

Integrate Power Automate to refresh reports automatically.
Connect Power BI directly to SQL Server for real-time insights.
Implement anomaly detection with Python or DAX measures.

