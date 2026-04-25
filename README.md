# 📊 Covered Call Options Analysis Engine

A Python-based options analysis tool that scans real market data to identify potential covered call opportunities using live option chains, liquidity filters, and risk constraints.

---

## 🚀 What This Project Does

This tool analyzes U.S. equities and generates covered call suggestions based on:

- Real-time stock prices
- Live options chain data
- Expiration (DTE) filtering
- Liquidity constraints (volume + bid/ask quality)
- Strike price range controls
- Yield-based ranking system

It outputs a ranked table of covered call opportunities and highlights the top recommendation.

---

## 📈 Example Output


SYMBOL PRICE STRIKE PREMIUM YIELD DTE SHARES
TSLA $373.35 $380.00 $15.15 4.06 28 0
MSFT $415.47 $420.00 $15.80 3.80 28 0
NVDA $199.21 $205.00 $6.80 3.41 28 0
AAPL $273.36 $277.50 $6.20 2.27 21 0


---

## 🧠 Key Features

### 📊 Market Data
- Uses live stock prices via Yahoo Finance
- Pulls full options chains across expirations

### ⚙️ Strategy Logic
- Filters contracts by:
  - 7–30 day expiration window
  - 1%–5% out-of-the-money strikes
  - Minimum volume threshold
  - Bid/ask liquidity quality

### 📈 Ranking System
- Calculates yield = premium / stock price
- Sorts and identifies highest-quality opportunities

### 🧾 Portfolio Awareness
- Connects to brokerage account (optional)
- Checks share ownership for covered call eligibility

---

## 🛠 Tech Stack

- Python 3
- yfinance (market + options data)
- Alpaca Trading API (optional brokerage integration)
- pandas (data processing)
- argparse (CLI interface)

---

## 📦 Installation

```bash
git clone https://github.com/yourusername/covered-call-engine.git
cd covered-call-engine
pip install -r requirements.txt
▶️ How to Run
Single stock analysis:
python covered_call_engine.py --symbol AAPL
Multi-stock scan:
python covered_call_engine.py --scan AAPL TSLA NVDA MSFT
⚠️ Disclaimer

This tool is for educational and analytical purposes only. It does not provide financial advice. Options trading involves risk and may not be suitable for all investors.

📌 Future Improvements

Planned enhancements include:

Probability of profit modeling
Implied volatility scoring
Risk-adjusted return ranking
API version for web/mobile integration
Frontend dashboard (Flutter integration)
👤 Author

Built as a personal finance + trading automation project exploring:

options strategy automation
market data engineering
Python-based financial systems
