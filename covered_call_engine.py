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
API_KEY = os.getenv("API_KEY")
SECRET_KEY = os.getenv("SECRET_KEY")

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
        filtered = options[
            (options["strike"] > price) &
            (options["strike"] <= price * 1.05) &
            (options["strike"] >= price * 1.01) &
            (options["dte"] >= min_dte) &
            (options["dte"] <= max_dte) &
            (options["volume"] > 0) &
            ((options["ask"] - options["bid"]) / options["ask"].replace(0, 1) < 0.2)
        ].copy()

        if filtered.empty:
            return None

        # Yield calculation
        filtered["yield"] = ((filtered["bid"] + filtered["ask"]) / 2 / price) * 100

        # Score (kept for future improvement)
        filtered["score"] = (
            (filtered["yield"] * 0.7) +
            (filtered["volume"] * 0.2) +
            (((filtered["ask"] - filtered["bid"]) / filtered["ask"].replace(0, 1)) * -100 * 0.1)
        )

        # Sort by yield (primary ranking logic)
        sorted_calls = filtered.sort_values(by="yield", ascending=False)

        # Take top 3 contracts
        top_calls = sorted_calls.head(3)

        results = []
        labels = ["best", "alternative", "aggressive"]

        for i, (_, row) in enumerate(top_calls.iterrows()):
            results.append({
                "rank": labels[i] if i < len(labels) else f"option_{i+1}",
                "strike": round(row.get("strike", 0), 2),
                "premium": round(row.get("bid", 0), 2),
                "yield": round(row.get("yield", 0), 2),
                "expiration": row.get("expiration"),
                "dte": int(row.get("dte", 0))
            })

        return results

    except Exception:
        return None


# =====================================================
# ANALYSIS (FIXED: NOW RETURNS 3 OPTIONS)
# =====================================================
def analyze(symbol, positions):
    price = get_price(symbol)

    if price is None:
        return None

    options = generate_covered_call(symbol, price)

    if options is None or len(options) == 0:
        return None

    shares = positions.get(symbol, 0)

    return {
        "symbol": symbol,
        "price": price,
        "options": options,
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
        price = get_price(symbol)
        if price is None:
            continue

        options = generate_covered_call(symbol, price)
        if not options:
            continue

        best = options[0]

        results.append({
            "symbol": symbol,
            "price": price,
            "strike": best["strike"],
            "premium": best["premium"],
            "yield": best["yield"],
            "expiration": best["expiration"],
            "dte": best["dte"],
            "shares": positions.get(symbol, 0)
        })

    if not results:
        print("No valid results found.")
        return

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


# =====================================================
# SINGLE MODE (UPDATED FOR MULTI-OPTIONS OUTPUT)
# =====================================================
def run_single(symbol):
    positions = get_positions()

    price = get_price(symbol)
    options = generate_covered_call(symbol, price) if price else None

    if price is None or not options:
        print("No valid data found.")
        return

    shares = positions.get(symbol, 0)

    print("\n==============================")
    print(" COVERED CALL ENGINE")
    print("==============================\n")

    print(f"Symbol: {symbol}")
    print(f"Current Price: ${price:.2f}")

    print("\n--- Top 3 Covered Call Suggestions ---")

    for opt in options:
        print(f"\nRank: {opt['rank']}")
        print(f"Strike: ${opt['strike']}")
        print(f"Premium: ${opt['premium']}")
        print(f"Yield: {opt['yield']}%")
        print(f"Expiration: {opt['expiration']} ({opt['dte']} days)")

    print("\n--- Position Check ---")
    print(f"Shares Owned: {shares}")

    if shares >= 100:
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