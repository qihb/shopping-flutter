import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:my_first_app/core/api/api_exception.dart';
import 'package:my_first_app/features/auth/application/auth_notifier.dart';
import 'package:my_first_app/features/auth/data/models/user_info.dart';
import 'package:my_first_app/features/profile/application/address_notifier.dart';
import 'package:my_first_app/features/profile/data/models/address_vo.dart';
import '../../../helpers/mocks.mocks.dart';
import '../../../helpers/stub_helpers.dart';

void main() {
  /// 构造未登录的登录态（本地无 token）。
  (AuthNotifier, AddressNotifier, MockAddressService) buildGuestFixture() {
    final MockAuthService authService = MockAuthService();
    final MockTokenStore tokenStore = MockTokenStore();
    when(tokenStore.readToken()).thenAnswer((_) async => null);

    final AuthNotifier authNotifier = AuthNotifier(
      authService: authService,
      tokenStore: tokenStore,
    );
    final MockAddressService addressService = MockAddressService();
    final AddressNotifier addressNotifier = AddressNotifier(
      addressService: addressService,
    )..attachAuth(authNotifier);

    return (authNotifier, addressNotifier, addressService);
  }

  /// 构造已登录的登录态（本地 token 有效），并关联地址状态。
  (AuthNotifier, AddressNotifier, MockAddressService, MockAuthService)
      buildLoggedInFixture() {
    final MockAuthService authService = MockAuthService();
    final MockTokenStore tokenStore = MockTokenStore();
    when(tokenStore.readToken()).thenAnswer((_) async => 'test-token');
    when(authService.fetchCurrentUser()).thenAnswer(
      (_) async => const UserInfo(
        id: 1,
        username: 'tester',
        nickname: '测试用户',
        phone: '13800000000',
      ),
    );

    final AuthNotifier authNotifier = AuthNotifier(
      authService: authService,
      tokenStore: tokenStore,
    );
    final MockAddressService addressService = MockAddressService();
    final AddressNotifier addressNotifier = AddressNotifier(
      addressService: addressService,
    )..attachAuth(authNotifier);

    return (authNotifier, addressNotifier, addressService, authService);
  }

  /// 让登录联动触发的异步刷新跑完（纯微任务链，让出一轮事件循环即可）。
  Future<void> flushAsync() => Future<void>.delayed(Duration.zero);

  group('登录态联动', () {
    test('未登录时不会拉取地址', () async {
      final (
        AuthNotifier authNotifier,
        AddressNotifier addressNotifier,
        MockAddressService addressService,
      ) = buildGuestFixture();

      await authNotifier.restoreSession();
      await flushAsync();

      verifyNever(addressService.fetchAddresses());
      expect(addressNotifier.addresses, isEmpty);
    });

    test('会话恢复成功后自动拉取服务端地址', () async {
      final (
        AuthNotifier authNotifier,
        AddressNotifier addressNotifier,
        MockAddressService addressService,
        MockAuthService _,
      ) = buildLoggedInFixture();
      stubAddressFetch(
        addressService,
        <AddressVO>[buildTestAddress(1, isDefault: true)],
      );

      await authNotifier.restoreSession();
      await flushAsync();

      verify(addressService.fetchAddresses()).called(1);
      expect(addressNotifier.addresses, hasLength(1));
      expect(addressNotifier.defaultAddress?.fullAddress, '上海市浦东新区张江高科');
    });

    test('登录成功后自动拉取服务端地址', () async {
      final (
        AuthNotifier authNotifier,
        AddressNotifier addressNotifier,
        MockAddressService addressService,
        MockAuthService authService,
      ) = buildLoggedInFixture();
      stubAddressFetch(
        addressService,
        <AddressVO>[buildTestAddress(1, isDefault: true)],
      );
      when(authService.login(
        username: anyNamed('username'),
        password: anyNamed('password'),
      )).thenAnswer(
        (_) async => const LoginResult(
          token: 'token-1',
          user: UserInfo(
            id: 1,
            username: 'tester',
            nickname: '测试用户',
            phone: '',
          ),
        ),
      );

      final bool didLogin =
          await authNotifier.login(username: 'tester', password: '123456');
      await flushAsync();

      expect(didLogin, isTrue);
      verify(addressService.fetchAddresses()).called(1);
      expect(addressNotifier.addresses, hasLength(1));
    });

    test('退出登录后清空本地地址数据', () async {
      final (
        AuthNotifier authNotifier,
        AddressNotifier addressNotifier,
        MockAddressService addressService,
        MockAuthService authService,
      ) = buildLoggedInFixture();
      stubAddressFetch(
        addressService,
        <AddressVO>[buildTestAddress(1, isDefault: true)],
      );
      when(authService.logout()).thenAnswer((_) async {});

      await authNotifier.restoreSession();
      await flushAsync();
      expect(addressNotifier.addresses, hasLength(1));

      await authNotifier.logout();
      await flushAsync();

      expect(addressNotifier.addresses, isEmpty);
      expect(addressNotifier.defaultAddress, isNull);
    });
  });

  group('读取与错误处理', () {
    test('未登录时 refresh 不发请求', () async {
      final (
        AuthNotifier _,
        AddressNotifier addressNotifier,
        MockAddressService addressService,
      ) = buildGuestFixture();

      await addressNotifier.refresh();

      verifyNever(addressService.fetchAddresses());
      expect(addressNotifier.addresses, isEmpty);
    });

    test('刷新成功后地址列表来自服务端', () async {
      final MockAddressService addressService = MockAddressService();
      final AddressNotifier addressNotifier = AddressNotifier(
        addressService: addressService,
      );
      stubAddressFetch(
        addressService,
        <AddressVO>[
          buildTestAddress(1, isDefault: true),
          buildTestAddress(
            2,
            district: '徐汇区',
            detailAddress: '漕河泾开发区',
          ),
        ],
      );

      await addressNotifier.refresh();

      expect(addressNotifier.isLoading, isFalse);
      expect(addressNotifier.errorMessage, isNull);
      expect(addressNotifier.addresses, hasLength(2));
      expect(addressNotifier.defaultAddress?.id, 1);
    });

    test('刷新失败时记录错误信息并结束加载态', () async {
      final MockAddressService addressService = MockAddressService();
      final AddressNotifier addressNotifier = AddressNotifier(
        addressService: addressService,
      );
      when(addressService.fetchAddresses())
          .thenThrow(ApiException(message: '登录已过期'));

      await addressNotifier.refresh();

      expect(addressNotifier.errorMessage, '登录已过期');
      expect(addressNotifier.isLoading, isFalse);
    });
  });

  group('变更操作', () {
    test('新增地址成功后调用服务端并静默刷新', () async {
      final MockAddressService addressService = MockAddressService();
      final AddressNotifier addressNotifier = AddressNotifier(
        addressService: addressService,
      );
      stubAddressMutationsSuccess(addressService);
      stubAddressFetch(
        addressService,
        <AddressVO>[buildTestAddress(1, isDefault: true)],
      );

      final bool didSucceed = await addressNotifier.addAddress(
        receiverName: '测试收货人',
        receiverPhone: '13900005678',
        province: '江苏省',
        city: '苏州市',
        district: '工业园区',
        detailAddress: '金鸡湖大道',
      );

      expect(didSucceed, isTrue);
      verify(addressService.addAddress(
        receiverName: '测试收货人',
        receiverPhone: '13900005678',
        province: '江苏省',
        city: '苏州市',
        district: '工业园区',
        detailAddress: '金鸡湖大道',
        isDefault: false,
      )).called(1);
      verify(addressService.fetchAddresses()).called(1);
      expect(addressNotifier.addresses, hasLength(1));
    });

    test('新增失败时返回 false 并记录错误信息', () async {
      final MockAddressService addressService = MockAddressService();
      final AddressNotifier addressNotifier = AddressNotifier(
        addressService: addressService,
      );
      when(addressService.addAddress(
        receiverName: anyNamed('receiverName'),
        receiverPhone: anyNamed('receiverPhone'),
        province: anyNamed('province'),
        city: anyNamed('city'),
        district: anyNamed('district'),
        detailAddress: anyNamed('detailAddress'),
        isDefault: anyNamed('isDefault'),
      )).thenThrow(ApiException(message: '收货手机号格式不正确'));

      final bool didSucceed = await addressNotifier.addAddress(
        receiverName: '测试收货人',
        receiverPhone: '123',
        province: '江苏省',
        city: '苏州市',
        district: '工业园区',
        detailAddress: '金鸡湖大道',
      );

      expect(didSucceed, isFalse);
      expect(addressNotifier.errorMessage, '收货手机号格式不正确');
      expect(addressNotifier.addresses, isEmpty);
    });

    test('修改 / 删除 / 设默认分别调用对应接口并静默刷新', () async {
      final MockAddressService addressService = MockAddressService();
      final AddressNotifier addressNotifier = AddressNotifier(
        addressService: addressService,
      );
      stubAddressMutationsSuccess(addressService);
      stubAddressFetch(
        addressService,
        <AddressVO>[buildTestAddress(1, isDefault: true)],
      );

      final bool didUpdate = await addressNotifier.updateAddress(
        id: 1,
        receiverName: '测试收货人',
        receiverPhone: '13900005678',
        province: '江苏省',
        city: '苏州市',
        district: '工业园区',
        detailAddress: '金鸡湖大道',
      );
      expect(didUpdate, isTrue);
      verify(addressService.updateAddress(
        id: 1,
        receiverName: '测试收货人',
        receiverPhone: '13900005678',
        province: '江苏省',
        city: '苏州市',
        district: '工业园区',
        detailAddress: '金鸡湖大道',
        isDefault: false,
      )).called(1);

      final bool didDelete = await addressNotifier.deleteAddress(1);
      expect(didDelete, isTrue);
      verify(addressService.deleteAddress(1)).called(1);

      final bool didSetDefault = await addressNotifier.setDefaultAddress(2);
      expect(didSetDefault, isTrue);
      verify(addressService.setDefaultAddress(2)).called(1);

      // 变更后的静默刷新不展示加载态，但列表都会重新拉取。
      verify(addressService.fetchAddresses()).called(3);
    });
  });

  group('defaultAddress', () {
    test('没有地址时为 null', () {
      final MockAddressService addressService = MockAddressService();
      final AddressNotifier addressNotifier = AddressNotifier(
        addressService: addressService,
      );

      expect(addressNotifier.defaultAddress, isNull);
    });

    test('没有 isDefault 标记时回退第一条', () async {
      final MockAddressService addressService = MockAddressService();
      final AddressNotifier addressNotifier = AddressNotifier(
        addressService: addressService,
      );
      stubAddressFetch(
        addressService,
        <AddressVO>[
          buildTestAddress(1),
          buildTestAddress(2),
        ],
      );

      await addressNotifier.refresh();

      expect(addressNotifier.defaultAddress?.id, 1);
    });

    test('优先返回 isDefault 的地址', () async {
      final MockAddressService addressService = MockAddressService();
      final AddressNotifier addressNotifier = AddressNotifier(
        addressService: addressService,
      );
      stubAddressFetch(
        addressService,
        <AddressVO>[
          buildTestAddress(1),
          buildTestAddress(2, isDefault: true),
        ],
      );

      await addressNotifier.refresh();

      expect(addressNotifier.defaultAddress?.id, 2);
    });
  });
}
