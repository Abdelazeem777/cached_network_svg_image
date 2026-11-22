# Cached Network SVG Image

`cached_network_svg_image` is a Flutter package that allows you to easily load and cache SVG images from the network. It provides a simple and efficient way to display SVG images with caching, placeholders, and error handling. 🌐🖼️
Now supports **Web**! 🌍

## Features ✨

- Load SVG images from the network. 🌍
- Cache images for offline use. 📦
- Display a placeholder while the image is loading. ⏳
- Show an error widget if the image fails to load. ❌
- Customize the fade-in duration for the image. ⏱️

## Installation 🛠️

Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  cached_network_svg_image: ^2.1.0
```

Then, run `flutter pub get` to install the package. 🚀

## Usage 📖

Import the package in your Dart file:

```dart
import 'package:cached_network_svg_image/cached_network_svg_image.dart';
```

Use the `CachedNetworkSVGImage` widget to display an SVG image from the network:

```dart
CachedNetworkSVGImage(
    'https://upload.wikimedia.org/wikipedia/commons/0/02/SVG_logo.svg',
    placeholder: const CircularProgressIndicator(color: Colors.green),
    errorWidget: const Icon(Icons.error, color: Colors.red),
    width: 250.0,
    height: 250.0,
    fadeDuration: const Duration(milliseconds: 500),
),
```

### Parameters 📋

- `url` (positional): The URL of the SVG image. 🌐
- `cacheKey`: A custom cache key to use for the image. Defaults to the URL without its query string, see [Cache key](#cache-key). 🔑
- `placeholder`: A widget to display while the image is loading. ⏳
- `errorWidget`: A widget to display if the image fails to load. ❌
- `width`: The width of the image. 📏
- `height`: The height of the image. 📏
- `fadeDuration`: The duration of the fade-in animation when the image loads. ⏱️
- `headers`: A map of headers to pass with the network request. 🗂️
- `cacheManager`: A custom cache manager to use for caching the image, Default is `DefaultCacheManager()`. 📦
- `fit`: How the image should be inscribed into the space allocated for it. 🔲
- `alignment`: How the image should be aligned within its bounds. 📐
- `matchTextDirection`: Whether to paint the image in the direction of the TextDirection. ↔️
- `allowDrawingOutsideViewBox`: Whether to allow the image to draw outside its view box. 📏
- `color`: The color to apply to the image. 🎨
- `colorBlendMode`: The blend mode to apply to the image color. 🎨
- `semanticsLabel`: A description of the image for accessibility tools. 🏷️
- `excludeFromSemantics`: Whether the image should be excluded from semantics. 🚫
- `colorFilter`: A color filter to apply to the image. 🎨
- `placeholderBuilder`: A builder function to create the placeholder widget. 🛠️
- `theme`: The theme to apply to the image. 🎨

### Functions 🔧

- `preCache`: A function to pre-cache the image. 📦
- `clearCacheForUrl`: A function to clear the cache for a specific URL. 🗑️
- `clearCache`: A function to clear the entire cache. 🗑️

### Cache key

By default an image is cached under its URL without the query string, that is everything before the first `?`. For example, `https://example.com/logo.svg?v=2` is cached as `https://example.com/logo.svg`. The download itself still uses the full URL, query included.

So URLs that differ only in their query share one cache entry: once `logo.svg?v=1` is cached, `logo.svg?v=2` is served from that cached file instead of being downloaded. That suits signed URLs whose token changes while the image stays the same. When the query does pick a different image (a version, a size, a user), pass a `cacheKey` that includes it, for example `cacheKey: url`. `preCache` and `clearCacheForUrl` use the same rule, so give them the same `cacheKey`.

## Example 💡

Here is a complete example of how to use the `cached_network_svg_image` package:

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_svg_image/cached_network_svg_image.dart';

void main() {
    runApp(MyApp());
}

class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            home: Scaffold(
                appBar: AppBar(
                    title: Text('Cached Network SVG Image Example'),
                ),
                body: Center(
                    child: CachedNetworkSVGImage(
                        'https://upload.wikimedia.org/wikipedia/commons/0/02/SVG_logo.svg',
                        placeholder: const CircularProgressIndicator(color: Colors.green),
                        errorWidget: const Icon(Icons.error, color: Colors.red),
                        width: 250.0,
                        height: 250.0,
                        fadeDuration: const Duration(milliseconds: 500),
                    ),
                ),
            ),
        );
    }
}
```

## License 📄

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
