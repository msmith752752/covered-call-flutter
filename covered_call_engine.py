import argparse
import yfinance as yf
from alpaca.trading.client import TradingClient

# =====================================================
# CONFIG
# =====================================================
API_KEY = "PKFVE3ZAZFMWYSTVOOY4ZFLWIO"
SECRET_KEY = "2oXUzQyfdoU65yLveBbxQYEm99GVTYsEZGGBKNvFXjrs"

client = TradingClient(API_KEY, SECRET_KEY, paper=True)

# =====================================================
# DATA LAYER
# =====================================================
def get_price(symbol):
    ticker = yf.Ticker(symbol)
    data = ticker.history(period="1d")

    if data.empty:
        return None

    return float(data["Close"].iloc[-1])

# =====================================================
# BROKERAGE LAYER
# =====================================================
def get_positions():
    try:
        positions = client.get_all_positions()
        return {p.symbol: int(float(p.qty)) for p in positions}
    except Exception:
        return {}

# =====================================================
# STRATEGY LAYER
# =====================================================
def generate_covered_call(symbol, price):
    volatility_map = {
        "AAPL": 0.008,
        "MSFT": 0.007,
        "TSLA": 0.015,
        "NVDA": 0.012
    }

    vol = volatility_map.get(symbol, 0.01)

    strike = round(price * 1.03, 2)
    premium = round(price * vol, 2)
    yield_pct = round((premium / price) * 100, 2)

    return strike, premium, yield_pct

# =====================================================
# ANALYSIS FUNCTION
# =====================================================
def analyze(symbol, positions):
    price = get_price(symbol)

    if price is None:
        return None

    strike, premium, yield_pct = generate_covered_call(symbol, price)
    shares = positions.get(symbol, 0)

    return {
        "symbol": symbol,
        "price": price,
        "strike": strike,
        "premium": premium,
        "yield": yield_pct,
        "shares": shares
    }

# =====================================================
# SCANNER MODE (TABLE OUTPUT)
# =====================================================
def run_scan(symbols):
    print("\n======================================")
    print(" COVERED CALL SCANNER")
    print("======================================\n")

    positions = get_positions()
    results = []

    for symbol in symbols:
        result = analyze(symbol, positions)
        if result:
            results.append(result)

    # Sort by yield (best first)
    results.sort(key=lambda x: x["yield"], reverse=True)

    # Header row
    print(f"{'SYMBOL':<8}{'PRICE':<12}{'STRIKE':<12}{'PREMIUM':<12}{'YIELD %':<10}{'SHARES':<10}")
    print("-" * 70)

    # Data rows
    for r in results:
        print(f"{r['symbol']:<8}"
              f"${r['price']:<11.2f}"
              f"${r['strike']:<11.2f}"
              f"${r['premium']:<11.2f}"
              f"{r['yield']:<10.2f}"
              f"{r['shares']:<10}")

    print("\n")

    # Top recommendation
    best = results[0]

    print("======================================")
    print(" TOP RECOMMENDATION")
    print("======================================")
    print(f"Symbol: {best['symbol']}")
    print(f"Yield: {best['yield']}%")
    print(f"Premium: ${best['premium']}")
    print("Reason: Highest covered call yield in scan universe")

# =====================================================
# SINGLE MODE
# =====================================================
def run_single(symbol):
    positions = get_positions()
    result = analyze(symbol, positions)

    print("\n==============================")
    print(" COVERED CALL ENGINE")
    print("==============================\n")

    print(f"Symbol: {result['symbol']}")
    print(f"Current Price: ${result['price']:.2f}")

    print("\n--- Covered Call Suggestion ---")
    print(f"Suggested Strike: ${result['strike']}")
    print(f"Estimated Premium: ${result['premium']}")
    print(f"Estimated Yield: {result['yield']}%")

    print("\n--- Position Check ---")
    print(f"Shares Owned: {result['shares']}")

    if result["shares"] >= 100:
        print("Status: Eligible for covered call")
    else:
        print("Status: NOT eligible (need 100 shares)")

# =====================================================
# CLI ENTRY
# =====================================================
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Covered Call Trading Assistant")

    parser.add_argument("--symbol", type=str, help="Single stock symbol")
    parser.add_argument("--scan", nargs="+", help="Scan multiple symbols")

    args = parser.parse_args()

    if args.scan:
        run_scan([s.upper() for s in args.scan])
    elif args.symbol:
        run_single(args.symbol.upper())
    else:
        print("Usage:")
        print("  python covered_call_engine.py --symbol AAPL")
        print("  python covered_call_engine.py --scan AAPL TSLA NVDA MSFT")