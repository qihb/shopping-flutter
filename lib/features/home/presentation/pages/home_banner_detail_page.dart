import 'package:flutter/material.dart';

import 'package:my_first_app/features/home/presentation/models/home_banner_item.dart';
import 'package:my_first_app/features/home/presentation/widgets/home_banner_media_artwork.dart';
import 'package:my_first_app/features/home/presentation/widgets/home_banner_video_player.dart';

/// 首页横幅详情页。
///
/// 这里先用一个独立页面承接轮播卡片点击后的去向，
/// 方便后续继续扩展成活动页、专题页或商品聚合页。
class HomeBannerDetailPage extends StatelessWidget {
  const HomeBannerDetailPage({super.key, required this.item});

  final HomeBannerItem item;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: item.isVideo && item.mediaUrl != null
                ? HomeBannerVideoPlayer(
                    videoUrl: item.mediaUrl!,
                    accentColor: item.accentColor,
                    title: item.title,
                  )
                : HomeBannerMediaArtwork(item: item, isDetail: true),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DetailChip(label: item.mediaTypeLabel),
              _DetailChip(label: item.subtitle),
              if (item.durationLabel != null) _DetailChip(label: item.durationLabel!),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item.title,
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            item.description,
            style: textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 20),
          Text(
            item.isVideo ? '视频内容' : '图片内容',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            item.isVideo
                ? '这里已经接入真实视频播放组件，适合继续学习初始化控制器、播放暂停和异常兜底这些 Flutter 视频能力。'
                : '这里先用生成的图片海报模拟专题详情页，后续可以继续补商品瀑布流、活动规则和更多素材。',
            style: textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {},
            child: const Text('立即购买同款'),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}
