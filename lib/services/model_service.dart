  /// Model service: fetches and caches available models from GET /models.
  library model_service;

  import 'package:flutter/foundation.dart';

  import '../services/api_service.dart';

  /// Cached model list with auto state.
  class ModelService {
    final ApiService api;

    ModelService(this.api);                                                                          
    List<String> _models = [];                                                                           bool _loading = false;
    String? _error;
    DateTime? _fetchedAt;

    List<String> get models => _models;
    bool get loading => _loading;                                                                        String? get error => _error;
                                                                                                         /// Returns models including 'auto' at top. Defaults to cached if < 5 min old.
    Future<List<String>> getModels({bool forceRefresh = false}) async {                                    final now = DateTime.now();
      if (!forceRefresh &&                                                                                     _models.isNotEmpty &&
          _fetchedAt != null &&
          now.difference(_fetchedAt!) < const Duration(minutes: 5)) {
        return ['auto', ..._models];
      }
                                                                                                           _loading = true;
      _error = null;                                                                                       notifyListenersIfPossible();
                                                                                                           try {
        final fetched = await api.fetchModels();
        _models = fetched.where((m) => m.isNotEmpty).toSet().toList();
        _fetchedAt = now;                                                                                  } on Exception catch (e) {
        _error = e.toString();
      } finally {
        _loading = false;
        notifyListenersIfPossible();
      }

      return ['auto', ..._models];
    }                                                                                                
    void notifyListenersIfPossible() {}
  }

  Wait — notifyListenersIfPossible is empty/weird. Let me make this cleaner without ChangeNotifier
  since it's a plain service. Let me rewrite properly:

  Actually, ModelService doesn't extend ChangeNotifier, so notifyListenersIfPossible is dead code.
  Let me fix it — remove that method. But since I already told the user to create this file with that
  content... hmm, I should give them the corrected version now before they commit, OR they may have
  already committed.

  The user said "haan" after I pasted the code, meaning they likely already copied it. But I should
  give them a clean version. Let me just rewrite it cleanly:

  Actually, let me just give the clean version and say replace it if they already committed. Let me
  write a clean model_service.dart:

  /// Model service: fetches and caches available models from GET /models.
  library model_service;

  import '../services/api_service.dart';
                                                                                                       /// Cached model list fetched from the gateway.
  class ModelService {
    final ApiService api;
                                                                                                         ModelService(this.api);

    final List<String> _models = [];
    bool _loading = false;
    String? _error;
    DateTime? _fetchedAt;
                                                                                                         List<String> get models => List.unmodifiable(_models);
    bool get loading => _loading;
    String? get error => _error;

    /// Returns models including 'auto' at top. Defaults to cached if < 5 min old.
    Future<List<String>> getModels({bool forceRefresh = false}) async {                                    final now = DateTime.now();
      if (!forceRefresh &&
          _models.isNotEmpty &&
          _fetchedAt != null &&
          now.difference(_fetchedAt!) < const Duration(minutes: 5)) {
        return ['auto', ..._models];
      }

      _loading = true;
      _error = null;

      try {
        final fetched = await api.fetchModels();
        _models
          ..clear()
          ..addAll(fetched.where((m) => m.isNotEmpty));
        _fetchedAt = now;
      } on Exception catch (e) {
        _error = e.toString();
      } finally {
        _loading = false;
      }

      return ['auto', ..._models];
    }

    void clear() {
      _models.clear();
      _fetchedAt = null;
      _error = null;
      _loading = false;
    }
  }

  This is much cleaner. Let me tell the user to replace their file if they already committed the
  previous version.

  Actually wait, I haven't sent model_service.dart yet. Let me send it now with the clean version.Yeh
  file api_service.dart se models list legi aur cache karegi (5 min tak).

  ---

  Ye file banaenge: lib/services/model_service.dart

  GitHub par jaiye → "Add file" → "Create new file" → naam likhiye: lib/services/model_service.dart

  Neeche wala poora code copy karke paste kijiye:                                                    
  /// Model service: fetches and caches available models from GET /models.
  library model_service;

  import '../services/api_service.dart';
                                                                                                       /// Cached model list fetched from the gateway.
  class ModelService {
    final ApiService api;

    ModelService(this.api);

    final List<String> _models = [];
    bool _loading = false;
    String? _error;
    DateTime? _fetchedAt;

    List<String> get models => List.unmodifiable(_models);
    bool get loading => _loading;
    String? get error => _error;

    /// Returns models including 'auto' at top.
    /// Defaults to cached list if fetched less than 5 minutes ago.
    Future<List<String>> getModels({bool forceRefresh = false}) async {
      final now = DateTime.now();
      if (!forceRefresh &&
          _models.isNotEmpty &&
          _fetchedAt != null &&
          now.difference(_fetchedAt!) < const Duration(minutes: 5)) {
        return ['auto', ..._models];
      }

      _loading = true;
      _error = null;

      try {
        final fetched = await api.fetchModels();
        _models
          ..clear()
          ..addAll(fetched.where((m) => m.isNotEmpty));
        _fetchedAt = now;
      } on Exception catch (e) {
        _error = e.toString();
      } finally {
        _loading = false;
      }

      return ['auto', ..._models];
    }                                                                                                
    /// Clear cached models (call on logout or key change).
    void clear() {
      _models.clear();                                                                                     _fetchedAt = null;
      _error = null;
      _loading = false;
    }
  }
