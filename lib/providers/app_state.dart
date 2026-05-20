import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';

const Map<String, double> gradeToGpa = {
  'AA': 4.0, 'BA': 3.5, 'BB': 3.0, 'CB': 2.5,
  'CC': 2.0, 'DC': 1.5, 'DD': 1.0, 'FF': 0.0,
  'DF': 0.0, 'DZ': 0.0, 'GR': 0.0,
};

class AppState extends ChangeNotifier {
  List<Course> courses = [];
  String currentTheme = 'light'; // light, dark, blue, yellow

  AppState() {
    loadData();
  }

  double get gpa {
    if (courses.isEmpty) return 0.0;
    double totalCredits = 0.0;
    double totalPoints = 0.0;

    for (var course in courses) {
      double credit = course.credit;
      String gradeLetter = course.grade.toUpperCase();
      double? gradeValue = gradeToGpa[gradeLetter];

      if (gradeValue != null) {
        totalCredits += credit;
        totalPoints += credit * gradeValue;
      }
    }

    return totalCredits > 0 ? (totalPoints / totalCredits) : 0.0;
  }

  int get passedCoursesCount {
    return courses.where((c) {
      double? val = gradeToGpa[c.grade.toUpperCase()];
      return val != null && val > 0;
    }).length;
  }

  int get failedCoursesCount {
    return courses.where((c) {
      double? val = gradeToGpa[c.grade.toUpperCase()];
      return val != null && val == 0;
    }).length;
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme
    currentTheme = prefs.getString('currentTheme') ?? 'dark';

    // Load courses
    String? coursesJson = prefs.getString('courses');
    if (coursesJson != null) {
      List<dynamic> decoded = jsonDecode(coursesJson);
      courses = decoded.map((i) => Course.fromJson(i)).toList();
    }

    notifyListeners();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('currentTheme', currentTheme);
    
    String encoded = jsonEncode(courses.map((c) => c.toJson()).toList());
    prefs.setString('courses', encoded);
  }

  void setTheme(String theme) {
    currentTheme = theme;
    saveData();
    notifyListeners();
  }

  void addCourse(Course course) {
    courses.add(course);
    saveData();
    notifyListeners();
  }

  void removeCourse(int index) {
    if (index >= 0 && index < courses.length) {
      courses.removeAt(index);
      saveData();
      notifyListeners();
    }
  }

  void updateCourse(int index, Course updatedCourse) {
     if (index >= 0 && index < courses.length) {
      courses[index] = updatedCourse;
      saveData();
      notifyListeners();
    }
  }

  void reorderCourses(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final Course item = courses.removeAt(oldIndex);
    courses.insert(newIndex, item);
    saveData();
    notifyListeners();
  }

  void addCourses(List<Course> newCourses) {
    courses.addAll(newCourses);
    saveData();
    notifyListeners();
  }

  void clearAllCourses() {
    courses.clear();
    saveData();
    notifyListeners();
  }
}
