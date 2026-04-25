from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from covered_call_engine import analyze, get_positions

app = FastAPI()

# =====================================================
# CORS FIX (allows Flutter Web / browser access)
# =====================================================
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # dev only
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# =====================================================
# HEALTH CHECK (optional but useful for debugging)
# =====================================================
@app.get("/")
def root():
    return {"status": "ok", "message": "Covered Call API running"}


# =====================================================
# COVERED CALL ENDPOINT (UPDATED FOR MULTI-OPTIONS)
# =====================================================
@app.get("/covered-call")
def covered_call(symbol: str):
    positions = get_positions()
    result = analyze(symbol.upper(), positions)

    if not result:
        return {"error": "No data found"}

    # Extract best option safely
    options = result.get("options", [])
    best = options[0] if options else None

    return {
        "symbol": result.get("symbol"),
        "price": result.get("price"),
        "shares": result.get("shares"),

        # NEW: full list of 3 strategies
        "options": options,

        # convenience shortcut (frontend still likes this)
        "best": best
    }