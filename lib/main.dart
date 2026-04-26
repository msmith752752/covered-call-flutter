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
      title: 'Covered Call App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
  final TextEditingController _controller = TextEditingController();
  String result = "";
  bool isLoading = false;

  final String baseUrl = "http://54.147.143.148:8000";

  String formatOption(String title, dynamic option) {
    final strike = option['strike'].toDouble();
    final premium = option['premium'].toDouble();
    final yieldPct = option['yield'].toDouble();

    return "$title\n"
        "---------------------------\n"
        "Strike: \$${strike.toStringAsFixed(2)}\n"
        "Premium: \$${premium.toStringAsFixed(2)}\n"
        "Yield: ${yieldPct.toStringAsFixed(2)}%\n"
        "Expiration: ${option['expiration']}\n"
        "Days to Expiration: ${option['dte']}\n";
  }

  Future<void> fetchCoveredCall() async {
    final symbol = _controller.text.trim().toUpperCase();

    if (symbol.isEmpty) {
      setState(() {
        result = "Please enter a symbol";
      });
      return;
    }

    setState(() {
      isLoading = true;
      result = "";
    });

    try {
      final url = Uri.parse("$baseUrl/covered-call")
          .replace(queryParameters: {"symbol": symbol});

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final options = data["options"];

        final best = options[0];
        final alternative = options[1];
        final aggressive = options[2];

        setState(() {
          final price = data['price'].toDouble();

          result =
              "📈 ${data['symbol']}\n"
              "Price: \$${price.toStringAsFixed(2)}\n\n"
              "${formatOption("💡 Best Covered Call", best)}\n"
              "${formatOption("⚖️ Alternative Covered Call", alternative)}\n"
              "${formatOption("🔥 Aggressive Covered Call", aggressive)}";
        });
      } else {
        setState(() {
          result = "HTTP ERROR ${response.statusCode}\n\n${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        result = "⚠️ NETWORK ERROR\n\n$e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Covered Call App"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Enter Symbol (e.g. AAPL)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: isLoading ? null : fetchCoveredCall,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text("Get Covered Call"),
            ),

            const SizedBox(height: 20),

            if (isLoading)
              const Center(child: CircularProgressIndicator()),

            if (!isLoading && result.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        result,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}