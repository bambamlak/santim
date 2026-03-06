import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AppIcons {
  /// Global icon wrapper setting active icons to Filled and inactive to Outline.
  static Widget icon({
    required PhosphorIconData activeIcon,
    required PhosphorIconData inactiveIcon,
    required bool isActive,
    Color? color,
    double size = 24.0,
  }) {
    return PhosphorIcon(
      isActive ? activeIcon : inactiveIcon,
      color: color,
      size: size,
    );
  }

  // Common App Icons based on Phosphor (Filled Version)
  static const PhosphorIconData homeActive = PhosphorIconsFill.house;
  static const PhosphorIconData homeInactive = PhosphorIconsFill.house;

  static const PhosphorIconData insightsActive = PhosphorIconsFill.chartLineUp;
  static const PhosphorIconData insightsInactive =
      PhosphorIconsFill.chartLineUp;

  static const PhosphorIconData profileActive = PhosphorIconsFill.user;
  static const PhosphorIconData profileInactive = PhosphorIconsFill.user;

  static const PhosphorIconData add = PhosphorIconsFill.plus;
  static const PhosphorIconData close = PhosphorIconsFill.x;
  static const PhosphorIconData check = PhosphorIconsFill.check;

  static const PhosphorIconData warningCircle = PhosphorIconsFill.warningCircle;

  // Icons (Filled Version)
  static const PhosphorIconData back = PhosphorIconsFill.caretLeft;
  static const PhosphorIconData shop = PhosphorIconsFill.storefront;
  static const PhosphorIconData chevronDown = PhosphorIconsFill.caretDown;
  static const PhosphorIconData calendar = PhosphorIconsFill.calendar;
  static const PhosphorIconData trash = PhosphorIconsFill.trash;

  // Category icons (Filled Version)
  static const PhosphorIconData food = PhosphorIconsFill.forkKnife;
  static const PhosphorIconData shopping = PhosphorIconsFill.shoppingBag;
  static const PhosphorIconData transport = PhosphorIconsFill.car;
  static const PhosphorIconData house = PhosphorIconsFill.house;
  static const PhosphorIconData health = PhosphorIconsFill.firstAid;
  static const PhosphorIconData bills = PhosphorIconsFill.receipt;
  static const PhosphorIconData heart = PhosphorIconsFill.heart;
  static const PhosphorIconData money = PhosphorIconsFill.bank;
  static const PhosphorIconData gift = PhosphorIconsFill.gift;
  static const PhosphorIconData education = PhosphorIconsFill.book;
  static const PhosphorIconData entertainment = PhosphorIconsFill.filmStrip;

  static const Map<String, PhosphorIconData> categoryIcons = {
    'food': food,
    'shopping': shopping,
    'transport': transport,
    'house': house,
    'health': health,
    'bills': bills,
    'heart': heart,
    'money': money,
    'gift': gift,
    'education': education,
    'entertainment': entertainment,
  };

  static PhosphorIconData fromName(String? name) {
    return categoryIcons[name?.toLowerCase()] ?? PhosphorIconsFill.question;
  }
}
