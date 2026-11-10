import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/text_scale.dart';

/// Shared harness for the large-text Gherkin steps.
///
/// The same shape as the group-call world on PR #905: steps mutate one
/// object, and the scenario runner in large_text_bdd_test.dart reads it.
class LargeTextWorld {
  LargeTextWorld(this.tester);

  final WidgetTester tester;
  TextScaleSession? session;
  bool sawSignInTitle = false;
  bool sawHome = false;
  bool sawDiscussion = false;
  bool sawMessages = false;
  bool sawFontChoices = false;
  bool sawFeedback = false;
}

LargeTextWorld? largeTextWorld;
