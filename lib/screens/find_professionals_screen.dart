// NOVO FICHEIRO

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ironborn/models/user_model.dart';
import 'package:ironborn/services/connection_service.dart';
import 'package:ironborn/widgets/responsive_layout.dart';

class FindProfessionalsScreen extends StatefulWidget {
  final UserModel currentUser;

  const FindProfessionalsScreen({super.key, required this.currentUser});

  @override
  State<FindProfessionalsScreen> createState() =>
      _FindProfessionalsScreenState();
}

class _FindProfessionalsScreenState extends State<FindProfessionalsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = "";
  UserType? _selectedFilter; // null para todos, ou um tipo específico

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Lógica para enviar o pedido de conexão
  void _sendConnectionRequest(UserModel professional) async {
    final connectionService = ConnectionService();
    // Mostra um indicador de progresso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await connectionService.sendRequest(widget.currentUser, professional);
      if (mounted) {
        Navigator.pop(context); // Fecha o indicador de progresso
        Navigator.pop(context); // Fecha o diálogo de perfil
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Pedido enviado com sucesso!"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fecha o indicador de progresso
        Navigator.pop(context); // Fecha o diálogo de perfil
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Erro: ${e.toString().replaceAll("Exception: ", "")}"),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      appBar: AppBar(
        title: const Text("Encontrar Profissionais"),
      ),
      body: Column(
        children: [
          // Barra de Pesquisa e Filtros
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Pesquisar por nome...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    ChoiceChip(
                      label: const Text('Todos'),
                      selected: _selectedFilter == null,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = null);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Treinadores'),
                      selected: _selectedFilter == UserType.treinador,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = UserType.treinador);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Nutricionistas'),
                      selected: _selectedFilter == UserType.nutricionista,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = UserType.nutricionista);
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
          // Lista de Profissionais
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('userType', whereIn: ['treinador', 'nutricionista'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("Nenhum profissional encontrado."));
                }

                var professionals = snapshot.data!.docs
                    .map((doc) => UserModel.fromMap(
                        doc.data() as Map<String, dynamic>, doc.id))
                    .where((p) => p.id != widget.currentUser.id)
                    .toList();

                if (_selectedFilter != null) {
                  professionals = professionals
                      .where((p) => p.userType == _selectedFilter)
                      .toList();
                }
                if (_searchQuery.isNotEmpty) {
                  professionals = professionals
                      .where((p) =>
                          p.name.toLowerCase().contains(_searchQuery))
                      .toList();
                }

                if (professionals.isEmpty) {
                  return const Center(child: Text("Nenhum profissional corresponde à sua pesquisa."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: professionals.length,
                  itemBuilder: (context, index) {
                    final professional = professionals[index];
                    return _ProfessionalCard(
                      professional: professional,
                      onSendRequest: () => _sendConnectionRequest(professional),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  final UserModel professional;
  final VoidCallback onSendRequest;

  const _ProfessionalCard(
      {required this.professional, required this.onSendRequest});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(professional.name),
              content: SingleChildScrollView(child: Text(professional.bio ?? "Sem biografia disponível.")),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Fechar"),
                ),
                ElevatedButton(
                  onPressed: onSendRequest,
                  child: const Text("Solicitar Acompanhamento"),
                ),
              ],
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage:
                    professional.photoUrl != null && professional.photoUrl!.isNotEmpty
                        ? NetworkImage(professional.photoUrl!)
                        : null,
                child: professional.photoUrl == null ||
                        professional.photoUrl!.isEmpty
                    ? Text(professional.name.isNotEmpty ? professional.name[0] : '?')
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      professional.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      professional.userType.name[0].toUpperCase() +
                          professional.userType.name.substring(1),
                      style: const TextStyle(
                          color: Colors.deepOrangeAccent, fontSize: 12),
                    ),
                    if (professional.specializations != null &&
                        professional.specializations!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        professional.specializations!.join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ]
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

