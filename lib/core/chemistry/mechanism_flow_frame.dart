import '../../data/models/reaction_models.dart';

/// Marker definitions also make the step valid when viewed outside Flutter.
const mechanismArrowMarkers = '''
<defs>
  <marker id="electron-arrow" markerWidth="10" markerHeight="10" refX="8" refY="5" orient="auto" markerUnits="userSpaceOnUse">
    <path d="M 0 1 L 8 5 L 0 9" fill="none" stroke="#24435F" stroke-width="1.5"/>
  </marker>
  <marker id="fishhook" markerWidth="10" markerHeight="10" refX="8" refY="5" orient="auto" markerUnits="userSpaceOnUse">
    <path d="M 0 1 L 8 5" fill="none" stroke="#24435F" stroke-width="1.5"/>
  </marker>
</defs>
''';

/// A reaction-center teaching frame. The layout separates electron bookkeeping
/// from molecular geometry. Coordination changes use an ordinary process arrow.
class MechanismFlowFrame {
  const MechanismFlowFrame(
    this.title,
    this.description,
    this.moves, {
    this.before,
    this.after,
    this.drawing,
  });

  final String title;
  final String description;
  final List<ElectronFlow> moves;
  final String? before;
  final String? after;
  final String? drawing;

  ReactionStep toStep(int number) => ReactionStep(
    stepNumber: number,
    title: title,
    description: description,
    svgContent: drawing ?? _svg(),
    electronFlow: moves,
  );

  String _svg() {
    final height = moves.isEmpty ? 162 : 66 + moves.length * 59;
    final out = StringBuffer(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 $height">'
      '<rect width="640" height="$height" rx="18" fill="#F9FAFE"/>',
    );
    void label(
      String value,
      int x,
      int y, {
      int size = 17,
      String color = '#24364B',
    }) {
      final safe = value
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;');
      out.write(
        '<text x="$x" y="$y" text-anchor="middle" '
        'font-family="sans-serif" font-size="$size" fill="$color">$safe</text>',
      );
    }

    void box(String value, int x, int y, String background) {
      out.write(
        '<rect x="$x" y="$y" width="238" height="42" rx="12" fill="$background"/>',
      );
      final size = (360 / value.runes.length).clamp(10, 17).round();
      label(value, x + 119, y + 26, size: size);
    }

    if (moves.isEmpty) {
      label('Coordination or bond changes', 320, 33, color: '#425970');
      box(before!, 22, 63, '#E7F0FA');
      box(after!, 380, 63, '#E3F2EC');
      out.write(
        '<path d="M 275 84 H 365 M 354 76 L 365 84 L 354 92" '
        'fill="none" stroke="#425970" stroke-width="3" stroke-linecap="round"/>',
      );
    } else {
      label('Electron source', 141, 31, color: '#425970');
      label('Electron destination', 499, 31, color: '#425970');
      for (final (i, move) in moves.indexed) {
        final y = 48 + i * 59;
        box(move.source, 22, y, '#E7F0FA');
        box(move.destination, 380, y, '#E3F2EC');
      }
      out.write('$mechanismArrowMarkers<g id="electron-arrows">');
      for (final (i, move) in moves.indexed) {
        final y = 69 + i * 59;
        final marker = move.type == 'fishhook' ? 'fishhook' : 'electron-arrow';
        out.write(
          '<path d="M 264 $y Q 320 ${y - 27} 376 $y" '
          'fill="none" stroke="#24435F" stroke-width="2" marker-end="url(#$marker)"/>',
        );
      }
      out.write('</g>');
    }
    return '${out.toString()}</svg>';
  }
}

MechanismFlowFrame flow(
  String title,
  String description,
  List<(String, String)> transfers, {
  bool singleElectron = false,
  String? drawing,
}) => MechanismFlowFrame(title, description, [
  for (final (source, destination) in transfers)
    ElectronFlow(
      type: singleElectron ? 'fishhook' : 'two-electron',
      source: source,
      destination: destination,
    ),
], drawing: drawing);

MechanismFlowFrame change(
  String title,
  String description,
  String before,
  String after,
) => MechanismFlowFrame(
  title,
  description,
  const [],
  before: before,
  after: after,
);
