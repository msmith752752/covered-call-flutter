import sys
import argparse
import yfinance as yf
from alpaca.trading.client import TradingClient

# =====================================================
# CONFIG (Alpaca Paper Trading Credentials)
# =====================================================
API_KEY = "PKFVE3ZAZFMWYSTVOOY4ZFLWIO"
SECRET_KEY = "2oXUzQyfdoU65yLveBbxQYEm99GVTYsEZGGBKNvFXjrs"

client = TradingClient(API_KEY, SECRET_KEY, paper=True)

# =====================================================
# DATA LAYER (Market Price via Yahoo Finance)
# =====================================================
def get_price(symbol):
    ticker = yf.Ticker(symbol)
    data = ticker.history(period="1d")

    if data.empty:
        raise Exception(f"No price data found for {symbol}")

    return float(data["Close"].iloc[-1])

# =====================================================
# BROKERAGE LAYER (Alpaca Positions)
# =====================================================
def get_positions():
    positions = client.get_all_positions()
    return {p.symbol: int(float(p.qty)) for p in positions}

# =====================================================
# STRATEGY LAYER (Covered Call Logic)
# =====================================================
def generate_covered_call(price):
    """
    Simple baseline strategy:
    - Strike: 3% above current price
    - Premium estimate: ~1% of stock price
    """

    strike = round(price * 1.03, 2)
    premium = round(price * 0.01, 2)
    yield_pct = round((premium / price) * 100, 2)

    return strike, premium, yield_pct

# =====================================================
# ENGINE
# =====================================================
def run(symbol):
    print("\n==============================")
    print(" COVERED CALL ENGINE (CLI)")
    print("==============================\n")

    price = get_price(symbol)
    positions = get_positions()
    shares = positions.get(symbol, 0)

    strike, premium, yield_pct = generate_covered_call(price)

    print(f"Symbol: {symbol.upper()}")
    print(f"Current Price: ${price:.2f}")

    print("\n--- Covered Call Suggestion ---")
    print(f"Suggested Strike: ${strike}")
    print(f"Estimated Premium: ${premium}")
    print(f"Estimated Yield: {yield_pct}%")

    print("\n--- Position Check ---")
    print(f"Shares Owned: {shares}")

    if shares >= 100:
        print("Status: Eligible for covered call")
    else:
        print("Status: NOT eligible (need 100 shares)")

# =====================================================
# CLI ENTRY POINT
# =====================================================
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Covered Call Trading Assistant")

    parser.add_argument(
        "--symbol",
        type=str,
        required=True,
        help="Stock symbol (e.g. AAPL, TSLA, NVDA)"
    )

    args = parser.parse_args()

    run(args.symbol.upper())