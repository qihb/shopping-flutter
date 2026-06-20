import 'dart:async';

import 'package:flutter/material.dart';

import 'package:my_first_app/features/home/presentation/models/home_banner_item.dart';
import 'package:my_first_app/features/home/presentation/pages/home_banner_detail_page.dart';
import 'package:my_first_app/features/home/presentation/widgets/home_banner_media_artwork.dart';
import 'package:my_first_app/features/home/presentation/widgets/home_banner_video_player.dart';

/// 首页焦点横幅轮播。
///
/// 这里改成 `StatefulWidget`，是因为当前页索引和自动轮播计时器都会变化。
/// 你可以把它理解成“横幅区自己维护一小块交互状态”。
class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key, this.onItemTap});

  final ValueChanged<HomeBannerItem>? onItemTap;

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  static const List<HomeBannerItem> _items = [
    HomeBannerItem(
      title: '露营装备开箱',
      subtitle: '视频短片',
      description: '用动态内容位模拟活动短视频入口，适合放新品介绍或种草内容。',
      tag: '短视频',
      buttonLabel: '查看详情',
      mediaType: HomeBannerMediaType.video,
      accentColor: Color(0xFF4DB6AC),
      backgroundColor: Color(0xFFE8F7F5),
      artworkIcon: Icons.forest_outlined,
      mediaUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      durationLabel: '01:28',
    ),
    HomeBannerItem(
      title: '城市夏日穿搭',
      subtitle: '图片专题',
      description: '用清爽配色和通勤单品，模拟首页主视觉图片素材。',
      tag: '今日主推',
      buttonLabel: '查看详情',
      mediaType: HomeBannerMediaType.image,
      accentColor: Color(0xFFFF8A65),
      backgroundColor: Color(0xFFFFF1EA),
      artworkIcon: Icons.wb_sunny_outlined,
    ),
    HomeBannerItem(
      title: '轻旅收纳指南',
      subtitle: '图片专题',
      description: '把箱包和收纳主题做成第二张图片横幅，丰富首页轮播节奏。',
      tag: '搭配灵感',
      buttonLabel: '查看详情',
      mediaType: HomeBannerMediaType.image,
      accentColor: Color(0xFF7986CB),
      backgroundColor: Color(0xFFEEF0FF),
      artworkIcon: Icons.luggage_outlined,
    ),
    HomeBannerItem(
      title: '夜跑鞋科技解析',
      subtitle: '视频短片',
      description: '第二条视频内容位可以承接卖点讲解、达人测评或活动宣传。',
      tag: '热播中',
      buttonLabel: '查看详情',
      mediaType: HomeBannerMediaType.video,
      accentColor: Color(0xFFBA68C8),
      backgroundColor: Color(0xFFF8EEFB),
      artworkIcon: Icons.directions_run_outlined,
      mediaUrl: 'https://samplelib.com/lib/preview/mp4/sample-10s.mp4',
      durationLabel: '02:06',
    ),
  ];

  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients || _items.length <= 1) {
        return;
      }

      final int nextIndex = (_currentIndex + 1) % _items.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _openDetail(BuildContext context, HomeBannerItem item) {
    if (widget.onItemTap != null) {
      widget.onItemTap!(item);
      return;
    }

    // `Navigator.push` 可以理解成“把一个新页面压到页面栈顶”。
    // 这和前端里点击卡片后进入详情路由是类似的体验。
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HomeBannerDetailPage(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '轮播推荐',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          '精选 2 张图片和 2 条视频素材，模拟电商首页焦点内容位',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 360,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _items.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final HomeBannerItem item = _items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _HomeBannerCard(
                  item: item,
                  onTap: () => _openDetail(context, item),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(_items.length, (index) {
            final bool isActive = index == _currentIndex;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: 8),
              width: isActive ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _HomeBannerCard extends StatelessWidget {
  const _HomeBannerCard({required this.item, required this.onTap});

  final HomeBannerItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.backgroundColor,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey<String>('home-banner-card-${item.title}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _MediaTypeChip(item: item),
                  const SizedBox(width: 8),
                  _TagChip(
                    label: item.tag,
                    backgroundColor: item.accentColor.withValues(alpha: 0.12),
                    foregroundColor: item.accentColor,
                  ),
                  if (item.durationLabel != null) ...[
                    const Spacer(),
                    _TagChip(
                      label: item.durationLabel!,
                      backgroundColor: Colors.black.withValues(alpha: 0.12),
                      foregroundColor: Colors.black87,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: item.isVideo && item.mediaUrl != null
                    // 视频素材在 banner 里直接复用播放器，这样首页卡片就能立即展示真实视频内容。
                    ? HomeBannerVideoPlayer(
                        videoUrl: item.mediaUrl!,
                        accentColor: item.accentColor,
                        title: item.title,
                      )
                    : HomeBannerMediaArtwork(item: item),
              ),
              const SizedBox(height: 18),
              Text(
                item.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                key: ValueKey<String>('home-banner-action-${item.title}'),
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(item.buttonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaTypeChip extends StatelessWidget {
  const _MediaTypeChip({required this.item});

  final HomeBannerItem item;

  @override
  Widget build(BuildContext context) {
    return _TagChip(
      label: item.mediaTypeLabel,
      backgroundColor: Colors.white.withValues(alpha: 0.22),
      foregroundColor: Colors.black87,
      icon: item.isVideo ? Icons.videocam_outlined : Icons.image_outlined,
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: foregroundColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
