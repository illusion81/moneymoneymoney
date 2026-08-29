import 'rig/viz_rig.dart';

/// Registry of every viz gameobject the workbench can show.
///
/// Each gameobject adds exactly one line here and nothing else.
class VizCatalog {
  const VizCatalog._();

  static List<VizRig> get all => List<VizRig>.unmodifiable(<VizRig>[]);

  static VizRig byId(String id) => all.firstWhere((rig) => rig.id == id);
}
