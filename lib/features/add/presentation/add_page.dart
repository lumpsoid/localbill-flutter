import 'package:flutter/material.dart';

import 'add_controller.dart';
import 'models/add_state.dart';

class AddPage extends StatefulWidget {
  const AddPage({required this.controller, super.key});

  final AddController controller;

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  late final ValueNotifier<AddState> _state;
  final _formKey = GlobalKey<FormState>();

  final _dateCtrl = TextEditingController();
  final _retailerCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');
  final _unitPriceCtrl = TextEditingController();
  final _priceTotalCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController(text: 'RSD');
  final _countryCtrl = TextEditingController(text: 'serbia');
  final _linkCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _state = ValueNotifier(const AddState());
    // Pre-fill date with now.
    final now = DateTime.now();
    _dateCtrl.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}T'
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    widget.controller.onViewAttach(
      updater: (s) => _state.value = s,
      pusher: _onEffect,
    );
  }

  void _onEffect(AddEffect effect) {
    if (!mounted) return;
    switch (effect) {
      case AddSuccessEffect():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction saved.')),
        );
        _resetForm();
      case AddErrorEffect(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $message')));
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    final now = DateTime.now();
    _dateCtrl.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}T'
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    _retailerCtrl.clear();
    _nameCtrl.clear();
    _quantityCtrl.text = '1';
    _unitPriceCtrl.clear();
    _priceTotalCtrl.clear();
    _currencyCtrl.text = 'RSD';
    _countryCtrl.text = 'serbia';
    _linkCtrl.clear();
    _notesCtrl.clear();
  }

  @override
  void dispose() {
    widget.controller.onViewDetach();
    _state.dispose();
    for (final c in [
      _dateCtrl, _retailerCtrl, _nameCtrl, _quantityCtrl,
      _unitPriceCtrl, _priceTotalCtrl, _currencyCtrl, _countryCtrl,
      _linkCtrl, _notesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AddState>(
      valueListenable: _state,
      builder: (context, state, _) {
        final isSaving = state.status == AddStatus.saving;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(_dateCtrl, 'Date (ISO 8601)', required: true),
                _field(_retailerCtrl, 'Retailer', required: true),
                _field(_nameCtrl, 'Product name', required: true),
                _numField(_quantityCtrl, 'Quantity', required: true),
                _numField(_unitPriceCtrl, 'Unit price', required: true),
                _numField(_priceTotalCtrl, 'Total price', required: true),
                _field(_currencyCtrl, 'Currency'),
                _field(_countryCtrl, 'Country'),
                _field(_linkCtrl, 'Invoice URL (optional)'),
                _field(_notesCtrl, 'Notes (optional)', maxLines: 3),
                const SizedBox(height: 20),
                if (isSaving)
                  const Center(child: CircularProgressIndicator())
                else
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save transaction'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        maxLines: maxLines,
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }

  Widget _numField(
    TextEditingController ctrl,
    String label, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) return 'Required';
          if (v != null && v.trim().isNotEmpty && double.tryParse(v) == null) {
            return 'Must be a number';
          }
          return null;
        },
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.controller.onSave(
      date: _dateCtrl.text.trim(),
      retailer: _retailerCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      quantity: double.tryParse(_quantityCtrl.text) ?? 1,
      unitPrice: double.tryParse(_unitPriceCtrl.text) ?? 0,
      priceTotal: double.tryParse(_priceTotalCtrl.text) ?? 0,
      currency: _currencyCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      link: _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
  }
}
