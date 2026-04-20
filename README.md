# 📈 Covered Call Analyzer (Flutter + API)

A mobile-first financial analytics app that helps investors evaluate covered call trades using real-time stock data and options pricing logic.

---

## 🎯 What This Project Demonstrates

This project is not just a calculator — it demonstrates:

- Real-time financial data integration via REST APIs
- Practical options trading analytics (covered calls)
- Financial modeling (return, breakeven, annualized yield)
- Clean Flutter architecture (UI + service separation)
- State-driven mobile UI development

---

## 🚀 Features

- 🔎 Live stock price lookup (Alpha Vantage API)
- 🧮 Covered call profit calculator
- 📊 Annualized return analysis
- 📉 Break-even price calculation
- 🟢 Trade quality scoring system (Strong / Moderate / Weak)
- 📱 Cross-platform Flutter UI (Web, iOS, Android)

---

## 🧠 How It Works

1. Enter stock ticker (e.g. AAPL)
2. Fetch live market price
3. Input:
   - Strike price
   - Premium received
   - Days to expiration
4. App calculates:
   - Max profit
   - Total profit
   - Break-even price
   - Return %
   - Annualized return
   - Trade quality score

---

## 📊 Example Output

- Stock: AAPL @ $190  
- Strike: $195  
- Premium: $3  
- Days: 30  

Results:
- 🟢 Strong Trade  
- Annualized Return: 22.5%  
- Break-even: $187  

---

## 🛠 Tech Stack

- Flutter (Dart)
- REST API (Alpha Vantage)
- HTTP package
- Stateful UI (setState)
- Financial modeling logic

---

## 📁 Project Structure
lib/
├── main.dart
├── covered_call_calculator.dart
├── stock_api_service.dart


---

## 📌 Key Engineering Highlights

- Separation of concerns (UI vs API vs logic)
- Real-world financial computation model
- Scalable architecture for future features
- External API integration with error handling

---

## 🚧 Future Improvements

- Options chain integration
- Multi-contract analysis
- Portfolio tracking system
- Backend (AWS Lambda)
- Chart visualization of payoff curves