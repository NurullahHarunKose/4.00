import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() async {
  String pdfPath = 'C:/Users/USER/Desktop/15383522582_Transkript (1) (1).pdf';
  File file = File(pdfPath);
  if (!file.existsSync()) {
    print("PDF NOT FOUND");
    return;
  }
  List<int> bytes = await file.readAsBytes();
  
  PdfDocument document = PdfDocument(inputBytes: bytes);
  
  String textFalse = PdfTextExtractor(document).extractText(layoutText: false);
  String textTrue = PdfTextExtractor(document).extractText(layoutText: true);
  
  document.dispose();
  
  File('C:/Users/USER/Desktop/dump_false.txt').writeAsStringSync(textFalse);
  File('C:/Users/USER/Desktop/dump_true.txt').writeAsStringSync(textTrue);
  
  print("DUMP COMPLETE");
}
