import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 视频横幅详情里的播放器区域。
///
/// 这里单独抽成组件，而不是把播放器逻辑直接写进页面里，
/// 是为了把“初始化控制器、播放暂停、异常兜底”这些职责收拢到一个地方。
class HomeBannerVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final Color accentColor;
  final String title;

  const HomeBannerVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.accentColor,
    required this.title,
  });

  @override
  State<HomeBannerVideoPlayer> createState() => _HomeBannerVideoPlayerState();
}

class _HomeBannerVideoPlayerState extends State<HomeBannerVideoPlayer> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;
  bool _hasInitializationError = false;

  @override
  void initState() {
    super.initState();
    _createController();
  }

  Future<void> _createController() async {
    final VideoPlayerController controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    controller.addListener(_handleControllerUpdate);
    _controller = controller;
    _initializeFuture = _initializeController(controller);
    setState(() {});
  }

  void _handleControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeController(VideoPlayerController controller) async {
    try {
      // `initialize()` 会异步准备视频解码和元数据。
      // 准备完成前，界面先显示加载态；完成后再展示真正的视频画面。
      await controller.initialize();
      await controller.setLooping(true);
    } catch (_) {
      _hasInitializationError = true;
    }
  }

  Future<void> _togglePlayback() async {
    final VideoPlayerController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
  }

  Future<void> _seekTo(double progress) async {
    final VideoPlayerController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final int totalMilliseconds = controller.value.duration.inMilliseconds;
    final int targetMilliseconds = (totalMilliseconds * progress).round();
    await controller.seekTo(Duration(milliseconds: targetMilliseconds));
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? controller = _controller;

    return Container(
      key: const ValueKey<String>('home-banner-video-player'),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<void>(
        future: _initializeFuture,
        builder: (context, snapshot) {
          if (_hasInitializationError) {
            return _VideoFallbackState(
              title: widget.title,
              accentColor: widget.accentColor,
              message: '当前环境暂时无法加载视频，后续可在真机或模拟器中继续体验。',
            );
          }

          if (controller == null ||
              snapshot.connectionState != ConnectionState.done) {
            return _VideoLoadingState(accentColor: widget.accentColor);
          }

          if (!controller.value.isInitialized) {
            return _VideoFallbackState(
              title: widget.title,
              accentColor: widget.accentColor,
              message: '视频初始化失败，请稍后重试。',
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: HomeBannerVideoControls(
                  currentPosition: controller.value.position,
                  totalDuration: controller.value.duration,
                  isPlaying: controller.value.isPlaying,
                  onSeek: _seekTo,
                  onTogglePlayback: _togglePlayback,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 视频播放控件条。
///
/// 它负责展示播放时间、总时长和进度条。
/// 你可以把它理解成视频播放器底部那一排“信息 + 控制器”的 UI 组件。
class HomeBannerVideoControls extends StatelessWidget {
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isPlaying;
  final ValueChanged<double> onSeek;
  final VoidCallback onTogglePlayback;

  const HomeBannerVideoControls({
    super.key,
    required this.currentPosition,
    required this.totalDuration,
    required this.isPlaying,
    required this.onSeek,
    required this.onTogglePlayback,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = _calculateProgress(
      currentPosition: currentPosition,
      totalDuration: totalDuration,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  formatVideoDuration(currentPosition),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  // `Slider` 是 Flutter 里常见的滑动选择组件。
                  // 在视频场景里，它很适合承载“拖动进度条跳到某个播放位置”的交互。
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                    ),
                    child: Slider(value: progress, onChanged: onSeek),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatVideoDuration(totalDuration),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                ),
                onPressed: onTogglePlayback,
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(isPlaying ? '暂停' : '播放'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _calculateProgress({
  required Duration currentPosition,
  required Duration totalDuration,
}) {
  final int totalMilliseconds = totalDuration.inMilliseconds;
  if (totalMilliseconds <= 0) {
    return 0;
  }

  final double progress = currentPosition.inMilliseconds / totalMilliseconds;
  return progress.clamp(0, 1);
}

String formatVideoDuration(Duration duration) {
  final int totalSeconds = duration.inSeconds;
  final int minutes = totalSeconds ~/ 60;
  final int seconds = totalSeconds % 60;
  final String minuteText = minutes.toString().padLeft(2, '0');
  final String secondText = seconds.toString().padLeft(2, '0');
  return '$minuteText:$secondText';
}

class _VideoLoadingState extends StatelessWidget {
  final Color accentColor;

  const _VideoLoadingState({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.92),
            accentColor.withValues(alpha: 0.54),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 12),
            Text(
              '视频加载中...',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoFallbackState extends StatelessWidget {
  final String title;
  final Color accentColor;
  final String message;

  const _VideoFallbackState({
    required this.title,
    required this.accentColor,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxHeight < 180;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accentColor.withValues(alpha: 0.96), Colors.black87],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 16 : 24),
            // 小尺寸横幅里如果沿用详情页的完整说明文案，布局很容易溢出。
            // 这里根据可用高度切换成紧凑版，让同一个组件既能用于详情，也能用于 banner 卡片。
            child: isCompact
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      const Icon(
                        Icons.play_circle_fill_rounded,
                        size: 52,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
