import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String description;
  final Color color;
  final IconData icon;
  final DateTime createdAt;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'color': color.value,
      'icon': icon.codePoint,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }

  factory CategoryModel.fromMap(String id, Map<String, dynamic> map) {
    return CategoryModel(
      id: id,
      name: map['name'] as String,
      description: map['description'] as String,
      color: Color(map['color'] as int),
      icon: IconData(map['icon'] as int, fontFamily: 'MaterialIcons'),
      createdAt: map['createdAt'].toDate(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}
