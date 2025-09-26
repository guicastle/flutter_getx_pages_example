import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

//================================================================
// PASSO 1: PONTO DE ENTRADA DA APLICAÇÃO (main)
//================================================================
void main() {
  // Garante que os bindings do Flutter sejam inicializados antes de qualquer outra coisa.
  WidgetsFlutterBinding.ensureInitialized();
  // Inicia e registra nossos controllers globais, como o AuthController.
  initServices();
  runApp(const MyApp());
}

/// Inicializa e injeta os serviços/controllers essenciais da aplicação.
void initServices() {
  // Registra o AuthController como um serviço permanente usando Get.put().
  // Ele ficará disponível em toda a aplicação.
  Get.put(AuthController(), permanent: true);
}

//================================================================
// PASSO 2: CONFIGURAÇÃO DO GETMATERIALAPP E ROTAS
//================================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // GetMaterialApp é o substituto do MaterialApp que habilita todo o poder do GetX.
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter GetX Navigation',
      // Ponto de partida da navegação.
      initialRoute: AppPages.INITIAL,
      // Define todas as rotas disponíveis na aplicação.
      getPages: AppPages.routes,
      // Define uma página para ser exibida caso uma rota não seja encontrada.
      unknownRoute: AppPages.unknownRoute,
    );
  }
}

/// Classe que centraliza a definição de todas as rotas da aplicação.
class AppPages {
  static const INITIAL = '/splash';

  // Rota para a página de 404.
  static final unknownRoute = GetPage(
    name: '/notfound',
    page: () => const NotFoundScreen(),
  );

  // Lista de todas as rotas (GetPage) da aplicação.
  static final routes = [
    GetPage(name: '/splash', page: () => const SplashScreen()),
    GetPage(name: '/login', page: () => const LoginScreen()),
    GetPage(
      name: '/',
      page: () => const MainView(),
      // Middleware de autenticação: protege o acesso à MainView e suas filhas.
      middlewares: [AuthMiddleware()],
    ),
    // Rota com parâmetro dinâmico para os detalhes do item.
    GetPage(
      name: '/orders/:itemId',
      page: () => const ItemDetailsScreen(),
      // Também protegida pelo middleware, pois depende de estar logado.
      middlewares: [AuthMiddleware()],
    ),
  ];
}

//================================================================
// PASSO 3: MIDDLEWARE DE AUTENTICAÇÃO
//================================================================
/// Middleware que verifica se o usuário está logado antes de permitir o acesso a uma rota.
class AuthMiddleware extends GetMiddleware {
  @override
  // A prioridade define a ordem de execução caso haja múltiplos middlewares.
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();

    // Se o usuário não estiver logado (isLoggedIn.value é false ou null),
    // redireciona para a página de login. Caso contrário, não faz nada (retorna null).
    if (authController.isLoggedIn.value != true) {
      return const RouteSettings(name: '/login');
    }
    return null;
  }
}

//================================================================
// PASSO 4: CONTROLLERS (LÓGICA DE NEGÓCIO)
//================================================================

/// Gerencia o estado e a lógica de autenticação do usuário.
class AuthController extends GetxController {
  final _storage = const FlutterSecureStorage();

  // Variáveis reativas que a UI pode observar.
  // Rxn<bool> permite que o valor inicial seja nulo.
  final isLoggedIn = RxnBool();
  final isAuthCheckComplete = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Verifica o status de autenticação assim que o controller é inicializado.
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'auth_token');
    isLoggedIn.value = token != null;
    isAuthCheckComplete.value = true;
  }

  Future<void> login() async {
    await _storage.write(key: 'auth_token', value: 'fake_auth_token_123');
    isLoggedIn.value = true;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    isLoggedIn.value = false;
    // Redireciona para o login após o logout.
    Get.offAllNamed('/login');
  }
}

/// Gerencia o estado da navegação principal (Drawer/BottomBar).
class MainController extends GetxController {
  // Variável reativa para o índice da página selecionada.
  final selectedIndex = 0.obs;

  // Lista de widgets das páginas principais.
  final List<Widget> pages = [
    const HomeView(),
    const OrdersView(),
    const SettingsView(),
  ];

  // Método para alterar a página exibida.
  void changePage(int index) {
    selectedIndex.value = index;
  }
}

//================================================================
// PASSO 5: TELAS (VIEWS)
//================================================================

/// Tela de Splash: verifica a autenticação e redireciona.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // GetX<AuthController> ouve as mudanças no controller.
    return GetX<AuthController>(
      builder: (controller) {
        // A lógica de redirecionamento é acionada quando a verificação termina.
        if (controller.isAuthCheckComplete.value) {
          final targetRoute =
              controller.isLoggedIn.value == true ? '/' : '/login';
          // WidgetsBinding garante que a navegação ocorra após o build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed(targetRoute);
          });
        }

        // Enquanto a verificação não termina, exibe um indicador de carregamento.
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

