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

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    // Rotas com layout fixo (Drawer)
    ShellRoute(
      builder: (context, state, child) {
        return MainLayout(child: child);
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => HomePage()),
        GoRoute(
          path: '/pagina1',
          builder: (context, state) => Page1(),
          routes: [
            GoRoute(
              path: ':itemId/detalhes',
              builder: (context, state) {
                final itemId = state.pathParameters['itemId']!;
                return Page1Details(itemId: itemId);
              },
            ),
          ],
        ),
        GoRoute(path: '/pagina2', builder: (context, state) => Page2()),
      ],
    ),

    // Rotas fora do Drawer (exemplo: login)
    GoRoute(path: '/login', builder: (context, state) => LoginPage()),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'App com Drawer e Rotas Dinâmicas',
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
                }).toList(),
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

/// Páginas básicas

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Center(child: Text('Bem-vindo à Home!', style: TextStyle(fontSize: 24)));
}

class Page1 extends StatelessWidget {
  const Page1({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => context.go('/pagina1/42/detalhes'),
        child: Text('Ver detalhes do item 42'),
      ),
    );
  }
}

class Page1Details extends StatelessWidget {
  final String itemId;
  const Page1Details({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Detalhes do item: $itemId', style: TextStyle(fontSize: 24)),
    );
  }
}

class Page2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Center(child: Text('Página 2', style: TextStyle(fontSize: 24)));
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
