import 'dart:convert';
import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

Map<String, dynamic> describe(StringLiteral node, [List<String>? existing]) {
  if (node is SimpleStringLiteral) return {'key': node.value, 'args': <String>[]};
  if (node is AdjacentStrings) {
    final args = existing ?? <String>[];
    final buffer = StringBuffer();
    for (final part in node.strings) { final value = describe(part, args); buffer.write(value['key']); }
    return {'key': buffer.toString(), 'args': args};
  }
  if (node is StringInterpolation) {
    final args = existing ?? <String>[];
    final buffer = StringBuffer();
    for (final item in node.elements) {
      if (item is InterpolationString) buffer.write(item.value);
      if (item is InterpolationExpression) {
        final expression = item.expression.toSource();
        var index = args.indexOf(expression);
        if (index < 0) { index = args.length; args.add(expression); }
        buffer.write('{p$index}');
      }
    }
    return {'key': buffer.toString(), 'args': args};
  }
  return {'key': '', 'args': <String>[]};
}

class Existing extends RecursiveAstVisitor<void> {
  final Map<String, String> pairs;
  Existing(this.pairs);
  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (['_pick', '_dual', '_t', 't', 'settingsText', '_txt', '_translate'].contains(node.methodName.name)) {
      final strings = node.argumentList.arguments.whereType<StringLiteral>().toList();
      if (strings.length == 2) {
        final args = <String>[];
        final english = describe(strings[0], args)['key'] as String;
        final swahili = describe(strings[1], args)['key'] as String;
        if (english.isNotEmpty && swahili.isNotEmpty && english != swahili) pairs.putIfAbsent(english, () => swahili);
      }
    }
    super.visitMethodInvocation(node);
  }
}

const names = {'title','subtitle','label','labelText','hintText','hint','tooltip','message','description','helperText','errorText','semanticLabel','text','emptyTitle','emptyMessage','discardLabel','saveLabel','queryHint','buttonText','loadingText','searchHint','placeholder','confirmLabel','cancelLabel'};
String? contextFor(AstNode node) {
  AstNode? current = node;
  var insideBody = false;
  while (current != null) {
    if (current is FunctionBody) insideBody = true;
    FormalParameterList? parameters;
    if (current is MethodDeclaration) parameters = current.parameters;
    if (current is FunctionDeclaration) parameters = current.functionExpression.parameters;
    if (current is FunctionExpression) parameters = current.parameters;
    if (parameters != null && RegExp(r'\bcontext\b').hasMatch(parameters.toSource())) return 'context';
    if (insideBody && current is ClassDeclaration && current.extendsClause?.superclass.toSource().startsWith('State<') == true) return 'context';
    current = current.parent;
  }
  return null;
}
bool bilingualBranch(AstNode node) {
  AstNode? current = node.parent;
  while (current != null && current is! ArgumentList && current is! FunctionBody) {
    if (current is ConditionalExpression && RegExp(r'isSwahili|\bisSw\b|\bsw\b|languageCode|\blang\b').hasMatch(current.condition.toSource())) return true;
    current = current.parent;
  }
  return false;
}
bool target(AstNode node) {
  AstNode? current = node;
  while (current?.parent != null) {
    final parent = current!.parent!;
    if (parent is NamedExpression) return names.contains(parent.name.label.name);
    if (parent is ArgumentList) {
      final owner = parent.parent;
      if (owner is MethodInvocation && ['_setError'].contains(owner.methodName.name)) {
        return parent.arguments.last == current;
      }
      if (owner is MethodInvocation && ['Text', 'SelectableText', 'Tooltip', 'Semantics'].contains(owner.methodName.name)) {
        return parent.arguments.first == current;
      }
      if (owner is InstanceCreationExpression) {
        final constructor = owner.constructorName.toSource();
        return ['Text','SelectableText','Semantics','Tooltip'].contains(constructor) && parent.arguments.first == current;
      }
      return false;
    }
    if (parent is FunctionExpression || parent is ReturnStatement) {
      AstNode? ancestor = parent;
      for (var i=0; i<5 && ancestor != null; i++, ancestor = ancestor.parent) {
        if (ancestor is NamedExpression && ancestor.name.label.name == 'validator') return true;
      }
      return false;
    }
    if (parent is ConditionalExpression || parent is AdjacentStrings || parent is ParenthesizedExpression || (parent is BinaryExpression && parent.operator.lexeme == '??')) { current = parent; continue; }
    return false;
  }
  return false;
}

class Scan extends RecursiveAstVisitor<void> {
  final String path;
  final List<Map<String,dynamic>> entries;
  Scan(this.path,this.entries);
  void add(StringLiteral node) {
    if (node.parent is AdjacentStrings || node.parent is InterpolationExpression || !target(node) || bilingualBranch(node)) return;
    final value = describe(node);
    final key = value['key'] as String;
    if (!RegExp(r'[A-Za-z]{2}').hasMatch(key) || key.contains('://') || key.startsWith('assets/') || key.startsWith('package:')) return;
    final context = contextFor(node);
    final constants = <Map<String,int>>[];
    AstNode? ancestor = node.parent;
    while (ancestor != null && ancestor is! CompilationUnit) {
      if (ancestor is InstanceCreationExpression && ancestor.keyword?.lexeme == 'const') constants.add({'offset': ancestor.keyword!.offset, 'length': 5});
      if (ancestor is ListLiteral && ancestor.constKeyword != null) constants.add({'offset': ancestor.constKeyword!.offset, 'length': 5});
      if (ancestor is SetOrMapLiteral && ancestor.constKeyword != null) constants.add({'offset': ancestor.constKeyword!.offset, 'length': 5});
      if (ancestor is VariableDeclarationList && ancestor.keyword?.lexeme == 'const') constants.add({'offset': ancestor.keyword!.offset, 'length': 5, 'final': 1});
      ancestor = ancestor.parent;
    }
    entries.add({'file':path,'offset':node.offset,'length':node.length,'key':key,'args':value['args'],'context':context,'constants':constants});
  }
  @override void visitSimpleStringLiteral(SimpleStringLiteral node) { add(node); super.visitSimpleStringLiteral(node); }
  @override void visitStringInterpolation(StringInterpolation node) { add(node); super.visitStringInterpolation(node); }
  @override void visitAdjacentStrings(AdjacentStrings node) { add(node); super.visitAdjacentStrings(node); }
}
void main() {
  final pairs = <String,String>{}; final entries = <Map<String,dynamic>>[];
  final files = Directory('lib').listSync(recursive:true).whereType<File>().where((file)=>file.path.endsWith('.dart') && !file.path.contains('ui_catalog.dart')).toList();
  for (final file in files) { final unit=parseFile(path:file.absolute.path,featureSet: FeatureSet.latestLanguageVersion(),throwIfDiagnostics:false).unit; unit.accept(Existing(pairs)); }
  for (final file in files.where((file)=>file.path.contains('ui\\') || file.path.contains('ui/') || file.path.endsWith('main.dart'))) {
    parseFile(path:file.absolute.path,featureSet: FeatureSet.latestLanguageVersion(),throwIfDiagnostics:false).unit.accept(Scan(file.path.replaceAll('\\','/'),entries));
  }
  File('tool/localization_audit.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert({'existing':pairs,'entries':entries}));
  final unique=entries.map((item)=>item['key']).toSet();
  final missing=unique.where((key)=>!pairs.containsKey(key));
  print('Existing translations: ${pairs.length}; UI phrases: ${unique.length}; missing: ${missing.length}; replaceable: ${entries.where((item)=>item['context'] != null).length}; missing context: ${entries.where((item)=>item['context'] == null).length}');
}
