# Controle de Gastos com Combustível

Aplicativo Flutter desenvolvido para a **Atividade Substitutiva da Prova 1** da disciplina
*Programação para Dispositivos Móveis II* (Prof. Arley).

## Descrição do aplicativo

O app permite registrar os abastecimentos de um veículo e acompanhar os gastos com combustível
e o consumo ao longo do tempo.

### Cadastro do veículo
- Apenas **um veículo por vez**, com **marca, modelo, ano e cilindrada do motor (cc)**.
- Tipo do veículo: carro, moto ou caminhão.
- **Marcas e modelos consultados na BrasilAPI (Tabela FIPE)**; a lista de modelos é carregada
  de acordo com a **marca escolhida**. As listas têm campo de busca.
- Para cadastrar outro veículo é preciso **excluir o atual**. A exclusão pede **confirmação**
  e apaga também **todos os abastecimentos** dele.

### Registro de abastecimentos
- Tipo de combustível (**etanol, gasolina ou diesel**), **preço por litro (R$)**,
  **quilometragem**, **litros abastecidos** e **data e horário**.
- **Valor total = preço por litro × litros**, calculado na hora enquanto o usuário digita.
- Validações: campos obrigatórios, valores maiores que zero e quilometragem coerente
  (maior que a do abastecimento anterior e menor que a do posterior).
- Os registros podem ser **editados** (toque no item) e **excluídos** (com confirmação).

### Persistência local
- Veículo e abastecimentos ficam salvos no dispositivo e continuam disponíveis depois que o
  app é fechado e aberto de novo (detalhes abaixo).

### Dashboard e gráficos
- Cards de resumo: total gasto, litros, média de km/L e média de R$/km.
- **Gráfico de barras** com o **valor de cada abastecimento**.
- **Gráfico de linha do consumo (km/L)** e **gráfico de linha do custo por km (R$/km)** ao longo
  dos abastecimentos.
- Tabela com o detalhamento de cada abastecimento.

Considerando que **todos os abastecimentos completam o tanque**, a partir do segundo:

| Indicador | Cálculo |
|---|---|
| Distância percorrida | km atual − km do abastecimento anterior |
| Consumo (km/L) | distância ÷ litros do abastecimento atual |
| Custo (R$/km) | valor total do abastecimento atual ÷ distância |

O **primeiro abastecimento é a referência inicial** e não mostra km/L nem R$/km.
Os abastecimentos são ordenados por data e horário para o cálculo.

### Navegação
- Sem veículo: tela inicial com botão **Cadastrar veículo** → tela de cadastro → telas de seleção de marca/modelo.
- Com veículo: barra inferior com **Abastecimentos**, **Dashboard** e **Veículo**; o botão
  **Abastecer** abre a tela de registro.

## Estrutura do projeto

```
lib/
├── main.dart
├── models/
│   ├── veiculo.dart                 # Veículo e tipo de veículo
│   └── abastecimento.dart           # Abastecimento, combustível e indicadores
├── services/
│   ├── fipe_service.dart            # Consulta à BrasilAPI (marcas e modelos)
│   ├── storage_service.dart         # Persistência local
│   └── calculos.dart                # km/L, R$/km, distância e validações
├── utils/
│   └── formatos.dart                # Moeda, números e datas em pt-BR
└── screens/
    ├── inicio_screen.dart           # Tela principal e navegação
    ├── veiculo_form_screen.dart     # Cadastro do veículo
    ├── selecao_screen.dart          # Seleção de marca/modelo com busca
    ├── abastecimento_form_screen.dart
    └── dashboard_screen.dart        # Indicadores e gráficos
test/
└── calculos_test.dart               # Testes dos cálculos
```

## Como executar

Pré-requisito: [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.19 ou superior.

```bash
git clone <URL_DO_REPOSITORIO>
cd controle_combustivel

# gera as pastas de plataforma (android/, ios/, web/, windows/...) se não existirem
flutter create .

flutter pub get
flutter run

# testes
flutter test
```

**Android:** confira se `android/app/src/main/AndroidManifest.xml` tem a permissão de internet
(fora da tag `<application>`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## API utilizada

**BrasilAPI – Tabela FIPE** (https://brasilapi.com.br/docs#tag/FIPE)

| Endpoint | Uso |
|---|---|
| `GET https://brasilapi.com.br/api/fipe/marcas/v1/{tipoVeiculo}` | Lista de marcas (`carros`, `motos` ou `caminhoes`) |
| `GET https://brasilapi.com.br/api/fipe/veiculos/v1/{tipoVeiculo}/{codigoMarca}` | Modelos da marca escolhida |

Falhas de conexão, tempo esgotado e respostas inválidas mostram mensagem com opção de tentar novamente.

## Bibliotecas adotadas

| Biblioteca | Uso |
|---|---|
| [`http`](https://pub.dev/packages/http) | Requisições à BrasilAPI |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | Persistência local |
| [`fl_chart`](https://pub.dev/packages/fl_chart) | Gráficos de barras e de linha do dashboard |
| [`intl`](https://pub.dev/packages/intl) | Formatação de moeda, números e datas em pt-BR |

### Estratégia de persistência

Os dados são salvos com `shared_preferences`, serializados em **JSON**, pela classe `StorageService`:

| Chave | Conteúdo |
|---|---|
| `veiculo` | JSON do único veículo cadastrado |
| `abastecimentos` | Lista de JSON com os abastecimentos do veículo |

Ao excluir o veículo as duas chaves são removidas, apagando também os abastecimentos.

## Capturas de tela

| Cadastro do veículo | Abastecimentos | Novo abastecimento | Dashboard |
|---|---|---|---|
| ![Veículo](screenshots/veiculo.png) | ![Lista](screenshots/abastecimentos.png) | ![Formulário](screenshots/novo_abastecimento.png) | ![Dashboard](screenshots/dashboard.png) |

> Rode o app, tire os prints e salve na pasta `screenshots/` com os nomes acima.
