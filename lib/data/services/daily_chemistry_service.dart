import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum ChemistryContentType {
  joke(Icons.mood, '🧪 Chemistry Joke', AppColors.warning),
  fact(Icons.science, '⚗️ Chemistry Fact', AppColors.purple),
  quote(Icons.format_quote, '🔬 Chemistry Quote', AppColors.blue),
  trivia(Icons.lightbulb_outline, '💡 Did You Know?', AppColors.purpleBright),
  tip(Icons.auto_awesome, '🎯 Study Motivation', AppColors.success);

  const ChemistryContentType(this.icon, this.header, this.color);
  final IconData icon;
  final String header;
  final Color color;
}

class DailyChemistryItem {
  final ChemistryContentType type;
  final String title;
  final String content;
  final String? authorOrNote;

  const DailyChemistryItem({
    required this.type,
    required this.title,
    required this.content,
    this.authorOrNote,
  });
}

class DailyChemistryService {
  DailyChemistryService._();
  static final instance = DailyChemistryService._();

  static const List<DailyChemistryItem> _items = [
    DailyChemistryItem(
      type: ChemistryContentType.joke,
      title: 'Reaction Control',
      content: 'Why did the organic chemist stay calm during the synthesis?\nBecause they had great reaction control!',
    ),
    DailyChemistryItem(
      type: ChemistryContentType.fact,
      title: 'Universal Catalyst',
      content: 'Catalysts accelerate chemical reactions by providing an alternative reaction pathway with lower activation energy, without undergoing any permanent chemical change.',
      authorOrNote: 'Kinetics Principle',
    ),
    DailyChemistryItem(
      type: ChemistryContentType.quote,
      title: 'The Study of Change',
      content: '“Chemistry is the study of matter, but I prefer to see it as the study of change.”',
      authorOrNote: 'Walter White',
    ),
    DailyChemistryItem(
      type: ChemistryContentType.trivia,
      title: 'Helium & Superfluidity',
      content: 'Liquid Helium-4 cooled below 2.17 Kelvin becomes a superfluid with zero viscosity, allowing it to climb up and out of glass beakers!',
      authorOrNote: 'Quantum Fluidity',
    ),
    DailyChemistryItem(
      type: ChemistryContentType.joke,
      title: 'Noble Gases',
      content: 'Argon walks into a bar. The bartender says, "We don''t serve noble gases here!"\nArgon doesn''t react.',
    ),
    DailyChemistryItem(
      type: ChemistryContentType.fact,
      title: 'The Benzene Ring',
      content: 'Kekulé conceived the cyclic structure of benzene in 1865 after daydreaming of an Ouroboros—a serpent seizing its own tail.',
      authorOrNote: 'Organic History',
    ),
    DailyChemistryItem(
      type: ChemistryContentType.quote,
      title: 'Courage in Science',
      content: '“Nothing in life is to be feared, it is only to be understood. Now is the time to understand more, so that we may fear less.”',
      authorOrNote: 'Marie Curie (Nobel Laureate in Physics & Chemistry)',
    ),
    DailyChemistryItem(
      type: ChemistryContentType.trivia,
      title: 'Chirality in Everyday Scents',
      content: 'The (R)-enantiomer of carvone smells like spearmint, while its mirror image (S)-carvone smells like caraway seeds. Receptors in your nose are chiral!',
      authorOrNote: 'Stereochemistry',
    ),
    DailyChemistryItem(
      type: ChemistryContentType.tip,
      title: 'Mastering Mechanisms',
      content: 'When studying arrow-pushing mechanisms, follow the electron pairs (nucleophile to electrophile), not the atoms. Charges will balance automatically.',
      authorOrNote: 'Organic Synthesis Tip',
    ),
    DailyChemistryItem(
      type: ChemistryContentType.joke,
      title: 'Optimist vs Chemist',
      content: 'To the optimist, the glass is half full. To the pessimist, it is half empty.\nTo the chemist, the glass is completely full: half liquid, half gas.',
    ),
    DailyChemistryItem(
      type: ChemistryContentType.fact,
      title: 'Graphene Strength',
      content: 'A single layer of graphene (sp² hybridized carbon) is 200 times stronger than steel and an exceptional electrical conductor.',
      authorOrNote: 'Materials Chemistry',
    ),
    DailyChemistryItem(
      type: ChemistryContentType.quote,
      title: 'Molecular Architecture',
      content: '“Synthetic chemistry is molecular architecture. We build microscopic cathedrals one bond at a time.”',
      authorOrNote: 'E. J. Corey (Nobel Laureate in Chemistry)',
    ),
    DailyChemistryItem(
      type: ChemistryContentType.trivia,
      title: 'The Blue of Ozone',
      content: 'Liquid ozone is dark blue in color and dangerously explosive. Even in gaseous form, ozone absorbs red wavelengths, giving it a faint sky-blue tint.',
      authorOrNote: 'Inorganic Chemistry',
    ),
    DailyChemistryItem(
      type: ChemistryContentType.joke,
      title: 'Sodium & Potassium',
      content: 'I told a chemistry joke about Sodium...\nNa, you wouldn''t get it. Then I asked Potassium...\nK.',
    ),
  ];

  DailyChemistryItem getTodayContent([DateTime? customDate]) {
    final date = customDate ?? DateTime.now();
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final index = (dayOfYear.abs()) % _items.length;
    return _items[index];
  }
}
