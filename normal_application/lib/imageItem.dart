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

  factory ImageItem.fromMap(Map<dynamic, dynamic> map, String id) {
    return ImageItem(
      id: id,
      title: map['title'] ?? '',
      userTitle: map['userTitle'],
      description: map['description'] ?? 'no description',
    );
  }

  String get displayTitle => userTitle ?? title;
}
