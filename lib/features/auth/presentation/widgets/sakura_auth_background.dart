import 'package:flutter/material.dart';

/// Variant presets adapting the Sakura artwork density and clean-white safe
/// zone to each authentication screen's layout density.
enum SakuraAuthBackgroundVariant {
  /// Spacious login layout: fuller top Sakura branch and bottom Seigaiha waves.
  login,

  /// Taller registration layout: softer top-left density, broader clean-white
  /// form zone over 4 inputs + terms, and compact bottom wave framing.
  register,

  /// Balanced framing for verification, recovery, and secondary auth routes.
  standard,
}

/// Shared three-zone Sakura Premium background for RikiPath authentication.
///
/// Renders non-interactive floral and Japanese Seigaiha wave artwork behind
/// forms while preserving a crisp white center zone (`#FFFFFF` / `#FFFCFC`)
/// for high legibility across all viewport sizes and keyboard states.
class SakuraAuthBackground extends StatelessWidget {
  const SakuraAuthBackground({
    this.variant = SakuraAuthBackgroundVariant.standard,
    this.topArtworkAlignment,
    this.bottomArtworkAlignment,
    this.topArtworkOpacity,
    this.bottomArtworkOpacity,
    super.key,
  });

  static const assetPath = 'assets/images/auth/auth_sakura_background.webp';

  final SakuraAuthBackgroundVariant variant;
  final AlignmentGeometry? topArtworkAlignment;
  final AlignmentGeometry? bottomArtworkAlignment;
  final double? topArtworkOpacity;
  final double? bottomArtworkOpacity;

