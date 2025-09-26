import 'package:flutter/material.dart';
import 'package:get/get.dart';

// --- CONFIGURAÇÃO DE ROTAS ---
// Centralizamos a lógica de mapeamento entre rotas e índices aqui.
class AppRoutes {
  static const home = '/';
  static const page1 = '/page1';
  static const page2 = '/page2';

  static final Map<String, int> routeToIndex = {home: 0, page1: 1, page2: 2};

  static final Map<int, String> indexToRoute = {0: home, 1: page1, 2: page2};
}

// Ponto de entrada da aplicação.
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Web Navigation - Fase 2',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Agora usamos um sistema de rotas nomeadas.
      initialRoute: AppRoutes.home,
      getPages: [
        // Todas as nossas rotas principais apontam para o mesmo MainLayout.
        // O Middleware se encarregará de sincronizar o estado correto.
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
      ],
    );
  }
}

// --- MIDDLEWARE DE SINCRONIZAÇÃO ---
// Esta classe intercepta as mudanças de rota e sincroniza o estado da UI.
class SyncMiddleware extends GetMiddleware {
  // Chamado sempre que uma página é buscada, ANTES de ser construída.
  @override
  RouteSettings? redirect(String? route) {
    // Garante que o controller já exista antes de usá-lo.
    if (!Get.isRegistered<NavigationController>()) return null;

    final controller = Get.find<NavigationController>();

    // Se a navegação foi iniciada internamente (pelo clique no Drawer),
    // não fazemos nada para evitar um loop.
    if (controller.isNavigatingInternally) return null;

    // Se a navegação veio de fora (URL, back/forward), atualizamos o índice.
    final newIndex = AppRoutes.routeToIndex[route];
    if (newIndex != null && newIndex != controller.selectedIndex.value) {
      // Atualiza o índice da UI para corresponder à URL.
      controller.changeIndex(newIndex, fromUrl: true);
    }

    return null; // Retornar null significa "prossiga com a rota original".
  }
}

// --- CONTROLLER ---
class NavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  // "Lock" para evitar o loop de feedback.
  bool isNavigatingInternally = false;

  // O método agora tem um parâmetro opcional para saber a origem da chamada.
  void changeIndex(int index, {bool fromUrl = false}) {
    // Evita disparos desnecessários se o índice já for o correto.
    if (selectedIndex.value == index) return;

    selectedIndex.value = index;

    // Se a mudança NÃO veio da URL (ou seja, veio do clique no Drawer),
    // então nós mesmos atualizamos a URL.
    if (!fromUrl) {
      isNavigatingInternally = true; // Ativa o lock
      final newRoute = AppRoutes.indexToRoute[index];
      if (newRoute != null) {
        // Usamos preventDuplicates para não empilhar a mesma rota várias vezes.
        Get.toNamed(newRoute, preventDuplicates: true);
      }
      isNavigatingInternally = false; // Libera o lock
    }
  }
}

// --- LAYOUT PRINCIPAL (Sem mudanças significativas) ---
class MainLayout extends StatelessWidget {
  MainLayout({super.key});

  final NavigationController controller = Get.put(NavigationController());

  final List<Widget> pages = [const HomePage(), const Page1(), const Page2()];

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
  const Page1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      appBar: AppBar(title: const Text('Página 1')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('Esta é a Página 1.', style: TextStyle(fontSize: 24)),
              SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Teste de Estado',
                  hintText: 'Digite algo aqui para ver se o estado se mantém.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
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
