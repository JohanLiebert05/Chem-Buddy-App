import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/chemistry_markdown_view.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
import '../../data/services/pericyclic_service.dart';
import 'reaction_mechanism_screen.dart';

class PericyclicHubScreen extends StatefulWidget {
  const PericyclicHubScreen({super.key});

  @override
  State<PericyclicHubScreen> createState() => _PericyclicHubScreenState();
}

class _PericyclicHubScreenState extends State<PericyclicHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PericyclicType _selectedType = PericyclicType.electrocyclic;
  int _selectedElectrons = 4; // 4 or 6
  ReactionCondition _selectedCondition = ReactionCondition.thermal;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Row(
            children: [
              Icon(Icons.all_inclusive_rounded, color: AppColors.brandBright, size: 22),
              SizedBox(width: 8),
              Text(
                'Pericyclic Chemistry & FMO',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.brandBright,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
              Tab(text: 'FMO Predictor'),
              Tab(text: 'Woodward-Hoffmann Rules'),
              Tab(text: 'MSc Reaction Classes'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPredictorTab(),
            _buildRulesTab(),
            _buildClassesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictorTab() {
    final prediction = PericyclicService.predict(
      type: _selectedType,
      electrons: _selectedElectrons,
      condition: _selectedCondition,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlowCard(
          borderColor: AppColors.brandBright.withValues(alpha: 0.4),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reaction Parameters',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text('Reaction Type:', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SegmentedButton<PericyclicType>(
                segments: const [
                  ButtonSegment(value: PericyclicType.electrocyclic, label: Text('Electrocyclic', style: TextStyle(fontSize: 11))),
                  ButtonSegment(value: PericyclicType.cycloaddition, label: Text('Cycloadd.', style: TextStyle(fontSize: 11))),
                  ButtonSegment(value: PericyclicType.sigmatropic, label: Text('Sigmatropic', style: TextStyle(fontSize: 11))),
                ],
                selected: {_selectedType},
                onSelectionChanged: (set) {
                  AppHaptics.selection();
                  setState(() => _selectedType = set.first);
                },
              ),
              const SizedBox(height: 12),
              const Text('Electron Framework (π / σ):', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('4n Electrons (e.g. 4π)')),
                      selected: _selectedElectrons == 4,
                      onSelected: (selected) {
                        if (selected) {
                          AppHaptics.selection();
                          setState(() => _selectedElectrons = 4);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('4n + 2 Electrons (e.g. 6π)')),
                      selected: _selectedElectrons == 6,
                      onSelected: (selected) {
                        if (selected) {
                          AppHaptics.selection();
                          setState(() => _selectedElectrons = 6);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Activation Mode:', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Thermal (Δ)')),
                      selected: _selectedCondition == ReactionCondition.thermal,
                      onSelected: (selected) {
                        if (selected) {
                          AppHaptics.selection();
                          setState(() => _selectedCondition = ReactionCondition.thermal);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Photochemical (hν)')),
                      selected: _selectedCondition == ReactionCondition.photochemical,
                      onSelected: (selected) {
                        if (selected) {
                          AppHaptics.selection();
                          setState(() => _selectedCondition = ReactionCondition.photochemical);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlowCard(
          borderColor: prediction.isThermallyAllowed ? AppColors.success.withValues(alpha: 0.5) : AppColors.brandBright.withValues(alpha: 0.5),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    prediction.isThermallyAllowed ? Icons.check_circle_rounded : Icons.wb_sunny_rounded,
                    color: prediction.isThermallyAllowed ? AppColors.success : AppColors.brandBright,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Predicted Mode: ${prediction.allowedMode}',
                    style: TextStyle(
                      color: prediction.isThermallyAllowed ? AppColors.success : AppColors.brandBright,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Symmetry Conservation:', prediction.transitionStateSymmetry, Colors.white),
              const SizedBox(height: 8),
              _buildDetailRow('Active FMO:', prediction.homoState, AppColors.brandBright),
              const SizedBox(height: 12),
              const Divider(color: AppColors.borderSubtle),
              const SizedBox(height: 8),
              const Text('Stereochemical Benchmark Example:', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              ChemistryMarkdownView(
                text: prediction.stereochemistryExample,
                textStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRulesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: PericyclicService.selectionRules.length,
      itemBuilder: (context, index) {
        final rule = PericyclicService.selectionRules[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(rule.reactionType, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(rule.electronCount, style: const TextStyle(color: AppColors.brandBright, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildDetailRow('Thermal (Δ):', rule.thermalMode, AppColors.success),
                const SizedBox(height: 6),
                _buildDetailRow('Photochemical (hν):', rule.photochemicalMode, AppColors.accentCyan),
                const SizedBox(height: 8),
                Text(rule.homoSymmetry, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClassesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildClassCard(
          title: '1. Electrocyclic Reactions',
          subtitle: 'Reversible intramolecular cyclization of conjugated polyenes with formation of a single sigma bond.',
          bullets: [
            'Conrotatory: Both terminal lobes rotate in the SAME direction (clockwise/clockwise or counter/counter). Preserves C₂ symmetry.',
            'Disrotatory: Terminal lobes rotate in OPPOSITE directions (one clockwise, one counter). Preserves mirror plane m symmetry.',
            '4n Thermal: Conrotatory (e.g. trans,trans-2,4-hexadiene -> trans-cyclobutene).',
            '4n+2 Thermal: Disrotatory (e.g. trans,cis,trans-2,4,6-octatriene -> cis-cyclohexadiene).',
          ],
        ),
        const SizedBox(height: 12),
        _buildClassCard(
          title: '2. Cycloaddition Reactions',
          subtitle: 'Two or more unsaturated molecules combine to form a ring with conversion of pi bonds to sigma bonds.',
          bullets: [
            '[4s+2s] Diels-Alder: Diene (4 pi electrons) + Dienophile (2 pi electrons). Thermally allowed with suprafacial overlap.',
            'Endo Rule: Electron-withdrawing substituents on the dienophile point toward the developing diene double bond due to secondary orbital interaction.',
            '[2s+2s] Photochemical: Irradiation promotes an electron into pi*, allowing constructive suprafacial overlap to form cyclobutanes.',
          ],
          actionWidget: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.accentCyan),
              foregroundColor: AppColors.accentCyan,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              AppHaptics.selection();
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const ReactionMechanismsScreen(initialReactionId: 'diels_alder'),
                ),
              );
            },
            icon: const Icon(Icons.view_in_ar_rounded, size: 16),
            label: const Text('Explore Diels-Alder 3D Lab & Vectors ⚗️', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 12),
        _buildClassCard(
          title: '3. Sigmatropic Rearrangements',
          subtitle: 'Uncatalyzed intramolecular migration of a sigma bond across a conjugated pi electron framework.',
          bullets: [
            '[3,3]-Cope Rearrangement: Thermal isomerization of 1,5-hexadienes through a 6-membered chair-like transition state.',
            '[3,3]-Claisen Rearrangement: Thermal rearrangement of allyl vinyl ethers or allyl aryl ethers into gamma,delta-unsaturated carbonyls.',
            '[1,5]-Sigmatropic Hydrogen Shift: Thermally allowed with suprafacial migration across a pentadienyl system (retention of configuration).',
          ],
          actionWidget: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.purpleBright),
                        foregroundColor: AppColors.purpleBright,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        AppHaptics.selection();
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const ReactionMechanismsScreen(initialReactionId: 'cope'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.sync_alt_rounded, size: 15),
                      label: const Text('Cope 3D Lab 🔄', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.accentCyan),
                        foregroundColor: AppColors.accentCyan,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        AppHaptics.selection();
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const ReactionMechanismsScreen(initialReactionId: 'claisen_sigmatropic'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.science_rounded, size: 15),
                      label: const Text('Claisen 3D Lab 🧪', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClassCard({
    required String title,
    required String subtitle,
    required List<String> bullets,
    Widget? actionWidget,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.3)),
          const Divider(color: AppColors.borderSubtle, height: 16),
          ...bullets.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: AppColors.brandBright, fontWeight: FontWeight.w900)),
                Expanded(child: Text(b, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35))),
              ],
            ),
          )),
          if (actionWidget != null) ...[
            const SizedBox(height: 10),
            actionWidget,
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800))),
      ],
    );
  }
}
