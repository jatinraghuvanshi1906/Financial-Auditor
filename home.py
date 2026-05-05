import streamlit as st
import psycopg2
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import re
from statsmodels.tsa.arima.model import ARIMA
from services.ai_insights import generate_audit_insights

# Tab title and icon
st.set_page_config(page_title="Financial Audit Dashboard", page_icon="💳", layout="wide")

# Establishing PostgreSQL connection
def get_conn():
    return psycopg2.connect(
        dbname="Audit_project",
        user="postgres",
        password="root",
        host="localhost",
        port="5432")

def get_data(query):
    conn = get_conn()
    df = pd.read_sql(query, conn)
    conn.close()
    return df

# Dashboard configuration
def show_dashboard():
    # Header
    st.title("💳 Financial Audit Dashboard")
    st.caption("Audit monitoring with fraud detection and business insights")

    # Capturing email to sent fraud report
    email = st.text_input(
        "Enter your email address for fraud/suspicious alerts:",
        key="email_input"
    )
    # Email validation
    email_regex = r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$'
    if email:
        if re.match(email_regex, email):
            st.success("Valid email format!")
            st.session_state["alert_email"] = email
            st.write("Saved Email:", st.session_state["alert_email"])
        else:
            st.error("Please enter a valid email address.")

    # KPI Summary
    customers = get_data("SELECT COUNT(*) AS count FROM customers")
    transactions = get_data("SELECT COUNT(*) AS count FROM transactions")
    audit_issues = get_data("SELECT COUNT(*) AS count FROM audit_results")
    fraud_flags = get_data("SELECT COUNT(*) AS count FROM fraud_flags")

    col1, col2, col3, col4 = st.columns(4)
    col1.metric("Customers",int(customers.iloc[0]["count"]))
    col2.metric("Transactions",int(transactions.iloc[0]["count"]))
    col3.metric("Audit Issues",int(audit_issues.iloc[0]["count"]))
    col4.metric("Fraud Flags",int(fraud_flags.iloc[0]["count"]))

    # Audit Summary Bar graph
    st.markdown("---")
    st.subheader("Audit Summary")
    summary = get_data("""SELECT issue_type,COUNT(*) AS total_count FROM audit_results GROUP BY issue_type ORDER BY total_count DESC""")
    if not summary.empty:
        fig = px.bar(summary,x="issue_type", y="total_count", color="issue_type")
        fig.update_layout(title="Audit Summary by Issue Type",xaxis_title="Issue Type",yaxis_title="Issue Count",template="plotly_dark")
        st.plotly_chart(fig,use_container_width=True)
    else:
        st.warning("No audit summary data available.")

    # Financial Performance (Using ARIMA Model)
    st.markdown("---")
    st.subheader("Financial Performance")
    monthly_revenue = get_data("""SELECT DATE_TRUNC('month', created_at) AS month,SUM(amount) AS total_revenue
        FROM transactions
        WHERE LOWER(status) = 'success'
        GROUP BY DATE_TRUNC('month', created_at)
        ORDER BY DATE_TRUNC('month', created_at)""")
    if not monthly_revenue.empty and len(monthly_revenue) >= 6:
        df = monthly_revenue.copy()
        df["month"] = pd.to_datetime(df["month"],errors="coerce")
        df["total_revenue"] = pd.to_numeric(df["total_revenue"],errors="coerce")

        # Cleanup
        df = df.dropna()
        df = df[df["total_revenue"] > 0]
        df = df.drop_duplicates(subset=["month"])
        df = df.sort_values("month")

        # Remove extreme outliers
        if len(df) >= 6:
            q_low = df["total_revenue"].quantile(0.05)
            q_high = df["total_revenue"].quantile(0.95)

            df = df[
                (df["total_revenue"] >= q_low) &
                (df["total_revenue"] <= q_high)
            ]

        st.write("Forecast Input")
        st.dataframe(df)
        #st.write("Total Forecast Rows:", len(df))

        if len(df) >= 6:
            try:
                # Forecasting using Arima model
                model = ARIMA(df["total_revenue"], order=(1, 1, 1))
                fitted_model = model.fit()

                # Forecast next 3 months
                forecast_values = fitted_model.forecast(steps=3)
                future_dates = pd.date_range(start=df["month"].max(),periods=4,freq="ME")[1:]
                forecast_df = pd.DataFrame({"month": future_dates,"forecast": forecast_values})
                fig = go.Figure()

                # Actual Revenue
                fig.add_trace(go.Scatter(
                    x=df["month"],
                    y=df["total_revenue"],
                    mode="lines+markers",
                    name="Actual Revenue"
                ))

                # Forecast Revenue
                fig.add_trace(go.Scatter(
                    x=forecast_df["month"],
                    y=forecast_df["forecast"],
                    mode="lines+markers",
                    name="Forecast Revenue",
                    line=dict(dash="dot")
                ))
                fig.update_layout(title="Revenue Forecast",xaxis_title="Month",yaxis_title="Revenue",template="plotly_dark")
                st.plotly_chart(fig,use_container_width=True)
            except Exception as e:
                st.error(f"Forecasting failed: {str(e)}")
                revenue_fig = px.line(
                    monthly_revenue,
                    x="month",
                    y="total_revenue",
                    markers=True,
                    title="Total Revenue by Month"
                )
                st.plotly_chart(revenue_fig,use_container_width=True)
        else:
            st.warning("Not enough stable monthly data for forecasting.")
            revenue_fig = px.line(
                monthly_revenue,
                x="month",
                y="total_revenue",
                markers=True,
                title="Total Revenue by Month"
            )
            st.plotly_chart(revenue_fig,use_container_width=True)
    else:
        st.warning("Need at least 6 months of revenue data for forecasting.")

    # KPI Financial Metrics
    revenue_val = get_data("""SELECT COALESCE(SUM(amount), 0) AS val FROM transactions WHERE LOWER(status) = 'success'""")
    expense_val = get_data("""SELECT COALESCE(SUM(amount), 0) AS val FROM payments""")
    cash_val = get_data("""SELECT COALESCE(SUM(balance), 0) AS val FROM accounts""")

    total_revenue = float(revenue_val.iloc[0]["val"])
    total_expense = float(expense_val.iloc[0]["val"])
    cash_in_bank = float(cash_val.iloc[0]["val"])
    gross_margin = total_revenue - total_expense

    m1, m2, m3, m4 = st.columns(4)

    m1.metric("💰 Total Revenue",f"₹{int(total_revenue):,}")
    m2.metric("💸 Total Expense",f"₹{int(total_expense):,}")
    m3.metric("📊 Gross Margin",f"₹{int(gross_margin):,}")
    m4.metric("🏦 Cash in Bank",f"₹{int(cash_in_bank):,}")

    # Using Ollama phi3 for AI Insights
    st.markdown("---")
    st.subheader("AI Audit Insights")

    total_issues = int(audit_issues.iloc[0]["count"])
    total_impact = int(revenue_val.iloc[0]["val"])
    fraud_count = int(fraud_flags.iloc[0]["count"])
    high_severity_df = get_data("""SELECT COUNT(*) AS cnt FROM audit_results WHERE LOWER(severity) = 'high'""")
    high_severity = int(high_severity_df.iloc[0]["cnt"])
    recent_issues = get_data("""SELECT issue_type, severity, impact_amount FROM audit_results ORDER BY created_at DESC""")
    if st.button("Generate AI Insights"):
        with st.spinner("Analyzing with AI..."):
            ai_summary = generate_audit_insights(total_issues,total_impact,fraud_count,high_severity,recent_issues)
            st.session_state["ai_insights"] = ai_summary
        st.markdown(ai_summary)
        final_html = f"""
        <html>
        <body style="font-family:Arial; line-height:1.6; color:#333;">
        <h2 style="color:#2F5597;">Financial Audit Report</h2>
        {ai_summary}
        <hr>
        <p style="font-size:12px; color:gray;">
        System-generated report. Please review before action.
        </p>
        </body>
        </html>
        """

# Sidebar Navigation
home_page = st.Page(show_dashboard,title="Home",icon="🏠")
upload_page = st.Page("pages/dataupload.py",title="Data Upload",icon="📁")
result_page = st.Page("pages/result_board.py",title="Results",icon="📊")
pg = st.navigation([home_page,upload_page,result_page])
pg.run()