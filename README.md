# 📊 Covered Call Options API (Live Trading Engine)

A production-style **FastAPI backend deployed on AWS EC2** that analyzes real-time market data and generates ranked covered call strategies using options chain data, liquidity filters, and yield optimization.

---

## 🚀 Overview

This project is a live API service designed to simulate a **covered call decision engine** for retail traders.

It:
- Fetches real-time stock prices
- Scans full options chains across expirations
- Applies liquidity + risk filters
- Ranks and returns optimized covered call strategies

Built as a backend-first system, it is designed for integration with a **Flutter mobile app or web frontend**.

---

## 🌐 Live API

**Base URL:**  

http://<EC2-PUBLIC-IP>:8000


### 📌 Endpoint

GET /covered-call?symbol=AAPL


### 📥 Example Response
```json
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
🧠 Core Features
📊 Market Data Engine
Real-time stock pricing via Yahoo Finance
Full options chain scanning across expirations
Live data processing pipeline
⚙️ Strategy Engine

Filters contracts using:

7–30 day expiration window (DTE)
Out-of-the-money strike selection
Liquidity constraints (volume + spread quality)

Includes:

Yield-based scoring system
Ranked contract selection
🏆 Recommendation System

Each request returns 3 structured strategies:

Type	Description
Best	Highest yield with balanced risk
Alternative	Secondary optimized contract
Aggressive	Higher risk / higher reward
🧾 Portfolio Awareness (Optional)
Optional integration with Alpaca API
Detects share holdings
Ensures covered call eligibility
🛠 Tech Stack
Python 3.12
FastAPI
Uvicorn (ASGI Server)
pandas
yfinance
AWS EC2 (Deployment)
GitHub (Version Control)
☁️ Architecture
Flutter / Web Frontend
          ↓
FastAPI Backend (AWS EC2)
          ↓
Market Data (Yahoo Finance)
🚀 Local Development
1. Install dependencies
pip install -r requirements.txt
2. Run server
uvicorn main:app --reload
3. Open API docs
http://127.0.0.1:8000/docs
🧪 Example API Call
curl "http://localhost:8000/covered-call?symbol=AAPL"
⚠️ Disclaimer

This project is for educational and analytical purposes only.

It does not constitute financial advice. Options trading involves risk and may not be suitable for all investors.

📌 Roadmap / Future Improvements
Probability of profit modeling
Implied volatility scoring
Risk-adjusted ranking engine
Trade history database
User portfolio tracking
Flutter mobile frontend integration
👤 Author

Built as a personal project focused on:

Options strategy automation
Real-time financial data systems
Backend API design on AWS
Scalable trading infrastructure
