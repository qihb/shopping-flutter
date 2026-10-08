import 'package:mockito/mockito.dart';

import 'package:my_first_app/features/home/data/home_recommend_mock_service.dart';
import 'mocks.mocks.dart';

/// 给 [MockHomeRecommendService] 打桩：按页返回 [HomeRecommendMockService] 的固定数据。
///
/// 首页相关测试原本通过子类把生产 mock 数据适配进 `HomeRecommendService`，
/// 迁移到 mockito 后用这个辅助函数保留“分页返回固定商品”的测试语义，
/// 免去每个用例重复书写基于 `Invocation` 的打桩代码。
void stubRecommendFromMockData(MockHomeRecommendService service) {
  const HomeRecommendMockService mockData = HomeRecommendMockService();

  when(service.fetchRecommendProducts(page: anyNamed('page'))).thenAnswer(
    (Invocation invocation) async => mockData.fetchRecommendProducts(
      page: invocation.namedArguments[#page] as int,
    ),
  );
}
