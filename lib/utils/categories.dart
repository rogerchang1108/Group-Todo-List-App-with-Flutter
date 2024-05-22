import 'package:flutter/material.dart';
import 'package:flutter_app/models/category.dart';

const categories = {
  Categories.learning: Category(
    'Learning',
    Color.fromARGB(255, 0, 255, 128),
  ),
  Categories.work: Category(
    'Work',
    Color.fromARGB(255, 145, 255, 0),
  ),
  Categories.personal: Category(
    'Personal',
    Color.fromARGB(255, 255, 102, 0),
  ),
  Categories.household: Category(
    'Household',
    Color.fromARGB(255, 0, 208, 255),
  ),
  Categories.family: Category(
    'Family',
    Color.fromARGB(255, 0, 60, 255),
  ),
  Categories.health: Category(
    'Health',
    Color.fromARGB(255, 255, 149, 0),
  ),
  Categories.shopping: Category(
    'Shopping',
    Color.fromARGB(255, 255, 187, 0),
  ),
  Categories.finance: Category(
    'Finance',
    Color.fromARGB(255, 191, 0, 255),
  ),
  Categories.social: Category(
    'Social',
    Color.fromARGB(255, 149, 0, 255),
  ),
  Categories.other: Category(
    'Other',
    Color.fromARGB(255, 0, 225, 255),
  ),
};
