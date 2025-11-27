/// Common extensions for Dart collections and types

extension FirstWhereOrNullExtension<E> on List<E> {
  /// Returns the first element that matches the predicate, or null if none match
  E? firstWhereOrNull(bool Function(E element) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }
}
