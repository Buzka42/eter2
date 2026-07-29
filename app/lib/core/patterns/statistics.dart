/// The arithmetic that decides whether a pattern is worth telling someone.
///
/// Eter looks for correlations across everything it records, which means it
/// tests a lot of pairs. Testing a lot of pairs is exactly how you find things
/// that are not there: at the conventional 5% threshold, one test in twenty
/// comes back "significant" from noise alone, and forty tests will hand you
/// two confident falsehoods every time you run them.
///
/// So significance here is not a single p-value against 0.05. It is:
///
/// * **enough paired days** — a correlation over five days is a coincidence
///   with a number attached;
/// * **an effect worth mentioning** — statistical significance is not the same
///   as mattering, and a real but tiny association is noise to a person;
/// * **a false-discovery correction across the whole sweep** — Benjamini and
///   Hochberg, so the survivors are controlled as a set rather than each
///   judged as if it were the only question asked.
///
/// The consequence is the one asked for: a new user is told nothing, because
/// nothing can honestly be said yet, and the same person is told something
/// months later when their own record has earned it.
library;

import 'dart:math' as math;

/// One tested relationship, before the sweep decides whether it survives.
class Correlation {
  const Correlation({
    required this.r,
    required this.n,
    required this.p,
  });

  /// Pearson's r, in [-1, 1].
  final double r;

  /// Paired observations. Days where either side is missing are not pairs.
  final int n;

  /// Two-tailed probability of an |r| this large under no association.
  final double p;

  /// Shared variance, which is the honest way to describe strength to a
  /// person: r = 0.5 sounds like half of something and explains a quarter.
  double get explainedFraction => r * r;

  bool get isPositive => r > 0;
}

/// Pearson correlation with its two-tailed p-value, or null when the pair
/// cannot be judged at all.
///
/// Returns null rather than zero for a constant series: someone whose step
/// count never varies has no relationship to measure, which is different from
/// having one of zero strength.
Correlation? correlate(List<double> xs, List<double> ys) {
  if (xs.length != ys.length || xs.length < 3) return null;
  final n = xs.length;
  final meanX = xs.reduce((a, b) => a + b) / n;
  final meanY = ys.reduce((a, b) => a + b) / n;

  var covariance = 0.0;
  var varianceX = 0.0;
  var varianceY = 0.0;
  for (var i = 0; i < n; i++) {
    final dx = xs[i] - meanX;
    final dy = ys[i] - meanY;
    covariance += dx * dy;
    varianceX += dx * dx;
    varianceY += dy * dy;
  }
  if (varianceX <= 0 || varianceY <= 0) return null;

  final r = (covariance / math.sqrt(varianceX * varianceY)).clamp(-1.0, 1.0);
  // Perfect correlation in real records means a variable derived from another,
  // not a discovery. It also makes the t statistic infinite.
  if (r.abs() >= 0.999) return null;

  final t = r * math.sqrt((n - 2) / (1 - r * r));
  return Correlation(r: r.toDouble(), n: n, p: _twoTailedT(t.abs(), n - 2));
}

/// Two-tailed p for Student's t with [df] degrees of freedom.
double _twoTailedT(double t, int df) {
  if (df <= 0) return 1;
  // P(|T| > t) = I_{df/(df+t²)}(df/2, 1/2)
  final x = df / (df + t * t);
  return _incompleteBeta(x, df / 2, 0.5).clamp(0.0, 1.0);
}

/// Regularised incomplete beta, by the standard continued fraction.
///
/// Written out rather than pulled in: one function is a smaller liability than
/// a statistics package, and this one is checkable against any table.
double _incompleteBeta(double x, double a, double b) {
  if (x <= 0) return 0;
  if (x >= 1) return 1;
  final lnBeta = _lnGamma(a) + _lnGamma(b) - _lnGamma(a + b);
  final front = math.exp(
    a * math.log(x) + b * math.log(1 - x) - lnBeta,
  );
  // The fraction converges quickly for x < (a+1)/(a+b+2); otherwise use the
  // symmetry I_x(a,b) = 1 - I_{1-x}(b,a).
  if (x > (a + 1) / (a + b + 2)) {
    return 1 - _incompleteBeta(1 - x, b, a);
  }
  var f = 1.0;
  var c = 1.0;
  var d = 0.0;
  for (var i = 0; i <= 300; i++) {
    final m = i ~/ 2;
    final double numerator;
    if (i == 0) {
      numerator = 1;
    } else if (i.isEven) {
      numerator = (m * (b - m) * x) / ((a + 2 * m - 1) * (a + 2 * m));
    } else {
      numerator =
          -((a + m) * (a + b + m) * x) / ((a + 2 * m) * (a + 2 * m + 1));
    }
    d = 1 + numerator * d;
    if (d.abs() < 1e-30) d = 1e-30;
    d = 1 / d;
    c = 1 + numerator / c;
    if (c.abs() < 1e-30) c = 1e-30;
    final delta = c * d;
    f *= delta;
    if ((1 - delta).abs() < 1e-12) break;
  }
  return front * (f - 1) / a;
}

/// Lanczos approximation. Accurate well beyond anything this needs.
double _lnGamma(double value) {
  const coefficients = [
    76.18009172947146,
    -86.50532032941677,
    24.01409824083091,
    -1.231739572450155,
    0.1208650973866179e-2,
    -0.5395239384953e-5,
  ];
  var y = value;
  final tmp = value + 5.5 - (value + 0.5) * math.log(value + 5.5);
  var series = 1.000000000190015;
  for (var i = 0; i < 6; i++) {
    series += coefficients[i] / ++y;
  }
  return -tmp + math.log(2.5066282746310005 * series / value);
}

/// A tested pair, carrying whatever the caller needs to describe it.
class Candidate<T> {
  const Candidate({required this.subject, required this.correlation});

  final T subject;
  final Correlation correlation;
}

/// Keeps only the findings that survive the whole sweep.
///
/// Benjamini–Hochberg: sort by p, keep the largest k where p(k) ≤ k/m · q, and
/// take everything at or below it. This controls the *proportion* of false
/// findings among those reported, which is the right question when the app is
/// looking for anything rather than testing one hypothesis somebody chose.
///
/// [minimumPairs] and [minimumAbsR] are applied first, because a finding that
/// is significant but trivial, or significant on nine days, should never enter
/// the correction in the first place — it would only consume its budget.
List<Candidate<T>> survivingFindings<T>(
  List<Candidate<T>> candidates, {
  double falseDiscoveryRate = 0.1,
  int minimumPairs = 21,
  double minimumAbsR = 0.35,
}) {
  final eligible = [
    for (final candidate in candidates)
      if (candidate.correlation.n >= minimumPairs &&
          candidate.correlation.r.abs() >= minimumAbsR)
        candidate,
  ]..sort((a, b) => a.correlation.p.compareTo(b.correlation.p));
  if (eligible.isEmpty) return const [];

  final m = eligible.length;
  var cutoff = -1;
  for (var i = 0; i < m; i++) {
    if (eligible[i].correlation.p <= (i + 1) / m * falseDiscoveryRate) {
      cutoff = i;
    }
  }
  if (cutoff < 0) return const [];
  return eligible.take(cutoff + 1).toList();
}
