import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/domain/repository_contracts/media_repository.dart';
import 'media_state.dart';

class MediaCubit extends Cubit<MediaState> {
  final MediaRepository _repository;

  // In-flight/completed fetches are cached in memory by URL for the
  // lifetime of this cubit, so re-opening the same report's detail sheet
  // (or the full-screen viewer after the thumbnail already loaded) doesn't
  // re-fetch the same bytes over the network again.
  final Set<String> _requested = {};

  MediaCubit(this._repository) : super(const MediaState());

  /// Fetches the bytes for [url] if not already loading/loaded.
  /// Safe to call repeatedly (e.g. from multiple thumbnails building at
  /// once) — duplicate calls for the same URL are ignored.
  Future<void> fetchMedia(String url) async {
    if (_requested.contains(url)) return;
    _requested.add(url);

    emit(state.copyWithItem(url, const MediaItemState.loading()));

    final result = await _repository.fetchMediaBytes(url);
    result.fold(
      (failure) {
        _requested.remove(url); // allow retry
        emit(state.copyWithItem(url, MediaItemState.error(failure.message)));
      },
      (bytes) => emit(state.copyWithItem(url, MediaItemState.loaded(bytes))),
    );
  }

  /// Clears a failed fetch so [fetchMedia] will try again (e.g. a manual
  /// "retry" button after a network error).
  void retry(String url) {
    _requested.remove(url);
    fetchMedia(url);
  }
}