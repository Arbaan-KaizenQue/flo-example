/// [ItemParams] — mutable request-body shape for creating / editing an item.
class ItemParams {
  ItemParams({required this.title, required this.content});

  String title;
  String content;

  Map<String, dynamic> toJson() => {'title': title, 'content': content};

  ItemParams copyWith({String? title, String? content}) =>
      ItemParams(
        title: title ?? this.title,
        content: content ?? this.content,
      );
}
