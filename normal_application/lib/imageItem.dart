class ImageItem {
  final String id;
  final String title;
  final String? userTitle;
  final String description;

  ImageItem({
    required this.id,
    required this.title,
    this.userTitle,
    required this.description,
  });

  String get displayTitle => userTitle ?? title;
}