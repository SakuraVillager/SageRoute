import 'package:flutter/material.dart';
import '../theme/color_schemes.dart';

enum HeritageGrade {
  confirmed('确证', AppColors.heritageConfirmed),
  suspected('疑似', AppColors.heritageSuspected),
  lost('已佚', AppColors.heritageLost);

  const HeritageGrade(this.label, this.color);
  final String label;
  final Color color;

  static HeritageGrade? parse(Object? value) {
    for (final grade in values) {
      if (value == grade.label || value == grade.name) return grade;
    }
    return null;
  }
}

const dongpoThemes = ['水利治绩', '交游酬唱', '诗词题咏', '民生善政', '自然山水'];
