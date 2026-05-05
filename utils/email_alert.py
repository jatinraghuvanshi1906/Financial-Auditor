import smtplib
import markdown 
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# Ftn to generate content for audit report for frauds, severity issues & impacted amount
def send_fraud_alert_email(
    receiver_email,
    fraud_count,
    total_impact,
    high_severity_count,
    ai_insights=None
):
    sender_email = "jatinraghuvanshi1906@gmail.com"     #senders email
    sender_password = "wizb ifgf cvya gqsm"             # app generated gmail password 
    subject = "Financial Audit Fraud Alert"

    # Convert AI insights to HTML
    ai_html = ""
    if ai_insights:
        ai_html = markdown.markdown(
            ai_insights.strip(),
            extensions=["extra", "sane_lists"]
        )

    # HTML email template
    body = f"""
    <html>
    <body style="font-family:Arial, sans-serif; line-height:1.6; color:#333;">
        <h2 style="color:#2F5597;">Financial Audit Report</h2>
        <p>Hello,</p>
        <h3>Summary</h3>
        <table style="border-collapse:collapse; width:100%; max-width:500px;">
            <tr>
                <td><b>Total Fraud Flags:</b></td>
                <td>{fraud_count}</td>
            </tr>
            <tr>
                <td><b>High Severity Issues:</b></td>
                <td>{high_severity_count}</td>
            </tr>
            <tr>
                <td><b>Financial Impact:</b></td>
                <td>₹{total_impact}</td>
            </tr>
        </table>
        <hr>
        {"<h3>AI Insights</h3>" + ai_html if ai_html else ""}
        <br>
        <p>Regards,<br>
        <b>Financial Audit Monitoring System</b></p>
    </body>
    </html>
    """
    try:
        msg = MIMEMultipart()
        msg["From"] = sender_email
        msg["To"] = receiver_email
        msg["Subject"] = subject
        #Send HTML (now properly formatted)
        msg.attach(MIMEText(body, "html"))
        server = smtplib.SMTP("smtp.gmail.com", 587)
        server.starttls()
        server.login(sender_email, sender_password)
        server.sendmail(
            sender_email,
            receiver_email,
            msg.as_string()
        )
        server.quit()
        return True
    except Exception as e:
        print("Email Error:", e)
        return False