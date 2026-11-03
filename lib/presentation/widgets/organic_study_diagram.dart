import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/services/organic_diagrams.dart';

class OrganicStudyDiagram extends StatelessWidget {
  const OrganicStudyDiagram({super.key, required this.diagram});
  final String diagram;
  @override
  Widget build(BuildContext context) {
    final data = organicDiagrams[diagram]!;
    final colors = Theme.of(context).colorScheme;
    String hex(Color c) => '#${c.toARGB32().toRadixString(16).substring(2)}';
    final svg = data.svg(
      ink: hex(colors.onSurface),
      accent: hex(colors.primary),
      surface: hex(colors.surfaceContainerLow),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(data.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Semantics(
          image: true,
          label: '${data.title}. ${data.caption}',
          child: RepaintBoundary(
            child: SvgPicture.string(svg, excludeFromSemantics: true),
          ),
        ),
        const SizedBox(height: 8),
        Text(data.caption),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.zoom_in_rounded),
            label: const Text('Explore diagram'),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (ctx) => Dialog.fullscreen(
                child: SafeArea(
                  child: Column(
                    children: [
                      AppBar(
                        title: Text(data.title),
                        leading: IconButton(
                          tooltip: 'Close diagram',
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ),
                      Expanded(
                        child: InteractiveViewer(
                          minScale: .5,
                          maxScale: 5,
                          child: Center(
                            child: SvgPicture.string(
                              svg,
                              semanticsLabel: data.caption,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(data.caption),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
