import 'package:flutter/material.dart';

abstract class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 28.0;
  static const double full = 999.0;

  static BorderRadius get xsBR => BorderRadius.circular(xs);
  static BorderRadius get smBR => BorderRadius.circular(sm);
  static BorderRadius get mdBR => BorderRadius.circular(md);
  static BorderRadius get lgBR => BorderRadius.circular(lg);
  static BorderRadius get xlBR => BorderRadius.circular(xl);
  static BorderRadius get xxlBR => BorderRadius.circular(xxl);
  static BorderRadius get fullBR => BorderRadius.circular(full);
}
