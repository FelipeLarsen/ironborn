// ARQUIVO ATUALIZADO: lib/screens/create_edit_template_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ironborn/models/workout_template_model.dart';
import 'package:ironborn/widgets/responsive_layout.dart';

class CreateEditTemplateScreen extends StatefulWidget {
  final WorkoutTemplateModel? template;

  const CreateEditTemplateScreen({super.key, this.template});

  @override
  State<CreateEditTemplateScreen> createState() =>
      _CreateEditTemplateScreenState();
}

class _CreateEditTemplateScreenState
    extends State<CreateEditTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  List<Exercise> _exercises = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _nameController.text = widget.template!.name;
      // A cópia já era segura, mantemos como está.
      _exercises = List<Exercise>.from(widget.template!.exercises);
    }
  }

  void _addExercise() {
    setState(() {
      // Usa o construtor 'const' do modelo imutável.
      _exercises.add(const Exercise(name: '', sets: '', reps: ''));
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validação para garantir que há pelo menos um exercício.
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Adicione pelo menos um exercício ao modelo."),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    setState(() => _isLoading = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Usa construtor 'const' do modelo principal.
    final template = WorkoutTemplateModel(
      id: widget.template?.id ?? '', // O Firestore gerará o ID se for novo.
      name: _nameController.text.trim(),
      trainerId: FirebaseAuth.instance.currentUser!.uid,
      exercises: _exercises,
    );

    try {
      if (widget.template == null) {
        // Criar novo
        await FirebaseFirestore.instance
            .collection('workoutTemplates')
            .add(template.toMap());
      } else {
        // Atualizar existente
        await FirebaseFirestore.instance
            .collection('workoutTemplates')
            .doc(widget.template!.id)
            .update(template.toMap());
      }
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
        content: Text("Modelo salvo com sucesso!"),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text("Erro ao salvar o modelo: $e"),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // NOVO: Função para atualizar um exercício de forma imutável.
  void _updateExercise(int index, {String? name, String? sets, String? reps}) {
    setState(() {
      final currentExercise = _exercises[index];
      _exercises[index] = currentExercise.copyWith(
        name: name,
        sets: sets,
        reps: reps,
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      appBar: AppBar(
        title: Text(
            widget.template == null ? 'Criar Novo Modelo' : 'Editar Modelo'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveTemplate,
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Modelo',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira um nome para o modelo.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text('Exercícios', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_exercises.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('A lista de exercícios aparecerá aqui.'),
                ),
              ),
            ..._exercises.asMap().entries.map((entry) {
              int index = entry.key;
              Exercise exercise = entry.value;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        // ALTERADO: Usa 'initialValue' para ser compatível com o padrão imutável.
                        initialValue: exercise.name,
                        decoration: InputDecoration(
                          labelText: 'Nome do Exercício',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            onPressed: () => _removeExercise(index),
                          ),
                        ),
                        // ALTERADO: Chama a função _updateExercise para uma atualização de estado explícita.
                        onChanged: (value) => _updateExercise(index, name: value),
                        validator: (v) => v!.isEmpty ? 'O nome é obrigatório.' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: exercise.sets,
                              decoration:
                                  const InputDecoration(labelText: 'Séries'),
                              onChanged: (value) => _updateExercise(index, sets: value),
                              validator: (v) => v!.isEmpty ? 'Obrigatório.' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: exercise.reps,
                              decoration:
                                  const InputDecoration(labelText: 'Reps'),
                              onChanged: (value) => _updateExercise(index, reps: value),
                              validator: (v) => v!.isEmpty ? 'Obrigatório.' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Exercício'),
            ),
          ],
        ),
      ),
    );
  }
}