// 这是一个基础的 Flutter Widget 测试文件。
//
// `WidgetTester` 可以帮助你在测试环境里渲染组件、查找节点、
// 模拟点击和滚动，并验证页面上最终显示的内容是否符合预期。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/app/app.dart';
import 'package:my_first_app/features/home/presentation/models/home_banner_item.dart';
import 'package:my_first_app/features/home/presentation/pages/home_banner_detail_page.dart';
import 'package:my_first_app/features/home/presentation/widgets/home_banner_carousel.dart';
import 'package:my_first_app/features/home/presentation/widgets/home_banner_video_player.dart';

void main() {
  testWidgets('应用启动后显示 4 个底部导航菜单并默认停留在首页', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('首页'), findsOneWidget);
    expect(find.text('分类'), findsOneWidget);
    expect(find.text('购物车'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(find.text('搜一搜你感兴趣的商品'), findsOneWidget);
    expect(find.text('轮播推荐'), findsOneWidget);
    expect(find.text('精选 2 张图片和 2 条视频素材，模拟电商首页焦点内容位'), findsOneWidget);
    expect(find.text('露营装备开箱'), findsOneWidget);
    await tester.fling(find.byType(Scrollable).first, const Offset(0, -800), 1000);
    await tester.pumpAndSettle();
    expect(find.text('为你推荐'), findsOneWidget);
    expect(find.text('夏季轻运动鞋'), findsOneWidget);
    expect(find.text('极简双肩包'), findsOneWidget);
  });

  testWidgets('点击底部导航后可以切换到对应占位页面', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('分类'));
    await tester.pumpAndSettle();
    expect(find.text('分类内容建设中'), findsOneWidget);

    await tester.tap(find.text('购物车'));
    await tester.pumpAndSettle();
    expect(find.text('购物车内容建设中'), findsOneWidget);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.text('我的内容建设中'), findsOneWidget);
  });

  testWidgets('首页轮播横幅点击视频卡片时会回传对应素材', (WidgetTester tester) async {
    HomeBannerItem? tappedItem;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeBannerCarousel(
            onItemTap: (item) {
              tappedItem = item;
            },
          ),
        ),
      ),
    );

    expect(find.text('露营装备开箱'), findsOneWidget);
    expect(find.text('视频'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey<String>('home-banner-card-露营装备开箱')),
    );
    await tester.pump();

    expect(tappedItem, isNotNull);
    expect(tappedItem!.title, '露营装备开箱');
    expect(tappedItem!.mediaType, HomeBannerMediaType.video);
  });

  testWidgets('首页轮播里的视频素材会直接渲染视频播放器', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeBannerCarousel(),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('home-banner-video-player')),
      findsOneWidget,
    );
  });

  testWidgets('视频播放器在横幅卡片的小空间降级态里不会溢出', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 136,
            width: 400,
            child: HomeBannerVideoPlayer(
              videoUrl: 'https://samplelib.com/lib/preview/mp4/sample-10s.mp4',
              accentColor: Color(0xFF4DB6AC),
              title: '露营装备开箱',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('视频横幅详情页会显示视频内容说明和购买按钮', (WidgetTester tester) async {
    const HomeBannerItem item = HomeBannerItem(
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
    );

    await tester.pumpWidget(MaterialApp(home: HomeBannerDetailPage(item: item)));

    expect(find.text('露营装备开箱'), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('home-banner-video-player')),
      findsOneWidget,
    );
    await tester.fling(find.byType(Scrollable).first, const Offset(0, -500), 1000);
    await tester.pumpAndSettle();
    expect(find.text('视频内容'), findsOneWidget);
    expect(find.text('立即购买同款'), findsOneWidget);
  });

  testWidgets('视频控件区会显示播放时间和进度条', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeBannerVideoControls(
            currentPosition: const Duration(seconds: 12),
            totalDuration: const Duration(minutes: 1, seconds: 28),
            isPlaying: false,
            onSeek: (_) {},
            onTogglePlayback: () {},
          ),
        ),
      ),
    );

    expect(find.text('00:12'), findsOneWidget);
    expect(find.text('01:28'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('播放'), findsOneWidget);
  });
}
