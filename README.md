Minhas Finanças

Flutter


Minhas Finanças é um aplicativo de gerenciamento financeiro pessoal desenvolvido em Flutter, projetado para ajudar usuários a organizar suas finanças, acompanhar receitas e despesas, definir metas financeiras e visualizar relatórios detalhados. Com uma interface amigável, suporte a personalização e recursos avançados como autenticação e backups automáticos, é uma ferramenta poderosa para controle financeiro no dia a dia.
Funcionalidades
Gerenciamento de Transações:
Adição, edição e exclusão de receitas e despesas com suporte a parcelamento.

Filtros por tipo, período, categoria e pesquisa por texto.

Transações recorrentes (diárias, semanais, mensais, anuais) com notificações automáticas.

Metas Financeiras:
Criação e acompanhamento de metas com valor alvo e prazo.

Progresso visualizado com barras e integração com receitas.

Relatórios Financeiros:
Gráficos de pizza para receitas e despesas por categoria.

Exportação de relatórios em CSV ou PDF.

Personalização:
Temas predefinidos (claro, escuro, AMOLED, roxo, etc.) e personalizados com cores ajustáveis.

Suporte a moedas (BRL, USD, EUR).

Segurança:
Autenticação via PIN de 6 dígitos ou biometria (impressão digital/facial).

Gerenciamento de acesso seguro.

Gerenciamento de Categorias:
Criação, renomeação e exclusão de categorias personalizadas.

Backup e Recuperação:
Backup automático configurável (diário, semanal, mensal) para armazenamento local.

Exportação e importação manual do banco de dados.

Registro de Erros:
Visualização de logs de erros para depuração.

Capturas de Tela
| Tela Inicial | Metas Financeiras | Relatórios |
|--------------|-------------------|------------|
| ![Home](screenshoots/Home.png) | ![Goals](screenshoots/Metas.png) | ![Reports](screenshoots/Graficos.png) |

Como Executar o Projeto
Pré-requisitos
Flutter (versão 3.x ou superior)
Dart (versão 2.x ou superior)

Tecnologias Utilizadas
Flutter: Framework principal para construção da UI multiplataforma.

Dart: Linguagem de programação.

SQLite: Banco de dados local via sqflite.

Provider: Gerenciamento de estado.

Dependências principais:
flutter_local_notifications: Notificações recorrentes.

local_auth: Autenticação biométrica.

fl_chart: Gráficos financeiros.

shared_preferences: Armazenamento de configurações.

flutter_background_service: Backup automático.

intl: Formatação de datas e moedas.

Veja todas as dependências no arquivo pubspec.yaml.

Licença
Este projeto está licenciado sob a [Licença MIT](LICENSE.md).


Desenvolvido por Leonardo Brandão.

