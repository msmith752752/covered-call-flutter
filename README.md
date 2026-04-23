📊 Covered Call Analyzer (Flutter + Real-Time Market Data)

A mobile-first financial analytics app built with Flutter that helps investors evaluate covered call options strategies using real-time stock prices, payoff modeling, and risk visualization.

🎯 Project Overview

This project goes beyond a simple calculator. It demonstrates real-world fintech engineering concepts including:

Live market data integration (REST API)
Options strategy modeling (covered calls)
Financial return analytics (ROI, breakeven, annualized return)
Defensive UI design with input validation
Data visualization with payoff charts
Clean separation of UI, API services, and calculation logic
🚀 Key Features
📡 Market Data
Live stock price lookup via external API (Alpha Vantage)
Auto-fill current price into trade setup
🧮 Covered Call Analytics
Max profit calculation
Total profit (including premium)
Break-even price analysis
ROI calculation on capital invested
Annualized return estimation
🛡️ Input Safety & UX
Input validation to prevent crashes
Graceful error handling with user feedback
Automatic cost basis pre-fill from market price
💰 Financial Formatting
Clean currency formatting using intl
Comma-separated values (e.g. $1,250.00)
Proper handling of negative values (loss display)
📈 Payoff Visualization
Interactive payoff chart using fl_chart
Strike price marker (red vertical line)
Break-even line (blue dashed line)
Zero-profit reference line
Dynamic scaling for readability
Axis labels for stock price and profit/loss
🧠 How It Works
Enter a stock ticker (e.g. AAPL)
Fetch live market price
Input trade parameters:
Strike price
Premium received
Days to expiration
Cost basis
App calculates:
Profit scenarios
ROI and annualized return
Risk/reward profile
Visualize payoff curve and key levels
📊 Example Trade Output
Stock: AAPL @ $190
Strike: $195
Premium: $3
Days: 30

🟢 Strong Trade
Max Profit: $8.00
Break-even: $187.00
ROI: 4.20%
Annualized Return: 22.5%
🛠 Tech Stack
Flutter (Dart)
REST API integration (Alpha Vantage)
HTTP package
fl_chart (data visualization)
intl (currency formatting)
Stateful UI (setState)
Custom financial modeling logic
📁 Project Structure
lib/
 ├── main.dart
 ├── covered_call_calculator.dart
 ├── stock_api_service.dart
 
📌 Engineering Highlights
Separation of concerns (UI / API / logic layers)
Real-world financial modeling (options payoff structure)
Defensive programming with input validation
Interactive data visualization
Clean, scalable Flutter architecture
Portfolio-grade UI/UX improvements

🚧 Future Improvements
Options chain integration (real market contracts)
Multi-leg strategy support (spreads, collars)
Portfolio tracking dashboard
AWS backend (Lambda + API Gateway)
Advanced payoff analytics (Greeks, volatility modeling)
Export trades to CSV / history tracking

🧭 Purpose

This project is part of a broader effort to build practical fintech engineering experience using:

Real market data
Financial modeling
Mobile-first UI design
Cloud-ready architecture (future expansion)

👨‍💻 Author

Built by Matthew R. Smith
Focused on fintech, cloud engineering, and applied software development.
