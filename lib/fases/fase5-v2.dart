import 'package:flutter/material.dart';
import 'package:get/get.dart';
// Para este projeto, adicione a seguinte dependência no seu pubspec.yaml:
// dependencies:
//   navigation_history_observer: ^1.2.0
import 'package:navigation_history_observer/navigation_history_observer.dart';

// --- CONFIGURAÇÃO DE ROTAS ---
// Centraliza todas as constantes e lógicas de mapeamento de rotas.
class AppRoutes {
  // Rotas base para cada aba principal.
  static const home = '/';
  static const page1 = '/page1';
  static const page2 = '/page2';

  // Rotas dinâmicas com parâmetros para deep links.
  static const page1Details = '/page1/details/:id';
  static const page1DetailsStock = '/page1/details/:id/stock';

  // Mapas para traduzir entre rotas e índices do IndexedStack.
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

  // Helper que extrai a rota base de uma URL completa.
  // Essencial para manter o Drawer sincronizado em deep links.
  // Ex: de '/page1/details/123' -> retorna '/page1'.
  static String getBaseRoute(String? route) {
    if (route == null) return home;
    if (route.startsWith(page1)) return page1;
    if (route.startsWith(page2)) return page2;
    return home;
  }
}

// --- OBSERVER DE HISTÓRICO ---
// Instância global para monitorar e logar o histórico de navegação.
final NavigationHistoryObserver historyObserver = NavigationHistoryObserver();

void main() {
  // --- INTEGRAÇÃO COM APP_LINKS (Conceitual para Mobile) ---
  // Em um app mobile, a inicialização para ouvir deep links do sistema
  // operacional seria feita aqui, usando um pacote como 'app_links'.
  // O link recebido seria então passado para o sistema de rotas do GetX.
  // Ex: appLinks.uriLinkStream.listen((uri) => Get.toNamed(uri.path));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Web Navigation - Versão Final',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Registra o observer para monitorar todas as navegações.
      navigatorObservers: [historyObserver],
      initialRoute: AppRoutes.home,
      // Define todas as rotas válidas da aplicação.
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
// O cérebro da arquitetura. Intercepta todas as navegações e garante que a
// UI (IndexedStack) e a URL do navegador estejam sempre em sincronia.
class SyncMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Logs detalhados para diagnóstico do fluxo de navegação.
    debugPrint("--- [NAVIGATOR] Mudança de Rota ---");
    debugPrint("De: ${Get.previousRoute}");
    debugPrint("Para: $route");
    debugPrint("Parâmetros: ${Get.parameters}");

    // Garante que os controllers já foram inicializados.
    if (!Get.isRegistered<NavigationController>()) return null;
    final navCtrl = Get.find<NavigationController>();

    // O "lock" anti-loop: se a navegação foi iniciada pela UI (Drawer),
    // o middleware não faz nada para evitar um ciclo de feedback.
    if (navCtrl.isNavigatingInternally) {
      debugPrint("Ação: Ignorando (navegação interna da UI).");
      debugPrint("-------------------------------------\n");
      return null;
    }

    // Se a navegação veio de uma fonte externa (URL, back/forward), o middleware age.
    debugPrint("Ação: Processando (navegação externa).");
    final baseRoute = AppRoutes.getBaseRoute(route);
    final newIndex = AppRoutes.baseRouteToIndex[baseRoute];

    if (newIndex != null) {
      // 1. Sincroniza o índice do IndexedStack.
      navCtrl.changeIndex(newIndex, fromUrl: true);

      // 2. Orquestra o estado da sub-página, se aplicável.
      if (baseRoute == AppRoutes.page1 && Get.isRegistered<Page1Controller>()) {
        final page1Ctrl = Get.find<Page1Controller>();
        page1Ctrl.updateFromParams(Get.parameters);
      }
    }
    debugPrint("-------------------------------------\n");
    return null; // Prossiga com a rota original.
  }
}

// --- CONTROLLERS ---

