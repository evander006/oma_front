/// Returns the upper budget limit for the AI API in BYN.
///
/// An "от ..." choice is a *minimum*, not a ceiling. The current API accepts
/// an upper limit only, so return null rather than enforcing a wrong maximum.
/// The full human-readable choice is still included in the recommendation
/// prompt, but a server-side minimum is not enforced by this helper.
double? maxBudgetBynFromLabel(String? label) {
  final value = label?.trim().toLowerCase();
  if (value == null || value.isEmpty || value.startsWith('от ')) {
    return null;
  }

  // The available labels include "до 1 000 BYN" and "1–3 000 BYN".
  // The last number is their upper bound.
  final matches = RegExp(r'\d[\d\s]*').allMatches(value).toList();
  if (matches.isEmpty) return null;

  final digits = matches.last.group(0)!.replaceAll(RegExp(r'\s'), '');
  return double.tryParse(digits);
}
