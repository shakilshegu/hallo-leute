import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poppylo/models/match_models.dart';

class SearchController extends StateNotifier<MeetRequest?> {
  SearchController() : super(null);

  void start(MeetRequest request) => state = request;

  void clear() => state = null;
}

final searchControllerProvider =
    StateNotifierProvider<SearchController, MeetRequest?>((ref) {
  return SearchController();
});
