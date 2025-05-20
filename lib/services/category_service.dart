import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'categories';

  Future<String> createCategory(CategoryModel category) async {
    try {
      final docRef = await _firestore.collection(_collection).add(category.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  Future<List<CategoryModel>> getAllCategories({bool activeOnly = true}) async {
    try {
      Query query = _firestore.collection(_collection);
      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }
      
      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  Future<void> updateCategory(String id, CategoryModel category) async {
    try {
      await _firestore.collection(_collection).doc(id).update(category.toMap());
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      // Soft delete by setting isActive to false
      await _firestore.collection(_collection).doc(id).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  Future<CategoryModel?> getCategoryById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists && doc.data() != null) {
        return CategoryModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get category: $e');
    }
  }

  Stream<List<CategoryModel>> categoriesStream({bool activeOnly = true}) {
    try {
      Query query = _firestore.collection(_collection);
      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }
      
      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => CategoryModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to stream categories: $e');
    }
  }
}
