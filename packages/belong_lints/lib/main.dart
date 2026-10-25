import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/no_print_use_app_logger.dart';
import 'src/prefer_use_text_editing_controller.dart';

/// Entry point the analysis server loads from this package.
final plugin = BelongLintsPlugin();

/// Belong lint rules.
///
/// `custom_lint` 0.8.1 cannot resolve on this SDK: it stops at analyzer 8,
/// and Dart 3.13 loads plugins through `analysis_server_plugin` instead.
/// These rules are the same checks, on the supported plugin API.
class BelongLintsPlugin extends Plugin {
  @override
  String get name => 'Belong lints';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(NoPrintUseAppLogger());
    registry.registerWarningRule(PreferUseTextEditingController());
  }
}
