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

    return {
        "strike": strike,
        "premium": premium,
        "yield_pct": yield_pct
    }

# =====================================================
# MAIN ENGINE
# =====================================================
def run(symbol):
    print("\n==============================")
    print(" COVERED CALL ENGINE (v1)")
    print("==============================\n")

    # 1. Get price (Yahoo Finance)
    price = get_price(symbol)

    # 2. Get positions (Alpaca)
    positions = get_positions()
    shares = positions.get(symbol, 0)

    # 3. Generate strategy output
    suggestion = generate_covered_call(price)

    # 4. Output results
    print(f"Symbol: {symbol}")
    print(f"Current Price: ${price}")

    print("\n--- Covered Call Suggestion ---")
    print(f"Suggested Strike: ${suggestion['strike']}")
    print(f"Estimated Premium: ${suggestion['premium']}")
    print(f"Estimated Yield: {suggestion['yield_pct']}%")

    print("\n--- Position Check ---")
    print(f"Shares Owned: {shares}")

    if shares >= 100:
        print("Status: Eligible for covered call")
    else:
        print("Status: NOT eligible (need 100 shares)")

# =====================================================
# ENTRY POINT
# =====================================================
if __name__ == "__main__":
    run("AAPL")