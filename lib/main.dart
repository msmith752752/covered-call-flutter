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

  // 🟢 NEW: Fetch live stock price
  Future<void> fetchPrice() async {
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
    }
  }

  void calculate() {
    try {
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
            inputField("Ticker (e.g. AAPL)", tickerController),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: fetchPrice,
                child: const Text("Fetch Stock Price"),
              ),
            ),

            inputField(
              "Stock Price (auto-filled)",
              stockController,
              type: TextInputType.number,
            ),
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

            resultBox(),
          ],
        ),
      ),
    );
  }
}