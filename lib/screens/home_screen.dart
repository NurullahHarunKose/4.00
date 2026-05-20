import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../providers/app_state.dart';
import '../utils/pdf_parser.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _areButtonsVisible = true;

  void _showAddCourseDialog(BuildContext context) {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final creditController = TextEditingController();
    String selectedGrade = 'AA'; // Varsayılan seçim
    final List<String> grades = ['AA', 'BA', 'BB', 'CB', 'CC', 'DC', 'DD', 'FF', 'DF', 'DZ', 'GR'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Ders Ekle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Ders Kodu (örn. MAT 101)')),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Ders Adı')),
                  TextField(controller: creditController, decoration: const InputDecoration(labelText: 'Kredi'), keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  const Text('Harf Notu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: grades.map((grade) {
                      return ChoiceChip(
                        label: Text(grade),
                        selected: selectedGrade == grade,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              selectedGrade = grade;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty && creditController.text.isNotEmpty && selectedGrade.isNotEmpty) {
                    final course = Course(
                      code: codeController.text, // Boş bırakılabilir
                      name: nameController.text,
                      credit: double.tryParse(creditController.text) ?? 0.0,
                      grade: selectedGrade,
                    );
                    Provider.of<AppState>(context, listen: false).addCourse(course);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Ekle'),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<String?> _showEditGradeDialog(BuildContext context, String currentGrade) async {
    final List<String> grades = ['AA', 'BA', 'BB', 'CB', 'CC', 'DC', 'DD', 'FF', 'DF', 'DZ', 'GR'];
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Harf Notunu Güncelle'),
          content: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: grades.map((grade) {
              return ChoiceChip(
                label: Text(grade),
                selected: currentGrade == grade,
                onSelected: (selected) {
                  if (selected) {
                    Navigator.pop(context, grade);
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Dashboard
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('GPA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(appState.gpa.toStringAsFixed(2), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Geçilen / Kalan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('${appState.passedCoursesCount} / ${appState.failedCoursesCount}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              // Course List
              Expanded(
                child: appState.courses.isEmpty
                    ? const Center(child: Text('Henüz ders eklenmedi. PDF yükleyin veya manuel ekleyin.'))
                    : ReorderableListView.builder(
                        itemCount: appState.courses.length,
                        onReorder: (oldIndex, newIndex) => appState.reorderCourses(oldIndex, newIndex),
                        itemBuilder: (context, index) {
                          final course = appState.courses[index];
                          final isPassed = gradeToGpa[course.grade] != null && gradeToGpa[course.grade]! > 0;
                          
                          return Dismissible(
                            key: ValueKey('${course.code}_$index'),
                            direction: DismissDirection.horizontal,
                            background: Container(
                              color: Colors.blue,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 16),
                              child: const Icon(Icons.edit, color: Colors.white),
                            ),
                            secondaryBackground: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.endToStart) {
                                return true; // Sola kaydırma (Sil)
                              } else {
                                // Sağa kaydırma (Düzenle)
                                String? newGrade = await _showEditGradeDialog(context, course.grade);
                                if (newGrade != null && newGrade != course.grade) {
                                  final updatedCourse = Course(
                                    code: course.code,
                                    name: course.name,
                                    credit: course.credit,
                                    grade: newGrade,
                                  );
                                  appState.updateCourse(index, updatedCourse);
                                }
                                return false; // Kart ekrandan kaybolmasın, yerine geri gelsin
                              }
                            },
                            onDismissed: (direction) {
                              if (direction == DismissDirection.endToStart) {
                                appState.removeCourse(index);
                              }
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: isPassed ? Colors.green : Colors.red, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                title: Text(course.code.isNotEmpty ? '${course.code} - ${course.name}' : course.name),
                                subtitle: Text('Kredi: ${course.credit}'),
                                trailing: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isPassed ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    course.grade,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isPassed ? Colors.green[800] : Colors.red[800],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          ), // Close SafeArea
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Opacity(
                opacity: _areButtonsVisible ? 1.0 : 0.5,
                child: FloatingActionButton(
                  heroTag: 'toggle_btn',
                  onPressed: () {
                    setState(() {
                      _areButtonsVisible = !_areButtonsVisible;
                    });
                  },
                  tooltip: 'Menüyü Gizle/Göster',
                  child: Icon(_areButtonsVisible ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up),
                ),
              ),
              if (_areButtonsVisible) ...[
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'theme_btn',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.light_mode),
                              title: const Text('Açık Tema'),
                              onTap: () { appState.setTheme('light'); Navigator.pop(context); },
                            ),
                            ListTile(
                              leading: const Icon(Icons.dark_mode),
                              title: const Text('Koyu Tema'),
                              onTap: () { appState.setTheme('dark'); Navigator.pop(context); },
                            ),
                            ListTile(
                              leading: const Icon(Icons.water_drop),
                              title: const Text('Mavi Tema'),
                              onTap: () { appState.setTheme('blue'); Navigator.pop(context); },
                            ),
                            ListTile(
                              leading: const Icon(Icons.wb_sunny),
                              title: const Text('Sarı Tema'),
                              onTap: () { appState.setTheme('yellow'); Navigator.pop(context); },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  tooltip: 'Tema Seçimi',
                  child: const Icon(Icons.palette),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'pdf_btn',
                  onPressed: () async {
                    final courses = await PdfParser.pickAndParsePdf();
                    if (courses != null && courses.isNotEmpty) {
                      appState.addCourses(courses);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${courses.length} ders eklendi.')));
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ders bulunamadı veya PDF seçilmedi.')));
                      }
                    }
                  },
                  tooltip: 'PDF Yükle',
                  child: const Icon(Icons.picture_as_pdf),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'add_btn',
                  onPressed: () => _showAddCourseDialog(context),
                  tooltip: 'Manuel Ders Ekle',
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'clear_btn',
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Tümünü Sil'),
                        content: const Text('Eklenen tüm dersleri silmek istediğinize emin misiniz?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () {
                              Provider.of<AppState>(context, listen: false).clearAllCourses();
                              Navigator.pop(context);
                            },
                            child: const Text('Sil'),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: 'Tümünü Sil',
                  child: const Icon(Icons.delete_sweep),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
