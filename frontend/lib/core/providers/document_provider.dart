import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../auth_provider.dart';

class DocumentState {
  final bool isLoading;
  final List<dynamic> documents;
  final String? error;

  const DocumentState({
    this.isLoading = false,
    this.documents = const [],
    this.error,
  });

  DocumentState copyWith({
    bool? isLoading,
    List<dynamic>? documents,
    String? error,
  }) {
    return DocumentState(
      isLoading: isLoading ?? this.isLoading,
      documents: documents ?? this.documents,
      error: error ?? this.error,
    );
  }
}

class DocumentNotifier extends Notifier<DocumentState> {
  @override
  DocumentState build() {
    // Initial state
    return const DocumentState();
  }

  Future<void> fetchDocuments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ref.read(apiClientProvider).get('/documents');
      state = state.copyWith(isLoading: false, documents: response is List ? response : []);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> uploadDocument(PlatformFile file, String category, {int? vendorId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = ref.read(authProvider).token;
      
      final uri = Uri.parse('http://localhost:8080/api/v1/documents');
      var request = http.MultipartRequest('POST', uri);
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      request.fields['category'] = category;
      if (vendorId != null) {
        request.fields['shared_with_vendor_id'] = vendorId.toString();
      }

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: file.name,
        ));
      }

      var response = await request.send();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchDocuments();
        return true;
      } else {
        final respBody = await response.stream.bytesToString();
        state = state.copyWith(isLoading: false, error: 'Upload failed: $respBody');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteDocument(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // In apiClient, there's no native delete yet, we can use http directly or add it.
      // For now we'll just use http directly to keep it simple since we need auth.
      final token = ref.read(authProvider).token;
      final uri = Uri.parse('http://localhost:8080/api/v1/documents/$id');
      final response = await http.delete(
        uri, 
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (response.statusCode == 200) {
        await fetchDocuments();
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Delete failed');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final documentProvider = NotifierProvider<DocumentNotifier, DocumentState>(DocumentNotifier.new);
