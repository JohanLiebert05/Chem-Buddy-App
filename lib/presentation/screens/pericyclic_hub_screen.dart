import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/chemistry_markdown_view.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
import '../../data/services/pericyclic_service.dart';

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
                'Select Reaction Parameters',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 12),

              // 1. Reaction Class Selector
              const Text('REACTION CLASS', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              SegmentedButton<PericyclicType>(
                segments: const [
                  ButtonSegment(value: PericyclicType.electrocyclic, label: Text('Electrocyclic', style: TextStyle(fontSize: 11.5))),
                  ButtonSegment(value: PericyclicType.cycloaddition, label: Text('Cycloaddition', style: TextStyle(fontSize: 11.5))),
                  ButtonSegment(value: PericyclicType.sigmatropic, label: Text('Sigmatropic', style: TextStyle(fontSize: 11.5))),
                ],
                selected: {_selectedType},
                onSelectionChanged: (val) {
                  AppHaptics.selection();
                  setState(() => _selectedType = val.first);
                },
              ),
              const SizedBox(height: 14),

              // 2. Electron System (4n vs 4n+2)
              const Text('PI ELECTRON COUNT', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 4, label: Text('4n (4 e⁻: Butadiene / [2+2])', style: TextStyle(fontSize: 11.5))),
                  ButtonSegment(value: 6, label: Text('4n+2 (6 e⁻: Hexatriene / [4+2])', style: TextStyle(fontSize: 11.5))),
                ],
                selected: {_selectedElectrons},
                onSelectionChanged: (val) {
                  AppHaptics.selection();
                  setState(() => _selectedElectrons = val.first);
                },
              ),
              const SizedBox(height: 14),

              // 3. Condition (Thermal vs Photochemical)
              const Text('REACTION CONDITIONS', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              SegmentedButton<ReactionCondition>(
                segments: const [
                  ButtonSegment(
                    value: ReactionCondition.thermal,
                    icon: Icon(Icons.local_fire_department, size: 16, color: AppColors.accentGold),
                    label: Text('Thermal (Δ)', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment(
                    value: ReactionCondition.photochemical,
                    icon: Icon(Icons.wb_sunny_outlined, size: 16, color: AppColors.accentCyan),
                    label: Text('Photochemical (hν)', style: TextStyle(fontSize: 12)),
                  ),
                ],
                selected: {_selectedCondition},
                onSelectionChanged: (val) {
                  AppHaptics.selection();
                  setState(() => _selectedCondition = val.first);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Result Prediction Card
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.statusSuccess.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.verified_rounded, color: AppColors.statusSuccess, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('WOODWARD-HOFFMANN OUTCOME', style: TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w800)),
                        Text(
                          prediction.allowedMode.toUpperCase(),
                          style: const TextStyle(color: AppColors.statusSuccess, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (prediction.isThermallyAllowed ? AppColors.accentGold : AppColors.accentCyan).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedCondition == ReactionCondition.thermal ? 'THERMAL Δ' : 'PHOTO hν',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _selectedCondition == ReactionCondition.thermal ? AppColors.accentGold : AppColors.accentCyan,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.borderSubtle, height: 24),
              _buildDetailRow('Allowed Mode:', prediction.allowedMode, AppColors.statusSuccess),
              const SizedBox(height: 6),
              _buildDetailRow('Forbidden Mode:', prediction.forbiddenMode, AppColors.statusDanger),
              const SizedBox(height: 6),
              _buildDetailRow('TS Topology:', prediction.transitionStateSymmetry, AppColors.brandBright),
              const SizedBox(height: 12),
              const Text('Frontier Molecular Orbital (FMO) Analysis:', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(prediction.homoState, style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.35)),
              const SizedBox(height: 12),
              const Text('Stereochemical Benchmark Example:', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              ChemistryMarkdownView(
                text: prediction.stereochemistryExample,
                textStyle: const TextStyle(color: AppColors.accentCyan, fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRulesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Master Woodward-Hoffmann Selection Rules Matrix',
          style: TextStyle(color: AppColors.brandBright, fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...PericyclicService.selectionRules.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.reactionType, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(r.electronCount, style: const TextStyle(color: AppColors.brandBright, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const Divider(color: AppColors.borderSubtle, height: 18),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, size: 16, color: AppColors.accentGold),
                    const SizedBox(width: 6),
                    const Text('Thermal (Δ): ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    Expanded(
                      child: Text(r.thermalMode, style: const TextStyle(color: AppColors.statusSuccess, fontWeight: FontWeight.w700, fontSize: 12.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.wb_sunny_outlined, size: 16, color: AppColors.accentCyan),
                    const SizedBox(width: 6),
                    const Text('Photochemical (hν): ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    Expanded(
                      child: Text(r.photochemicalMode, style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.w700, fontSize: 12.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(r.homoSymmetry, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.3)),
              ],
            ),
          ),
        )),
      ],
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
        ),
      ],
    );
  }

  Widget _buildClassCard({required String title, required String subtitle, required List<String> bullets}) {
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
