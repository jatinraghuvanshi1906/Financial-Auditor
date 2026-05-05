import streamlit as st
import psycopg2
import pandas as pd
from utils.email_alert import send_fraud_alert_email

# PostgreSQL connection
def get_conn():
    return psycopg2.connect(
        dbname="Audit_project",
        user="postgres",
        password="root",
        host="localhost",
        port="5432"
    )

def get_data(query):
    conn = get_conn()
    df = pd.read_sql(query, conn)
    conn.close()
    return df

# Page Header AND Sidebar Filter
st.title("Financial Results")
st.sidebar.header("Filters")
issue_types = get_data("SELECT DISTINCT issue_type FROM audit_results")
issue_list = ["All"] + issue_types["issue_type"].dropna().tolist()
selected_issue = st.sidebar.selectbox("Issue Type", issue_list)

# FILTER CONDITION
filter_condition = ""
safe_issue = ""
if selected_issue != "All":
    safe_issue = selected_issue.replace("'", "''")
    filter_condition = f"WHERE issue_type = '{safe_issue}'"

# IMPORTANT VALUES
customers = get_data("SELECT COUNT(*) AS count FROM customers")
transactions = get_data("SELECT COUNT(*) AS count FROM transactions")
audit_issues = get_data(f"""SELECT COUNT(*) AS count FROM audit_results {filter_condition}""")
fraud_flags = get_data(f"""SELECT COUNT(*) AS count FROM fraud_flags {"WHERE issue_type = '" + safe_issue + "'" if selected_issue != "All" else ""}""")
impact = get_data(f"""SELECT COALESCE(SUM(impact_amount),0) AS total_impact FROM audit_results {filter_condition}""")
high_severity = get_data(f"""SELECT COUNT(*) AS cnt FROM audit_results {filter_condition + " AND" if filter_condition else "WHERE"} LOWER(severity) = 'high'""")

col1, col2, col3, col4, col5 = st.columns(5)

col1.metric("Customers", int(customers.iloc[0]["count"]))
col2.metric("Transactions", int(transactions.iloc[0]["count"]))
col3.metric("Audit Issues", int(audit_issues.iloc[0]["count"]))
col4.metric("Fraud Flags", int(fraud_flags.iloc[0]["count"]))
col5.metric("Impact (₹)", int(impact.iloc[0]["total_impact"]))

st.markdown(f"High Severity Issues: {int(high_severity.iloc[0]['cnt'])}")

# AUDIT SUMMARY
st.markdown("---")
st.subheader("Audit Summary")
summary = get_data(f"""SELECT issue_type, COUNT(*) AS total_count
FROM audit_results
{filter_condition}
GROUP BY issue_type
ORDER BY total_count DESC
""")
if not summary.empty:
    #st.bar_chart(summary.set_index("issue_type"))
    st.bar_chart(summary,x='issue_type',y='total_count',x_label="Issue Type",y_label="Issue Count")

# Insights on Issue Type count
st.markdown("---")
st.subheader("Key Insights")
insights = get_data(f"""SELECT issue_type, COUNT(*) AS cnt, COALESCE(SUM(impact_amount),0) AS impact
FROM audit_results
{filter_condition}
GROUP BY issue_type
ORDER BY impact DESC
LIMIT 3""")

if not insights.empty:
    insights["impact"] = insights["impact"].astype(int)
    insights = insights.rename(columns={
        "issue_type": "Issue Type",
        "cnt": "Total Issues",
        "impact": "Impact Amount (₹)"
    })
    st.dataframe(insights,use_container_width=True,hide_index=True)
else:
    st.warning("No insights available.")

# Fraud Alerts
st.markdown("---")
st.subheader("Fraud Alerts")
fraud_query = f"""SELECT transaction_id, issue_type, severity, created_at FROM fraud_flags
{"WHERE issue_type = '" + safe_issue + "'" if selected_issue != "All" else ""}
ORDER BY created_at DESC
LIMIT 10"""
fraud = get_data(fraud_query)
if not fraud.empty:
    st.dataframe(fraud, use_container_width=True,
                 hide_index=True)
else:
    st.success("No fraud alerts detected.")

# Display Anomalies (High value in transactions = suspicious or possible fraud)
st.markdown("---")
st.subheader("High Value Transactions")
anomalies = get_data("""SELECT transaction_id, customer_id, amount, created_at FROM transactions
WHERE amount > (SELECT AVG(amount) + 3 * STDDEV(amount) FROM transactions)
ORDER BY amount DESC
LIMIT 20""")

if not anomalies.empty:
    st.dataframe(anomalies, use_container_width=True,hide_index=True)

# Audit Table results display
st.markdown("---")
st.subheader("Recent Audit Results")
logs = get_data(f"""SELECT issue_type, rule_name, record_id, issue_details,severity, impact_amount, created_at FROM audit_results
{filter_condition}
ORDER BY created_at DESC
LIMIT 50""")
st.dataframe(logs,use_container_width=True,hide_index=True)

# Email Alert
email = st.session_state.get("alert_email", "")
ai_insights = st.session_state.get("ai_insights", None)
if not email:
    st.warning("Please enter email address in Home page first.")
include_ai = st.checkbox("Include AI Insights in Audit Report")
if st.button("Send Report"):
    # Validation
    if include_ai and not ai_insights:
        st.error("Please generate AI Insights from Home page before sending report.")
        st.stop()
    fraud_count = int(fraud_flags.iloc[0]["count"])
    total_impact = int(impact.iloc[0]["total_impact"])
    high_count = int(high_severity.iloc[0]["cnt"])
    sent = send_fraud_alert_email(email,fraud_count,total_impact,high_count,ai_insights if include_ai else None)
    if sent:
        st.success(f"Audit report sent to {email}")
    else:
        st.error("Failed to send email")