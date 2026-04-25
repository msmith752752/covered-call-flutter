📊 Covered Call Options API (Live Trading Engine)

A Python-based FastAPI backend deployed on AWS EC2 that analyzes real market data and generates ranked covered call opportunities using live option chains, liquidity filters, and yield optimization.

🚀 What This Project Does

This project runs as a live API service that:

Fetches real-time stock prices via Yahoo Finance
Pulls full options chains across multiple expirations
Filters contracts using liquidity + risk constraints
Generates 3 ranked covered call strategies
Exposes results through a REST API endpoint

Instead of a CLI tool, this is now a production-style backend service ready for frontend integration (Flutter/web).

🌐 Live API Endpoint
Base URL (EC2 hosted)
http://<EC2-IP>:8000
📌 Covered Call Recommendation
GET /covered-call?symbol=AAPL
Example Response
{
  "symbol": "AAPL",
  "price": 271.05,
  "shares": 0,
  "options": [
    {
      "rank": "best",
      "strike": 275.0,
      "premium": 6.3,
      "yield": 2.4,
      "expiration": "2026-05-22",
      "dte": 26
    },
    {
      "rank": "alternative",
      "strike": 275.0,
      "premium": 5.65,
      "yield": 2.12,
      "expiration": "2026-05-15",
      "dte": 19
    },
    {
      "rank": "aggressive",
      "strike": 275.0,
      "premium": 4.9,
      "yield": 1.84,
      "expiration": "2026-05-08",
      "dte": 12
    }
  ],
  "best": {
    "rank": "best",
    "strike": 275.0,
    "premium": 6.3,
    "yield": 2.4,
    "expiration": "2026-05-22",
    "dte": 26
  }
}
🧠 Key Features

📊 Market Data Engine

Live stock prices via Yahoo Finance
Full options chain scanning across expirations
Real-time market data processing

⚙️ Strategy Logic


Filters options by:
7–30 day expiration window (DTE)
Out-of-the-money strike selection
Liquidity constraints (volume + spread quality)
Computes yield-based ranking system

🏆 3-Level Recommendation System

Each stock returns:

Best → highest yield + balanced risk
Alternative → secondary optimized contract
Aggressive → higher risk/reward structure
🧾 Portfolio Awareness (Optional)
Alpaca integration (if configured)
Checks share holdings for covered call eligibility
🛠 Tech Stack
Python 3.12
FastAPI
Uvicorn (ASGI server)
yfinance (market data)
pandas (data processing)
AWS EC2 (deployment)
GitHub (version control)

☁️ Deployment Architecture
Flutter / Web App
        ↓
FastAPI Backend (EC2)
        ↓
Market Data (Yahoo Finance)

🚀 How to Run Locally
pip install -r requirements.txt
uvicorn main:app --reload

Then open:

http://127.0.0.1:8000/docs

🧪 Example API Call
curl "http://localhost:8000/covered-call?symbol=AAPL"
⚠️ Disclaimer

This project is for educational and analytical purposes only.
It does not provide financial advice. Options trading involves risk and may not be suitable for all investors.

📌 Future Improvements
Probability of profit modeling
Implied volatility scoring
Risk-adjusted ranking engine
Database for trade history tracking
Flutter frontend dashboard integration
User portfolio tracking system
👤 Author

Built as a personal finance + trading automation project exploring:

options strategy automation
real-time financial data engineering
backend API design on AWS
scalable trading system architecture
