# UPI Payment Reliability & Risk Analytics

## Project Overview

This project analyzes 250,000 UPI transactions to understand where payment failures occur, when they happen, which transaction and bank segments are most affected, and where the highest transaction-risk exposure exists.

The analysis focuses on payment reliability, failed transaction value, technical factors, transaction behaviour, and fraud exposure.

## Business Problem

UPI processes a large volume of transactions, so even a moderate failure rate can create significant operational and monetary exposure.

The objective is to identify major failure and risk hotspots and translate them into actionable business recommendations.

## Core Business Question

Where are UPI payments failing, when are they failing, which banks and transaction types are most affected, and where is the greatest payment and risk exposure?

## Analysis Story

UPI activity is large → overall reliability is measured → failures are localized by bank, transaction type and time → technical factors are investigated → monetary exposure is quantified → transaction behaviour and fraud risk are examined → recommendations are made.

## Key Findings

- 250,000 UPI transactions were analyzed.
- Total transaction value was approximately ₹328M.
- Overall payment failure rate was approximately 4.95%.
- Approximately 12.4K transactions failed.
- Failed transactions represented approximately ₹16.8M in transaction value.
- SBI had the highest failed transaction value at approximately ₹4.13M.
- P2P transactions contributed the highest number and value of failed transactions.
- P2M showed higher monetary fraud exposure among the transaction types analyzed.
- Shopping had the highest successful transaction value as well as the highest fraud transaction value.
- Network and device differences were comparatively smaller than the major bank, transaction-type and monetary-exposure findings.

## Tools Used

- Excel — Data cleaning and preparation
- MySQL — Data analysis and business questions
- Power BI — Dashboard development and visualization

## Project Workflow

1. Imported the UPI transaction dataset into MySQL.
2. Standardized and optimized relevant data types.
3. Verified transaction records and table structure.
4. Performed focused SQL analysis around reliability, failure exposure and fraud risk.
5. Cleaned and prepared the dataset using Excel.
6. Built an interactive Power BI dashboard.
7. Converted analytical findings into business recommendations.

## Dashboard

The dashboard provides a single-page view of:

- Total transaction volume
- Total transaction value
- Failure rate
- Failed transaction value
- Fraud rate
- Bank-level failure exposure
- Transaction-type failure volume
- Hourly failure patterns
- Network-level failure distribution
- Merchant-category fraud exposure
- Key insights and business recommendations

A transaction-type slicer allows the dashboard to be explored across P2P, P2M, Bill Payment and Recharge.

## Business Recommendations

1. Prioritize reliability improvements for high-volume banks with significant failed transaction exposure.
2. Monitor peak failure periods and investigate operational or infrastructure-related bottlenecks.
3. Evaluate network-level failure patterns to identify potential reliability improvement areas.
4. Strengthen fraud monitoring for high-value and high-risk merchant categories.
5. Consider suitable retry and recovery mechanisms for failed transactions where operationally appropriate.

## Project Outcome

This project demonstrates a business-driven approach to fintech analytics by moving from raw UPI transaction data to measurable insights around payment reliability, operational exposure and fraud risk.

The focus is not only on identifying what happened, but also on identifying where the business should investigate and prioritize action.
