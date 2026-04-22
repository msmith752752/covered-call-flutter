import 'package:flutter/material.dart';
import 'covered_call_calculator.dart';
import 'stock_api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Covered Call Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const CoveredCallScreen(),
    );
  }
}

class CoveredCallScreen extends StatefulWidget {
  const CoveredCallScreen({super.key});

  @override
  State<CoveredCallScreen> createState() => _CoveredCallScreenState();
}

class _CoveredCallScreenState extends State<CoveredCallScreen> {
  // Controllers
  final tickerController = TextEditingController();
  final stockController = TextEditingController();
  final strikeController = TextEditingController();
  final premiumController = TextEditingController();
  final daysController = TextEditingController();

  CoveredCallResult? result;
  bool isLoadingPrice = false;

  // Trade Quality Score
  String getTradeQuality(double annualizedReturn) {
    if (annualizedReturn >= 0.20) {
      return "🟢 Strong Trade";
    } else if (annualizedReturn >= 0.10) {
      return "🟡 Moderate Trade";
    } else {
      return "🔴 Weak Trade";
    }
  }

  // Fetch live stock price
  Future<void> fetchPrice() async {
    setState(() => isLoadingPrice = true);

    try {
      final ticker = tickerController.text.trim().toUpperCase();

      if (ticker.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a ticker symbol')),
        );
        return;
      }

      final price = await StockApiService.fetchStockPrice(ticker);

      setState(() {
        stockController.text = price.toStringAsFixed(2);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching price: $e')),
      );
    } finally {
      setState(() => isLoadingPrice = false);
    }
  }

  void calculate() {
    try {
      if (stockController.text.isEmpty ||
          strikeController.text.isEmpty ||
          premiumController.text.isEmpty ||
          daysController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fill in all fields')),
        );
        return;
      }

      final stockPrice = double.parse(stockController.text);
      final strikePrice = double.parse(strikeController.text);
      final premium = double.parse(premiumController.text);
      final days = int.parse(daysController.text);

      final calc = CoveredCallCalculator.calculate(
        stockPrice: stockPrice,
        strikePrice: strikePrice,
        premium: premium,
        daysToExpiration: days,
      );

      setState(() {
        result = calc;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid numbers in all fields')),
      );
    }
  }

  Widget inputField(String label, TextEditingController controller,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // NEW: Section header widget
  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget resultBox() {
    if (result == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTradeQuality(result!.annualizedReturn),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Text("Max Profit: \$${result!.maxProfit.toStringAsFixed(2)}"),
          Text("Total Profit: \$${result!.totalProfit.toStringAsFixed(2)}"),
          Text("Breakeven: \$${result!.breakeven.toStringAsFixed(2)}"),
          Text("Return: ${(result!.returnPercent * 100).toStringAsFixed(2)}%"),
          Text("Annualized: ${(result!.annualizedReturn * 100).toStringAsFixed(2)}%"),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Covered Call Calculator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📊 Market Data
            sectionTitle("📊 Market Data"),

            inputField("Ticker (e.g. AAPL)", tickerController),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoadingPrice ? null : fetchPrice,
                child: isLoadingPrice
                    ? const CircularProgressIndicator()
                    : const Text("Fetch Stock Price"),
              ),
            ),

            inputField(
              "Stock Price (auto-filled)",
              stockController,
              type: TextInputType.number,
            ),

            // 📈 Trade Setup
            sectionTitle("📈 Trade Setup"),

            inputField(
              "Strike Price",
              strikeController,
              type: TextInputType.number,
            ),
            inputField(
              "Premium",
              premiumController,
              type: TextInputType.number,
            ),
            inputField(
              "Days to Expiration",
              daysController,
              type: TextInputType.number,
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: calculate,
                child: const Text("Calculate"),
              ),
            ),

            // 🧮 Results
            sectionTitle("🧮 Results"),

            resultBox(),
          ],
        ),
      ),
    );
  }
}