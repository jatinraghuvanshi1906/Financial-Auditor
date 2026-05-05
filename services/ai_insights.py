import requests
import requests

# Ftn to generate findings based on the i/p data and suggest action plan to overcome the underlying issues
def generate_audit_insights(total_issues, total_impact, fraud_count, high_severity, recent_issues):
    issues_text = ""
    for _, row in recent_issues.iterrows():
        issues_text += f"- {row['issue_type']} | Severity: {row['severity']} | Impact: {row['impact_amount']}\n"
    prompt = f"""You are a senior financial auditor presenting findings to executives.

    Total Issues: {total_issues}
    Total Impact: {total_impact}
    Fraud Cases: {fraud_count}
    High Severity Issues: {high_severity}

    Recent Issues:
    {issues_text}

    Provide:
    1. Top 3 Key Insights
    2. Critical Risks
    3. Immediate Action Plan"""

    try:
        response = requests.post("http://localhost:11434/api/generate",
            json={"model": "phi3","prompt": prompt,"stream": False},timeout=300)
        if response.status_code == 200:
            return response.json()["response"]
        return "AI service returned an unexpected response."
    except Exception as e:
        return f"Ollama Error: {str(e)}"