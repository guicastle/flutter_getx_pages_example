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
final NavigationHistoryObserver historyObserver = NavigationHistoryObserver();

void main() {
  // --- INTEGRAÇÃO COM APP_LINKS (Conceitual) ---
  // Se este fosse um app mobile, a inicialização do app_links seria aqui.
  // O código seria algo como:
  //
  // AppLinks appLinks = AppLinks();
  // appLinks.uriLinkStream.listen((uri) {
  //   // Quando um link é recebido (ex: myapp://page1/details/123),
  //   // nós o traduzimos para uma rota do GetX e navegamos.
  //   debugPrint('App Link recebido: $uri');
  //   Get.toNamed(uri.path); // Ex: uri.path seria '/page1/details/123'
  // });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Web Navigation - Fase 5',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
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

// --- MIDDLEWARE DE SINCRONIZAÇÃO (Logs Aprimorados) ---
class SyncMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final from = Get.previousRoute;
    debugPrint("--- [NAVIGATOR] Mudança de Rota ---");
    debugPrint("De: $from");
    debugPrint("Para: $route");
    debugPrint("Parâmetros: ${Get.parameters}");

    if (!Get.isRegistered<NavigationController>()) return null;
    final navCtrl = Get.find<NavigationController>();
    if (navCtrl.isNavigatingInternally) {
      debugPrint("Ação: Ignorando (navegação interna da UI).");
      debugPrint("-------------------------------------\n");
      return null;
    }

    debugPrint("Ação: Processando (navegação externa - URL, back/forward).");
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
    debugPrint("-------------------------------------\n");
    return null;
  }
}

// --- CONTROLLERS ---
class NavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  // Nova variável reativa para o título da página, usada no layout responsivo.
  final RxString currentPageTitle = 'Home'.obs;
  bool isNavigatingInternally = false;

  void changeIndex(int index, {bool fromUrl = false}) {
    if (selectedIndex.value == index && fromUrl == false) return;

    // --- REVISÃO DE MEMÓRIA E ESTADO ---
    // A lógica abaixo é crucial para o gerenciamento de estado. Ao sair de uma
    // página complexa (como a Página 1), nós explicitamente limpamos seu
    // estado de "detalhes". Isso garante que, ao retornar, o usuário veja
    // a visualização padrão (a lista), evitando inconsistências de UI.
    if (selectedIndex.value == 1 && Get.isRegistered<Page1Controller>()) {
      final page1Ctrl = Get.find<Page1Controller>();
      page1Ctrl.clearDetails();
    }

    selectedIndex.value = index;
    _updatePageTitle(index);

    if (!fromUrl) {
      isNavigatingInternally = true;
      final newRoute = AppRoutes.indexToBaseRoute[index];
      if (newRoute != null) {
        Get.toNamed(newRoute, preventDuplicates: true);
      }
      isNavigatingInternally = false;
    }
  }

  void _updatePageTitle(int index) {
    switch (index) {
      case 0:
        currentPageTitle.value = 'Home';
        break;
      case 1:
        currentPageTitle.value = 'Página 1';
        break;
      case 2:
        currentPageTitle.value = 'Página 2';
        break;
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

// --- LAYOUT PRINCIPAL (Agora Responsivo) ---
class MainLayout extends StatelessWidget {
  MainLayout({super.key});

  final NavigationController controller = Get.put(NavigationController());
  final List<Widget> pages = [const HomePage(), Page1(), const Page2()];

  // Ponto de quebra para a mudança de layout.
  final double breakpoint = 768.0;

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder nos dá as dimensões do widget pai, permitindo
    // construir uma UI diferente com base na largura disponível.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          // TELA LARGA: Mostra o Drawer fixo à esquerda.
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
        } else {
          // TELA ESTREITA: Usa o Drawer padrão (colapsável).
          return Scaffold(
            appBar: AppBar(
              // O título do AppBar agora é reativo e controlado pelo NavigationController.
              title: Obx(() => Text(controller.currentPageTitle.value)),
            ),
            drawer: const CustomDrawer(),
            body: Obx(
              () => IndexedStack(
                index: controller.selectedIndex.value,
                children: pages,
              ),
            ),
          );
        }
      },
    );
  }
}

// --- WIDGETS DO LAYOUT (CustomDrawer agora é reutilizável) ---
class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});
  @override
  Widget build(BuildContext context) {
    final NavigationController controller = Get.find();
    return Obx(
      () => Drawer(
        // Envolvemos com o widget Drawer para o layout estreito
        child: Container(
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
                onTap: () {
                  controller.changeIndex(0);
                  if (Get.context != null) {
                    Get.back();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.looks_one),
                title: const Text('Página 1'),
                selected: controller.selectedIndex.value == 1,
                selectedTileColor: Colors.indigo.withOpacity(0.2),
                onTap: () {
                  controller.changeIndex(1);
                  if (Get.context != null) {
                    Get.back();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.looks_two),
                title: const Text('Página 2'),
                selected: controller.selectedIndex.value == 2,
                selectedTileColor: Colors.indigo.withOpacity(0.2),
                onTap: () {
                  controller.changeIndex(2);
                  if (Get.context != null) {
                    Get.back();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- PÁGINAS (Agora sem AppBar próprio) ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Bem-vindo à Home Page!', style: TextStyle(fontSize: 24)),
    );
  }
}

class Page1 extends StatelessWidget {
  Page1({super.key});
  final Page1Controller controller = Get.put(Page1Controller());
  @override
  Widget build(BuildContext context) {
    // O Scaffold foi removido, pois o MainLayout já provê um.
    return Obx(() {
      if (controller.currentId.value != null) {
        if (controller.showStock.value) {
          return StockPage(id: controller.currentId.value!);
        }
        return DetailsPage(id: controller.currentId.value!);
      } else {
        return const ItemListPage();
      }
    });
  }
}

class Page2 extends StatelessWidget {
  const Page2({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Esta é a Página 2.', style: TextStyle(fontSize: 24)),
    );
  }
}

// --- SUB-PÁGINAS DA PÁGINA 1 ---
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
          // Adicionamos um botão de voltar para a Home na lista de itens
          // para facilitar o teste de navegação profunda.
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
          const SizedBox(height: 30),
          TextButton(
            onPressed: () => Get.find<NavigationController>().changeIndex(0),
            child: const Text('Voltar para a Home'),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Mostrando detalhes para o ID: $id',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Get.toNamed(AppRoutes.page1),
            child: const Text('Voltar para a lista'),
          ),
        ],
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Mostrando o estoque para o ID: $id',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Get.toNamed(AppRoutes.page1),
            child: const Text('Voltar para a lista'),
          ),
        ],
      ),
    );
  }
}
