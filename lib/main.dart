import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Covered Call Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const CoveredCallPage(),
    );
  }
}

class CoveredCallPage extends StatefulWidget {
  const CoveredCallPage({super.key});

  @override
  State<CoveredCallPage> createState() => _CoveredCallPageState();
}

class _CoveredCallPageState extends State<CoveredCallPage> {
  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _sharesController = TextEditingController();

  final String baseUrl = "http://54.147.143.148:8000";

  bool isLoading = false;
  String errorMessage = "";

  String symbol = "";
  double? stockPrice;
  int sharesOwned = 0;
  List<dynamic> options = [];

  Future<void> fetchCoveredCall() async {
    final inputSymbol = _symbolController.text.trim().toUpperCase();
    final parsedShares = int.tryParse(_sharesController.text.trim()) ?? 0;

    if (inputSymbol.isEmpty) {
      setState(() {
        errorMessage = "Please enter a stock symbol.";
        options = [];
        stockPrice = null;
        symbol = "";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = "";
      options = [];
      stockPrice = null;
      symbol = "";
      sharesOwned = parsedShares;
    });

    try {
      final url = Uri.parse("$baseUrl/covered-call")
          .replace(queryParameters: {"symbol": inputSymbol});

      final response = await http.get(url);

      if (response.statusCode != 200) {
        setState(() {
          errorMessage = "HTTP Error ${response.statusCode}\n${response.body}";
        });
        return;
      }

      final data = jsonDecode(response.body);
      final returnedOptions = data["options"];

      if (returnedOptions == null ||
          returnedOptions is! List ||
          returnedOptions.isEmpty) {
        setState(() {
          errorMessage = "No covered call options found for $inputSymbol.";
        });
        return;
      }

      setState(() {
        symbol = data["symbol"] ?? inputSymbol;
        stockPrice = (data["price"] as num).toDouble();
        options = returnedOptions;
      });
    } catch (e) {
      setState(() {
        errorMessage =
            "Network error. Make sure the EC2 backend is running.\n\n$e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  int get contractCount {
    if (sharesOwned < 100) return 0;
    return sharesOwned ~/ 100;
  }

  String optionTitle(int index) {
    if (index == 0) return "Best Covered Call";
    if (index == 1) return "Alternative Covered Call";
    if (index == 2) return "Aggressive Covered Call";
    return "Covered Call Option";
  }

  IconData optionIcon(int index) {
    if (index == 0) return Icons.lightbulb_outline;
    if (index == 1) return Icons.balance;
    if (index == 2) return Icons.local_fire_department_outlined;
    return Icons.trending_up;
  }

  Widget buildOptionCard(dynamic option, int index) {
    final strike = (option["strike"] as num).toDouble();
    final premium = (option["premium"] as num).toDouble();
    final yieldPct = (option["yield"] as num).toDouble();
    final expiration = option["expiration"];
    final dte = option["dte"];

    final estimatedIncome = premium * contractCount * 100;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(optionIcon(index)),
                const SizedBox(width: 8),
                Text(
                  optionTitle(index),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            buildMetricRow("Strike", "\$${strike.toStringAsFixed(2)}"),
            buildMetricRow("Premium / Share", "\$${premium.toStringAsFixed(2)}"),
            buildMetricRow("Yield", "${yieldPct.toStringAsFixed(2)}%"),
            buildMetricRow("Expiration", "$expiration"),
            buildMetricRow("Days to Expiration", "$dte"),
            const Divider(height: 24),
            buildMetricRow("Contracts", "$contractCount"),
            buildMetricRow(
              "Estimated Income",
              "\$${estimatedIncome.toStringAsFixed(2)}",
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget buildStockHeader() {
    if (symbol.isEmpty || stockPrice == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  symbol,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "\$${stockPrice!.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            buildMetricRow("Shares Owned", "$sharesOwned"),
            buildMetricRow("Covered Call Contracts", "$contractCount"),
          ],
        ),
      ),
    );
  }

  Widget buildDisclaimer() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: const Text(
        "Educational use only. This app does not provide financial advice. "
        "Estimated income assumes 100 shares per options contract and does not include fees, assignment risk, taxes, or price changes.",
        style: TextStyle(fontSize: 13, color: Colors.black87),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = options.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Covered Call Assistant"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "Find covered call ideas and estimate potential income based on shares owned.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _symbolController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: "Enter Symbol",
                  hintText: "Example: AAPL",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => fetchCoveredCall(),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _sharesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Shares Owned",
                  hintText: "Example: 100",
                  prefixIcon: Icon(Icons.pie_chart_outline),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => fetchCoveredCall(),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : fetchCoveredCall,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isLoading ? "Loading..." : "Get Covered Calls",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              if (isLoading) const CircularProgressIndicator(),

              if (!isLoading && errorMessage.isNotEmpty)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),

              if (!isLoading && hasResults)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        buildStockHeader(),
                        for (int i = 0; i < options.length && i < 3; i++)
                          buildOptionCard(options[i], i),
                        buildDisclaimer(),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}