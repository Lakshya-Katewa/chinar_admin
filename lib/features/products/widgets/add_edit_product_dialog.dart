// add_edit_dialog_product.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/models/product.dart';
import '../../../core/providers/product_provider.dart';
import '../../../core/services/firebase_service.dart'; // Import FirebaseService

class AddEditProductDialog extends ConsumerStatefulWidget {
  final Product? product;

  const AddEditProductDialog({super.key, this.product});

  @override
  ConsumerState<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends ConsumerState<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  // We no longer need the imageUrlController, as the URL is managed dynamically
  
  ProductUnit _selectedUnit = ProductUnit.liter;
  ProductType _selectedType = ProductType.oneTimeOnly;
  ProductCategory _selectedCategory = ProductCategory.milk;
  bool _isLoading = false;
  File? _selectedImage;
  String? _existingImageUrl; // To hold the initial image URL
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _descriptionController.text = widget.product!.description;
      _existingImageUrl = widget.product!.imageUrl; // Store the existing URL
      _selectedUnit = widget.product!.unit;
      _selectedType = widget.product!.type;
      _selectedCategory = widget.product!.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Widget _buildImagePreview() {
    // If a new image is selected, show it from the file
    if (_selectedImage != null) {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _selectedImage!,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedImage = null;
                }),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      );
    // If there's an existing URL and no new image, show it from the network
    } else if (_existingImageUrl != null) {
       return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _existingImageUrl!,
            height: 100,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 100,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
              );
            },
          ),
        ),
      );
    // Otherwise, show the placeholder
    } else {
       return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, color: Colors.grey.shade400, size: 32),
            const SizedBox(height: 4),
            Text('No image', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      );
    }
  }

  // --- MODIFIED LOGIC ---
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      String? uploadedImageUrl = _existingImageUrl; // Start with the old URL

      // Determine if this is a new product or an update
      final bool isUpdating = widget.product != null;
      final String productId = widget.product?.id ?? const Uuid().v4();

      // If a new image was selected, upload it
      if (_selectedImage != null) {
        uploadedImageUrl = await FirebaseService.uploadProductImage(
          file: _selectedImage!,
          productId: productId,
        );
      }

      final productData = Product(
        id: productId,
        name: _nameController.text,
        price: double.parse(_priceController.text),
        description: _descriptionController.text,
        unit: _selectedUnit,
        category: _selectedCategory,
        type: _selectedType,
        imageUrl: uploadedImageUrl,
        isActive: true,
        createdAt: widget.product?.createdAt ?? now,
        updatedAt: now,
      );

      if (isUpdating) {
        await ref.read(productNotifierProvider).updateProduct(productData);
      } else {
        // Since addProduct now returns a string, we don't need to await it here
        // if we have the ID already. But if the image was uploaded with a temp
        // ID, we might need to update the product with the real ID later.
        // For simplicity, this flow works well.
        await ref.read(productNotifierProvider).addProduct(productData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isUpdating ? 'Product updated successfully' : 'Product added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving product: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    // ... (Your build method remains the same)
    // Just make sure you are not using _imageUrlController in it anymore.
    // The rest of the file (from build method down) is correct.
    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(widget.product == null ? Icons.add : Icons.edit, 
                       color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    widget.product == null ? 'Add Product' : 'Edit Product',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImagePreview(),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.upload, size: 18),
                                label: const Text('Upload Image'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Product Name *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.shopping_bag),
                          ),
                          validator: (value) => value?.isEmpty == true ? 'Please enter product name' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Price (₹) *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.currency_rupee),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Please enter price';
                            if (double.tryParse(value!) == null) return 'Please enter a valid price';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 2,
                          validator: (value) => value?.isEmpty == true ? 'Please enter description' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<ProductCategory>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: ProductCategory.values.map((category) {
                            String text = switch (category) {
                              ProductCategory.milk => 'Milk',
                              ProductCategory.paneer => 'Paneer',
                              ProductCategory.cheese => 'Cheese',
                            };
                            return DropdownMenuItem(value: category, child: Text(text));
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedCategory = value!),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<ProductUnit>(
                          value: _selectedUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unit *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.straighten),
                          ),
                          items: ProductUnit.values.map((unit) {
                            String text = switch (unit) {
                              ProductUnit.liter => 'Liter',
                              ProductUnit.kg => 'Kg',
                              ProductUnit.piece => 'Piece',
                            };
                            return DropdownMenuItem(value: unit, child: Text(text));
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedUnit = value!),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<ProductType>(
                          value: _selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Type *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.type_specimen),
                          ),
                          items: ProductType.values.map((type) {
                            String text = switch (type) {
                              ProductType.oneTimeOnly => 'One Time',
                              ProductType.general => 'General',
                              ProductType.subscription => 'Subscription',
                            };
                            return DropdownMenuItem(value: type, child: Text(text));
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedType = value!),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProduct,
                    child: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(widget.product == null ? 'Add Product' : 'Update Product'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}