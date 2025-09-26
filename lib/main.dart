import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(MyApp());
}

// NOVO: A estrutura de dados agora suporta sub-menus.
// Adicionamos uma chave 'subItems' opcional para aninhar rotas no Drawer.
final pages = [
  {'title': 'Home', 'path': '/'},
  {
    'title': 'Página 1',
    'path': '/pagina1',
    'subItems': [
      {'title': 'Item 1', 'path': '/pagina1/item1'},
      {'title': 'Item 2', 'path': '/pagina1/item2'},
      {'title': 'Item 3 (com detalhes)', 'path': '/pagina1/item3'},
    ],
  },
  {'title': 'Página 2', 'path': '/pagina2'},
];

// O RouteTracker e o Observer permanecem os mesmos, são boas ferramentas de diagnóstico.
class RouteTracker {
  static String? previousRoute;
  static String? currentRoute;

  static void update(String newRoute) {
    previousRoute = currentRoute;
    currentRoute = newRoute;
    print('[ROUTE] from: $previousRoute → to: $currentRoute');
  }
}

class RouteTrackerObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    RouteTracker.update(route.settings.name ?? '');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    RouteTracker.update(previousRoute?.settings.name ?? '');
    super.didPop(route, previousRoute);
  }
}

// CORREÇÃO: A estrutura do roteador foi simplificada e corrigida.
final GoRouter _router = GoRouter(
  initialLocation: '/',
  observers: [RouteTrackerObserver()],
  routes: [
    // Rota de Login: Fica fora do ShellRoute, pois não tem o Drawer.
    // Esta é a maneira correta de ter uma página "a parte".
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween<Offset>(begin: Offset(1, 0), end: Offset.zero);
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      },
    ),

    // ShellRoute agrupa todas as páginas que compartilham o mesmo layout (o Drawer).
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => HomePage()),
        GoRoute(
          path: '/pagina1',
          builder: (context, state) => Page1(),
          // Rotas de detalhes agora existem APENAS aninhadas aqui.
          // Isso garante que elas possam cobrir o Shell quando navegadas,
          // sem a necessidade de defini-las fora.
          routes: [
            GoRoute(
              path: ':itemId', // ex: /pagina1/item1
              builder: (context, state) {
                final itemId = state.pathParameters['itemId']!;
                return ItemPage(itemId: itemId);
              },
              routes: [
                GoRoute(
                  path: '/detalhes',
                  pageBuilder: (context, state) {
                    final itemId = state.pathParameters['itemId']!;
                    return CustomTransitionPage(
                      key: state.pageKey,
                      child: DetalhePage(itemId: itemId),
                      transitionsBuilder: (
                        context,
                        animation,
                        secondaryAnimation,
                        child,
                      ) {
                        final tween = Tween<Offset>(
                          begin: Offset(1, 0),
                          end: Offset.zero,
                        );
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(path: '/pagina2', builder: (context, state) => Page2()),
      ],
    ),

    // CORREÇÃO: As rotas de detalhes duplicadas que estavam aqui foram removidas.
    // Elas não são necessárias no nível superior, pois o aninhamento dentro
    // da ShellRoute já lida com a navegação e a sobreposição da UI.
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'App com Drawer e Detalhes',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}

class MainLayout extends StatelessWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            color: Colors.blue.shade700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.blue),
                  child: Text(
                    'Menu',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),

                // NOVO: Lógica de renderização para o menu e sub-menus.
                ...pages.map((page) {
                  final hasSubItems =
                      (page['subItems'] as List?)?.isNotEmpty ?? false;
                  var title = page['title']! as String;

                  if (hasSubItems) {
                    // Se tiver sub-itens, renderiza um ExpansionTile.
                    final subItems =
                        page['subItems'] as List<Map<String, String>>;
                    return ExpansionTile(
                      trailing: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                      ),
                      title: Text(title, style: TextStyle(color: Colors.white)),
                      children:
                          subItems.map((subItem) {
                            final isSubItemSelected =
                                location == subItem['path'];
                            // ITEM EM SI FINAL - item1, item2,item3
                            return ListTile(
                              selected: isSubItemSelected,
                              selectedTileColor: Colors.blue.shade900,
                              title: Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Text(
                                  subItem['title']!,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              onTap: () {
                                if (!isSubItemSelected) {
                                  context.go(subItem['path']!);
                                }
                              },
                            );
                          }).toList(),
                    );
                  } else {
                    // Senão, renderiza um ListTile normal.
                    // CORREÇÃO: Lógica de seleção ajustada para a Home.
                    bool selected = false;
                    var path = page['path']! as String;
                    if (page['path'] == '/') {
                      // A Home só é selecionada se a rota for EXATAMENTE a dela.
                      selected = location == page['path'];
                    } else {
                      // As outras páginas são selecionadas se a rota começar com o path delas.
                      selected = location.startsWith(path);
                    }

                    return ListTile(
                      selected: selected,
                      selectedTileColor: Colors.blue.shade900,
                      title: Text(title, style: TextStyle(color: Colors.white)),
                      onTap: () {
                        if (!selected) context.go(path);
                      },
                    );
                  }
                }).toList(),

                const Spacer(),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.white),
                  title: Text('Sair', style: TextStyle(color: Colors.white)),
                  onTap: () => context.go('/login'),
                ),
              ],
            ),
          ),
          Expanded(
            // O `child` aqui é a página que o go_router está renderizando.
            child: child,
          ),
        ],
      ),
    );
  }
}

// --- PÁGINAS ---
// As páginas agora são mais simples. O MainLayout provê o Scaffold e o AppBar.

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Home')),
    body: Center(
      child: Text('Bem-vindo à Home!', style: TextStyle(fontSize: 24)),
    ),
  );
}

class Page1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Página 1')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            'Página 1 - Selecione um item no menu lateral',
            style: TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }
}

class Page2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Página 2')),
    body: Center(child: Text('Página 2', style: TextStyle(fontSize: 24))),
  );
}

// A ItemPage agora é renderizada DENTRO do Shell, mas como tem seu próprio
// Scaffold, ela cobre o layout principal, dando a impressão de ser uma página separada.
class ItemPage extends StatelessWidget {
  final String itemId;
  const ItemPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do $itemId'),
        // O go_router adiciona o botão de voltar automaticamente aqui.
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Informações do $itemId', style: TextStyle(fontSize: 24)),
            if (itemId == 'item3') ...[
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/pagina1/$itemId/detalhes'),
                child: Text('Ver mais detalhes'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DetalhePage extends StatelessWidget {
  final String itemId;
  const DetalhePage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detalhes Extras de $itemId')),
      body: Center(
        child: Text(
          'Mais detalhes sobre $itemId',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.go('/'),
          child: Text('Entrar'),
        ),
      ),
    );
  }
}
