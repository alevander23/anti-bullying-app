import 'dart:typed_data';
import 'package:equatable/equatable.dart';

enum MediaFetchStatus { loading, loaded, error }

class MediaItemState extends Equatable {
  final MediaFetchStatus status;
  final Uint8List? bytes;
  final String? errorMessage;

  const MediaItemState({
    required this.status,
    this.bytes,
    this.errorMessage,
  });

  const MediaItemState.loading() : this(status: MediaFetchStatus.loading);

  const MediaItemState.loaded(Uint8List bytes)
      : this(status: MediaFetchStatus.loaded, bytes: bytes);

  const MediaItemState.error(String message)
      : this(status: MediaFetchStatus.error, errorMessage: message);

  @override
  List<Object?> get props => [status, bytes, errorMessage];
}

// Keyed by media URL, since the report detail sheet may have several
// thumbnails (and potentially a dialog) all fetching concurrently.
class MediaState extends Equatable {
  final Map<String, MediaItemState> items;

  const MediaState({this.items = const {}});

  MediaItemState? statusFor(String url) => items[url];

  MediaState copyWithItem(String url, MediaItemState itemState) {
    return MediaState(items: {...items, url: itemState});
  }

  @override
  List<Object?> get props => [items];
}