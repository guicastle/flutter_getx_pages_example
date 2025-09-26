import 'package:flutter/material.dart';
import 'package:get/get.dart';

// --- CONFIGURAÇÃO DE ROTAS ---
class AppRoutes {
  // Rotas base
  static const home = '/';
  static const page1 = '/page1';
  static const page2 = '/page2';

  // Rotas dinâmicas (com parâmetros)
  static const page1Details = '/page1/details/:id';
  static const page1DetailsStock = '/page1/details/:id/stock';

  // Mapeamento para o IndexedStack
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

  // Helper para extrair a rota base de uma URL completa
  static String getBaseRoute(String? route) {
    if (route == null) return home;
    if (route.startsWith(page1)) return page1;
    if (route.startsWith(page2)) return page2;
    return home;
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Web Navigation - Fase 3',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: AppRoutes.home,
      getPages: [
        // Rotas base
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
        // Rotas de deep link
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

// --- MIDDLEWARE DE SINCRONIZAÇÃO (EVOLUÍDO) ---
class SyncMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<NavigationController>()) return null;

    final navCtrl = Get.find<NavigationController>();
    if (navCtrl.isNavigatingInternally) return null;

    // 1. Descobrir o índice da aba principal a partir da rota completa
    final baseRoute = AppRoutes.getBaseRoute(route);
    final newIndex = AppRoutes.baseRouteToIndex[baseRoute];

    if (newIndex != null) {
      // 2. Atualiza o índice do IndexedStack se necessário
      if (newIndex != navCtrl.selectedIndex.value) {
        navCtrl.changeIndex(newIndex, fromUrl: true);
      }

      // 3. Se a rota for da Página 1, passa os parâmetros para seu controller
      if (baseRoute == AppRoutes.page1 && Get.isRegistered<Page1Controller>()) {
        final page1Ctrl = Get.find<Page1Controller>();
        // Get.parameters já é parseado pelo GetX a partir da URL
        page1Ctrl.updateFromParams(Get.parameters);
      }
    }

    return null;
  }
}

// --- CONTROLLERS ---

class NavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  bool isNavigatingInternally = false;

  void changeIndex(int index, {bool fromUrl = false}) {
    if (selectedIndex.value == index) return;

    // *** INÍCIO DA CORREÇÃO ***
    // Antes de mudar de aba, verifica se a aba anterior (a que estamos deixando)
    // precisa ter seu estado interno limpo.
    if (selectedIndex.value == 1 && Get.isRegistered<Page1Controller>()) {
      final page1Ctrl = Get.find<Page1Controller>();
      page1Ctrl.clearDetails();
    }
    // Adicionar lógica similar para outras páginas se elas também tiverem
    // estados internos complexos no futuro.
    // *** FIM DA CORREÇÃO ***

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

// Novo controller específico para a Página 1
class Page1Controller extends GetxController {
  // Variáveis reativas para controlar o estado interno da Página 1
  final RxnString currentId = RxnString();
  final RxBool showStock = false.obs;

  // Método chamado pelo Middleware para atualizar o estado a partir da URL
  void updateFromParams(Map<String, String?> params) {
    currentId.value = params['id'];
    // Verifica se a rota contém '/stock'
    showStock.value = Get.currentRoute.endsWith('/stock');
  }

  // Limpa o estado ao voltar para a lista principal
  void clearDetails() {
    currentId.value = null;
    showStock.value = false;
  }
}

// --- LAYOUT PRINCIPAL ---
class MainLayout extends StatelessWidget {
  MainLayout({super.key});

  final NavigationController controller = Get.put(NavigationController());

  final List<Widget> pages = [
    const HomePage(),
    Page1(), // Page1 agora é mais complexa
    const Page2(),
  ];

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

// --- PÁGINAS ---

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

// Page1 agora é um widget dinâmico que gerencia seu próprio estado interno.
class Page1 extends StatelessWidget {
  Page1({super.key});

  // Cada instância de Page1 terá seu próprio controller.
  final Page1Controller controller = Get.put(Page1Controller());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      appBar: AppBar(
        title: const Text('Página 1'),
        // Adiciona um botão de voltar se estivermos em uma sub-página
        leading: Obx(
          () =>
              controller.currentId.value != null
                  ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      // Ao voltar, limpamos os detalhes e navegamos para a base da Page1
                      controller.clearDetails();
                      Get.toNamed(AppRoutes.page1);
                    },
                  )
                  : const SizedBox.shrink(),
        ),
      ),
      // O corpo da página reage ao estado do controller
      body: Obx(() {
        if (controller.currentId.value != null) {
          // Se temos um ID, mostramos a tela de detalhes
          if (controller.showStock.value) {
            return StockPage(id: controller.currentId.value!);
          }
          return DetailsPage(id: controller.currentId.value!);
        } else {
          // Senão, mostramos a lista de itens
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

// --- SUB-PÁGINAS DA PÁGINA 1 ---

// A lista de itens que agora é a "home" da Página 1
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

// A tela que mostra os detalhes de um item
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

// A tela que mostra o estoque de um item
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
