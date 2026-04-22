import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
      title: 'Covered Call',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
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
  final tickerController = TextEditingController();
  final stockController = TextEditingController();
  final strikeController = TextEditingController();
  final premiumController = TextEditingController();
  final daysController = TextEditingController();

  CoveredCallResult? result;
  bool isLoadingPrice = false;

  String getTradeQuality(double annualizedReturn) {
    if (annualizedReturn >= 0.20) return "Strong Trade 🟢";
    if (annualizedReturn >= 0.10) return "Moderate Trade 🟡";
    return "Weak Trade 🔴";
  }

  Future<void> fetchPrice() async {
    setState(() => isLoadingPrice = true);

    try {
      final ticker = tickerController.text.trim().toUpperCase();
      if (ticker.isEmpty) return;

      final price = await StockApiService.fetchStockPrice(ticker);

      setState(() {
        stockController.text = price.toStringAsFixed(2);
      });
    } finally {
      setState(() => isLoadingPrice = false);
    }
  }

  void calculate() {
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

    setState(() => result = calc);
  }

  Widget card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: child,
    );
  }

  Widget input(TextEditingController c, String label,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF2F3F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget buildResult() {
    if (result == null) return const SizedBox();

    return card(
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
          const SizedBox(height: 12),
          Text("Max Profit: \$${result!.maxProfit.toStringAsFixed(2)}"),
          Text("Total Profit: \$${result!.totalProfit.toStringAsFixed(2)}"),
          Text("Breakeven: \$${result!.breakeven.toStringAsFixed(2)}"),
          Text("Return: ${(result!.returnPercent * 100).toStringAsFixed(2)}%"),
          Text(
              "Annualized: ${(result!.annualizedReturn * 100).toStringAsFixed(2)}%"),
        ],
      ),
    );
  }

  Widget profitChart() {
    if (result == null) return const SizedBox();

    final stock = double.tryParse(stockController.text) ?? 0;
    final premium = double.tryParse(premiumController.text) ?? 0;
    final baseStrike = double.tryParse(strikeController.text) ?? stock;

    final List<FlSpot> spots = [];

    for (double s = baseStrike - 10; s <= baseStrike + 10; s += 2) {
      double profit;

      if (stock >= s) {
        profit = (s - stock) + premium;
      } else {
        profit = premium;
      }

      spots.add(FlSpot(s, profit));
    }

    return card(
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                barWidth: 3,
                dotData: const FlDotData(show: false),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Covered Call"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // MARKET
          card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Market",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                input(tickerController, "Ticker (AAPL)"),
                ElevatedButton(
                  onPressed: isLoadingPrice ? null : fetchPrice,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(45),
                  ),
                  child: isLoadingPrice
                      ? const CircularProgressIndicator()
                      : const Text("Get Price"),
                ),
                const SizedBox(height: 12),
                input(stockController, "Stock Price",
                    type: TextInputType.number),
              ],
            ),
          ),

          // TRADE SETUP
          card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Trade Setup",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                input(strikeController, "Strike Price",
                    type: TextInputType.number),
                input(premiumController, "Premium",
                    type: TextInputType.number),
                input(daysController, "Days to Expiration",
                    type: TextInputType.number),
                const SizedBox(height: 6),
                ElevatedButton(
                  onPressed: calculate,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(45),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Calculate Trade"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // RESULTS + CHART
          buildResult(),
          const SizedBox(height: 12),
          profitChart(),
        ],
      ),
    );
  }
}