  _VariantConfig get _config => switch (variant) {
    SakuraAuthBackgroundVariant.login => const _VariantConfig(
      topAlignment: Alignment.topCenter,
      bottomAlignment: Alignment.bottomCenter,
      topOpacity: 0.94,
      bottomOpacity: 0.90,
      scrimStops: <double>[0.0, 0.21, 0.48, 0.77, 1.0],
      scrimColors: <Color>[
        Color(0x14FFFCFC),
        Color(0xF5FFFFFF),
        Color(0xFFFFFFFF),
        Color(0xF7FFFFFF),
        Color(0xFFFFFFFF),
      ],
      topLeftHaloCenter: Alignment(-0.56, -0.76),
      topLeftHaloRadius: 0.62,
      topLeftHaloOpacity: 0.56,
      bottomHeightFraction: 0.28,
      bottomMinHeight: 168,
      bottomMaxHeight: 248,
      bottomCenterWashOpacity: 0.66,
    ),
    SakuraAuthBackgroundVariant.register => const _VariantConfig(
      topAlignment: Alignment.topCenter,
      bottomAlignment: Alignment.bottomCenter,
      topOpacity: 0.72,
      bottomOpacity: 0.72,
      scrimStops: <double>[0.0, 0.145, 0.48, 0.86, 1.0],
      scrimColors: <Color>[
        Color(0x2EFFFCFC),
        Color(0xFAFFFFFF),
        Color(0xFFFFFFFF),
        Color(0xFAFFFFFF),
        Color(0xFFFFFFFF),
      ],
      topLeftHaloCenter: Alignment(-0.50, -0.82),
      topLeftHaloRadius: 0.78,
      topLeftHaloOpacity: 0.76,
      bottomHeightFraction: 0.21,
      bottomMinHeight: 132,
      bottomMaxHeight: 184,
      bottomCenterWashOpacity: 0.78,
    ),
    SakuraAuthBackgroundVariant.standard => const _VariantConfig(
      topAlignment: Alignment.topCenter,
      bottomAlignment: Alignment.bottomCenter,
      topOpacity: 0.85,
      bottomOpacity: 0.82,
      scrimStops: <double>[0.0, 0.18, 0.48, 0.80, 1.0],
      scrimColors: <Color>[
        Color(0x20FFFCFC),
        Color(0xF7FFFFFF),
        Color(0xFFFFFFFF),
        Color(0xF7FFFFFF),
        Color(0xFFFFFFFF),
      ],
      topLeftHaloCenter: Alignment(-0.52, -0.78),
      topLeftHaloRadius: 0.66,
      topLeftHaloOpacity: 0.64,
      bottomHeightFraction: 0.24,
      bottomMinHeight: 148,
      bottomMaxHeight: 214,
      bottomCenterWashOpacity: 0.70,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _config;
    final resolvedTopAlignment = topArtworkAlignment ?? cfg.topAlignment;
    final resolvedBottomAlignment =
        bottomArtworkAlignment ?? cfg.bottomAlignment;
    final resolvedTopOpacity = (topArtworkOpacity ?? cfg.topOpacity).clamp(
      0.0,
      1.0,
    );
    final resolvedBottomOpacity = (bottomArtworkOpacity ?? cfg.bottomOpacity)
        .clamp(0.0, 1.0);

    return RepaintBoundary(
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bottomBandHeight =
                  (constraints.maxHeight * cfg.bottomHeightFraction).clamp(
                    cfg.bottomMinHeight,
                    cfg.bottomMaxHeight,
                  );

              return Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Color(0xFFFFFCFC)),
                  // Zone A: Top Sakura branch, petals, sun & pagoda framing.
                  Image.asset(
                    assetPath,
                    key: const ValueKey<String>('auth_sakura_background'),
                    fit: BoxFit.cover,
                    alignment: resolvedTopAlignment,
                    opacity: AlwaysStoppedAnimation<double>(resolvedTopOpacity),
                    filterQuality: FilterQuality.medium,
                  ),
                  // Soft localized cream breathing glow behind the enlarged
                  // top-left brand lockup so twigs never collide with letters.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: cfg.topLeftHaloCenter,
                        radius: cfg.topLeftHaloRadius,
                        colors: <Color>[
                          Color(0xFFFFFCFC).withValues(
                            alpha: cfg.topLeftHaloOpacity,
                          ),
                          Color(0xFFFFFCFC).withValues(
                            alpha: cfg.topLeftHaloOpacity * 0.45,
                          ),
                          const Color(0x00FFFCFC),
                        ],
                        stops: const <double>[0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                  // Zone B: Crisp clean-white center protecting headings, inputs,
                  // checkboxes, and CTAs across Login & Register.
                  DecoratedBox(
                    key: const ValueKey<String>('auth_sakura_scrim'),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: cfg.scrimStops,
                        colors: cfg.scrimColors,
                      ),
                    ),
                  ),
                  // Zone C: Dedicated bottom Japanese Seigaiha wave & Sakura
                  // framing anchored independently so all viewports keep it visible.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: bottomBandHeight,
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: <double>[0.0, 0.36, 0.72, 1.0],
                        colors: <Color>[
                          Colors.transparent,
                          Color(0xAAFFFFFF),
                          Colors.white,
                          Colors.white,
                        ],
                      ).createShader(bounds),
                      child: Image.asset(
                        assetPath,
                        key: const ValueKey<String>(
                          'auth_sakura_bottom_artwork',
                        ),
                        fit: BoxFit.cover,
                        alignment: resolvedBottomAlignment,
                        opacity: AlwaysStoppedAnimation<double>(
                          resolvedBottomOpacity,
                        ),
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                  // Soft center-bottom legibility pillow behind footer links &
                  // security notice while keeping outer waves and corners rich.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: bottomBandHeight * 0.85,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, 0.25),
                          radius: 0.82,
                          colors: <Color>[
                            Color(0xFFFFFCFC).withValues(
                              alpha: cfg.bottomCenterWashOpacity,
                            ),
                            Color(0xFFFFFCFC).withValues(
                              alpha: cfg.bottomCenterWashOpacity * 0.42,
                            ),
                            const Color(0x00FFFCFC),
                          ],
                          stops: const <double>[0.0, 0.52, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _VariantConfig {
  const _VariantConfig({
    required this.topAlignment,
    required this.bottomAlignment,
    required this.topOpacity,
    required this.bottomOpacity,
    required this.scrimStops,
    required this.scrimColors,
    required this.topLeftHaloCenter,
    required this.topLeftHaloRadius,
    required this.topLeftHaloOpacity,
    required this.bottomHeightFraction,
    required this.bottomMinHeight,
    required this.bottomMaxHeight,
    required this.bottomCenterWashOpacity,
  });

  final AlignmentGeometry topAlignment;
  final AlignmentGeometry bottomAlignment;
  final double topOpacity;
  final double bottomOpacity;
  final List<double> scrimStops;
  final List<Color> scrimColors;
  final Alignment topLeftHaloCenter;
  final double topLeftHaloRadius;
  final double topLeftHaloOpacity;
  final double bottomHeightFraction;
  final double bottomMinHeight;
  final double bottomMaxHeight;
  final double bottomCenterWashOpacity;
}
