import argparse
import os
from datetime import datetime
import yfinance as yf
import pandas as pd

try:
    from alpaca.trading.client import TradingClient
except Exception:
    TradingClient = None


# =====================================================
# CONFIG
# =====================================================
API_KEY = os.getenv("ALPACA_API_KEY")
SECRET_KEY = os.getenv("ALPACA_SECRET_KEY")

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
# BROKERAGE
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
# STRATEGY
# =====================================================
def generate_covered_call(symbol, price, min_dte=7, max_dte=30):
    options = get_options_chain(symbol)

    if options is None or options.empty:
        return None

    # Safe numeric conversion
    for col in ["bid", "ask", "lastPrice", "volume"]:
        if col in options.columns:
            options[col] = pd.to_numeric(options[col], errors="coerce")
        else:
            options[col] = 0

    options = options.fillna(0)

    try:
        filtered = options[
            (options["strike"] > price) &
            (options["strike"] <= price * 1.05) &
            (options["strike"] >= price * 1.01) &
            (options["dte"] >= min_dte) &
            (options["dte"] <= max_dte) &
            (options["lastPrice"].fillna(0) > 0) &
            (options["volume"].fillna(0) > 50)
        ].copy()

        if filtered.empty:
            return None

        filtered["yield"] = (filtered["lastPrice"].fillna(0) / price) * 100

        sorted_calls = filtered.sort_values(by="yield", ascending=False)
        top_calls = sorted_calls.head(3)

        results = []
        labels = ["best", "alternative", "aggressive"]

        for i, (_, row) in enumerate(top_calls.iterrows()):
            results.append({
                "rank": labels[i] if i < len(labels) else f"option_{i+1}",
                "strike": round(row.get("strike", 0), 2),
                "premium": round(row.get("lastPrice", 0), 2),
                "yield": round(row.get("yield", 0), 2),
                "expiration": row.get("expiration"),
                "dte": int(row.get("dte", 0))
            })

        return results

    except Exception:
        return None


# =====================================================
# ANALYSIS
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