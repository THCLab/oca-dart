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

///An exception thrown when OCA Bundle cannot be downloaded
class ServiceUnreachableException implements Exception {
  ///The description for the exception.
  String cause;

  ///Exception constructor containing the description for the exception.
  ServiceUnreachableException(this.cause);
  @override
  String toString() => "ServiceUnreachableException: $cause";
}

///An exception thrown when the path to the widget in `cells` is incorrect
class CellPathException implements Exception {
  ///The description for the exception.
  String cause;

  ///Exception constructor containing the description for the exception.
  CellPathException(this.cause);
  @override
  String toString() => "CellPathException: $cause";
}