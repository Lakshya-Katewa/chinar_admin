import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/banner.dart' as model;
import '../../core/providers/banner_provider.dart';

class AddEditBannerDialog extends ConsumerStatefulWidget {
  final model.Banner? banner;
  const AddEditBannerDialog({super.key, this.banner});

  @override
  ConsumerState<AddEditBannerDialog> createState() =>
      _AddEditBannerDialogState();
}

class _AddEditBannerDialogState extends ConsumerState<AddEditBannerDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _targetController;
  late String _actionType;
  late bool _isActive;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final b = widget.banner;
    _titleController = TextEditingController(text: b?.title ?? '');
    _subtitleController = TextEditingController(text: b?.subtitle ?? '');
    _targetController = TextEditingController(text: b?.target ?? '');
    _actionType = b?.actionType ?? 'none';
    _isActive = b?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null && widget.banner == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image.')),
        );
        return;
      }

      final notifier = ref.read(bannerNotifierProvider.notifier);
      final isUpdating = widget.banner != null;

      if (isUpdating) {
        await notifier.updateBanner(
          bannerId: widget.banner!.id!,
          title: _titleController.text.trim(), // Trim empty spaces
          subtitle: _subtitleController.text.trim(),
          actionType: _actionType,
          target: _targetController.text.trim(),
          isActive: _isActive,
          imageFile: _imageFile,
          existingImageUrl: widget.banner!.imageUrl,
        );
      } else {
        await notifier.addBanner(
          title: _titleController.text.trim(),
          subtitle: _subtitleController.text.trim(),
          actionType: _actionType,
          target: _targetController.text.trim(),
          isActive: _isActive,
          imageFile: _imageFile!,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpdating = widget.banner != null;
    final isLoading = ref.watch(bannerNotifierProvider).isLoading;

    return AlertDialog(
      title: Text(isUpdating ? 'Edit Banner' : 'Add Banner'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title (Optional)',
                  hintText: 'Leave blank if not needed',
                ),
                // REMOVED VALIDATOR
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subtitleController,
                decoration: const InputDecoration(
                  labelText: 'Subtitle (Optional)',
                  hintText: 'Leave blank if not needed',
                ),
                // REMOVED VALIDATOR
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _actionType,
                decoration: const InputDecoration(labelText: 'Action Type'),
                items: ['none', 'category', 'product']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _actionType = v!),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _targetController,
                decoration: const InputDecoration(
                  labelText: 'Target (e.g., Category Name or Product ID)',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_imageFile!, fit: BoxFit.cover),
              )
            : (widget.banner?.imageUrl.isNotEmpty == true
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.banner!.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Select Image'),
                      ],
                    )),
      ),
    );
  }
}
