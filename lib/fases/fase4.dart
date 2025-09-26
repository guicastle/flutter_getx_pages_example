import 'package:flutter/material.dart';
import 'package:get/get.dart';
// Para esta fase, você precisará adicionar a dependência no seu pubspec.yaml:
// dependencies:
//   navigation_history_observer: ^1.2.0
import 'package:navigation_history_observer/navigation_history_observer.dart';

// --- CONFIGURAÇÃO DE ROTAS (Sem mudanças) ---
class AppRoutes {
  static const home = '/';
  static const page1 = '/page1';
  static const page2 = '/page2';
  static const page1Details = '/page1/details/:id';
  static const page1DetailsStock = '/page1/details/:id/stock';

  static final Map<String, int> baseRouteToIndex = {
    home: 0,
    page1: 1,
    page2: 2,
  };
  static final Map<int, String> indexToBaseRoute = {
    0: home,
    1: page1,
    2: page2,
  };

  static String getBaseRoute(String? route) {
    if (route == null) return home;
    if (route.startsWith(page1)) return page1;
    if (route.startsWith(page2)) return page2;
    return home;
  }
}

// --- OBSERVER DE HISTÓRICO ---
// Instanciamos o observer globalmente para que ele possa ser acessado em qualquer lugar.
final NavigationHistoryObserver historyObserver = NavigationHistoryObserver();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Web Navigation - Fase 4',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Adicionamos o historyObserver à lista de observadores do GetX.
      // Ele agora registrará todas as operações de navegação (push, pop, replace).
      navigatorObservers: [historyObserver],
      initialRoute: AppRoutes.home,
      getPages: [
        GetPage(
          name: AppRoutes.home,
          page: () => MainLayout(),
          middlewares: [SyncMiddleware()],
        ),
        GetPage(
          name: AppRoutes.page1,
          page: () => MainLayout(),
          middlewares: [SyncMiddleware()],
        ),
        GetPage(
          name: AppRoutes.page2,
          page: () => MainLayout(),
          middlewares: [SyncMiddleware()],
        ),
        GetPage(
          name: AppRoutes.page1Details,
          page: () => MainLayout(),
          middlewares: [SyncMiddleware()],
        ),
        GetPage(
          name: AppRoutes.page1DetailsStock,
          page: () => MainLayout(),
          middlewares: [SyncMiddleware()],
        ),
      ],
    );
  }
}

// --- MIDDLEWARE DE SINCRONIZAÇÃO ---
class SyncMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Log de diagnóstico usando o historyObserver
    debugPrint("--- Navegação Detectada ---");
    debugPrint("Rota atual (Middleware): $route");
    // O histórico aqui pode estar um passo atrás, pois a navegação ainda não foi concluída.
    debugPrint(
      "Histórico anterior: ${historyObserver.history.map((r) => r.settings.name).toList()}",
    );

    if (!Get.isRegistered<NavigationController>()) return null;
    final navCtrl = Get.find<NavigationController>();
    if (navCtrl.isNavigatingInternally) return null;

    final baseRoute = AppRoutes.getBaseRoute(route);
    final newIndex = AppRoutes.baseRouteToIndex[baseRoute];

    if (newIndex != null) {
      if (newIndex != navCtrl.selectedIndex.value) {
        navCtrl.changeIndex(newIndex, fromUrl: true);
      }
      if (baseRoute == AppRoutes.page1 && Get.isRegistered<Page1Controller>()) {
        final page1Ctrl = Get.find<Page1Controller>();
        page1Ctrl.updateFromParams(Get.parameters);
      }
    }

    // Após a lógica, podemos logar o histórico novamente para ver o estado final.
    // Usamos um Future.delayed para garantir que a navegação tenha tempo de ser registrada.
    Future.delayed(const Duration(milliseconds: 100), () {
      debugPrint(
        "Histórico atualizado: ${historyObserver.history.map((r) => r.settings.name).toList()}",
      );
      debugPrint("---------------------------\n");
    });

    return null;
  }
}

