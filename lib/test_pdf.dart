import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() async {
  File file = File('C:/Users/USER/Desktop/obs.btu.edu.tr_oibs_std_index.aspx_curOp=0%23.pdf');
  List<int> bytes = await file.readAsBytes();
  PdfDocument document = PdfDocument(inputBytes: bytes);
  String text = PdfTextExtractor(document).extractText();
  document.dispose();
  print(text);
}
