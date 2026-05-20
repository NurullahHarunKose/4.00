void main() {
  String normalizedText = "BLM0101 Bilgisayar Mühendisliğine Giriş (Introduction to Computer Engineering) Z Tr 3 0 5 5 BA 17.5 G";
  
  RegExp pattern = RegExp(
        r'([A-ZÇĞİÖŞÜ]{3,5}\s*\d{2,4})\s*' + 
        r'((?:(?![A-ZÇĞİÖŞÜ]{3,5}\s*\d{2,4}).){1,120})\s*' + 
        r'([ZSE])\s*(Tr|En|İng|TR|EN|İNG)\s*' +
        r'(\d+(?:[\.,]\d+)?)\s*(\d+(?:[\.,]\d+)?)\s*(\d+(?:[\.,]\d+)?)\s*(\d+(?:[\.,]\d+)?)' +                 
        r'((?:(?![A-ZÇĞİÖŞÜ]{3,5}\s*\d{2,4}).)*)',
        unicode: true);

  var matches = pattern.allMatches(normalizedText);
  for (var match in matches) {
      String code = match.group(1)!.replaceAll(' ', '');
      String name = match.group(2)!.trim();
      String t = match.group(5)!;
      String u = match.group(6)!;
      String uk = match.group(7)!;
      String akts = match.group(8)!;
      String restOfLine = match.group(9) ?? '';
      print('code: \$code, name: \$name, t: \$t, u: \$u, uk: \$uk, akts: \$akts, rest: \$restOfLine');
  }
}
