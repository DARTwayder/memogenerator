import 'dart:convert';
import 'package:memogenerator/data/models/template.dart';
import 'package:memogenerator/data/shared_preference_data.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';

class TemplatesRepository {
  final updater = PublishSubject<Null>();
  final SharedPreferenceData spData;

  //статический конструктор,возвращает инстанс
  static TemplatesRepository? _instance;

  factory TemplatesRepository.getInstance() => _instance ??=
      TemplatesRepository._internal(SharedPreferenceData.getInstance());

  TemplatesRepository._internal(this.spData);

  //Метод добавления в избраное
  Future<bool> addToTemplates(final Template newTemplate) async {
    // Если лист пустой
    final templates = await getTemplates();
    final templateIndex = templates.indexWhere((template) => template.id == newTemplate.id);
    if (templateIndex == -1) {
      templates.add(newTemplate);
    } else {
      templates.removeAt(templateIndex);
      templates.insert(templateIndex, newTemplate);
    }
    return _setTemplates(templates);
  }

  //Метод удаления из избранного
  Future<bool> removeFromTemplates(final String id) async {
    // Если лист пустой
    final templates = await getTemplates();
    templates.removeWhere((template) => template.id == id);
    return _setTemplates(templates);
  }

  // Метод будет выдавать список со всем избранным,которые будут обображатся на мейн странице при входе на экран
  // Метод Observe
  Stream<List<Template>> observeTemplates() async* {
    yield await getTemplates();
    await for (final _ in updater) {
      yield await getTemplates();
    }
  }

  // еще 2 доп Метода
  Future<List<Template>> getTemplates() async {
    final rawTemplates = await spData.getTemplates();
    return rawTemplates
        .map((rawTemplate) => Template.fromJson(json.decode(rawTemplate)))
        .toList();
  }

  //Метод оффлайн просмотра избранного
  Future<Template?> getTemplate(final String id) async {
    final templates = await getTemplates();
    return templates.firstWhereOrNull((template) => template.id == id);
  }

  Future<bool> _setTemplates(final List<Template> Templates) async {
    final rawTemplates = Templates.map((Template) => json.encode(Template.toJson())).toList();
    return _setRawTemplates(rawTemplates);
  }

  Future<bool> _setRawTemplates(final List<String> rawTemplates) {
    updater.add(null);
    return spData.setTemplates(rawTemplates);
  }
}
