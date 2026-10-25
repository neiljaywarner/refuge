import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Disallow `print` and `developer.log` under `lib/` so diagnostics go through
/// `AppLogger`. Command-line tools under `tool/` keep stdout.
class NoPrintUseAppLogger extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_print_use_app_logger',
    'Use AppLogger instead of print or developer.log.',
    correctionMessage:
        'Call AppLogger.debug, AppLogger.info, AppLogger.warning, or '
        'AppLogger.error.',
    severity: DiagnosticSeverity.WARNING,
  );

  NoPrintUseAppLogger()
    : super(
        name: 'no_print_use_app_logger',
        description:
            'Routes lib/ diagnostics through AppLogger instead of print '
            'or developer.log.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addMethodInvocation(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!context.isInLibDir) return;
    if (_isPrint(node) || _isDeveloperLog(node)) {
      rule.reportAtNode(node);
    }
  }

  bool _isPrint(MethodInvocation node) => node.target == null && node.methodName.name == 'print';

  bool _isDeveloperLog(MethodInvocation node) {
    final target = node.target;
    return node.methodName.name == 'log' &&
        target is SimpleIdentifier &&
        target.name == 'developer';
  }
}
