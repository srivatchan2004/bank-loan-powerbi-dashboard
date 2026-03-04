# 🏦 Bank Loan Report | Power BI Dashboard

An interactive two-page Power BI dashboard analyzing bank loan data — covering application trends, loan quality, funding amounts, and borrower demographics.

---

## 🖼️ Dashboard Preview

### Page 1 – Summary
![Bank Loan Summary](images/summary.png)

### Page 2 – Overview
![Bank Loan Overview](images/overview.png)

---

## 📁 Repository Structure

```
bank-loan-dashboard/
├── README.md
├── bank_loan_report.pbix        ← Power BI report file
├── data/
│   └── bank_loan_data.csv       ← Source dataset
└── images/
    ├── summary.png              ← Summary page screenshot
    └── overview.png             ← Overview page screenshot
```

---

## 📌 Dashboard Pages

### 1. Bank Loan Report | Summary
High-level KPIs and loan quality breakdown.

| KPI | Value |
|---|---|
| Total Loan Applications | 38.6K (MTD: 4.3K, MoM: 6.9%) |
| Total Funded Amount | $435.8M (MTD: $54.0M, MoM: 13.0%) |
| Total Amount Received | $473.1M (MTD: $58.1M, MoM: 15.8%) |
| Average Interest Rate | 12.0% (MTD: 12.4%, MoM: 3.5%) |
| Average DTI | 13.3% (MTD: 13.7%, MoM: 2.7%) |

**Good vs Bad Loan Split:**
- ✅ **Good Loans:** 86.2% → 33.2K applications, $370.2M funded, $435.8M received
- ❌ **Bad Loans:** 13.8% → 5.3K applications, $65.5M funded, $37.3M received

**Loan Status Table:** Current, Charged Off, Fully Paid — with Funded Amount, Amount Received, MTD figures, Avg. Interest Rate, and Avg. DTI

**Filters:** State, Grade, Good vs Bad Loan

---

### 2. Bank Loan Report | Overview
Trend and distribution analysis across multiple dimensions.

- **By Month:** Loan applications trend line (Jan–Dec) showing steady growth peaking in Dec
- **By State:** US choropleth map highlighting high-volume states (California leads)
- **By Term:** Donut chart — 36 months vs 60 months split
- **By Employee Length:** Bar chart — 10+ years borrowers are the largest segment
- **By Purpose:** Bar chart — Debt consolidation is the top reason, followed by credit card and other

**Filters:** State, Grade, Good vs Bad Loan

---

## 📂 Dataset

| Field | Description |
|---|---|
| `loan_status` | Current / Charged Off / Fully Paid |
| `application_type` | Individual or joint application |
| `loan_amount` | Requested loan amount (USD) |
| `funded_amount` | Amount actually funded (USD) |
| `total_payment` | Total amount received from borrower |
| `interest_rate` | Annual interest rate (%) |
| `dti` | Debt-to-income ratio |
| `grade` | Loan grade assigned (A–G) |
| `purpose` | Reason for loan (debt consolidation, credit card, etc.) |
| `emp_length` | Borrower's employment length |
| `addr_state` | Borrower's state |
| `issue_d` | Loan issue date |

---

## 🛠️ Tools Used

| Tool | Purpose |
|---|---|
| Power BI Desktop | Dashboard design & DAX measures |
| CSV | Source data |
| DAX | KPI calculations (MTD, MoM %, Good/Bad loan %, DTI) |
| Power Query | Data cleaning & transformation |

---

## 🔑 Key Insights

- **86.2% of loans are Good Loans**, indicating a healthy lending portfolio
- **Debt consolidation** is the #1 loan purpose, reflecting high consumer debt refinancing demand
- **10+ year employees** are the most frequent borrowers, suggesting income stability correlates with loan applications
- **December** sees the highest monthly applications, indicating year-end financial activity
- **California** is the highest loan-volume state by a significant margin
- The **fully paid** segment (32,145 loans) vastly outnumbers charged-off loans (5,333), showing strong repayment rates

---

## 🚀 How to Use

1. Clone or download this repository
2. Open `bank_loan_report.pbix` in **Power BI Desktop**
3. Use the **State**, **Grade**, and **Good vs Bad Loan** slicers to filter data
4. Toggle between pages using the **Summary** and **Overview** buttons (top right)

---

## 📬 Contact

Feel free to connect or raise an issue for feedback or questions!
