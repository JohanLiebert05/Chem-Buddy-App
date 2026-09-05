import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/haptics.dart';
import 'molecule_3d_models.dart';
import 'molecule_3d_painter.dart';

/// Interactive 3D Molecular Viewer with rotation, pinch-to-zoom, auto-spin,
/// CPK space-filling toggle, and atom inspection.
class Molecule3DViewer extends StatefulWidget {
  final Molecule3D molecule;
  final double height;
  final bool autoRotateInitial;
  final String? subtitle;

  const Molecule3DViewer({
    super.key,
    required this.molecule,
    this.height = 340,
    this.autoRotateInitial = false,
    this.subtitle,
  });

  @override
  State<Molecule3DViewer> createState() => _Molecule3DViewerState();
}

class _Molecule3DViewerState extends State<Molecule3DViewer>
    with SingleTickerProviderStateMixin {
  late Molecule3D _centeredMolecule;
  double _yaw = 0.45;
  double _pitch = 0.25;
  double _zoom = 1.0;
  double _baseZoom = 1.0;

  bool _isAutoRotating = false;
  late final AnimationController _autoRotateController;

  MoleculeRenderMode _renderMode = MoleculeRenderMode.ballAndStick;
  bool _showLabels = true;
  int? _selectedAtomIndex;

  @override
  void initState() {
    super.initState();
    _centeredMolecule = widget.molecule.centered();
    _isAutoRotating = widget.autoRotateInitial;

    _autoRotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..addListener(() {
        if (_isAutoRotating && mounted) {
          setState(() {
            _yaw = (_yaw + 0.0075) % (2 * math.pi);
          });
        }
      });

    if (_isAutoRotating) {
      _autoRotateController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant Molecule3DViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.molecule.id != widget.molecule.id) {
      setState(() {
        _centeredMolecule = widget.molecule.centered();
        _selectedAtomIndex = null;
      });
    }
  }

  @override
  void dispose() {
    _autoRotateController.dispose();
    super.dispose();
  }

  void _resetView() {
    AppHaptics.selection();
    setState(() {
      _yaw = 0.45;
      _pitch = 0.25;
      _zoom = 1.0;
      _selectedAtomIndex = null;
    });
  }

  void _toggleAutoRotate() {
    AppHaptics.selection();
    setState(() {
      _isAutoRotating = !_isAutoRotating;
      if (_isAutoRotating) {
        _autoRotateController.repeat();
      } else {
        _autoRotateController.stop();
      }
    });
  }

  void _toggleRenderMode() {
    AppHaptics.selection();
    setState(() {
      _renderMode = _renderMode == MoleculeRenderMode.ballAndStick
          ? MoleculeRenderMode.spaceFilling
          : MoleculeRenderMode.ballAndStick;
    });
  }

  void _toggleLabels() {
    AppHaptics.selection();
    setState(() {
      _showLabels = !_showLabels;
    });
  }

  void _handleTap(TapUpDetails details, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxR = math.max(_centeredMolecule.maxRadius, 1.0);
    final baseScale = (math.min(size.width, size.height) * 0.36 / maxR) * _zoom;
    const cameraDistance = 14.0;

    final cosY = math.cos(_yaw);
    final sinY = math.sin(_yaw);
    final cosP = math.cos(_pitch);
    final sinP = math.sin(_pitch);

    int? closestIndex;
    double minDistance = 28.0; // Hit threshold in pixels

    for (int i = 0; i < _centeredMolecule.atoms.length; i++) {
      final a = _centeredMolecule.atoms[i];
      final x1 = a.x * cosY + a.z * sinY;
      final z1 = -a.x * sinY + a.z * cosY;
      final y2 = a.y * cosP - z1 * sinP;
      final z2 = a.y * sinP + z1 * cosP;
      final factor = cameraDistance / (cameraDistance + z2);
      final sx = centerX + x1 * baseScale * factor;
      final sy = centerY + y2 * baseScale * factor;

      final dist = math.sqrt(
        math.pow(details.localPosition.dx - sx, 2) +
            math.pow(details.localPosition.dy - sy, 2),
      );

      if (dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }

    if (closestIndex != null) {
      AppHaptics.selection();
      setState(() {
        _selectedAtomIndex = (_selectedAtomIndex == closestIndex) ? null : closestIndex;
      });
    } else if (_selectedAtomIndex != null) {
      setState(() {
        _selectedAtomIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedAtom = (_selectedAtomIndex != null &&
            _selectedAtomIndex! < _centeredMolecule.atoms.length)
        ? _centeredMolecule.atoms[_selectedAtomIndex!]
        : null;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0B1E), // Deep space laboratory dark background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Subtle radial grid background
          Positioned.fill(
            child: CustomPaint(
              painter: _LabGridPainter(),
            ),
          ),

          // 3D Canvas with gesture detector
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  onTapUp: (details) => _handleTap(details, size),
                  onScaleStart: (_) {
                    _baseZoom = _zoom;
                    if (_isAutoRotating) {
                      _autoRotateController.stop();
                    }
                  },
                  onScaleUpdate: (details) {
                    setState(() {
                      if (details.pointerCount == 1) {
                        // Rotation drag
                        _yaw += details.focalPointDelta.dx * 0.012;
                        _pitch -= details.focalPointDelta.dy * 0.012;
                        _pitch = _pitch.clamp(-math.pi / 2.2, math.pi / 2.2);
                      } else if (details.pointerCount > 1) {
                        // Pinch to zoom
                        _zoom = (_baseZoom * details.scale).clamp(0.65, 2.5);
                      }
                    });
                  },
                  onScaleEnd: (_) {
                    if (_isAutoRotating) {
                      _autoRotateController.repeat();
                    }
                  },
                  child: CustomPaint(
                    size: size,
                    painter: Molecule3DPainter(
                      molecule: _centeredMolecule,
                      yaw: _yaw,
                      pitch: _pitch,
                      zoom: _zoom,
                      renderMode: _renderMode,
                      selectedAtomIndex: _selectedAtomIndex,
                      showLabels: _showLabels,
                      primaryColor: AppColors.purpleBright,
                    ),
                  ),
                );
              },
            ),
          ),

          // Header: Molecule Name & Formula
          Positioned(
            top: 12,
            left: 14,
            right: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _centeredMolecule.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.purple.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.purpleBright.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              _centeredMolecule.formula,
                              style: const TextStyle(
                                color: AppColors.accentCyan,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.85),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Hint badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_outlined, size: 12, color: AppColors.accentCyan),
                      SizedBox(width: 4),
                      Text(
                        'Drag to rotate',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating Control Toolbar (Bottom-Right)
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1638).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.4)),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Auto-Rotate Toggle
                  _buildToolButton(
                    icon: Icons.sync_rounded,
                    isActive: _isAutoRotating,
                    tooltip: 'Auto-Rotate',
                    onTap: _toggleAutoRotate,
                  ),
                  const SizedBox(width: 4),

                  // Ball & Stick vs Space-Filling
                  _buildToolButton(
                    icon: _renderMode == MoleculeRenderMode.ballAndStick
                        ? Icons.bubble_chart_outlined
                        : Icons.scatter_plot_rounded,
                    isActive: _renderMode == MoleculeRenderMode.spaceFilling,
                    tooltip: _renderMode == MoleculeRenderMode.ballAndStick
                        ? 'Switch to Space-Filling (CPK)'
                        : 'Switch to Ball & Stick',
                    onTap: _toggleRenderMode,
                  ),
                  const SizedBox(width: 4),

                  // Toggle Labels
                  _buildToolButton(
                    icon: Icons.text_fields_rounded,
                    isActive: _showLabels,
                    tooltip: 'Toggle Element Labels',
                    onTap: _toggleLabels,
                  ),
                  const SizedBox(width: 4),

                  // Reset Camera
                  _buildToolButton(
                    icon: Icons.center_focus_strong_rounded,
                    isActive: false,
                    tooltip: 'Reset Perspective',
                    onTap: _resetView,
                  ),
                ],
              ),
            ),
          ),

          // Selected Atom Inspector Pill (Bottom-Left)
          if (selectedAtom != null)
            Positioned(
              bottom: 12,
              left: 12,
              right: 170, // Leave room for control buttons
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1638).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.6)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 8),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: selectedAtom.cpkColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${selectedAtom.symbol} atom',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11.5,
                                ),
                              ),
                              if (selectedAtom.hybridization != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  selectedAtom.hybridization!,
                                  style: const TextStyle(
                                    color: AppColors.accentCyan,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (selectedAtom.note != null) ...[
                            const SizedBox(height: 1),
                            Text(
                              selectedAtom.note!,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _selectedAtomIndex = null),
                      child: const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Icon(Icons.close, size: 14, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required bool isActive,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColors.purple : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Subtle grid pattern for lab aesthetic
class _LabGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 1.0;

    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
