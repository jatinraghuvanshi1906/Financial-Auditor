import streamlit as st
import psycopg2
import pandas as pd
import time

# Page Title
st.title("Financial Data Upload")

# PostgreSQL connection
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

# Multiple csv files upload
st.markdown("---")
st.subheader("📂 Upload Financial Files")

uploaded_files = st.file_uploader("Upload CSV Files for (customers, transactions, invoices, payments, accounts)", type=["csv"], accept_multiple_files=True)
if uploaded_files:
    file_map = {}
    for file in uploaded_files:
        file_name = file.name.lower()
        try:
            df = pd.read_csv(file)
            # Standarizing column names
            df.columns = [col.strip().lower() for col in df.columns]

            # Fixing date columns
            if "created_at" in df.columns:
                df["created_at"] = pd.to_datetime(df["created_at"], dayfirst=True, errors="coerce")
            if "invoice_date" in df.columns:
                df["invoice_date"] = pd.to_datetime(df["invoice_date"], dayfirst=True, errors="coerce").dt.date
            if "payment_date" in df.columns:
                df["payment_date"] = pd.to_datetime(df["payment_date"], dayfirst=True, errors="coerce")

            # Numeric column cleanup
            numeric_columns = [
                "customer_id",
                "transaction_id",
                "payment_id",
                "account_id",
                "invoice_id",
                "payment_method_id",
                "product_id",
                "item_id",
                "amount",
                "balance",
                "price",
                "quantity",
                "total_amount"
            ]
            for col in numeric_columns:
                if col in df.columns:
                    df[col] = (df[col].astype(str).str.strip().str.replace(r"[^0-9a-zA-Z.\-]", "", regex=True).replace("", None))

            # FINAL CLEANUP
            df = df.astype(object).where(pd.notnull(df), None)

            # Customer table phonenumber column cleanup
            if "phone" in df.columns:
                df["phone"] = (
                    df["phone"]
                    .astype(str)
                    .str.replace(r"[^0-9+]", "", regex=True)
                    .str[:15]
                    .replace("", None)
                )

            # Detect table name from uploaded csv files
            if "customer" in file_name:
                table = "customers"
            elif "transaction" in file_name:
                table = "transactions"
            elif "account" in file_name:
                table = "accounts"
            elif "payment" in file_name:
                table = "payments"
            elif "invoice" in file_name:
                table = "invoices"
            else:
                st.warning(f"Could not map file: {file.name}")
                continue
            file_map[table] = df
            st.write(f"✅ Loaded: {file.name} → {table}")
            st.write(f"Total Rows: {len(df)}")
            #st.write("Detected Columns:", df.columns.tolist())
            st.dataframe(df.head(20),use_container_width=True,hide_index=True)
        except Exception as e:
            st.error(f"Error reading {file.name}: {e}")

    # Run Button
    if st.button("Run Audit"):
        try:
            conn = get_conn()
            cur = conn.cursor()
            # STEP 1: Upload CSV → STAGING TABLES
            for table, df in file_map.items():
                st.write(f"Processing {table}...")
                # Clear staging table data first
                cur.execute(f"DELETE FROM stg_{table}")
                # INSERTION using column names
                columns = ",".join(df.columns)
                placeholders = ",".join(["%s"] * len(df.columns))
                for _, row in df.iterrows():
                    values = tuple(
                        None
                        if x is None or str(x).strip().lower() in ["nan", "none", ""]
                        else str(x).strip()
                        for x in row
                    )
                    cur.execute(f"""INSERT INTO stg_{table} ({columns}) VALUES ({placeholders})""", values)
            conn.commit()
            # STEP 2: RUN CLEAN + VALIDATION SQL
            st.write("Running cleaning & validation process...")
            with open("D:/Financial_Auditor/SQL/clean_validating_data.sql","r") as f:
                sql_commands = f.read().split(";")
                for command in sql_commands:
                    command = command.strip()
                    if command and not command.startswith("--"):
                        cur.execute(command)
            conn.commit()
            # STEP 3: RUN AUDIT ENGINE
            st.write("Running audit engine...")
            with open("D:/Financial_Auditor/SQL/full_audit_inserts.sql","r") as f:
                sql_commands = f.read().split(";")
                for command in sql_commands:
                    command = command.strip()
                    if command and not command.startswith("--"):
                        cur.execute(command)
            conn.commit()
            conn.close()
            st.success("Upload successful & Audit completed")
            time.sleep(2)
            st.rerun()
        except Exception as e:
            st.error(f"Upload failed: {e}")