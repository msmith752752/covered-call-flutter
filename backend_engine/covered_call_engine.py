import argparse
import os
from datetime import datetime
import yfinance as yf
import pandas as pd

# Optional Alpaca import
try:
    from alpaca.trading.client import TradingClient
except Exception:
    TradingClient = None

# =====================================================
# CONFIG
# =====================================================
API_KEY = os.getenv("PKFVE3ZAZFMWYSTVOOY4ZFLWIO")
SECRET_KEY = os.getenv("2oXUzQyfdoU65yLveBbxQYEm99GVTYsEZGGBKNvFXjrs")

# Safe client initialization
if TradingClient and API_KEY and SECRET_KEY:
    try:
        client = TradingClient(API_KEY, SECRET_KEY, paper=True)
    except Exception:
        client = None
else:
    client = None

# =====================================================
# DATA LAYER
# =====================================================
def get_price(symbol):
    try:
        ticker = yf.Ticker(symbol)
        data = ticker.history(period="1d")

        if data.empty:
            return None

        return float(data["Close"].iloc[-1])
    except Exception:
        return None


def get_options_chain(symbol):
    try:
        ticker = yf.Ticker(symbol)
        expirations = ticker.options

        all_calls = []

        for exp in expirations:
            try:
                chain = ticker.option_chain(exp)
                calls = chain.calls.copy()

                calls["expiration"] = exp
                calls["dte"] = (
                    datetime.strptime(exp, "%Y-%m-%d") - datetime.today()
                ).days

                all_calls.append(calls)

            except Exception:
                continue

        if not all_calls:
            return None

        return pd.concat(all_calls, ignore_index=True)

    except Exception:
        return None


# =====================================================
# BROKERAGE LAYER
# =====================================================
def get_positions():
    if client is None:
        return {}

    try:
        positions = client.get_all_positions()
        return {p.symbol: int(float(p.qty)) for p in positions}
    except Exception:
        return {}


# =====================================================
# STRATEGY LAYER
# =====================================================
def generate_covered_call(symbol, price, min_dte=7, max_dte=30):
    options = get_options_chain(symbol)

    if options is None:
        return None

    try:
        # ✅ ONLY CHANGE: added volume filter
        filtered = options[
    (options["strike"] > price) &
    (options["strike"] <= price * 1.05) &   # NEW RULE
    (options["strike"] >= price * 1.01) &   # NEW RULE
    (options["dte"] >= min_dte) &
    (options["dte"] <= max_dte) &
    (options["bid"] > 0) &
    (options["volume"] > 50) &
((options["bid"] / options["ask"]) >= 0.6)
].copy()

        if filtered.empty:
            return None

        # Yield calculation
        filtered["yield"] = (filtered["bid"] / price) * 100

        # Pick best option
        best = filtered.sort_values(by="yield", ascending=False).iloc[0]

        return {
            "strike": round(best["strike"], 2),
            "premium": round(best["bid"], 2),
            "yield": round(best["yield"], 2),
            "expiration": best["expiration"],
            "dte": int(best["dte"])
        }

    except Exception:
        return None


# =====================================================
# ANALYSIS
# =====================================================
def analyze(symbol, positions):
    price = get_price(symbol)

    if price is None:
        return None

    cc = generate_covered_call(symbol, price)

    if cc is None:
        return None

    shares = positions.get(symbol, 0)

    return {
        "symbol": symbol,
        "price": price,
        "strike": cc["strike"],
        "premium": cc["premium"],
        "yield": cc["yield"],
        "expiration": cc["expiration"],
        "dte": cc["dte"],
        "shares": shares
    }


# =====================================================
# SCANNER MODE
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

    if not results:
        print("No valid results found.")
        return

    # Sort by yield
    results.sort(key=lambda x: x["yield"], reverse=True)

    print(f"{'SYMBOL':<8}{'PRICE':<10}{'STRIKE':<10}{'PREM':<10}{'YIELD':<8}{'DTE':<6}{'SHARES':<10}")
    print("-" * 75)

    for r in results:
        print(f"{r['symbol']:<8}"
              f"${r['price']:<9.2f}"
              f"${r['strike']:<9.2f}"
              f"${r['premium']:<9.2f}"
              f"{r['yield']:<8.2f}"
              f"{r['dte']:<6}"
              f"{r['shares']:<10}")

    best = results[0]

    print("\n======================================")
    print(" TOP RECOMMENDATION")
    print("======================================")
    print(f"Symbol: {best['symbol']}")
    print(f"Yield: {best['yield']}%")
    print(f"Premium: ${best['premium']}")
    print(f"Expiration: {best['expiration']} ({best['dte']} days)")
    print("Reason: Highest yield within selected DTE range")


# =====================================================
# SINGLE MODE
# =====================================================
def run_single(symbol):
    positions = get_positions()
    result = analyze(symbol, positions)

    if result is None:
        print("No valid data found.")
        return

    print("\n==============================")
    print(" COVERED CALL ENGINE")
    print("==============================\n")

    print(f"Symbol: {result['symbol']}")
    print(f"Current Price: ${result['price']:.2f}")

    print("\n--- Covered Call Suggestion ---")
    print(f"Strike: ${result['strike']}")
    print(f"Premium: ${result['premium']}")
    print(f"Yield: {result['yield']}%")
    print(f"Expiration: {result['expiration']} ({result['dte']} days)")

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