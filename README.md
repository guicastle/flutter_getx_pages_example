## 📦 `flutter_getx_pages_example`

## 🧩 Problema principal

O uso de `Get.offNamed()` no seu código **recria toda a árvore de widgets**, o que causa **piscadas (flickering)** e faz com que o `Drawer` seja reconstruído toda vez — mesmo parecendo fixo.

Para evitar esse problema, a melhor abordagem é **manter o Drawer e a navegação dentro da mesma estrutura**, usando uma estratégia baseada em **estado interno** (como `IndexedStack` ou `PageController`) — **em vez de usar rotas do GetX diretamente**.

---

## ✅ Solução sugerida: `StatefulWidget` com `IndexedStack`

Isso permite:

* Drawer fixo ✅
* Alternância entre páginas sem reconstrução do layout ✅
* Transições suaves ✅

### Mas... e no Flutter Web?

Se você quer URLs amigáveis como `/pagina1`, `/pagina2`, **e** quer evitar flickering mantendo o Drawer fixo, a solução precisa combinar:

* Navegação declarativa (via URL)
* Controle de estado interno (via `IndexedStack` ou similar)

---

## 🧠 O dilema:

| Situação                                         | Resultado                             |
| ------------------------------------------------ | ------------------------------------- |
| Usar `Get.offNamed()` ou `Navigator.pushNamed()` | Recria widgets → ❌ flickering         |
| Usar `IndexedStack`                              | Layout fixo → ✅, mas não altera URL ❌ |

---

## ✅ Solução ideal: **Sincronizar o estado com a URL (Manual Routing)**

Você pode usar:

* [`go_router`](https://pub.dev/packages/go_router) (**recomendado para web**)
* `Router`, `RouteInformationParser`, etc.
* `GetX` com `Get.rootDelegate` (menos comum hoje)

---

## 📌 Dois problemas se cruzando:

### ❗ Problema 1: `push()` vs `go()`

| Método           | Comportamento                                                |
| ---------------- | ------------------------------------------------------------ |
| `context.push()` | Empilha a nova rota → **mantém layout atual (ShellRoute)** ✅ |
| `context.go()`   | Substitui rota atual → **sai do ShellRoute, perde layout** ❌ |

---

### ❗ Problema 2: Subrotas com ou sem `Drawer`

Você quer navegar entre:

```
/pagina1 → /pagina1/item1 → /pagina1/item1/detalhes
```

Requisitos:

* URL correta ✅
* Botão de voltar funcionando ✅
* **Sem Drawer nas subpáginas** ❌

---

## ✅ Solução final com boas práticas

### 1. `ShellRoute` só para páginas com `Drawer`:

```dart
ShellRoute(
  builder: (context, state, child) => MainLayout(child: child),
  routes: [
    GoRoute(path: '/', builder: (context, state) => HomePage()),
    GoRoute(path: '/pagina1', builder: (context, state) => Page1()),
    GoRoute(path: '/pagina2', builder: (context, state) => Page2()),
  ],
),
```

---

### 2. Subrotas **fora do `ShellRoute`**, sem Drawer:

```dart
GoRoute(
  path: '/pagina1/:itemId',
  builder: (context, state) {
    final itemId = state.pathParameters['itemId']!;
    return ItemPage(itemId: itemId);
  },
  routes: [
    GoRoute(
      path: 'detalhes',
      builder: (context, state) {
        final itemId = state.pathParameters['itemId']!;
        return DetalhePage(itemId: itemId);
      },
    ),
  ],
),
```

---

### 3. Use `.push()` com rota completa:

```dart
onTap: () => context.push('/pagina1/$id'),
```

---

## 🔁 Resultado esperado

| Caminho                   | Drawer? | Voltar? | URL? |
| ------------------------- | ------- | ------- | ---- |
| `/pagina1`                | ✅       | —       | ✅    |
| `/pagina1/item1`          | ❌       | ✅       | ✅    |
| `/pagina1/item1/detalhes` | ❌       | ✅       | ✅    |

---

### ✅ Por que funciona?

* `push()` → mantém empilhamento.
* Rota `/pagina1/:itemId` está **fora do `ShellRoute`** → não recebe o Drawer.
* Rota absoluta (`/pagina1/item1`) usada → URL correta.

---

### 🔧 Dica extra: não precisa de `BackButton` personalizado

Ao invés de:

```dart
leading: BackButton(onPressed: () => GoRouter.of(context).pop()),
```

Use:

```dart
appBar: AppBar(
  title: Text('Detalhes do $itemId'),
)
```

O `automaticallyImplyLeading: true` já cuida disso. O Flutter mostrará o botão de voltar automaticamente com comportamento padrão.

---

## 📚 Extras: integração com outras libs

### 1. `navigation_history_observer`

* Observa o **histórico de navegação** (push, pop, etc.).
* Permite:

  * Saber qual página o usuário entrou/saiu.
  * Criar lógica de "voltar para onde estava".
  * Usar com analytics, logs, auditoria.

👉 **Com GetX**:

* GetX gerencia rotas (`Get.to`, `Get.off`, etc.).
* Mas não expõe histórico completo.
* Use `navigation_history_observer` para **ouvir eventos de navegação**, mesmo com GetX.
* Exemplo: logar rota no Firebase Analytics quando a página muda.

---

### 2. `app_links`

* Gerencia **deep links** e **universal links**:

  * `meuapp://produto/10`
  * `https://minhaloja.com/produto/10`

* Permite:

  * Abrir uma rota do app a partir de um link externo.
  * Campanhas de marketing com links diretos para o app.

👉 **Com GetX**:

* Combine com `Get.toNamed('/rota')` para redirecionar a partir de links externos.

---

## 🔄 Analogia simples

Imagine que seu app é um **shopping center**:

| Item                            | Equivalência                                            |
| ------------------------------- | ------------------------------------------------------- |
| **GetX**                        | Mapa oficial do shopping – te leva de uma loja a outra. |
| **navigation_history_observer** | Segurança do shopping – anota por onde você passou.     |
| **app_links**                   | Convite do WhatsApp – já te leva direto à loja certa.   |

---

## 🧪 Resumo prático

| Lib                           | Para que serve                                       |
| ----------------------------- | ---------------------------------------------------- |
| `GetX`                        | Gerenciar navegação interna do app                   |
| `navigation_history_observer` | Monitorar histórico de navegação (analytics, lógica) |
| `app_links`                   | Abrir o app via links externos (deep/universal)      |

---

## ⚙️ mini projeto Flutter com GetX funcionando :)

👉 by @kads

---


