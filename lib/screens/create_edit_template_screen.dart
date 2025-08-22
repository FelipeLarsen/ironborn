import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/workout_template_model.dart';

class CreateEditTemplateScreen extends StatefulWidget {
  final WorkoutTemplateModel? template;

  const CreateEditTemplateScreen({super.key, this.template});

  @override
  State<CreateEditTemplateScreen> createState() => _CreateEditTemplateScreenState();
}

class _CreateEditTemplateScreenState extends State<CreateEditTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  List<Exercise> _exercises = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _nameController.text = widget.template!.name;
      _exercises = List.from(widget.template!.exercises);
    }
  }

  void _addExercise() {
    setState(() {
      _exercises.add(Exercise(name: '', sets: '', reps: ''));
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final newTemplate = WorkoutTemplateModel(
      id: widget.template?.id,
      creatorId: currentUser.uid,
      name: _nameController.text.trim(),
      exercises: _exercises,
    );

    try {
      final collection = FirebaseFirestore.instance.collection('workoutTemplates');
      if (newTemplate.id == null) {
        await collection.add(newTemplate.toMap());
      } else {
        await collection.doc(newTemplate.id).update(newTemplate.toMap());
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template == null ? 'Criar Modelo' : 'Editar Modelo'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _saveTemplate),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome do Modelo'),
                validator: (value) =>
                    value!.isEmpty ? 'Por favor, insira um nome' : null,
              ),
              const SizedBox(height: 24),
              const Text('Exercícios', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _exercises.length,
                itemBuilder: (context, index) {
                  return _buildExerciseTile(index);
                },
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Adicionar Exercício'),
                onPressed: _addExercise,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseTile(int index) {
    final nameController = TextEditingController(text: _exercises[index].name);
    final setsController = TextEditingController(text: _exercises[index].sets);
    final repsController = TextEditingController(text: _exercises[index].reps);

    nameController.addListener(() => _exercises[index] = Exercise(name: nameController.text, sets: _exercises[index].sets, reps: _exercises[index].reps));
    setsController.addListener(() => _exercises[index] = Exercise(name: _exercises[index].name, sets: setsController.text, reps: _exercises[index].reps));
    repsController.addListener(() => _exercises[index] = Exercise(name: _exercises[index].name, sets: _exercises[index].sets, reps: repsController.text));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome do Exercício'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: setsController,
                    decoration: const InputDecoration(labelText: 'Séries'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: repsController,
                    decoration: const InputDecoration(labelText: 'Reps'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _removeExercise(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}