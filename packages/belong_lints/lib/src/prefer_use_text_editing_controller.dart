import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

const _hookTypeNames = {
  'HookWidget',
  'HookConsumerWidget',
  'HookConsumerStatefulWidget',
  'HookConsumerState',
  'HookState',
};

/// In hook widgets, prefer `useTextEditingController` over a raw
/// `TextEditingController` that the widget must dispose by hand.
///
/// Stateful widgets that already dispose their controllers are left alone.
/// pyramid_lint `dispose_controllers` covers that case.
class PreferUseTextEditingController extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_use_text_editing_controller',
    'Use useTextEditingController instead of TextEditingController() in a hook widget.',
    correctionMessage:
        'Create the controller with useTextEditingController() in build. '
        'Hooks dispose it.',
    severity: DiagnosticSeverity.WARNING,
  );

  PreferUseTextEditingController()
    : super(
        name: 'prefer_use_text_editing_controller',
        description:
            'Hook widgets should create text controllers with '
            'useTextEditingController.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addInstanceCreationExpression(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!context.isInLibDir) return;
    if (!_createsTextEditingController(node)) return;
    if (!_insideHookClass(node)) return;
    rule.reportAtNode(node);
  }

  bool _createsTextEditingController(InstanceCreationExpression node) {
    final name = node.constructorName.type.name.lexeme;
    return name == 'TextEditingController';
  }

  bool _insideHookClass(AstNode node) {
    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is! ClassDeclaration) continue;
      final superclass = current.extendsClause?.superclass.toSource() ?? '';
      for (final hookName in _hookTypeNames) {
        if (superclass.contains(hookName)) return true;
      }
    }
    return false;
  }
}
