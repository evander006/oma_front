import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oma/core/network/api_config.dart';
import 'package:oma/core/network/dio_client.dart';
import 'package:oma/core/repositories/ai_chat_repository.dart';
import 'package:oma/core/repositories/catalog_repository.dart';
import 'package:oma/core/repositories/commerce_repository.dart';
import 'package:oma/core/repositories/loyalty_repository.dart';
import 'package:oma/core/repositories/home_passport_repository.dart';
import 'package:oma/core/repositories/masters_repository.dart';
import 'package:oma/core/repositories/orders_repository.dart';
import 'package:oma/core/repositories/profile_repository.dart';
import 'package:oma/core/repositories/properties_repository.dart';
import 'package:oma/core/repositories/renovation_repository.dart';
import 'package:oma/core/repositories/services_repository.dart';
import 'package:oma/features/cart/cubit/cart_cubit.dart';
import 'package:oma/features/catalog/cubit/catalog_cubit.dart';
import 'package:oma/features/favorites/cubit/favorites_cubit.dart';
import 'package:oma/features/my_home/cubit/properties_cubit.dart';
import 'package:oma/features/masters/cubit/masters_cubit.dart';
import 'package:oma/features/orders/cubit/orders_cubit.dart';
import 'package:oma/features/projects/cubit/projects_cubit.dart';
import 'package:oma/shared/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppScope extends StatelessWidget {
  const AppScope({
    super.key,
    required this.prefs,
    required this.child,
  });

  final SharedPreferences prefs;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // flutter_test stubs HttpClient with 400 — force mock under test bindings.
    final underTest = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
    final useMock = ApiConfig.useMock || underTest;
    final dio = DioClient();
    final CatalogRepository catalog = useMock
        ? MockCatalogRepository()
        : RemoteCatalogRepository(dio);
    final CommerceRepository? commerce =
        useMock ? null : RemoteCommerceRepository(dio);
    final AiChatRepository ai = useMock
        ? MockAiChatRepository()
        : RemoteAiChatRepository(
            dio,
            catalogByIds: (ids) async {
              final out = <Product>[];
              for (final id in ids) {
                final p = await catalog.byId(id);
                if (p != null) out.add(p);
              }
              return out;
            },
          );
    final PropertiesRepository properties = useMock
        ? LocalPropertiesRepository(prefs)
        : RemotePropertiesRepository(dio, prefs);
    final HomePassportRepository passport = useMock
        ? LocalHomePassportRepository(prefs)
        : RemoteHomePassportRepository(dio);
    final demoMasters = DemoMastersRepository(prefs);
    final MastersRepository masters = useMock
        ? demoMasters
        : RemoteMastersRepository(dio, demoMasters);
    final orders = OrdersRepository(prefs);
    final localRenovation = LocalRenovationRepository(prefs);
    final RenovationRepository renovation = useMock
        ? localRenovation
        : RemoteRenovationRepository(dio, localRenovation);
    final ServicesRepository services =
        useMock ? LocalServicesRepository() : RemoteServicesRepository(dio);
    final LoyaltyRepository loyalty =
        useMock ? DemoLoyaltyRepository() : RemoteLoyaltyRepository(dio);
    final ProfileRepository profile =
        useMock ? DemoProfileRepository() : RemoteProfileRepository(dio);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DioClient>.value(value: dio),
        RepositoryProvider<CatalogRepository>.value(value: catalog),
        if (commerce != null)
          RepositoryProvider<CommerceRepository>.value(value: commerce),
        RepositoryProvider<AiChatRepository>.value(value: ai),
        RepositoryProvider.value(value: properties),
        RepositoryProvider<HomePassportRepository>.value(value: passport),
        RepositoryProvider<MastersRepository>.value(value: masters),
        RepositoryProvider.value(value: orders),
        RepositoryProvider<RenovationRepository>.value(value: renovation),
        RepositoryProvider<ServicesRepository>.value(value: services),
        RepositoryProvider<LoyaltyRepository>.value(value: loyalty),
        RepositoryProvider<ProfileRepository>.value(value: profile),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => CartCubit(commerce: commerce)..hydrate(),
          ),
          BlocProvider(
            create: (_) => FavoritesCubit(commerce: commerce)..hydrate(),
          ),
          BlocProvider(create: (_) => CatalogCubit(catalog)..load()),
          BlocProvider(create: (_) => PropertiesCubit(properties)),
          BlocProvider(create: (_) => MastersCubit(masters)..load()),
          BlocProvider(create: (_) => OrdersCubit(orders, commerce: commerce)),
          BlocProvider(
            create: (_) => ProjectsCubit(renovation)..load(),
          ),
        ],
        child: child,
      ),
    );
  }
}
