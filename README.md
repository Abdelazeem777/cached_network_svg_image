```dart
CachedNetworkSVGImage(
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/0/02/SVG_logo.svg',
    placeholder: const CircularProgressIndicator(color: Colors.green),
    errorWidget: const Icon(Icons.error, color: Colors.red),
    width: 250.0,
    height: 250.0,
    fadeDuration: const Duration(milliseconds: 500),
),

```

# Future plans

[ ] Build a custom cache manager that use the same default mechanism but making the in-memory cache optional synchronous which will improve displaying the image experiance.
