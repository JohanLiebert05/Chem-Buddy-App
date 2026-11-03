import 'dart:convert';
import 'dart:io';
import 'package:chem_buddy/data/models/organic_study.dart';
import 'package:chem_buddy/data/services/organic_curriculum.dart';
import 'package:chem_buddy/data/services/organic_diagrams.dart';

void main(){
  final report={'version':'3.5.8','title':'Basics of Organic Chemistry',
    'levels':organicLessons.length,'chapters':organicChapters,'diagrams':organicDiagrams.length,
    'checks':organicLessons.expand((l)=>l.questions).length,
    'session_plans':[for(final mode in StudyLength.values){'minutes':mode.minutes,
      'learn_seconds':mode.learnSeconds,'practice_seconds':mode.practiseSeconds}],
    'scope':'A 60-level foundation-to-MSc bridge with continued practice required; not a promise of full MSc mastery.',
    'reading':[for(final source in organicReading){'title':source.$1,'url':source.$2}],
    'curriculum':[for(final lesson in organicLessons){'id':lesson.id,'level':lesson.number,
      'chapter':lesson.chapter,'title':lesson.title,'question':lesson.hook,
      'plain_language':lesson.simple,'reasoning':lesson.reasoning,'worked_example':lesson.example,
      'advanced_connection':lesson.advanced,'diagram':lesson.diagram,
      'checks':[for(final q in lesson.questions){'question':q.prompt,'options':q.options,
        'answer':q.options[q.answer],'explanation':q.explanation}]}],
  };
  final file=File('docs/reports/study-mode-curriculum.json');
  file.parent.createSync(recursive:true);
  file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(report)}\n');
  stdout.writeln('Wrote ${organicLessons.length} levels, ${report['checks']} checks, ${organicDiagrams.length} vector diagrams.');
}
