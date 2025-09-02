# Contas para teste:

## User
    Email: user@gmail.com
    Senha: user!@ 
## Nutri
    Email: nutri@gmail.com
    Senha: nutri
## Trainer
    Email: trainer@gmail.com
    Senha: trainer

---

ironborn/
└── lib/  // Contém todo o código-fonte da aplicação Dart/Flutter.
    |
    ├── main.dart  // PONTO DE ENTRADA: Inicializa o Firebase e inicia o app com o AuthGate.
    |
    ├── models/  // Contém as classes que definem a ESTRUTURA DOS DADOS.
    │   ├── user_model.dart  // Define o Usuário (aluno, treinador, nutricionista).
    │   ├── diet_plan_model.dart  // Define o Plano de Dieta e suas sub-estruturas (Refeição, Alimento).
    │   ├── workout_template_model.dart  // Define um Modelo de Treino e seus Exercícios.
    │   ├── workout_schedule_model.dart  // Define a Agenda Semanal que conecta dias a modelos de treino.
    │   └── daily_log_model.dart  // Define o registro diário do aluno (peso, treino concluído).
    |
    ├── screens/  // Contém todas as TELAS (páginas) da aplicação.
    │   ├── auth_gate.dart  // ROTEADOR INICIAL: Verifica se o usuário está logado e se tem perfil, direcionando-o.
    │   ├── home_screen.dart  // ROTEADOR PÓS-LOGIN: Lê o tipo de perfil e exibe o dashboard correto.
    │   |
    │   ├── dashboards/  // Subpasta com as telas principais para cada tipo de perfil.
    │   │   ├── student_dashboard.dart  // DASHBOARD DO ALUNO: Vê treino do dia, dieta e registra progresso.
    │   │   ├── trainer_dashboard.dart  // DASHBOARD DO TREINADOR: Vê sua lista de alunos e os gerencia.
    │   │   └── nutritionist_dashboard.dart  // DASHBOARD DO NUTRICIONISTA: Vê sua lista de pacientes e os gerencia.
    │   |
    │   ├── login_screen.dart  // TELA DE LOGIN: Permite que usuários existentes entrem no app.
    │   ├── register_screen.dart  // TELA DE REGISTRO: Permite que novos usuários criem uma conta.
    │   ├── create_profile_screen.dart  // TELA DE CRIAÇÃO DE PERFIL: Primeiro passo após o registro para definir o papel do usuário.
    │   |
    │   ├── profile_screen.dart  // TELA DE PERFIL: Permite ao usuário ver e editar suas informações básicas (ex: nome).
    │   ├── daily_workout_screen.dart  // TELA DE VISUALIZAÇÃO DO TREINO: Mostra os detalhes do treino do dia para o aluno.
    │   ├── diet_plan_screen.dart  // TELA DE VISUALIZAÇÃO DA DIETA: Mostra os detalhes do plano alimentar para o aluno.
    │   |
    │   ├── student_management_screen.dart  // TELA DE GESTÃO DO ALUNO (para Treinadores): Permite atribuir treinos à agenda semanal.
    │   ├── patient_management_screen.dart  // TELA DE GESTÃO DO PACIENTE (para Nutricionistas): Permite criar/editar o plano alimentar.
    │   ├── workout_templates_screen.dart  // TELA DE LISTA DE TEMPLATES (para Treinadores): Exibe todos os modelos de treino criados.
    │   └── create_edit_template_screen.dart  // TELA DE CRIAÇÃO/EDIÇÃO DE TEMPLATE (para Treinadores): Formulário para criar ou modificar um modelo de treino.
    |
    └── widgets/  // Contém WIDGETS REUTILIZÁVEIS que podem ser usados em várias telas.
        └── responsive_layout.dart  // Garante que o conteúdo tenha uma largura máxima, melhorando a aparência em telas grandes (web/tablet).