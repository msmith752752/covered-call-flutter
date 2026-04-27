import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yield Pilot',
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

  @override
  void initState() {
    super.initState();
    loadSavedInputs();
  }

  Future<void> loadSavedInputs() async {
    final prefs = await SharedPreferences.getInstance();

    final savedSymbol = prefs.getString("last_symbol") ?? "";
    final savedShares = prefs.getInt("last_shares") ?? 0;

    setState(() {
      _symbolController.text = savedSymbol;
      _sharesController.text = savedShares == 0 ? "" : savedShares.toString();
    });
  }

  Future<void> saveInputs(String symbol, int shares) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("last_symbol", symbol);
    await prefs.setInt("last_shares", shares);
  }

  void showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("About This App"),
          content: const Text(
            "This app helps estimate covered call income.\n\n"
            "Covered calls generate income, but shares may be called away.\n\n"
            "Educational use only.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Got it"),
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchCoveredCall() async {
    final inputSymbol = _symbolController.text.trim().toUpperCase();
    final parsedShares = int.tryParse(_sharesController.text.trim()) ?? 0;

    await saveInputs(inputSymbol, parsedShares);

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
      final data = jsonDecode(response.body);

      setState(() {
        symbol = data["symbol"];
        stockPrice = (data["price"] as num).toDouble();
        options = data["options"];
      });
    } catch (e) {
      setState(() {
        errorMessage = "Backend not running or network issue.";
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

    final breakEven = stockPrice != null ? stockPrice! - premium : 0;
    final maxProfit = stockPrice != null
        ? ((strike - stockPrice!) + premium) * sharesOwned
        : 0;

    double distancePct = 0;
    if (stockPrice != null) {
      distancePct = (strike - stockPrice!) / stockPrice!;
    }

    String riskLabel = "Balanced";
    Color riskColor = Colors.orange;
    IconData riskIcon = Icons.balance;

    if (distancePct <= 0.02) {
      riskLabel = "Conservative";
      riskColor = Colors.green;
      riskIcon = Icons.shield;
    } else if (distancePct <= 0.05) {
      riskLabel = "Balanced";
    } else {
      riskLabel = "Aggressive";
      riskColor = Colors.red;
      riskIcon = Icons.warning_amber;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(riskIcon, size: 16, color: riskColor),
                      const SizedBox(width: 4),
                      Text(
                        riskLabel,
                        style: TextStyle(
                          color: riskColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
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
            const Divider(height: 24),
            const Text(
              "Trade Summary",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            buildMetricRow("Break-even", "\$${breakEven.toStringAsFixed(2)}"),
            buildMetricRow("Max Profit", "\$${maxProfit.toStringAsFixed(2)}"),
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

  @override
  Widget build(BuildContext context) {
    final hasResults = options.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Yield Pilot",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: showInfoDialog,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Navigate Covered Call Income With Clarity",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Enter Position",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _symbolController,
              decoration: const InputDecoration(
                labelText: "Stock Symbol (e.g. AAPL)",
                hintText: "AAPL",
                prefixIcon: Icon(Icons.search),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _sharesController,
              decoration: const InputDecoration(
                labelText: "Shares Owned",
                hintText: "100",
                prefixIcon: Icon(Icons.pie_chart_outline),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: fetchCoveredCall,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Analyze Covered Call",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),

            if (isLoading)
              Column(
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text("Analyzing options..."),
                ],
              ),

            if (errorMessage.isNotEmpty)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),

            if (!isLoading && options.isEmpty && errorMessage.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text(
                  "Enter a stock symbol and shares to analyze covered call opportunities.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ),

            if (hasResults)
              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    return buildOptionCard(options[index], index);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}