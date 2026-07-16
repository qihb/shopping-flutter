import 'package:flutter/material.dart';

/// 横幅素材的类型。
///
/// 这里先区分“图片”和“视频”两种内容，
/// 方便轮播图和详情页根据类型显示不同的视觉提示。
enum HomeBannerMediaType { image, video }

/// 首页轮播横幅的数据模型。
///
/// 目前这些数据还是静态假数据，所以直接用一个轻量类描述 UI 所需字段即可。
/// 等后续接接口时，再把它替换成从服务端返回的数据结构也很自然。
class HomeBannerItem {
  final String title;
  final String subtitle;
  final String description;
  final String tag;
  final String buttonLabel;
  final HomeBannerMediaType mediaType;
  final Color accentColor;
  final Color backgroundColor;
  final IconData artworkIcon;
  final String? mediaUrl;
  final String? durationLabel;

  const HomeBannerItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.tag,
    required this.buttonLabel,
    required this.mediaType,
    required this.accentColor,
    required this.backgroundColor,
    required this.artworkIcon,
    this.mediaUrl,
    this.durationLabel,
  });

  bool get isVideo => mediaType == HomeBannerMediaType.video;

  String get mediaTypeLabel => isVideo ? '视频' : '图片';
}
