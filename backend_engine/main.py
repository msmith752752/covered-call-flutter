from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from covered_call_engine import analyze, get_positions

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {
        "status": "ok",
        "message": "Yield Pilot API running"
    }

@app.get("/covered-call")
def covered_call(symbol: str, shares: int = 0):
    clean_symbol = symbol.upper().strip()

    positions = get_positions()

    if shares > 0:
        positions[clean_symbol] = shares

    result = analyze(clean_symbol, positions)

    if not result:
        return {
            "error": "No data found",
            "symbol": clean_symbol,
            "shares": shares
        }

    options = result.get("options", [])
    best = options[0] if options else None

    return {
        "symbol": result.get("symbol"),
        "price": result.get("price"),
        "shares": result.get("shares"),
        "options": options,
        "best": best
    }