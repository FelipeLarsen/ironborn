// ARQUIVO ATUALIZADO E FINAL

import 'package:flutter/material.dart';

// Este é o nosso widget reutilizável e robusto para criar layouts responsivos.
class ResponsiveLayout extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const ResponsiveLayout({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    // ALTERADO: O Scaffold principal agora está envolvido por um SafeArea.
    // Isto garante que todos os ecrãs que usem este layout respeitarão
    // as barras de navegação do sistema operativo (em cima e em baixo).
    return SafeArea(
      child: Scaffold(
        appBar: appBar,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: body,
          ),
        ),
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}

