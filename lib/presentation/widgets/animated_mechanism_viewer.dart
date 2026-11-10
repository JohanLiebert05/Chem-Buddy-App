import 'package:flutter/material.dart';

import '../../data/models/reaction_models.dart';
import '../../data/services/mechanism_lessons.dart';
import '../../data/services/reaction_curation_repository.dart';
import '../../data/services/reaction_mechanism_service.dart';
import 'mechanism_step_viewer.dart';

/// Predictor lessons use representative chemistry for the matched reaction class.
class AnimatedMechanismViewer extends StatelessWidget {
  const AnimatedMechanismViewer({
    super.key,
    required this.reaction,
    this.initialStepIndex = 0,
  });

  final CuratedReaction reaction;
  final int initialStepIndex;

  @override
  Widget build(BuildContext context) {
    final libraryId = MechanismLessons.libraryIdForPredictor(
      reaction.reactionId,
    );
    final lessonSteps = MechanismLessons.predictorSteps(reaction.reactionId);
    final library = libraryId == null
        ? null
        : ReactionMechanismService.instance.find(libraryId);
    final steps =
        lessonSteps ??
        library?.steps ??
        [
          for (final step in reaction.steps)
            ReactionStep(
              stepNumber: step.stepNumber,
              title: step.stepTitle,
              description: step.stepDescription,
              curvedArrowNotes: step.bondChanges,
            ),
        ];
    return MechanismStepViewer(
      key: ObjectKey(reaction),
      mechanism:
          library ??
          ReactionMechanism(
            id: reaction.reactionId,
            name: reaction.reactionName,
            category: ReactionCategory.namedReactions,
            summary: reaction.description,
            reactants: '',
            reagentsAndConditions: reaction.conditions,
            products: '',
          ),
      lessonSteps: steps,
      scopeLabel: MechanismLessons.hasPredictorLesson(reaction.reactionId)
          ? 'Representative mechanism for this reaction class'
          : 'Predicted mechanism notes',
      initialStepIndex: initialStepIndex,
    );
  }
}
