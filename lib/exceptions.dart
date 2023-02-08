///An exception thrown when the attribute has no element `labels`
class NoLabelException implements Exception {
  ///The description for the exception.
  String cause;

  ///Exception constructor containing the description for the exception.
  NoLabelException(this.cause);
  @override
  String toString() => "NoLabelException: $cause";
}

///An exception thrown when other type than List<Int> is provided as `cells` element value
class WrongCellFormatException implements Exception {
  ///The description for the exception.
  String cause;

  ///Exception constructor containing the description for the exception.
  WrongCellFormatException(this.cause);
  @override
  String toString() => "WrongCellFormatException: $cause";
}