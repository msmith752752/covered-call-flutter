class CoveredCallResult {
  final double maxProfit;          // per share
  final double breakeven;
  final double returnPercent;      // decimal (0.07 = 7%)
  final double annualizedReturn;   // decimal
  final double totalProfit;        // for 100 shares

  CoveredCallResult({
    required this.maxProfit,
    required this.breakeven,
    required this.returnPercent,
    required this.annualizedReturn,
    required this.totalProfit,
  });

  @override
  String toString() {
    return '''
Max Profit (per share): \$${maxProfit.toStringAsFixed(2)}
Total Profit (100 shares): \$${totalProfit.toStringAsFixed(2)}
Breakeven: \$${breakeven.toStringAsFixed(2)}
Return: ${(returnPercent * 100).toStringAsFixed(2)}%
Annualized Return: ${(annualizedReturn * 100).toStringAsFixed(2)}%
''';
  }
}

class CoveredCallCalculator {
  static CoveredCallResult calculate({
    required double stockPrice,
    required double strikePrice,
    required double premium,
    required int daysToExpiration,
  }) {
    if (daysToExpiration <= 0) {
      throw ArgumentError('Days to expiration must be greater than 0');
    }

    // Max profit per share
    double maxProfit = (strikePrice - stockPrice) + premium;

    // Breakeven price
    double breakeven = stockPrice - premium;

    // Return %
    double returnPercent = maxProfit / stockPrice;

    // Annualized return %
    double annualizedReturn =
        returnPercent * (365 / daysToExpiration);

    // Total profit (100 shares standard contract)
    double totalProfit = maxProfit * 100;

    return CoveredCallResult(
      maxProfit: maxProfit,
      breakeven: breakeven,
      returnPercent: returnPercent,
      annualizedReturn: annualizedReturn,
      totalProfit: totalProfit,
    );
  }
}