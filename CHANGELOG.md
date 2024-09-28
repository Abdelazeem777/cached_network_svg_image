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
