import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/book.dart';

part 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final FirebaseAuth auth;
  LibraryCubit({
    required this.firestore,
    required this.storage,
    required this.auth,
  }) : super(const LibraryState());

  // Listen to books for current user
  Stream<void> listenToBooks() {
    final userId = auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();
    return firestore
        .collection('books')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final books = snapshot.docs
          .map((doc) => Book.fromFirestore(doc.data(), doc.id))
          .toList();
      emit(state.copyWith(books: books, isLoading: false));
    });
  }

  // Add a book: upload to Firebase Storage, create Firestore doc
  Future<void> addBook({
    required File file,
    required String format,
    required String userId,
    void Function(String message)? onDuplicate,
    String? customFileName,
  }) async {
    emit(state.copyWith(isLoading: true));
    try {
      final fileName = customFileName ?? file.path.split('/').last;
      final title = fileName.contains('.')
          ? fileName.substring(0, fileName.lastIndexOf('.'))
          : fileName;
      // Check for duplicate by title in Firestore
      final dupQuery = await firestore
          .collection('books')
          .where('userId', isEqualTo: userId)
          .where('title', isEqualTo: title)
          .get();
      if (dupQuery.docs.isNotEmpty) {
        emit(state.copyWith(isLoading: false));
        if (onDuplicate != null) {
          onDuplicate('Duplicate file: $fileName');
        }
        return;
      }
      // Create Firestore doc to get bookId
      final docRef = firestore.collection('books').doc();
      final bookId = docRef.id;
      final storageRef = storage.ref().child('$userId/books/$bookId/$fileName');
      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();
      // Copy file to app data
      final appDir = await getApplicationDocumentsDirectory();
      final localPath =
          '${appDir.path}/${bookId}_$title.${format.toLowerCase()}';
      final localFile = File(localPath);
      if (kDebugMode) {
        print('[BookCubit.addBook] appDir.path: ${appDir.path}');
      }
      if (kDebugMode) {
        print('[BookCubit.addBook] localPath: $localPath');
      }
      if (kDebugMode) {
        print(
          '[BookCubit.addBook] localFile.parent.path: ${localFile.parent.path}');
      }
      if (localFile.parent.path.isEmpty) {
        throw Exception('Local file parent path is empty. Cannot copy file.');
      }
      try {
        await localFile.parent.create(recursive: true);
        await file.copy(localPath);
      } catch (e) {
        if (e is FileSystemException && e.osError?.errorCode == 30) {
          emit(state.copyWith(
              isLoading: false,
              error: 'Cannot write to app data: Read-only file system.'));
          return;
        } else {
          rethrow;
        }
      }
      // Extract lastReadPage
      String lastReadPage = '1';
      if (format.toUpperCase() == 'PDF') {
        // lastReadPage = '1';
      } else if (format.toUpperCase() == 'EPUB') {
        // lastReadPage = 'epub-cfi';
      }
      final book = Book(
        id: bookId,
        title: title,
        format: format,
        link: downloadUrl,
        userId: userId,
        lastReadPage: lastReadPage,
      );
      await docRef.set(book.toFirestore());
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  // Download file if not exists locally
  Future<File> getOrDownloadBookFile(Book book,
      {Function(double)? onProgress}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final localPath =
        '${appDir.path}/${book.id}_${book.title}.${book.format.toLowerCase()}';
    final localFile = File(localPath);
    if (kDebugMode) {
      print('[BookCubit.getOrDownloadBookFile] appDir.path: ${appDir.path}');
    }
    if (kDebugMode) {
      print('[BookCubit.getOrDownloadBookFile] localPath: $localPath');
    }
    if (kDebugMode) {
      print(
        '[BookCubit.getOrDownloadBookFile] localFile.parent.path: ${localFile.parent.path}');
    }
    if (localFile.parent.path.isEmpty) {
      throw Exception('Local file parent path is empty. Cannot download file.');
    }
    try {
      await localFile.parent.create(recursive: true);
    } catch (e) {
      if (e is FileSystemException && e.osError?.errorCode == 30) {
        emit(state.copyWith(
            isLoading: false,
            error: 'Cannot write to app data: Read-only file system.'));
        rethrow;
      } else {
        rethrow;
      }
    }
    if (await localFile.exists()) {
      return localFile;
    }
    // Download to Downloads directory first
    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir == null) {
      throw Exception('Unable to get Downloads directory');
    }
    final tempDownloadPath =
        '${downloadsDir.path}/${book.id}_${book.title}.${book.format.toLowerCase()}';
    final tempDownloadFile = File(tempDownloadPath);
    if (kDebugMode) {
      print(
        '[BookCubit.getOrDownloadBookFile] tempDownloadPath: $tempDownloadPath');
    }
    try {
      final ref = storage.refFromURL(book.link);
      final downloadTask = ref.writeToFile(tempDownloadFile);
      downloadTask.snapshotEvents.listen((event) {
        if (onProgress != null && event.totalBytes > 0) {
          onProgress(event.bytesTransferred / event.totalBytes);
        }
      });
      await downloadTask;
      if (kDebugMode) {
        print('[BookCubit.getOrDownloadBookFile] Downloaded to Downloads folder');
      }
      // Now copy to app data
      await tempDownloadFile.copy(localPath);
      if (kDebugMode) {
        print('[BookCubit.getOrDownloadBookFile] Copied to app data');
      }
      return localFile;
    } catch (e) {
      if (kDebugMode) {
        print('[BookCubit.getOrDownloadBookFile] Download or copy failed: $e');
      }
      rethrow;
    }
  }

  // Delete a book (Firestore + Storage)
  Future<void> deleteBook(Book book) async {
    final userId = auth.currentUser?.uid;
    if (userId == null || book.userId != userId) return;
    emit(state.copyWith(isLoading: true));
    try {
      await firestore.collection('books').doc(book.id).delete();
      final storageRef = storage.ref().child(
          '$userId/books/${book.id}/${book.title}.${book.format.toLowerCase()}');
      await storageRef.delete();
      // Delete local file in app data
      final appDir = await getApplicationDocumentsDirectory();
      final localPath =
          '${appDir.path}/${book.id}_${book.title}.${book.format.toLowerCase()}';
      final localFile = File(localPath);
      if (await localFile.exists()) {
        await localFile.delete();
      }
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  // Update a book's title (Firestore and Firebase Storage)
  Future<void> updateBook({
    required Book book,
    required String newTitle,
  }) async {
    final userId = auth.currentUser?.uid;
    if (userId == null) return;
    emit(state.copyWith(isLoading: true));
    try {
      // Rename file in Firebase Storage
      final oldFileName = '${book.title}.${book.format.toLowerCase()}';
      final newFileName = '$newTitle.${book.format.toLowerCase()}';
      final oldStorageRef =
          storage.ref().child('$userId/books/${book.id}/$oldFileName');
      final newStorageRef =
          storage.ref().child('$userId/books/${book.id}/$newFileName');
      // Copy file to new name
      final data = await oldStorageRef.getData();
      if (data == null) {
        throw Exception('Failed to download file data for rename');
      }
      await newStorageRef.putData(data);
      final newDownloadUrl = await newStorageRef.getDownloadURL();
      // Delete old file
      await oldStorageRef.delete();
      // Update Firestore document
      await firestore.collection('books').doc(book.id).update({
        'title': newTitle,
        'link': newDownloadUrl,
      });
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  // Update lastReadPage in Firestore
  Future<void> updateLastReadPage({
    required String bookId,
    required String lastReadPage,
  }) async {
    final userId = auth.currentUser?.uid;
    if (userId == null) return;
    try {
      await firestore.collection('books').doc(bookId).update({
        'lastReadPage': lastReadPage,
      });
    } catch (e) {
      // Optionally handle error
      if (kDebugMode) {
        print('Failed to update lastReadPage: $e');
      }
    }
  }
}
