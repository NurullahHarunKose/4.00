import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/course.dart';

class PdfParser {
  static Future<List<Course>?> pickAndParsePdf() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      List<int> bytes = await file.readAsBytes();
      
      PdfDocument document = PdfDocument(inputBytes: bytes);
      // layoutText: true parametresi, PDF içerisindeki tabloların sütun sütun değil 
      // satır satır ve aralarında boşluk bırakılarak okunmasını sağlar.
      String text = PdfTextExtractor(document).extractText(layoutText: true);
      document.dispose();

      return extractCoursesFromText(text);
    }
    return null;
  }

  static List<Course> extractCoursesFromText(String text) {
    Map<String, Course> courseMap = {};
    
    // PDF okuyucu layoutText: true modunda tablo sütunlarını birleştirirken 
    // aradaki boşlukları SİLİYOR (Örn: BLM0101Bilgisayar Mühendisliğine Giriş5578BAZ).
    // Metindeki satır atlamalarını boşluğa çevirip tek satır yapıyoruz.
    String normalizedText = text.replaceAll('\n', ' ').replaceAll('\r', ' ');

    // PDF okuyucu bazen Türkçe karakterleri bozarak string halinde çıkarıyor 
    // (Örn: İ -> Idotaccent, ğ -> gbreve). 
    // Bu durum ders kodlarının (Örn: AİT0201 -> AIdotaccentT0201) bozulmasına 
    // ve regex'in şaşmasına neden oluyor. Bu karakterleri düzeltiyoruz:
    normalizedText = normalizedText
        .replaceAll('Idotaccent', 'İ')
        .replaceAll('gbreve', 'ğ')
        .replaceAll('Gbreve', 'Ğ')
        .replaceAll('scedilla', 'ş')
        .replaceAll('Scedilla', 'Ş')
        .replaceAll('odieresis', 'ö')
        .replaceAll('Odieresis', 'Ö')
        .replaceAll('udieresis', 'ü')
        .replaceAll('Udieresis', 'Ü')
        .replaceAll('ccedilla', 'ç')
        .replaceAll('Ccedilla', 'Ç')
        .replaceAll('dotlessi', 'ı')
        .replaceAll('idotless', 'ı');

    // Şablon açıklaması (Yeni formata göre):
    // 1: Ders Kodu (SADECE BÜYÜK HARF, 3-5 harf, opsiyonel boşluk, 2-4 rakam)
    // 2: Ders Adı
    // 3: Statü (Z, S, E)
    // 4: Öğretim Dili (Tr, En vs.)
    // 5: Nümerik değerler (T, U, UK, AKTS) ve Not/Puan aralığı
    RegExp pattern = RegExp(
        r'([A-ZÇĞİÖŞÜ]{3,5}\s*\d{2,4})\s*' + 
        r'((?:(?![A-ZÇĞİÖŞÜ]{3,5}\s*\d{2,4}).){1,120}?)\s*' + 
        r'([ZSE])\s*(Tr|En|İng|TR|EN|İNG)\s*' +
        r'([\d\s\.,]+)' + // T, U, UK, AKTS ve Puanı yakalar
        r'\s*(AA|BA|BB|CB|CC|DC|DD|FF|DF|DZ|GR|-)?' + // Opsiyonel harf notu
        r'((?:(?![A-ZÇĞİÖŞÜ]{3,5}\s*\d{2,4}).)*)',
        unicode: true);

    var matches = pattern.allMatches(normalizedText);

    for (var match in matches) {
      String code = match.group(1)!.replaceAll(' ', '');
      String name = match.group(2)!.trim();
      String numbersStr = match.group(5)!.trim();
      String grade = match.group(6) ?? '';
      
      if (grade == '-') grade = '';

      // Rakamları ayıkla
      List<String> numParts = numbersStr.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
      double credit = 0.0;

      if (numParts.length >= 4) {
        // Normal durum: T, U, UK, AKTS ayrı ayrı boşlukla ayrılmış
        // AKTS her zaman 4. sayıdır (index 3).
        String aktsStr = numParts[3].replaceAll(',', '.');
        credit = double.tryParse(aktsStr) ?? 0.0;
      } else {
        // Bitişik durum: Örn "3055" veya "10114"
        String s = numParts.join('');
        if (s.length >= 4) {
          double uk = double.tryParse(s.substring(2, 3)) ?? 0.0;
          double val1 = double.tryParse(s.substring(3, 4)) ?? 0.0;
          double val2 = s.length > 4 ? (double.tryParse(s.substring(3, 5)) ?? 0.0) : val1;
          
          double multiplier = -1.0;
          switch (grade) {
            case 'AA': multiplier = 4.0; break;
            case 'BA': multiplier = 3.5; break;
            case 'BB': multiplier = 3.0; break;
            case 'CB': multiplier = 2.5; break;
            case 'CC': multiplier = 2.0; break;
            case 'DC': multiplier = 1.5; break;
            case 'DD': multiplier = 1.0; break;
            case 'FF': case 'FD': case 'DZ': case 'GR': multiplier = 0.0; break;
          }

          if (multiplier >= 0 && s.length > 4) {
            String ep1 = (val1 * multiplier).toString().replaceAll('.0', '');
            String ep2 = (val2 * multiplier).toString().replaceAll('.0', '');
            String ep1_alt = (val1 * multiplier).toString().replaceAll('.', '');
            String ep2_alt = (val2 * multiplier).toString().replaceAll('.', '');
            
            bool matches1 = s.endsWith(ep1) || s.endsWith(ep1_alt);
            bool matches2 = s.endsWith(ep2) || s.endsWith(ep2_alt);
            
            if (matches1 && !matches2) {
              credit = val1;
            } else if (matches2 && !matches1 && val2 <= 30) {
              credit = val2;
            } else {
              if (val2 > 30) credit = val1;
              else if (val1 < uk) credit = val2;
              else credit = val1;
            }
          } else {
            if (s.length == 4) {
              credit = val1;
            } else if (s.length == 5 && multiplier < 0) {
              if (val2 <= 30) credit = val2;
              else credit = val1;
            } else {
              if (val2 > 30) credit = val1;
              else if (val1 < uk) credit = val2;
              else credit = val1;
            }
          }
        }
      }

      // Aynı ders kodu tekrar gelirse, Map üzerine yazılacağı için
      // her zaman en son (en güncel) durumu saklamış oluruz.
      // PDF'in orijinal kronolojik sırasını (dönem sırasını) korumak için,
      // ders daha önce varsa siliyoruz, böylece listenin en sonuna ekleniyor.
      if (courseMap.containsKey(code)) {
        courseMap.remove(code);
      }
      courseMap[code] = Course(
        code: code,
        name: name,
        credit: credit,
        grade: grade,
      );
    }
    
    List<Course> courses = courseMap.values.toList();
    
    // Sınıf ve döneme göre sıralama (getSortPriority) işlemi kaldırıldı.
    // Çünkü PDF belgesi zaten kronolojik (dönem dönem) bir sıraya sahip ve 
    // sıralama algoritması bazı derslerin (örn: kodunda sayı bulunmayan veya farklı formattaki) 
    // sırasını bozarak alfabetik sıralamaya düşmelerine neden oluyordu.
    // courseMap.values.toList() ile orijinal belge sırasını kullanıyoruz.

    // Geri bildirim (Hata olursa ne çıktığını görmek için)
    if (courses.isEmpty) {
      courses.add(Course(
        code: 'DBG',
        name: normalizedText.substring(0, normalizedText.length > 500 ? 500 : normalizedText.length),
        credit: 0.0,
        grade: 'AA'
      ));
    }

    return courses;
  }
}
