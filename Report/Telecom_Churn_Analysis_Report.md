# Telecom Customer Churn & Revenue Analytics
## Business Analysis Report

**Author:** Subhash Gautam, Data Analyst  
**Dataset:** IBM Telco Customer Churn — Kaggle  
**Tools:** PostgreSQL · Python (Pandas, Matplotlib, Seaborn) · Power BI  
**Date:** June 2026  
**GitHub:** [github.com/subhashgautam788-DS/Telecom-churn-revenue-analytics](https://github.com/subhashgautam788-DS/Telecom-churn-revenue-analytics)

---

## Executive Summary

A mid-sized telecommunications company analyzed here has a **26.54% customer churn rate**, resulting in **$139,130 of monthly recurring revenue loss**. This report presents a complete data-driven investigation of the churn problem — analyzing 7,043 customers across 21 features including contract type, tenure, internet service, payment method, and demographic attributes.

The analysis reveals that churn is not random. It is heavily concentrated in a specific, identifiable customer profile: month-to-month contract holders in their first year, using Fiber optic internet, paying via electronic check. These four factors together create a compound churn risk that the retention team can target with precision.

| Metric | Value |
|--------|-------|
| Total Customers | 7,043 |
| Churned Customers | 1,869 (26.54%) |
| Active Customers | 5,174 (73.46%) |
| Total Monthly Revenue | $456,117 |
| Monthly Revenue Lost to Churn | **$139,130** |
| Revenue at Risk (% of total) | 30.5% |
| Average CLV — All Customers | $2,283.30 |
| CLV Gap: Monthly vs Two-Year Contracts | $2,359 per customer |
| Avg Monthly Charge — Churned Customers | $74.44 |
| Avg Monthly Charge — Active Customers | $61.27 |

---

## Section 1: Dataset Overview and Data Cleaning

### 1.1 Dataset Profile

The IBM Telco Customer Churn dataset contains **7,043 customer records** representing a cross-sectional snapshot of a telecom company's subscriber base. Each record contains demographic information, service subscriptions, account details, and a binary churn label.

Key structural details: single table with no joins required, mix of categorical and numeric features, and a binary target variable (Churn: Yes/No).

### 1.2 Data Quality Issues Found and Resolved

**Issue 1 — Blank TotalCharges Values**

The `TotalCharges` column was imported as `VARCHAR(15)` in PostgreSQL because 11 records had blank string values instead of numeric data. These correspond to new customers with `tenure = 0` who had never been billed.

Resolution in SQL:
```sql
ALTER TABLE telco_customers ADD COLUMN total_charges_clean NUMERIC(10,2);

UPDATE telco_customers
SET total_charges_clean =
    CASE
        WHEN TRIM(total_charges) = '' THEN 0
        ELSE CAST(TRIM(total_charges) AS NUMERIC(10,2))
    END;
```

Resolution in Python:
```python
df['TotalCharges'] = pd.to_numeric(df['TotalCharges'], errors='coerce')
df['TotalCharges'].fillna(0, inplace=True)
```

**Issue 2 — No Tenure Segmentation**

Raw tenure data (0–72 months) was not usable for group-level analysis. A derived `tenure_group` column was added to both SQL and Python:

| Tenure Group | Interpretation |
|-------------|----------------|
| 0–12 Months | New customers |
| 13–24 Months | Early-stage customers |
| 25–48 Months | Mid-stage customers |
| 49–72 Months | Long-term / loyal customers |

**Issue 3 — senior_citizen Stored as Integer**

The `senior_citizen` field was stored as SMALLINT (0 or 1). Mapped to Senior / Non-Senior labels using `.map()` in Python for readability in dashboards and reports.

**Issue 4 — Churn Column Casing**

Standardized using `INITCAP()` in SQL to ensure consistent Yes/No values for filtering across all queries.

### 1.3 Final Data Quality Summary

After cleaning: 7,043 total records retained with no rows dropped, zero duplicate customer IDs, zero NULL values in key analytical columns, 11 blank TotalCharges resolved, and churn column fully standardized.

---

## Section 2: Exploratory Analysis — Demographic Factors

### 2.1 Overall Churn Rate

Out of 7,043 customers, 1,869 have churned — giving an **overall churn rate of 26.54%**. This means the company loses roughly one in four customers, requiring constant acquisition spending just to maintain revenue.

![Churn Distribution](../Outputs/01_churn_distribution.png)

### 2.2 Churn by Gender

| Gender | Total Customers | Churned | Churn Rate |
|--------|----------------|---------|------------|
| Female | 3,488 | 939 | 26.92% |
| Male | 3,555 | 930 | 26.16% |

Gender has no meaningful impact on churn — the difference is less than one percentage point. Gender-based segmentation for retention is not justified by this data.

### 2.3 Churn by Senior Citizen Status

| Segment | Total Customers | Churned | Churn Rate |
|---------|----------------|---------|------------|
| Senior (65+) | 1,142 | 476 | **41.68%** |
| Non-Senior | 5,901 | 1,393 | 23.61% |

![Senior vs Non-Senior Churn](../Outputs/09_churn_senior_vs_non_senior.png)

Senior customers represent 16.2% of the customer base but 25.5% of all churned customers. The 18-percentage-point gap signals a dedicated senior retention program is a high-value opportunity.

### 2.4 Churn by Partner and Dependent Status

| Partner | Dependents | Churn Rate |
|---------|-----------|------------|
| No | No | Highest |
| No | Yes | Lower |
| Yes | No | Moderate |
| Yes | Yes | **Lowest** |

Customers with both a partner and dependents have the lowest churn rate. Household billing consolidation creates natural switching costs and retention lock-in.

---

## Section 3: Contract and Service Analysis

### 3.1 Churn by Contract Type

Contract type is the single most powerful predictor of churn in this dataset.

| Contract Type | Total Customers | Churned | Churn Rate | Avg Monthly Charge |
|--------------|----------------|---------|------------|-------------------|
| Month-to-month | 3,875 | 1,655 | **42.71%** | $66 |
| One year | 1,473 | 166 | 11.27% | $65 |
| Two year | 1,695 | 48 | **2.83%** | $61 |

![Churn by Contract](../Outputs/02_churn_by_contract.png)

Month-to-month customers churn at **15 times the rate** of two-year contract customers. Average monthly charges are nearly identical across all contract types ($61–$66), meaning the churn difference is driven by commitment level — not pricing.

### 3.2 Churn by Tenure Group

| Tenure Group | Total Customers | Churned | Churn Rate |
|-------------|----------------|---------|------------|
| 0–12 Months | 2,175 | 1,032 | **47.44%** |
| 13–24 Months | 1,060 | 304 | 28.71% |
| 25–48 Months | 1,524 | 311 | 20.39% |
| 49–72 Months | 2,284 | 222 | 9.51% |

![Churn by Tenure Group](../Outputs/03_churn_by_tenure_group.png)

Nearly half of all customers who churn do so within the first 12 months. After four years, churn drops below 10%. The first year is the most critical retention window.

**Heatmap — Contract Type vs Tenure Group:**

![Churn Heatmap](../Outputs/08_churn_heatmap_contract_tenure.png)

The most dangerous combination: Month-to-month + 0–12 months = **51.4% churn rate**. One in two customers in this profile will leave within a year.

### 3.3 Churn by Internet Service Type

| Internet Service | Total Customers | Churned | Churn Rate | Avg ARPU |
|-----------------|----------------|---------|------------|----------|
| Fiber optic | 3,096 | 1,297 | **41.89%** | $87 |
| DSL | 2,421 | 459 | 18.96% | $51 |
| No Internet | 1,526 | 113 | 7.40% | — |

![Churn by Internet Service](../Outputs/05_churn_by_internet_service.png)

Fiber optic customers churn at more than double the rate of DSL customers. Combined with their higher ARPU ($87 vs $51), this represents a disproportionate loss from what should be the company's most valuable segment. This signals a product quality or pricing problem that requires investigation beyond retention campaigns alone.

### 3.4 Add-On Services and Churn

Customers subscribing to Online Security, Online Backup, and Tech Support in combination show significantly lower churn rates than customers with none of these services. Bundled services create switching costs and increase perceived value, acting as a natural retention mechanism.

---

## Section 4: Revenue Analysis

### 4.1 Monthly Revenue at Risk

| Churn Status | Customers | Total Monthly Revenue | Avg Monthly Charge |
|-------------|-----------|----------------------|-------------------|
| Active (No) | 5,174 | $316,987 | $61.27 |
| Churned (Yes) | 1,869 | **$139,130** | $74.44 |

The $13 higher average monthly charge among churned customers is significant — the company is losing its higher-paying customers at a disproportionate rate. This is the opposite of a healthy retention outcome.

### 4.2 Revenue at Risk by Contract Type

| Contract Type | Monthly Revenue Lost | Share of Total Loss |
|--------------|---------------------|---------------------|
| Month-to-month | **$120,847** | 86.9% |
| One year | $14,118 | 10.1% |
| Two year | $4,165 | 3.0% |

![Revenue at Risk by Contract](../Outputs/07_revenue_at_risk_by_contract.png)

### 4.3 Monthly Charges Distribution: Churned vs Active

![Monthly Charges Distribution](../Outputs/04_monthly_charges_distribution.png)

Churned customers cluster at higher monthly charge levels ($74 average) while active customers cluster lower ($61 average). The gap confirms that premium-tier subscribers — primarily Fiber optic users — are churning at a higher rate.

### 4.4 ARPU and Customer Lifetime Value by Contract Type

| Contract Type | ARPU (Monthly) | Avg Lifetime Value (CLV) |
|--------------|----------------|--------------------------|
| Month-to-month | $66 | $1,369.25 |
| One year | $65 | $3,034.68 |
| Two year | $61 | **$3,728.93** |
| **Overall Average** | **$65** | **$2,283.30** |

Despite a slightly lower ARPU, two-year contract customers deliver a CLV of $3,729 — **2.7 times higher** than month-to-month customers. This gap exists entirely because they stay longer. The business case for contract conversion incentives is clear.

Top CLV segments identified:
- Two year + DSL + Senior: $4,663.01 average CLV
- Two year + DSL + Non-Senior: $4,246.31 average CLV
- One year + DSL + Senior: $3,179.85 average CLV

### 4.5 Payment Method Revenue and Churn Risk

| Payment Method | Customers | Monthly Revenue | Churn Rate |
|---------------|-----------|----------------|------------|
| Electronic check | 2,365 | $180,345 | **45.29%** |
| Mailed check | 1,612 | $70,794 | 19.11% |
| Bank transfer (auto) | 1,544 | $103,745 | 16.71% |
| Credit card (auto) | 1,522 | $101,232 | 15.24% |

![Churn by Payment Method](../Outputs/06_churn_by_payment_method.png)

Electronic check users represent 33.6% of all customers but **57.3% of all churned customers**. Auto-pay methods consistently show 15–17% churn, suggesting that automatic payment creates passive retention behavior.

---

## Section 5: Advanced Segment Analysis

### 5.1 Cumulative Churn by Tenure

By month 12: approximately 1,032 customers churned — 55.2% of all churned customers  
By month 24: approximately 1,336 customers churned — 71.5% of all churned  
By month 48: approximately 1,647 customers churned — 88.1% of all churned  

If the company retains a customer past two years, long-term retention probability becomes very high. Early-stage retention investment pays back over many years of extended customer lifetime value.

### 5.2 Payment Method Ranking by Revenue and Churn Risk

Using `RANK() OVER` window functions, payment methods were ranked simultaneously by revenue contribution and churn risk. Electronic check ranks first in revenue contribution and first in churn risk — making it the most urgent intervention target. Bank transfer and credit card auto-pay rank second and third in revenue with the lowest churn risk, representing the stable profitable payment base.

### 5.3 Correlation Analysis

![Correlation Matrix](../Outputs/10_correlation_heatmap.png)

| Feature | Correlation with Churn | Direction |
|---------|----------------------|-----------|
| Tenure | **-0.35** | Longer tenure = less churn |
| Total Charges | -0.20 | Higher CLV = less churn |
| Monthly Charges | +0.19 | Higher bill = slightly more churn |
| Senior Citizen | +0.15 | Senior = marginally more churn |

Tenure has the strongest correlation with churn at -0.35. Monthly charges show +0.19 correlation, confirming higher-billing customers — primarily Fiber optic subscribers — churn at a higher rate.

### 5.4 High-Risk Active Customer Identification

The most operationally actionable output of this analysis is the High-Risk Customer Retention List generated by SQL Q15.

A high-risk active customer is defined as a currently active customer (churn = No) matching all four highest-churn criteria simultaneously:
- Contract: Month-to-month
- Tenure: 12 months or fewer
- Payment method: Electronic check
- Internet service: Fiber optic

These customers match the exact profile that churns at a **51.4% rate**. Proactive outreach — before they initiate cancellation — gives the retention team an opportunity to intervene. This list is visible on Page 3 of the Power BI dashboard with customer IDs, monthly charges, and demographic details ready for immediate action.

---

## Section 6: Business Recommendations

### Recommendation 1 — Contract Migration Campaign
**Priority: Critical | Estimated Monthly Revenue Protected: $20,000–$30,000**

Month-to-month customers churn at 42.71%. Moving them to one-year contracts reduces churn to 11.27% — a 31-percentage-point improvement. Offer one month free plus locked-in pricing for customers who convert from monthly to annual. Target all month-to-month customers with tenure under 24 months first, using personalized outreach showing individual savings amounts.

### Recommendation 2 — First 90 Days Onboarding Program
**Priority: High | Target: Reduce 0–12 month churn from 47.44% toward 30%**

The 0–12 month cohort represents 55% of all churned customers by volume. Structured onboarding: welcome call at Day 7, product usage check-in at Day 30, satisfaction survey at Day 60, upgrade offer at Day 90. Assign a customer success contact for the first six months.

### Recommendation 3 — Auto-Pay Migration Drive
**Priority: High | Estimated Churn Reduction: 28–30 percentage points for converted customers**

Electronic check users churn at 45.29% versus 15–17% for auto-pay users — a 30 percentage point gap. Offer a $5–$10 monthly bill discount for switching to bank transfer or credit card auto-pay. The discount cost is recovered many times over by improved retention.

### Recommendation 4 — Fiber Optic Service Quality Investigation
**Priority: High | Revenue at Risk: $54,000+ per month from Fiber optic churners**

A 41.89% churn rate among Fiber optic users signals a product or service delivery problem. Required actions: exit surveys with recently churned Fiber customers, support ticket volume and resolution time analysis, pricing competitiveness review against local competitors, and geographic analysis to identify network infrastructure issues.

### Recommendation 5 — Senior Citizen Dedicated Plan
**Priority: Medium | Target: 1,142 senior customers at 41.68% churn risk**

Dedicated offering with simplified pricing, phone-first support (not chatbot), loyalty reward at 12-month and 24-month milestones, and a two-year price freeze guarantee.

### Recommendation 6 — Add-On Service Bundling at Onboarding
**Priority: Medium | Dual benefit: reduces churn and increases ARPU**

Offer Online Security plus Tech Support as a 3-month free trial for all new customers at sign-up. Add-on adoption reduces churn through switching costs. Converting trial users to paid subscribers increases ARPU and CLV simultaneously.

### Recommendation 7 — Monthly High-Risk Customer Report
**Priority: Ongoing | Tool: Automate Q15 identification query on live data**

Run the high-risk identification query on live customer data at the start of each month. Export results to the retention team's CRM. Assign agents to each identified customer for personalized outreach before their next billing cycle. This converts a one-time analytical finding into an ongoing operational retention process.

---

## Section 7: Project Limitations

1. **No time dimension.** This is a cross-sectional dataset — a single snapshot. Churn trends over time cannot be assessed.

2. **No reason-for-churn data.** The dataset records that a customer churned but not why. Exit survey data would dramatically improve the actionability of recommendations, particularly for the Fiber optic investigation.

3. **No geographic data.** Network quality, competitive dynamics, and demographics vary by region. Geographic segmentation is not possible without location data.

4. **No acquisition channel data.** Whether churn differs by acquisition channel (online, retail, referral) would enable channel-specific strategies.

5. **No price history.** If Fiber optic pricing changed during the observation period, that could partially explain the elevated churn. Price sensitivity analysis requires billing history.

6. **Correlation, not causation.** All relationships are correlational. Causation cannot be established without controlled experiments or additional longitudinal data.

---

## Section 8: Technical Notes

### SQL Approach

`FILTER (WHERE ...)` syntax was used throughout instead of `CASE WHEN` inside `SUM()` — cleaner conditional aggregation in PostgreSQL. Window functions (`RANK() OVER`, `SUM() OVER`) were applied only where they genuinely add value — ranking comparisons and cumulative running totals — not for cosmetic demonstration. Tenure group ordering in Q6 is handled via `CASE` inside `ORDER BY` since PostgreSQL cannot sort VARCHAR tenure labels chronologically by default. A `customer_count >= 50` filter in Q13 CLV analysis ensures statistical reliability — segments under 50 customers are excluded to prevent misleading averages. Q15 explicitly filters `churn = 'No'` to ensure only active customers are returned — this is a retention action list, not a retrospective analysis.

### Python Approach

`os.chdir()` sets the working directory relative to the script file location. `pd.Categorical()` with `ordered=True` enforces correct chronological sort order for the tenure group column. `warnings.filterwarnings('ignore')` suppresses version-compatibility FutureWarning messages from pandas and seaborn — not substantive errors. `plt.rcParams['savefig.bbox'] = 'tight'` ensures chart labels are never clipped when saved. Consistent color coding across all 10 charts: red (#E74C3C) for high churn or danger signals, green (#2ECC71) for low churn or safe signals, orange (#F39C12) for moderate risk.

---

**Subhash Gautam** | Data Analyst  
[linkedin.com/in/subhash-gautam-a6126626b](https://www.linkedin.com/in/subhash-gautam-a6126626b/) | subhashgautam788@gmail.com  
[github.com/subhashgautam788-DS](https://github.com/subhashgautam788-DS)
