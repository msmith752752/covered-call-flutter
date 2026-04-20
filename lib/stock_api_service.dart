import 'dart:convert';
import 'package:http/http.dart' as http;

class StockApiService {
  // 👉 Replace this with your real Alpha Vantage API key
  static const String _apiKey = 'UIFQ7CFLE5Y68I39';

  /// Fetches live stock price for a given ticker (e.g. AAPL, TSLA)
  static Future<double> fetchStockPrice(String symbol) async {
    final url = Uri.parse(
      'https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$_apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load stock data');
    }

    final data = jsonDecode(response.body);

    final priceString = data['Global Quote']?['05. price'];

    if (priceString == null) {
      throw Exception('Invalid symbol or no data returned');
    }

    return double.parse(priceString);
  }
}