from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from covered_call_engine import analyze, get_positions

app = FastAPI()

# =====================================================
# CORS FIX (allows Flutter Web / browser access)
# =====================================================
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # for development only
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =====================================================
# API ENDPOINT
# =====================================================
@app.get("/covered-call")
def covered_call(symbol: str):
    positions = get_positions()
    result = analyze(symbol.upper(), positions)

    if not result:
        return {"error": "No data found"}

    return result