/// Why a [SocialStoryShareException] was thrown.
enum SocialStoryShareErrorCode {
  /// The target app is not installed or not visible to your app.
  ///
  /// On iOS, also check that its URL scheme is listed under
  /// `LSApplicationQueriesSchemes` in `Info.plist`.
  appNotInstalled,

  /// A file path does not point to an existing file.
  fileNotFound,

  /// A file or byte buffer is not a readable image.
  invalidImage,

  /// The platform rejected the arguments it was given.
  invalidArgument,

  /// There is no foreground activity or view controller to share from.
  uiUnavailable,

  /// The user refused the permission needed to save to the gallery.
  permissionDenied,

  /// Any other platform failure. See [SocialStoryShareException.message].
  failed,
}

/// Thrown when a share or save cannot be completed.
class SocialStoryShareException implements Exception {
  /// Creates an exception with a [code] and an optional [message].
  const SocialStoryShareException(this.code, [this.message]);

  /// Why the operation failed.
  final SocialStoryShareErrorCode code;

  /// A readable description from the platform, if available.
  final String? message;

  @override
  String toString() {
    final details = message;
    return details == null
        ? 'SocialStoryShareException(${code.name})'
        : 'SocialStoryShareException(${code.name}): $details';
  }
}
