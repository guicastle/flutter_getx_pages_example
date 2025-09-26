import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => HomePage()),
        GetPage(name: '/page1', page: () => Page1()),
        GetPage(name: '/page2', page: () => Page2()),
        GetPage(name: '/page3', page: () => Page3()),
        GetPage(name: '/page4', page: () => Page4()),
        GetPage(name: '/page5', page: () => Page5()),
      ],
    ),
  );
}

/// Página principal com Drawer
class HomePage extends StatelessWidget {
  final drawerItems = [
    {'title': 'Página 1', 'route': '/page1'},
    {'title': 'Página 2', 'route': '/page2'},
    {'title': 'Página 3', 'route': '/page3'},
    {'title': 'Página 4', 'route': '/page4'},
    {'title': 'Página 5', 'route': '/page5'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home com Drawer')),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Text(
                'Menu',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
              decoration: BoxDecoration(color: Colors.blue),
            ),
            ...drawerItems.map((item) {
              return ListTile(
                title: Text(item['title']!),
                onTap: () {
                  Get.back(); // Fecha o Drawer
                  Get.toNamed(item['route']!); // Vai para a rota sem o Drawer
                },
              );
            }).toList(),
          ],
        ),
      ),
      body: Center(
        child: Text(
          'Bem-vindo! Abra o menu para navegar.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

/// Páginas sem Drawer
class Page1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SimplePage(title: 'Página 1');
  }
}

class Page2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SimplePage(title: 'Página 2');
  }
}

class Page3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SimplePage(title: 'Página 3');
  }
}

class Page4 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SimplePage(title: 'Página 4');
  }
}

class Page5 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SimplePage(title: 'Página 5');
  }
}

/// Widget base para páginas sem Drawer
class _SimplePage extends StatelessWidget {
  final String title;
  const _SimplePage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Get.offAllNamed('/'),
              child: Text('Voltar para Home'),
            ),
          ],
        ),
      ),
    );
  }
}
