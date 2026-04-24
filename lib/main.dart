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
      final url = Uri.parse(
          "http://98.93.104.104:8000/covered-call?symbol=$symbol");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          result =
              "Symbol: ${data['symbol']}\n"
              "Price: \$${data['price']}\n"
              "Strike: \$${data['strike']}\n"
              "Premium: \$${data['premium']}\n"
              "Yield: ${data['yield']}%\n"
              "Expiration: ${data['expiration']}\n"
              "DTE: ${data['dte']}";
        });
      } else {
        setState(() {
          result = "Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        result = "Error: $e";
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
              Card(
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
          ],
        ),
      ),
    );
  }
}