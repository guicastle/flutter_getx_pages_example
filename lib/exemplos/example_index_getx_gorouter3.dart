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
    // Rotas com Drawer
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => HomePage()),
        GoRoute(path: '/pagina1', builder: (context, state) => Page1()),
        GoRoute(path: '/pagina2', builder: (context, state) => Page2()),
      ],
    ),

    // Rotas sem Drawer, com botão voltar
    GoRoute(
      path: '/pagina1/:itemId',
      builder: (context, state) {
        final itemId = state.pathParameters['itemId']!;
        return ItemPage(itemId: itemId);
      },
    ),

    // Tela sem Drawer, ex login
    GoRoute(path: '/login', builder: (context, state) => LoginPage()),
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
        for (var id in [1, 2, 3])
          ListTile(
            title: Text('Item $id'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () => context.push('/pagina1/$id'),
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
        title: Text('Detalhes do Item $itemId'),
        leading: BackButton(onPressed: () => GoRouter.of(context).pop()),
      ),
      body: Center(
        child: Text(
          'Informações detalhadas do item $itemId',
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
