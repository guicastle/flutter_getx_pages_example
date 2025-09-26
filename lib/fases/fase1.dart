import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Ponto de entrada da aplicação.
// Configura o GetMaterialApp, que é a base para usarmos o GetX para
// gerenciamento de estado e, futuramente, rotas.
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Web Navigation - Fase 1',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // A tela inicial da nossa aplicação é o layout principal.
      home: MainLayout(),
    );
  }
}

// --- CONTROLLER ---
// Responsável por gerenciar o estado da navegação principal.
// Ele detém o "índice da página selecionada" como uma variável reativa (.obs).
class NavigationController extends GetxController {
  // RxInt é um tipo observável do GetX. A UI vai reagir automaticamente
  // a qualquer mudança em seu valor.
  final RxInt selectedIndex = 0.obs;

  // Método público para alterar o índice. Será chamado pelos itens do Drawer.
  void changeIndex(int index) {
    selectedIndex.value = index;
  }
}

// --- LAYOUT PRINCIPAL ---
// Este widget constrói a estrutura visual da aplicação: Drawer fixo + Área de conteúdo.
class MainLayout extends StatelessWidget {
  MainLayout({super.key});

  // Instancia e registra o NavigationController na memória usando Get.put().
  // Isso o torna disponível para qualquer widget filho que o procure com Get.find().
  final NavigationController controller = Get.put(NavigationController());

  // Lista de páginas que serão exibidas no IndexedStack.
  // Instanciamos elas apenas uma vez aqui para garantir que seu estado seja preservado.
  final List<Widget> pages = [const HomePage(), const Page1(), const Page2()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // O Drawer (menu lateral) é o primeiro filho da Row.
          const CustomDrawer(),

          // A área de conteúdo usa Expanded para ocupar todo o espaço restante.
          Expanded(
            // Obx é um widget do GetX que reconstrói seu filho sempre que uma
            // variável observável dentro dele (aqui, controller.selectedIndex) muda.
            child: Obx(
              () => IndexedStack(
                // O índice do IndexedStack é vinculado diretamente ao valor
                // do nosso controller. Mudar um, muda o outro.
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

// --- WIDGETS DO LAYOUT ---

// O menu lateral customizado e fixo.
class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Encontra a instância do NavigationController que foi criada no MainLayout.
    final NavigationController controller = Get.find();

    return Obx(
      // O Obx garante que o Drawer se reconstrua para atualizar o destaque
      // visual (propriedade 'selected') sempre que o índice mudar.
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
            // Cada ListTile representa um item de menu.
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              // A propriedade 'selected' controla o destaque visual.
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
// Widgets simples e estáticos para representar cada tela.
// Adicionamos um TextField em uma delas para facilitar o teste de preservação de estado.

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
