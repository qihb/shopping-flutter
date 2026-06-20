import 'package:flutter/material.dart';

import 'package:my_first_app/features/home/presentation/models/home_banner_item.dart';

/// 用纯 Flutter 组件生成横幅“素材图”。
///
/// 这样做的好处是不用额外引入图片资源，也能先把视觉结构和类型差异搭出来。
/// 后续如果你想替换成真实图片或视频封面，只需要改这里的展示方式。
class HomeBannerMediaArtwork extends StatelessWidget {
  const HomeBannerMediaArtwork({super.key, required this.item, this.isDetail = false});

  final HomeBannerItem item;
  final bool isDetail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double iconSize = isDetail ? 54 : 42;
        final double cardWidth = constraints.maxWidth;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                item.accentColor.withValues(alpha: 0.92),
                item.accentColor.withValues(alpha: 0.56),
              ],
            ),
            borderRadius: BorderRadius.circular(isDetail ? 30 : 24),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -18,
                right: -8,
                child: Container(
                  width: cardWidth * 0.42,
                  height: cardWidth * 0.42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -26,
                left: -12,
                child: Container(
                  width: cardWidth * 0.48,
                  height: cardWidth * 0.48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isDetail ? 24 : 18),
                child: item.isVideo
                    ? _VideoArtwork(item: item, iconSize: iconSize)
                    : _ImageArtwork(item: item, iconSize: iconSize),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ImageArtwork extends StatelessWidget {
  const _ImageArtwork({required this.item, required this.iconSize});

  final HomeBannerItem item;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Icon(item.artworkIcon, size: iconSize, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VideoArtwork extends StatelessWidget {
  const _VideoArtwork({required this.item, required this.iconSize});

  final HomeBannerItem item;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(item.artworkIcon, size: iconSize, color: Colors.white70),
                
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.42,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              item.durationLabel ?? '',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }
}
