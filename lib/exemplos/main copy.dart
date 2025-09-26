import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(MyApp());
}

final pages = [
  {'title': 'Home', 'path': '/'},
  {'title': 'Página 1', 'path': '/pagina1'},
  {'title': 'Página 2', 'path': '/pagina2'},
];

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
  void didPush(Route route, Route? previousRoute) {
    RouteTracker.update(route.settings.name ?? '');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    RouteTracker.update(previousRoute?.settings.name ?? '');
    super.didPop(route, previousRoute);
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  observers: [RouteTrackerObserver()],
  routes: [
    // Rotas com Drawer
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        // Home com animação
        GoRoute(
          path: '/',
          pageBuilder: (context, state) {
            final fromLogin = RouteTracker.previousRoute == '/login';

            if (fromLogin) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: HomePage(),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  final tween = Tween<Offset>(
                    begin: Offset(1, 0),
                    end: Offset(0, 0),
                  );
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
                transitionDuration: Duration(milliseconds: 300),
                reverseTransitionDuration: Duration(milliseconds: 300),
              );
            } else {
              return MaterialPage(key: state.pageKey, child: HomePage());
            }
          },
        ),

        GoRoute(path: '/pagina1', builder: (context, state) => Page1()),
        GoRoute(path: '/pagina2', builder: (context, state) => Page2()),
      ],
    ),

    // Rotas sem Drawer, com botão voltar
    GoRoute(
      path: '/pagina1/:itemId',
      pageBuilder: (context, state) {
        final itemId = state.pathParameters['itemId']!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: ItemPage(itemId: itemId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slide da direita para esquerda
            final tween = Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0));
            final reverseTween = Tween<Offset>(
              begin: Offset(0, 0),
              end: Offset(1, 0),
            );
            final offsetAnimation = animation.drive(tween);
            secondaryAnimation.drive(reverseTween);

            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: Duration(milliseconds: 300),
          reverseTransitionDuration: Duration(milliseconds: 300),
        );
      },
    ),

    GoRoute(
      path: '/pagina1/:itemId/detalhes',
      pageBuilder: (context, state) {
        final itemId = state.pathParameters['itemId']!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: DetalhePage(itemId: itemId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween<Offset>(begin: Offset(1, 0), end: Offset.zero);
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: Duration(milliseconds: 300),
        );
      },
    ),

    // Login com animação
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0));
            final offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: Duration(milliseconds: 300),
          reverseTransitionDuration: Duration(milliseconds: 300),
        );
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
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
          // Drawer fixo
          Container(
            width: 250,
            color: Colors.blue.shade700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: Colors.blue),
                  child: Text(
                    'Menu',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),

                // Lista de páginas
                ...pages.map((page) {
                  final selected =
                      location == page['path'] ||
                      location.startsWith('${page['path']}/');
                  return ListTile(
                    selected: selected,
                    selectedTileColor: Colors.blue.shade900,
                    title: Text(
                      page['title']!,
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      if (!selected) context.go(page['path']!);
                    },
                  );
                }),

                // Espaço restante
                Spacer(),

                // Botão de sair no rodapé
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.white),
                  title: Text('Sair', style: TextStyle(color: Colors.white)),
                  onTap: () => context.go('/login'),
                ),
              ],
            ),
          ),

          // Conteúdo da página
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  pages.firstWhere(
                    (p) =>
                        location == p['path'] ||
                        location.startsWith('${p['path']}/'),
                    orElse: () => {'title': 'App'},
                  )['title']!,
                ),
              ),
              body: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Páginas dentro do Drawer

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Center(child: Text('Bem-vindo à Home!', style: TextStyle(fontSize: 24)));
}

class Page1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Text('Página 1 - Lista de Itens', style: TextStyle(fontSize: 24)),
        SizedBox(height: 20),
        for (var id in ["item1", "item2", "item3"])
          ListTile(
            title: Text('Item $id'),
            trailing: Icon(Icons.arrow_forward),
            // onTap: () => context.push('/pagina1/$id'),
            onTap: () => GoRouter.of(context).go('/pagina1/$id'),
          ),
      ],
    );
  }
}

class Page2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Center(child: Text('Página 2', style: TextStyle(fontSize: 24)));
}

/// Página de item sem Drawer, com botão voltar no AppBar
class ItemPage extends StatelessWidget {
  final String itemId;
  const ItemPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do $itemId'),
        leading: BackButton(onPressed: () => GoRouter.of(context).pop()),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Informações do $itemId', style: TextStyle(fontSize: 24)),
            if (itemId == 'item3') ...[
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/pagina1/$itemId/detalhes'),
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
      appBar: AppBar(
        title: Text('Detalhes Extras de $itemId'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Center(
        child: Text(
          'Mais detalhes sobre $itemId',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

/// Tela fora do Drawer (ex: login)

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
