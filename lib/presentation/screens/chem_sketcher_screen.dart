import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/hex_background.dart';
import '../../data/services/rdkit_service.dart';
import '../../services/reaction_predictor_service.dart';
import 'ask_chembuddy_screen.dart';
import 'organic_reaction_predictor_screen.dart';

/// Mobile-First Chemical Sketcher (ChemDraw Alternative)
/// Optimized for mobile touchscreens with generous hitboxes, haptic snaps,
/// local zero-cost RDKit descriptors, forward reaction product predictor, and direct ChemBuddy AI integration.
class ChemSketcherScreen extends StatefulWidget {
  const ChemSketcherScreen({super.key, this.initialSmiles});

  final String? initialSmiles;

  @override
  State<ChemSketcherScreen> createState() => _ChemSketcherScreenState();
}

class _ChemSketcherScreenState extends State<ChemSketcherScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentSmiles = '';
  int _atomCount = 0;
  int _bondCount = 0;
  bool _isAnalyzing = false;
  bool _isPredicting = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B0F19))
      ..addJavaScriptChannel(
        'ChemBridge',
        onMessageReceived: (JavaScriptMessage msg) {
          try {
            final data = jsonDecode(msg.message);
            if (data is Map && data['type'] == 'structureChanged') {
              final payload = data['data'];
              setState(() {
                _atomCount = (payload['atomCount'] as num?)?.toInt() ?? 0;
                _bondCount = (payload['bondCount'] as num?)?.toInt() ?? 0;
                _currentSmiles = payload['smiles'] as String? ?? '';
              });
              AppHaptics.selection();
            }
          } catch (e) {
            debugPrint('[ChemBridge] Error parsing bridge message: $e');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            setState(() => _isLoading = false);
            if (widget.initialSmiles != null && widget.initialSmiles!.isNotEmpty) {
              await _loadSmiles(widget.initialSmiles!);
            }
          },
        ),
      )
      ..loadFlutterAsset('assets/web/sketcher.html');
  }

  Future<String> _getSmiles() async {
    try {
      final res = await _controller.runJavaScriptReturningResult('getSmiles()');
      final s = res.toString().replaceAll('"', '').trim();
      return s.isNotEmpty ? s : _currentSmiles;
    } catch (_) {
      return _currentSmiles;
    }
  }

  Future<String> _getMolfile() async {
    try {
      final res = await _controller.runJavaScriptReturningResult('getMolfile()');
      return res.toString().replaceAll('\\n', '\n').replaceAll('"', '');
    } catch (_) {
      return '';
    }
  }

  Future<void> _loadSmiles(String smiles) async {
    final escaped = smiles.replaceAll("'", "\\'");
    await _controller.runJavaScript("loadSmiles('$escaped')");
  }

  Future<void> _analyzeWithRdkit() async {
    AppHaptics.confirm();
    setState(() => _isAnalyzing = true);

    final smiles = await _getSmiles();
    if (smiles.isEmpty) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please draw a chemical structure first.'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
      return;
    }

    try {
      // Validate valency first
      final valency = await RdkitService.instance.validateValency(smiles);
      if (!valency.isValid && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(valency.errorMessage ?? 'Valence error detected.'),
            backgroundColor: AppColors.statusDanger,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      final desc = await RdkitService.instance.calculateDescriptors(smiles);
      setState(() {
        _isAnalyzing = false;
      });

      if (mounted) {
        _showDescriptorsSheet(desc);
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e'), backgroundColor: AppColors.statusDanger),
        );
      }
    }
  }

  Future<void> _predictMajorProduct() async {
    AppHaptics.confirm();
    final rawSmiles = await _getSmiles();
    final smiles = rawSmiles.trim();

    if (smiles.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please draw or select reactant molecule(s) on the canvas first.'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
      return;
    }

    setState(() => _isPredicting = true);

    try {
      final result = await ReactionPredictorService.instance.predictMajorProduct(smiles);
      setState(() => _isPredicting = false);

      if (!mounted) return;

      if (!result.success || result.productSmiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Reaction product prediction unavailable across all 4 keys.'),
            backgroundColor: AppColors.statusDanger,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      _showPredictionBottomSheet(smiles, result);
    } catch (e) {
      setState(() => _isPredicting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prediction failed: $e'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
    }
  }

  void _showPredictionBottomSheet(String reactantsSmiles, ReactionPredictionResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        maxChildSize: 0.92,
        minChildSize: 0.45,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Predicted Major Product',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Forward Chemical Reaction Outcome',
                      style: TextStyle(color: AppColors.accentCyan, fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA78BFA), width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: Color(0xFFA78BFA), size: 13),
                      const SizedBox(width: 4),
                      Text(
                        result.isCached ? 'Cached Zero-Token' : '4-Key Gemini',
                        style: const TextStyle(
                          color: Color(0xFFA78BFA),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Reactants Input Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.input_rounded, color: AppColors.textMuted, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Reactants (Canvas Input)',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    reactantsSmiles,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 2D Vector Structure Rendering
            const Text(
              '2D Molecular Vector Structure (NIH Cactus Engine)',
              style: TextStyle(color: AppColors.brandBright, fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0F19),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderHighlight, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: result.svgData.isNotEmpty && result.svgData.contains('<svg')
                    ? SvgPicture.string(
                        result.svgData,
                        fit: BoxFit.contain,
                        placeholderBuilder: (_) => const Center(
                          child: CircularProgressIndicator(color: AppColors.accentCyan, strokeWidth: 2),
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.science_rounded, color: AppColors.accentCyan, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              result.productSmiles,
                              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            // Product SMILES Text & Copy
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Product SMILES',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          result.productSmiles,
                          style: const TextStyle(color: AppColors.accentCyan, fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppColors.textMuted, size: 18),
                    tooltip: 'Copy Product SMILES',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: result.productSmiles));
                      AppHaptics.selection();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Product SMILES copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Action Buttons: Import to Canvas & Ask ChemBuddy Mechanism
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentCyan,
                      foregroundColor: const Color(0xFF0B0F19),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _loadSmiles(result.productSmiles);
                      AppHaptics.confirm();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Imported "${result.productSmiles}" onto canvas!'),
                            backgroundColor: AppColors.statusSuccess,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.input_rounded, size: 18),
                    label: const Text(
                      'Import to Canvas',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.brandBright),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _launchChatWithPrompt(
                        "For the reaction with reactants '$reactantsSmiles' forming major organic product '${result.productSmiles}', provide the complete step-by-step reaction mechanism with curved electron-pushing arrows, transition state, stereochemical outcome, and driving force with postgraduate MSc rigor.",
                      );
                    },
                    icon: const Icon(Icons.auto_awesome, color: AppColors.brandBright, size: 16),
                    label: const Text(
                      'Full Mechanism',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDescriptorsSheet(MolecularDescriptors d) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.formula.isEmpty ? 'Structure' : d.formula,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SMILES: ${d.smiles}',
                      style: const TextStyle(color: AppColors.accentCyan, fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: d.lipinskiPass
                        ? AppColors.statusSuccess.withValues(alpha: 0.15)
                        : AppColors.statusDanger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: d.lipinskiPass ? AppColors.statusSuccess : AppColors.statusDanger,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    d.lipinskiPass ? 'Lipinski Pass' : 'Lipinski Alert',
                    style: TextStyle(
                      color: d.lipinskiPass ? AppColors.statusSuccess : AppColors.statusDanger,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.borderSubtle),
            const SizedBox(height: 12),
            const Text(
              'Physicochemical & Drug-Likeness Properties (Zero Token Local RDKit)',
              style: TextStyle(color: AppColors.brandBright, fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildMetricTile('Molecular Weight', '${d.molecularWeight} g/mol', 'Exact: ${d.exactMass}'),
                _buildMetricTile('DBE / IHD', d.dbe.toStringAsFixed(1), 'Unsaturation index'),
                _buildMetricTile('LogP', d.logP.toStringAsFixed(2), 'Lipophilicity'),
                _buildMetricTile('TPSA', '${d.tpsa} Å²', 'Polar surface area'),
                _buildMetricTile('H-Bond Donors', '${d.hbd}', 'Max 5 (Rule of 5)'),
                _buildMetricTile('H-Bond Acceptors', '${d.hba}', 'Max 10 (Rule of 5)'),
                _buildMetricTile('Rotatable Bonds', '${d.rotatableBonds}', 'Conformational flex'),
                _buildMetricTile('Aromatic Rings', '${d.aromaticRings}', 'Aromatic systems'),
              ],
            ),
            const SizedBox(height: 16),
            if (d.elementalComposition.isNotEmpty) ...[
              const Text(
                'Elemental Composition (% by mass)',
                style: TextStyle(color: AppColors.brandBright, fontSize: 13, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: d.elementalComposition.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.bg1,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      '${e.key}: ${e.value.toStringAsFixed(2)}%',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _openAiWithSmiles(d.smiles);
                },
                icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                label: const Text('Consult ChemBuddy AI on this Structure', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, String sub) {
    return Container(
      width: (MediaQuery.of(context).size.width - 50) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: AppColors.accentCyan, fontSize: 10)),
        ],
      ),
    );
  }

  void _openAiWithSmiles(String smiles) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select AI Analysis Template',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Target SMILES: $smiles',
              style: const TextStyle(color: AppColors.accentCyan, fontSize: 11.5, fontFamily: 'monospace'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            _buildAiOption(
              title: 'Reaction Predictor & Mechanism Viewer ⚡',
              subtitle: 'Deterministic forward prediction, curved electron-pushing SVG player & MSc pedagogy.',
              icon: Icons.bolt_rounded,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrganicReactionPredictorScreen(
                      initialReactantsSmiles: smiles,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildAiOption(
              title: 'Predict Major Forward Reaction Product',
              subtitle: 'Calculates major organic product and renders 2D SVG vector via Cactus API.',
              icon: Icons.auto_mode_rounded,
              onTap: _predictMajorProduct,
            ),
            const SizedBox(height: 10),
            _buildAiOption(
            title: 'Predict ¹H & ¹³C NMR Spectral Peaks',
            subtitle: 'Chemical shifts (δ ppm), splitting multiplicities, and integration.',
            icon: Icons.graphic_eq_rounded,
            onTap: () => _launchChatWithPrompt(
              'Analyze the chemical structure with SMILES "$smiles". Predict its 1H NMR chemical shifts, splitting patterns (coupling constants J in Hz), and 13C NMR (including DEPT-45, DEPT-90, DEPT-135) with postgraduate MSc rigor.',
            ),
          ),
          const SizedBox(height: 10),
          _buildAiOption(
            title: 'Explain Reactivity & Orbital Control',
            subtitle: 'HOMO-LUMO, electrophilic/nucleophilic sites, and pKa.',
            icon: Icons.flare_rounded,
            onTap: () => _launchChatWithPrompt(
              'For the molecule with SMILES "$smiles", explain its chemical reactivity, identify nucleophilic and electrophilic centers, thermodynamic vs kinetic sites, and orbital considerations (HOMO/LUMO).',
            ),
          ),
          const SizedBox(height: 10),
          _buildAiOption(
            title: 'Suggest Retrosynthetic Disconnection Route',
            subtitle: 'FGI, synthons, and forward multi-step organic synthesis.',
            icon: Icons.account_tree_outlined,
            onTap: () => _launchChatWithPrompt(
              'Perform a complete retrosynthetic analysis for the molecule with SMILES "$smiles". Provide target disconnections, synthetic equivalents (synthons), and forward reaction conditions.',
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildAiOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.brandBright, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
          ],
        ),
      ),
    );
  }

  void _launchChatWithPrompt(String prompt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AskChemBuddyScreen(initialQuestion: prompt),
      ),
    );
  }

  void _showExportDialog() async {
    final smiles = await _getSmiles();
    final molfile = await _getMolfile();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Export Structure', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SMILES Notation:', style: TextStyle(color: AppColors.brandBright, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            SelectableText(
              smiles.isEmpty ? 'Empty canvas' : smiles,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentCyan,
                      side: const BorderSide(color: AppColors.accentCyan),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: smiles));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('SMILES copied to clipboard!')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 14),
                    label: const Text('Copy SMILES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentGold,
                      side: const BorderSide(color: AppColors.accentGold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: molfile));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('MDL Molfile copied to clipboard!')),
                      );
                    },
                    icon: const Icon(Icons.data_object, size: 14),
                    label: const Text('Copy Molfile', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF111827),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context, _currentSmiles),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.gesture_rounded, color: AppColors.brandBright, size: 18),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ChemDraw Mobile Canvas',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                  ),
                  Text(
                    'Touch-Optimized • 100% Offline RDKit',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            if (_currentSmiles.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.pop(context, _currentSmiles),
                child: const Text(
                  'Use',
                  style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            IconButton(
              icon: _isPredicting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentCyan),
                    )
                  : const Icon(Icons.auto_awesome_rounded, color: Color(0xFFA78BFA), size: 21),
              tooltip: 'Predict Major Product ⚡',
              onPressed: _isPredicting ? null : _predictMajorProduct,
            ),
            IconButton(
              icon: const Icon(Icons.file_upload_outlined, color: AppColors.accentCyan, size: 20),
              tooltip: 'Export SMILES / Molfile',
              onPressed: _showExportDialog,
            ),
          ],
        ),
        body: Column(
          children: [
            // Top Status Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF0F172A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bubble_chart_outlined, color: AppColors.accentCyan, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '$_atomCount Atoms • $_bondCount Bonds',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  if (_currentSmiles.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxWidth: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _currentSmiles,
                        style: const TextStyle(color: AppColors.brandBright, fontSize: 11, fontFamily: 'monospace'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            // Sketcher WebView Canvas
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.brandBright),
                    ),
                ],
              ),
            ),
            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF111827),
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Primary Action: Predict Major Product
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                        ),
                        onPressed: _isPredicting ? null : _predictMajorProduct,
                        icon: _isPredicting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.accentCyan),
                        label: Text(
                          _isPredicting ? 'Predicting Reaction Product...' : 'Predict Major Product ⚡',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentCyan,
                              foregroundColor: const Color(0xFF0B0F19),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _isAnalyzing ? null : _analyzeWithRdkit,
                            icon: _isAnalyzing
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                  )
                                : const Icon(Icons.biotech_outlined, size: 16),
                            label: const Text(
                              'RDKit Descriptors',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.borderHighlight),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              final smiles = await _getSmiles();
                              _openAiWithSmiles(smiles.isNotEmpty ? smiles : 'C1=CC=CC=C1');
                            },
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.brandBright),
                            label: const Text(
                              'Ask ChemBuddy',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
