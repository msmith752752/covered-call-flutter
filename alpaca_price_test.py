import requests

API_KEY = "CK98WRRPZT4COIUU0EA8"
SECRET_KEY = "3zAQacJOYWI9TAspgaW2NEt1aXfyCi1Z5IYJiLMW"

url = "https://data.alpaca.markets/v2/stocks/AAPL/trades/latest"

headers = {
    "APCA-API-KEY-ID": API_KEY,
    "APCA-API-SECRET-KEY": SECRET_KEY
}

response = requests.get(url, headers=headers)

print("STATUS CODE:", response.status_code)
print("RAW RESPONSE:")
print(response.text)