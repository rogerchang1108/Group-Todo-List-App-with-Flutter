import 'package:flutter/material.dart';

enum Categories {
  learning,
  work,
  personal,
  household,
  family,
  health,
  shopping,
  finance,
  social,
  other,
}

class Category {
  const Category(this.title, this.color);

  final String title;
  final Color color;
}
