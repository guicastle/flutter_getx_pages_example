import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:navigation_history_observer/navigation_history_observer.dart';

void main() => runApp(MyApp());

final pages = [
  {'title': 'Home', 'path': '/'},
  {'title': 'Página 1', 'path': '/pagina1'},
  {'title': 'Página 2', 'path': '/pagina2'},
];

final navObserver = NavigationHistoryObserver();

final GoRouter _router = GoRouter(
  initialLocation: '/',
  observers: [navObserver], // ✅ usando navigation_history_observer
  routes: [
    // Layout com Drawer
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) {
            final history = navObserver.history;
            final previousRouteName =
                history.length > 1
                    ? history[history.length - 2].settings.name
                    : null;
            // ✅ checando rota anterior
            final fromLogin = previousRouteName == '/login';
            if (fromLogin) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: HomePage(),
                transitionsBuilder: (context, animation, _, child) {
                  final tween = Tween<Offset>(
                    begin: Offset(1, 0),
                    end: Offset.zero,
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

    // Páginas sem Drawer
    GoRoute(
      name: 'item',
      path: '/pagina1/:itemId',
      builder: (context, state) {
        final itemId = state.pathParameters['itemId']!;
        return ItemPage(itemId: itemId);
      },
      routes: [
        GoRoute(
          name: 'detalhe',
          path: 'detalhes',
          builder: (context, state) {
            final itemId = state.pathParameters['itemId']!;
            return DetalhePage(itemId: itemId);
          },
        ),
      ],
    ),

    GoRoute(
      path: '/login',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: LoginPage(),
          transitionsBuilder: (context, animation, _, child) {
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
          // Drawer lateral
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
                Spacer(),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.white),
                  title: Text('Sair', style: TextStyle(color: Colors.white)),
                  onTap: () => context.go('/login'),
                ),
              ],
            ),
          ),
          // Conteúdo principal
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

/// Páginas com Drawer

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
            onTap:
                () => context.pushNamed('item', pathParameters: {'itemId': id}),
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

/// Páginas fora do ShellRoute (sem Drawer)

class ItemPage extends StatelessWidget {
  final String itemId;
  const ItemPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detalhes do $itemId')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Informações do $itemId', style: TextStyle(fontSize: 24)),
            if (itemId == 'item3') ...[
              SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    () => context.pushNamed(
                      'detalhe',
                      pathParameters: {'itemId': itemId},
                    ),
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
