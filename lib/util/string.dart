extension Parsing on String {
  bool parseBool() {
    final lowerCase = toLowerCase();
    if (lowerCase == 'true') {
      return true;
    } else if (lowerCase == 'false') {
      return false;
    }
    throw 'Unable to parse $this into bool';
  }
}
