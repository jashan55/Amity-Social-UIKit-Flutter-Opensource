/// Host-app-injected font configuration for the Amity UIKit.
///
/// `AmityUIKitProvider` builds its own inner `MaterialApp` with a fresh
/// `ThemeData`, which means the host app's `Theme.of(context).textTheme`
/// (and its fontFamily) does not reach UIKit screens. Setting
/// [AmityFontConfig.family] before the provider is built lets the host
/// pass a font family through that inner theme so all `TextStyle`s
/// inherit it on both Android and iOS.
class AmityFontConfig {
  /// Font family the host app wants UIKit text to use.
  /// `null` (default) keeps the platform default.
  static String? family;
}
