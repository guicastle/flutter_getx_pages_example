import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(MyApp());
}

/// Mapeamento de páginas
final pages = [
  {'title': 'Home', 'path': '/'},
  {'title': 'Página 1', 'path': '/pagina1'},
  {'title': 'Página 2', 'path': '/pagina2'},
  {'title': 'Página 3', 'path': '/pagina3'},
  {'title': 'Página 4', 'path': '/pagina4'},
  {'title': 'Página 5', 'path': '/pagina5'},
];

/// Cria um router com navegação por URL e sincronização com estado
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainLayout(child: child);
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => HomePage()),
        GoRoute(path: '/pagina1', builder: (context, state) => Page1()),
        GoRoute(path: '/pagina2', builder: (context, state) => Page2()),
        GoRoute(path: '/pagina3', builder: (context, state) => Page3()),
        GoRoute(path: '/pagina4', builder: (context, state) => Page4()),
        GoRoute(path: '/pagina5', builder: (context, state) => Page5()),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}

/// Layout principal com Drawer fixo à esquerda
class MainLayout extends StatelessWidget {
  final Widget child;
  const MainLayout({required this.child});

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
                  child: Text(
                    'Menu',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  decoration: BoxDecoration(color: Colors.blue),
                ),
                ...pages.map((page) {
                  bool selected = location == page['path'];
                  return ListTile(
                    selected: selected,
                    selectedTileColor: Colors.blue.shade900,
                    title: Text(
                      page['title']!,
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      if (!selected) {
                        context.go(page['path']!);
                      }
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
                    (p) => p['path'] == location,
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

/// Páginas
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SimplePage(title: 'Bem-vindo à Home!');
}

class Page1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SimplePage(title: 'Página 1');
}

class Page2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SimplePage(title: 'Página 2');
}

class Page3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SimplePage(title: 'Página 3');
}

class Page4 extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SimplePage(title: 'Página 4');
}

class Page5 extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SimplePage(title: 'Página 5');
}

class _SimplePage extends StatelessWidget {
  final String title;
  const _SimplePage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(title, style: TextStyle(fontSize: 24)));
  }
}
