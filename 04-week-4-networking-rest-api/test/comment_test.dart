import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/data/models/comment.dart';

void main() {
  test('Comment.fromJson uses defaults for missing fields', () {
    final comment = Comment.fromJson({'id': 7, 'name': 'A comment'});

    expect(comment.postId, 0);
    expect(comment.id, 7);
    expect(comment.name, 'A comment');
    expect(comment.email, '');
    expect(comment.body, '');
  });

  test('Comment.fromJson handles null and empty JSON', () {
    final emptyComment = Comment.fromJson({});
    final nullComment = Comment.fromJson({
      'postId': null,
      'id': null,
      'name': null,
      'email': null,
      'body': null,
    });

    expect(emptyComment.postId, 0);
    expect(emptyComment.id, 0);
    expect(emptyComment.name, '');
    expect(emptyComment.email, '');
    expect(emptyComment.body, '');
    expect(nullComment.postId, 0);
    expect(nullComment.id, 0);
    expect(nullComment.name, '');
    expect(nullComment.email, '');
    expect(nullComment.body, '');
  });
}