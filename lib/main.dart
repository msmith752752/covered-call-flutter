import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const CoveredCallApp());
}

class CoveredCallApp extends StatelessWidget {
  const CoveredCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Covered Call Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CoveredCallHome(),
    );
  }
}

class CoveredCallHome extends StatefulWidget {
  const CoveredCallHome({super.key});

  @override
  State<CoveredCallHome> createState() => _CoveredCallHomeState();
}

class _CoveredCallHomeState extends State<CoveredCallHome> {
  final TextEditingController tickerController = TextEditingController();
  final TextEditingController strikeController = TextEditingController();
  final TextEditingController premiumController = TextEditingController();
  final TextEditingController daysController = TextEditingController();

  String currentPrice = "—";
  String result = "";

  final String apiKey = "YOUR_ALPHA_VANTAGE_KEY";

  Future<void> fetchStockPrice(String ticker) async {
    if (ticker.isEmpty) return;

    setState(() {
      currentPrice = "Loading...";
      result = "";
    });

    final url =
        "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=$ticker&apikey=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final price = data["Global Quote"]?["05. price"] ?? "N/A";

        setState(() {
          currentPrice = price.toString();
        });
      } else {
        setState(() {
          currentPrice = "Error";
        });
      }
    } catch (e) {
      setState(() {
        currentPrice = "Error";
      });
    }
  }

  void calculateCoveredCall() {
    final stock = double.tryParse(currentPrice) ?? 0;
    final strike = double.tryParse(strikeController.text) ?? 0;
    final premium = double.tryParse(premiumController.text) ?? 0;
    final days = double.tryParse(daysController.text) ?? 0;

    if (stock == 0 || strike == 0 || premium == 0) {
      setState(() {
        result = "Please enter valid inputs.";
      });
      return;
    }

    final breakEven = stock - premium;
    final maxProfit = (strike - stock) + premium;
    final returnPct = (premium / stock) * 100;
    final annualizedReturn =
        days > 0 ? (premium / stock) * (365 / days) * 100 : 0;

    setState(() {
      result = """
Covered Call Analysis

Stock Price: ${stock.toStringAsFixed(2)}
Strike Price: ${strike.toStringAsFixed(2)}
Premium: ${premium.toStringAsFixed(2)}

Break-even: ${breakEven.toStringAsFixed(2)}
Max Profit: ${maxProfit.toStringAsFixed(2)} per share

Return: ${returnPct.toStringAsFixed(2)}%
Annualized Return: ${annualizedReturn.toStringAsFixed(2)}%
""";
    });
  }

  List<FlSpot> generatePayoffData(
      double stock, double strike, double premium) {
    List<FlSpot> points = [];

    for (double price = stock * 0.5;
        price <= stock * 1.5;
        price += stock * 0.02) {
      double profit;

      if (price >= strike) {
        profit = (strike - stock) + premium;
      } else {
        profit = (price - stock) + premium;
      }

      points.add(FlSpot(price, profit));
    }

    return points;
  }

  Widget buildLabel(String text, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }

  Widget buildPayoffChart() {
    final stock = double.tryParse(currentPrice) ?? 0;
    final strike = double.tryParse(strikeController.text) ?? 0;
    final premium = double.tryParse(premiumController.text) ?? 0;

    if (stock == 0 || strike == 0 || premium == 0) {
      return const Text("Enter inputs to view chart");
    }

    final breakEven = stock - premium;
    final spots = generatePayoffData(stock, strike, premium);

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          minY: -stock * 0.5,
          maxY: stock * 0.5,

          gridData: const FlGridData(show: true),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: true),

          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 0,
                color: Colors.grey,
                strokeWidth: 1,
              ),
            ],
          ),

          lineBarsData: [
            // Payoff curve
            LineChartBarData(
              spots: spots,
              isCurved: true,
              dotData: const FlDotData(show: false),
              barWidth: 3,
            ),

            // Break-even
            LineChartBarData(
              spots: [
                FlSpot(breakEven, -stock * 0.5),
                FlSpot(breakEven, stock * 0.5),
              ],
              isCurved: false,
              color: Colors.green,
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),

            // Strike
            LineChartBarData(
              spots: [
                FlSpot(strike, -stock * 0.5),
                FlSpot(strike, stock * 0.5),
              ],
              isCurved: false,
              color: Colors.red,
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Covered Call Builder"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: tickerController,
                decoration: const InputDecoration(
                  labelText: "Ticker (e.g. AAPL)",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    fetchStockPrice(
                        tickerController.text.trim().toUpperCase());
                  },
                  child: const Text("Get Stock Price"),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Current Price: ${currentPrice}",
                style: const TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: strikeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Strike Price",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: premiumController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Option Premium (per share)",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: daysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Days to Expiration",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: calculateCoveredCall,
                  child: const Text("Calculate Covered Call"),
                ),
              ),

              const SizedBox(height: 20),

              Text(result, style: const TextStyle(fontSize: 16)),

              const SizedBox(height: 20),

              const Text(
                "Payoff Chart",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildLabel("Payoff", Colors.blue),
                  buildLabel("Break-even", Colors.green),
                  buildLabel("Strike", Colors.red),
                ],
              ),

              const SizedBox(height: 10),

              buildPayoffChart(),
            ],
          ),
        ),
      ),
    );
  }
}