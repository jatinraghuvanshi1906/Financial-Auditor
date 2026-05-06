# Financial-Auditor
Financial auditor system for fraud detection &amp; AI insights that ingests business data, identifies anomalies using SQL + ML + LLM insights, and visualizes actionable risk intelligence through an interactive Streamlit dashboard.

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
  Python (pandas, numpy, psycopg2)
-Forecasting Model
  ARIMA
-AI Integration
  Ollama (ollama3, tinyllama,phi3)
