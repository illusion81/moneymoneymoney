import 'package:flutter/material.dart';

import '../rig/viz_clip.dart';
import '../rig/viz_rig.dart';
import '../viz_catalog.dart';
import '../viz_stage.dart';

/// The one interactive file under lib/viz. Lets a reviewer pick a gameobject
/// and a clip and watch it loop while its look is being refined.
class VizWorkbenchScreen extends StatefulWidget {
  const VizWorkbenchScreen({super.key});

  @override
  State<VizWorkbenchScreen> createState() => _VizWorkbenchScreenState();
}

class _VizWorkbenchScreenState extends State<VizWorkbenchScreen> {
  late VizRig _rig = VizCatalog.all.first;
  VizClip _clip = VizClip.breathe;
  double _speed = 1.0;
  bool _showPivots = false;

  void _selectRig(VizRig rig) {
    setState(() {
      _rig = rig;
      if (!rig.supportedClips.contains(_clip)) {
        _clip = rig.supportedClips.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viz Workbench'),
        actions: [
          IconButton(
            key: const Key('viz-pivots-toggle'),
            tooltip: 'Show pivots',
            icon: Icon(
              _showPivots
                  ? Icons.center_focus_strong
                  : Icons.center_focus_weak_outlined,
            ),
            onPressed: () => setState(() => _showPivots = !_showPivots),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: [
                // Bounded and scrollable so adding gameobjects can never
                // overflow the column as the catalog grows.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 140),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final rig in VizCatalog.all)
                          ChoiceChip(
                            key: Key('viz-subject-${rig.id}'),
                            label: Text(rig.displayName),
                            selected: rig.id == _rig.id,
                            onSelected: (_) => _selectRig(rig),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    key: const Key('viz-stage'),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xfffaf7ef),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffe3dcc9)),
                    ),
                    child: VizStage(
                      rig: _rig,
                      clip: _clip,
                      speed: _speed,
                      showPivots: _showPivots,
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final clip in VizClip.values)
                              ChoiceChip(
                                key: Key('viz-clip-${clip.name}'),
                                label: Text(clip.label),
                                selected: clip == _clip,
                                onSelected: _rig.supportedClips.contains(clip)
                                    ? (_) => setState(() => _clip = clip)
                                    : null,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Speed'),
                            Expanded(
                              child: Slider(
                                key: const Key('viz-speed-slider'),
                                min: 0.25,
                                max: 2.0,
                                divisions: 7,
                                value: _speed,
                                label: '${_speed.toStringAsFixed(2)}x',
                                onChanged: (value) =>
                                    setState(() => _speed = value),
                              ),
                            ),
                            Text('${_speed.toStringAsFixed(2)}x'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
