import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/hex_background.dart';
import '../../data/services/rdkit_service.dart';
import 'ask_chembuddy_screen.dart';

/// Mobile-First Chemical Sketcher (ChemDraw Alternative)
/// Optimized for mobile touchscreens with generous hitboxes, haptic snaps,
/// local zero-cost RDKit descriptors, and direct ChemBuddy AI integration.
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
            onPressed: () => Navigator.pop(context),
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
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentCyan,
                          foregroundColor: const Color(0xFF0B0F19),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isAnalyzing ? null : _analyzeWithRdkit,
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(Icons.biotech_outlined, size: 18),
                        label: const Text(
                          'Analyze with RDKit',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final smiles = await _getSmiles();
                          _openAiWithSmiles(smiles.isNotEmpty ? smiles : 'C1=CC=CC=C1');
                        },
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text(
                          'Ask ChemBuddy AI',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
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