/// Tela de Login.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find();
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Fazer Login'),
          onPressed: () async {
            await authController.login();
            // Após o login, substitui a tela de login pela tela principal.
            Get.offAllNamed('/');
          },
        ),
      ),
    );
  }
}

/// A "casca" (shell) da aplicação que contém o Scaffold responsivo e troca as views principais.
class MainView extends StatelessWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    // Injeta o MainController, que viverá enquanto esta view estiver na árvore.
    final MainController controller = Get.put(MainController());

    return ResponsiveScaffold(
      // Obx ouve a mudança no selectedIndex e reconstrói o body com a página correta.
      child: Obx(() => controller.pages[controller.selectedIndex.value]),
    );
  }
}

// ----- Views principais que são trocadas pela MainView -----

class HomeView extends StatelessWidget {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Home View', style: TextStyle(fontSize: 24)),
    );
  }
}

class OrdersView extends StatelessWidget {
  const OrdersView({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text('Ver Pedido #item_001'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => Get.toNamed('/orders/item_001'),
        ),
        ListTile(
          title: const Text('Ver Pedido #item_002'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => Get.toNamed('/orders/item_002'),
        ),
        ListTile(
          title: const Text('Ver Pedido #item_003'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => Get.toNamed('/orders/item_003'),
        ),
      ],
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Settings View', style: TextStyle(fontSize: 24)),
    );
  }
}

/// Tela de detalhes de um item, acessada com parâmetro na rota.
class ItemDetailsScreen extends StatelessWidget {
  const ItemDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Acessa o parâmetro da URL de forma simples com Get.parameters.
    final String? itemId = Get.parameters['itemId'];

    return Scaffold(
      appBar: AppBar(title: Text('Detalhes: $itemId')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Você está vendo os detalhes do item: $itemId'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Voltar para Pedidos'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tela de erro 404 para rotas não encontradas.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página Não Encontrada')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '404',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Oops! A página que você procurava não existe.'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.offAllNamed('/'),
              child: const Text('Ir para a Home'),
            ),
          ],
        ),
      ),
    );
  }
}

//================================================================
// PASSO 6: WIDGETS REUTILIZÁVEIS
//================================================================

/// Scaffold que se adapta a telas grandes (menu fixo) e pequenas (drawer).
class ResponsiveScaffold extends StatelessWidget {
  final Widget child;
  const ResponsiveScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Títulos para a AppBar baseados no índice da página.
    final titles = ['Home', 'Orders', 'Settings'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 600;

        if (isDesktop) {
          // Layout para Desktop com menu lateral fixo.
          return Scaffold(
            body: Row(
              children: [
                const SizedBox(
                  width: 240,
                  child: Drawer(elevation: 0, child: _AppDrawerContent()),
                ),
                Expanded(
                  child: Scaffold(
                    // AppBar que reage às mudanças de página.
                    appBar: AppBar(
                      title: Obx(
                        () => Text(
                          titles[Get.find<MainController>()
                              .selectedIndex
                              .value],
                        ),
                      ),
                    ),
                    body: child,
                  ),
                ),
              ],
            ),
          );
        } else {
          // Layout para Mobile com Drawer tradicional.
          return Scaffold(
            appBar: AppBar(
              title: Obx(
                () => Text(
                  titles[Get.find<MainController>().selectedIndex.value],
                ),
              ),
            ),
            drawer: const Drawer(child: _AppDrawerContent()),
            body: child,
          );
        }
      },
    );
  }
}

/// Conteúdo do Drawer, separado para reutilização.
class _AppDrawerContent extends StatelessWidget {
  const _AppDrawerContent();

  @override
  Widget build(BuildContext context) {
    final MainController mainController = Get.find();
    final AuthController authController = Get.find();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(color: Colors.blue),
          child: Text(
            "Menu Principal",
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
        // Obx para destacar o item de menu selecionado.
        Obx(
          () => ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            selected: mainController.selectedIndex.value == 0,
            onTap: () => _navigateTo(context, 0),
          ),
        ),
        Obx(
          () => ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Orders'),
            selected: mainController.selectedIndex.value == 1,
            onTap: () => _navigateTo(context, 1),
          ),
        ),
        Obx(
          () => ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            selected: mainController.selectedIndex.value == 2,
            onTap: () => _navigateTo(context, 2),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: () async {
            await authController.logout();
          },
        ),
      ],
    );
  }

  /// Função auxiliar para navegação do Drawer.
  void _navigateTo(BuildContext context, int index) {
    final MainController mainController = Get.find();
    mainController.changePage(index);
    // Fecha o Drawer em telas mobile.
    if (Scaffold.of(context).isDrawerOpen) {
      Navigator.of(context).pop();
    }
  }
}