// Gerencia o estado da navegação principal (a aba ativa).
class NavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  final RxString currentPageTitle = 'Home'.obs;
  bool isNavigatingInternally = false;

  void changeIndex(int index, {bool fromUrl = false}) {
    if (selectedIndex.value == index && !fromUrl) return;

    // CORREÇÃO CRÍTICA: Gerenciamento de estado ao sair de uma aba.
    // Antes de mudar de aba, limpamos o estado interno da página anterior
    // para garantir que, ao retornar, ela esteja em seu estado inicial.
    if (selectedIndex.value == 1 && Get.isRegistered<Page1Controller>()) {
      Get.find<Page1Controller>().clearDetails();
    }

    selectedIndex.value = index;
    _updatePageTitle(index);

    // Se a mudança veio da UI (Drawer), nós atualizamos a URL.
    if (!fromUrl) {
      isNavigatingInternally = true; // Ativa o lock
      final newRoute = AppRoutes.indexToBaseRoute[index];
      if (newRoute != null) {
        Get.toNamed(newRoute, preventDuplicates: true);
      }
      isNavigatingInternally = false; // Libera o lock
    }
  }

  void _updatePageTitle(int index) {
    currentPageTitle.value =
        AppRoutes.indexToBaseRoute[index]?.replaceAll('/', '') ?? 'Home';
    if (currentPageTitle.value.isEmpty) currentPageTitle.value = 'Home';
  }
}

// Gerencia o estado interno e complexo da Página 1.
class Page1Controller extends GetxController {
  final RxnString currentId = RxnString();
  final RxBool showStock = false.obs;

  // Atualiza o estado a partir dos parâmetros da URL.
  void updateFromParams(Map<String, String?> params) {
    currentId.value = params['id'];
    showStock.value = Get.currentRoute.endsWith('/stock');
  }

  // Reseta o estado para a visualização padrão (lista de itens).
  void clearDetails() {
    currentId.value = null;
    showStock.value = false;
  }
}

// --- LAYOUT PRINCIPAL (Responsivo) ---
// O "Shell" da aplicação. Constrói a estrutura visual com base no tamanho da tela.
class MainLayout extends StatelessWidget {
  MainLayout({super.key});

  final NavigationController controller = Get.put(NavigationController());
  final List<Widget> pages = [const HomePage(), Page1(), const Page2()];
  final double breakpoint = 768.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // TELA LARGA: Layout com Drawer fixo.
        if (constraints.maxWidth >= breakpoint) {
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
        // TELA ESTREITA: Layout com AppBar e Drawer colapsável.
        else {
          return Scaffold(
            appBar: AppBar(
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

// --- WIDGETS DO LAYOUT ---
// O menu lateral, que se adapta para ser fixo ou colapsável.
class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});
  @override
  Widget build(BuildContext context) {
    final NavigationController controller = Get.find();
    // Usamos o mesmo breakpoint do MainLayout para manter a consistência.
    const double breakpoint = 768.0;

    // CORREÇÃO ANTI-FLICKER: A estrutura principal do Drawer (Drawer, Container, Column, DrawerHeader)
    // é construída apenas uma vez. Apenas os widgets que precisam mudar (os ListTiles)
    // são envolvidos em um Obx para reatividade granular.
    return Drawer(
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
            Obx(
              () => ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                selected: controller.selectedIndex.value == 0,
                selectedTileColor: Colors.indigo.withOpacity(0.2),
                onTap: () {
                  controller.changeIndex(0);
                  if (Get.width < breakpoint) {
                    Get.back();
                  }
                },
              ),
            ),
            Obx(
              () => ListTile(
                leading: const Icon(Icons.looks_one),
                title: const Text('Página 1'),
                selected: controller.selectedIndex.value == 1,
                selectedTileColor: Colors.indigo.withOpacity(0.2),
                onTap: () {
                  controller.changeIndex(1);
                  if (Get.width < breakpoint) {
                    Get.back();
                  }
                },
              ),
            ),
            Obx(
              () => ListTile(
                leading: const Icon(Icons.looks_two),
                title: const Text('Página 2'),
                selected: controller.selectedIndex.value == 2,
                selectedTileColor: Colors.indigo.withOpacity(0.2),
                onTap: () {
                  controller.changeIndex(2);
                  if (Get.width < breakpoint) {
                    Get.back();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- PÁGINAS ---
// As páginas agora são widgets mais simples, pois o Scaffold e o AppBar
// são gerenciados pelo MainLayout.

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Bem-vindo à Home Page!', style: TextStyle(fontSize: 24)),
    );
  }
}

// A Página 1 é dinâmica e reage ao seu próprio controlador.
class Page1 extends StatelessWidget {
  Page1({super.key});
  final Page1Controller controller = Get.put(Page1Controller());
  @override
  Widget build(BuildContext context) {
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
          ElevatedButton(
            onPressed: () => Get.toNamed('/page1/details/123'),
            child: const Text('Ver Detalhes do Item 123'),
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
