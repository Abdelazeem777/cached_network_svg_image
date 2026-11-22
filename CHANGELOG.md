## Unreleased

- Fix an older load overwriting the newer image: when the URL changed while the previous image was still loading and that load finished last, the next rebuild showed the old image (#33).
- Fix the 15 ms placeholder timer piling up on every reload: it is now cancelled on reload and on dispose, and only shows the placeholder for the current load (#33).
- Fix a duplicate-key error when two images with the same URL are siblings: the widget no longer defaults its `key` to `ValueKey(url)`, since it already reloads when `url`, `cacheKey`, `headers` or `cacheManager` change (#33).
- Fix a new `fadeDuration` being ignored after the first build (#33).
- Docs: explain that the default cache key is the URL without its query string, so URLs that differ only in their query share one cache entry, and when to pass `cacheKey` (#33).

## 2.1.0

- Fix `flutter build web --wasm` (the web loader is now selected with a conditional import that also works under dart2wasm), thanks to [MousyBusiness](https://github.com/MousyBusiness) (#23).
- Fix `preCache` downloading the cache key instead of the real URL, and dropping the query string, so signed/token URLs now work (#27).
- Fix the widget not reloading when `url`, `cacheKey`, `headers` or `cacheManager` change under the same widget `key` (#27).
- Fix `errorWidget` not being shown when the downloaded bytes are not a valid SVG (#29), thanks to [ybeshkarov](https://github.com/ybeshkarov) for proposing `errorBuilder` (#25).
- Raise the minimum SDK to Dart 3.4 / Flutter 3.22 and `flutter_svg` to `^2.0.17` (required for `errorBuilder`) (#29).
- Fix the README examples (the URL is a positional argument, not `imageUrl:`).
- Add a test suite, CI workflow and Maestro smoke flows (#26, #28).
- Example: send a descriptive `User-Agent`, since Wikimedia rate-limits dart:io's default one.

## 2.0.0

- Major update: Add support for Web! 🌐
- Zero performance regression on Mobile (uses standard `dart:io`).

## 1.2.0

- Fix building issue with Flutter v3.27.0.

## 1.1.0

- Add optional `cacheKey` parameter to `CachedNetworkSVGImage` constructor to allow custom cache key generation.
- Update `README.md` with more detailed information about the package.

## 1.0.0

Stable version release 🎉.

- Add support to pass CustomCacheManager instead of the DefaultCacheManager, thanks to [aospiridonov](https://github.com/aospiridonov).
- Add support to pass headers to the network request, thanks to [joukhar](https://github.com/joukhar).

## 0.0.7

- Fix supported platforms bug.

## 0.0.6

- Add support for Windows and Linux.

## 0.0.5

- Migrate to `flutter_svg` 2.0.4.
- Fix mount bug.
- Performance enhancements.

## 0.0.4

- Migrate to `flutter_svg` 2.0.1.

## 0.0.3

- Add support for functions (`preCache` - `clearCacheForUrl` - `clearCache`) built-in inside the `CachedNetworkSVGImage` class.

## 0.0.2

- Pass the fade animation duration `fadeDuration` from the outside constructor.
- Exclude the params from the url cache key for better caching experience.

## 0.0.1

- Initial release.
