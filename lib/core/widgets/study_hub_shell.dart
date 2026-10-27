import 'package:flutter/material.dart';

import '../utils/haptics.dart';
import 'expressive_motion.dart';
import 'hex_background.dart';
import 'liquid_glass.dart';

@immutable
class HubDestination {
  const HubDestination(
    this.title,
    this.summary,
    this.icon, {
    this.shortLabel,
    this.keywords = '',
  });
  final String title;
  final String summary;
  final IconData icon;
  final String? shortLabel;
  final String keywords;
}

/// A quiet overview followed by a single focused, state-preserving workspace.
class StudyHubShell extends StatefulWidget {
  const StudyHubShell({
    super.key,
    required this.title,
    required this.headline,
    required this.description,
    required this.icon,
    required this.controller,
    required this.destinations,
    required this.panes,
    this.initialSection,
    this.actions = const [],
    this.onSecretSearch,
    this.onEmblemLongPress,
  });
  final String title;
  final String headline;
  final String description;
  final IconData icon;
  final TabController controller;
  final List<HubDestination> destinations;
  final List<Widget> panes;
  final int? initialSection;
  final List<Widget> actions;
  final VoidCallback? onSecretSearch;
  final VoidCallback? onEmblemLongPress;
  @override
  State<StudyHubShell> createState() => StudyHubShellState();
}

class StudyHubShellState extends State<StudyHubShell>
    with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  String _query = '';
  late bool _overview;
  late bool _started;
  late int _active;
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 1,
  );
  @override
  void initState() {
    super.initState();
    _overview = widget.initialSection == null;
    _started = !_overview;
    _active = widget.controller.index;
    widget.controller.addListener(_listen);
  }

  void _listen() {
    if (_active == widget.controller.index) {
      return;
    }
    setState(() => _active = widget.controller.index);
  }

  void openSection(int index) {
    AppHaptics.selection();
    widget.controller.index = index.clamp(0, widget.destinations.length - 1);
    setState(() {
      _started = true;
      _overview = false;
      _active = widget.controller.index;
    });
    if (!MediaQuery.disableAnimationsOf(context)) {
      _entrance.forward(from: 0);
    }
  }

  void _back() {
    if (!_overview) {
      setState(() => _overview = true);
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  void didUpdateWidget(covariant StudyHubShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_listen);
      widget.controller.addListener(_listen);
      _active = widget.controller.index;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listen);
    _search.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: _overview,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _back();
        }
      },
      child: HexBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: SpringPress(
              child: IconButton(
                tooltip: _overview ? 'Back' : 'All workspaces',
                icon: Icon(
                  _overview
                      ? Icons.arrow_back_rounded
                      : Icons.grid_view_rounded,
                ),
                onPressed: _back,
              ),
            ),
            title: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            actions: widget.actions,
          ),
          body: SafeArea(
            top: false,
            child: IndexedStack(
              index: _overview ? 0 : 1,
              children: [
                TickerMode(enabled: _overview, child: _overviewBody(context)),
                if (_started)
                  TickerMode(
                    enabled: !_overview,
                    child: Column(
                      children: [
                        LiquidGlassContainer(
                          margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          borderRadius: 26,
                          padding: const EdgeInsets.all(6),
                          blurSigma: 12,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (
                                  var i = 0;
                                  i < widget.destinations.length;
                                  i++
                                )
                                  Padding(
                                    padding: const EdgeInsets.only(right: 5),
                                    child: SpringPress(
                                      child: ChoiceChip(
                                        selected: i == _active,
                                        onSelected: (_) => openSection(i),
                                        label: Text(
                                          widget.destinations[i].shortLabel ??
                                              widget.destinations[i].title,
                                        ),
                                        avatar: Icon(
                                          widget.destinations[i].icon,
                                          size: 17,
                                        ),
                                        selectedColor: colors.primaryContainer,
                                        labelStyle: TextStyle(
                                          color: i == _active
                                              ? colors.onPrimaryContainer
                                              : colors.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.destinations[_active].summary,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ),
                        ),
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _entrance,
                            child: TabBarView(
                              controller: widget.controller,
                              children: [
                                for (var i = 0; i < widget.panes.length; i++)
                                  _RetainedHubPane(
                                    child: TickerMode(
                                      enabled: i == _active,
                                      child: widget.panes[i],
                                    ),
                                  ),
                              ],
                            ),
                            builder: (context, child) {
                              final progress =
                                  MediaQuery.disableAnimationsOf(context)
                                  ? 1.0
                                  : Curves.easeOutCubic.transform(
                                      _entrance.value,
                                    );
                              return Opacity(
                                opacity: .7 + .3 * progress,
                                child: Transform.translate(
                                  offset: Offset(0, 8 * (1 - progress)),
                                  child: child,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _overviewBody(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final matches = widget.destinations
        .asMap()
        .entries
        .where(
          (entry) =>
              ('${entry.value.title} ${entry.value.summary} ${entry.value.keywords}')
                  .toLowerCase()
                  .contains(_query.toLowerCase()),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        LiquidGlassContainer(
          borderRadius: 30,
          blurSigma: 12,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: '${widget.title} emblem',
                onLongPress: widget.onEmblemLongPress,
                child: SpringPress(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onLongPress: widget.onEmblemLongPress,
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        widget.icon,
                        color: colors.onPrimaryContainer,
                        size: 29,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                widget.headline,
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.description,
                style: text.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        TextField(
          controller: _search,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Find a workspace or concept',
            contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          ),
          onChanged: (value) {
            if (value.trim() == '42' && widget.onSecretSearch != null) {
              _search.clear();
              setState(() => _query = '');
              widget.onSecretSearch!();
            } else {
              setState(() => _query = value.trim());
            }
          },
        ),
        const SizedBox(height: 24),
        Text('Choose your workspace', style: text.titleMedium),
        const SizedBox(height: 12),
        if (matches.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No matches. Try a technique, formula or topic.',
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        for (final entry in matches)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SpringPress(
              child: LiquidGlassContainer(
                enableBlur: false,
                borderRadius: 24,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: ValueKey(entry.value.title),
                    onTap: () => openSection(entry.key),
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.secondaryContainer.withValues(
                                alpha: .65,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              entry.value.icon,
                              color: colors.onSecondaryContainer,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.value.title, style: text.titleSmall),
                                const SizedBox(height: 5),
                                Text(
                                  entry.value.summary,
                                  style: text.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: colors.primary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RetainedHubPane extends StatefulWidget {
  const _RetainedHubPane({required this.child});
  final Widget child;
  @override
  State<_RetainedHubPane> createState() => _RetainedHubPaneState();
}

class _RetainedHubPaneState extends State<_RetainedHubPane>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