// --- CONTROLLERS (Sem mudanças funcionais) ---
class NavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  bool isNavigatingInternally = false;

  void changeIndex(int index, {bool fromUrl = false}) {
    if (selectedIndex.value == index) return;

    if (selectedIndex.value == 1 && Get.isRegistered<Page1Controller>()) {
      final page1Ctrl = Get.find<Page1Controller>();
      page1Ctrl.clearDetails();
    }

    selectedIndex.value = index;

    if (!fromUrl) {
      isNavigatingInternally = true;
      final newRoute = AppRoutes.indexToBaseRoute[index];
      if (newRoute != null) {
        Get.toNamed(newRoute, preventDuplicates: true);
      }
      isNavigatingInternally = false;
    }
  }
}

class Page1Controller extends GetxController {
  final RxnString currentId = RxnString();
  final RxBool showStock = false.obs;

  void updateFromParams(Map<String, String?> params) {
    currentId.value = params['id'];
    showStock.value = Get.currentRoute.endsWith('/stock');
  }

  void clearDetails() {
    currentId.value = null;
    showStock.value = false;
  }
}

// --- LAYOUT PRINCIPAL (Sem mudanças) ---
class MainLayout extends StatelessWidget {
  MainLayout({super.key});
  final NavigationController controller = Get.put(NavigationController());
  final List<Widget> pages = [const HomePage(), Page1(), const Page2()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const CustomDrawer(),
          Expanded(
            child: Obx(
              () => IndexedStack(
                index: controller.selectedIndex.value,
                children: pages,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGETS DO LAYOUT (Sem mudanças) ---
class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});
  @override
  Widget build(BuildContext context) {
    final NavigationController controller = Get.find();
    return Obx(
      () => Container(
        width: 250,
        color: Colors.grey[200],
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Center(
                child: Text(
                  'Navegação Principal',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              selected: controller.selectedIndex.value == 0,
              selectedTileColor: Colors.indigo.withOpacity(0.2),
              onTap: () => controller.changeIndex(0),
            ),
            ListTile(
              leading: const Icon(Icons.looks_one),
              title: const Text('Página 1'),
              selected: controller.selectedIndex.value == 1,
              selectedTileColor: Colors.indigo.withOpacity(0.2),
              onTap: () => controller.changeIndex(1),
            ),
            ListTile(
              leading: const Icon(Icons.looks_two),
              title: const Text('Página 2'),
              selected: controller.selectedIndex.value == 2,
              selectedTileColor: Colors.indigo.withOpacity(0.2),
              onTap: () => controller.changeIndex(2),
            ),
          ],
        ),
      ),
    );
  }
}

// --- PÁGINAS (Sem mudanças) ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Home Page')),
      body: const Center(
        child: Text('Bem-vindo à Home Page!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

class Page1 extends StatelessWidget {
  Page1({super.key});
  final Page1Controller controller = Get.put(Page1Controller());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      appBar: AppBar(
        title: const Text('Página 1'),
        leading: Obx(
          () =>
              controller.currentId.value != null
                  ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      controller.clearDetails();
                      Get.toNamed(AppRoutes.page1);
                    },
                  )
                  : const SizedBox.shrink(),
        ),
      ),
      body: Obx(() {
        if (controller.currentId.value != null) {
          if (controller.showStock.value) {
            return StockPage(id: controller.currentId.value!);
          }
          return DetailsPage(id: controller.currentId.value!);
        } else {
          return const ItemListPage();
        }
      }),
    );
  }
}

class Page2 extends StatelessWidget {
  const Page2({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen[50],
      appBar: AppBar(title: const Text('Página 2')),
      body: const Center(
        child: Text('Esta é a Página 2.', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

// --- SUB-PÁGINAS DA PÁGINA 1 (Sem mudanças) ---
class ItemListPage extends StatelessWidget {
  const ItemListPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Selecione um item para ver os detalhes:',
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Get.toNamed('/page1/details/123'),
            child: const Text('Ver Detalhes do Item 123'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Get.toNamed('/page1/details/555'),
            child: const Text('Ver Detalhes do Item 555'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Get.toNamed('/page1/details/555/stock'),
            child: const Text('Ver Estoque do Item 555'),
          ),
        ],
      ),
    );
  }
}

class DetailsPage extends StatelessWidget {
  final String id;
  const DetailsPage({super.key, required this.id});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Mostrando detalhes para o ID: $id',
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class StockPage extends StatelessWidget {
  final String id;
  const StockPage({super.key, required this.id});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Mostrando o estoque para o ID: $id',
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }
}
