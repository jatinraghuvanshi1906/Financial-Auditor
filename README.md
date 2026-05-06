# Financial-Auditor
Financial Audit System
This is  end-to-end automated system that ingests raw data , identifies anomalies and generate actionable AI insights. System visualizes generated audit results ,predicts future revenue patterns.  And sends report via email  to user in an interactive Streamlit dashboard connected to database via PostgresSQL.

# Project Structure
Audit_project/
│
├── home.py
├── Input data
|   └── accounts.csv
|   └── transactions.csv
|   └── invoices.csv
|   └── payments.csv
|   └── accounts.csv
├── SQL Scripts
|   └── TableSetup.sql
|   └── Staging_table.py
|   └── clean_validating_data.sql
|   └── full_audit_inserts.py
├── pages
│   └── dataupload.py
│   └── result_board.py
├── services
│   └── ai_insights.py
├── utils
│   └── email_alert.py
├── .streamlit/
     └── config.toml

# Prerequisites
-Tools & Platforms
  IDE: Visual Studio Code
  Database: PostgreSQL
  Database GUI: pgAdmin
  Web Framework: Streamlit
-Programming
  Python (pandas, numpy, psycopg2,smtplib)
-Forecasting Model
  ARIMA
-AI Integration
  Ollama (ollama3, tinyllama,phi3)
