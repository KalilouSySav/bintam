import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bintam/utils/pick_image_as_base64_string.dart';

import '../controllers/product_controller.dart';
import '../models/product_model.dart';

class ProductDialog extends StatefulWidget {
  final ProductModel? product;

  const ProductDialog({Key? key, this.product}) : super(key: key);

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prixController = TextEditingController();
  final _categorieController = TextEditingController();
  final _stockController = TextEditingController();
  bool _estEcologique = false;
  bool _isLoading = false;
  bool _isPickingFile = false;

  String? _imagePath;
  List<String> _secondaryImagePaths = [];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nomController.text = widget.product!.nom;
      _descriptionController.text = widget.product!.description;
      _prixController.text = widget.product!.prix.toString();
      _categorieController.text = widget.product!.categorie;
      _stockController.text = widget.product!.stock.toString();
      _estEcologique = widget.product!.estEcologique;
      _imagePath = widget.product!.imageUrl;
      _secondaryImagePaths = widget.product!.imagesSecondaires;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Ajouter un produit' : 'Modifier le produit'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer un nom';
                    }
                    if (value.trim().length < 2) {
                      return 'Le nom doit contenir au moins 2 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer une description';
                    }
                    if (value.trim().length < 10) {
                      return 'La description doit contenir au moins 10 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _prixController,
                  decoration: const InputDecoration(
                    labelText: 'Prix (\$)',
                    hintText: '0.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer un prix';
                    }
                    final prix = double.tryParse(value.trim());
                    if (prix == null) {
                      return 'Veuillez entrer un nombre valide';
                    }
                    if (prix < 0) {
                      return 'Le prix ne peut pas être négatif';
                    }
                    if (prix > 999999) {
                      return 'Le prix est trop élevé';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categorieController,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer une catégorie';
                    }
                    if (value.trim().length < 2) {
                      return 'La catégorie doit contenir au moins 2 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock',
                    hintText: '0',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer un stock';
                    }
                    final stock = int.tryParse(value.trim());
                    if (stock == null) {
                      return 'Veuillez entrer un nombre entier valide';
                    }
                    if (stock < 0) {
                      return 'Le stock ne peut pas être négatif';
                    }
                    if (stock > 999999) {
                      return 'Le stock est trop élevé';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Image principale',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (_imagePath != null) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Image sélectionnée',
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _imagePath = null;
                                    });
                                  },
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.grey, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Aucune image sélectionnée',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: _isPickingFile
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : const Icon(Icons.upload_file),
                            label: Text(_isPickingFile
                                ? 'Sélection en cours...'
                                : 'Choisir une image'),
                            onPressed: _isPickingFile ? null : _pickImage,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Images secondaires',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (_secondaryImagePaths.isNotEmpty) ...[
                          Column(
                            children: _secondaryImagePaths.map((imagePath) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: Colors.green, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Image sélectionnée',
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _secondaryImagePaths.remove(imagePath);
                                        });
                                      },
                                      child: const Text('Supprimer'),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.grey, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Aucune image secondaire sélectionnée',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: _isPickingFile
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : const Icon(Icons.upload_file),
                            label: Text(_isPickingFile
                                ? 'Sélection en cours...'
                                : 'Ajouter des images secondaires'),
                            onPressed: _isPickingFile ? null : _pickSecondaryImages,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Produit écologique'),
                  subtitle: const Text('Ce produit respecte l\'environnement'),
                  value: _estEcologique,
                  onChanged: _isLoading ? null : (value) {
                    setState(() {
                      _estEcologique = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    setState(() {
      _isPickingFile = true;
    });

    try {
      // final path = await pickImageAsBase64String();
      final path = await  await pickImageAndUploadToAWS(
        awsBucketUrl: 'https://bintam.s3.amazonaws.com',
        awsFolder: 'product_images',
      );

      if (mounted) {
        setState(() {
          _isPickingFile = false;
          if (path != null) {
            _imagePath = path;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image sélectionnée avec succès!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPickingFile = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _pickSecondaryImages() async {
    setState(() {
      _isPickingFile = true;
    });

    try {
      // final paths = await pickImagesAsBase64Strings();
      final paths = await pickAndUploadMultipleImagesToAWS(
        awsBucketUrl: 'https://bintam.s3.amazonaws.com',
        awsFolder: 'product_images/',
      );
      if (mounted) {
        setState(() {
          _isPickingFile = false;
          if (paths != null) {
            _secondaryImagePaths.addAll(paths);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Images secondaires sélectionnées avec succès!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPickingFile = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection des images: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final product = ProductModel(
        id: widget.product?.id ?? '',
        nom: _nomController.text.trim(),
        description: _descriptionController.text.trim(),
        prix: double.parse(_prixController.text.trim()),
        imageUrl: _imagePath ?? '',
        imagesSecondaires: _secondaryImagePaths,
        categorie: _categorieController.text.trim(),
        stock: int.parse(_stockController.text.trim()),
        estEcologique: _estEcologique,
        dateAjout: widget.product?.dateAjout ?? DateTime.now(),
      );

      if (widget.product == null) {
        await context.read<ProductController>().addProduct(product);
      } else {
        await context.read<ProductController>().updateProduct(product.id, product);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.product == null
                ? 'Produit ajouté avec succès!'
                : 'Produit modifié avec succès!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage = 'Erreur lors de l\'enregistrement';
        if (e.toString().contains('network')) {
          errorMessage = 'Erreur de connexion. Vérifiez votre internet.';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'Permissions insuffisantes.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: _submitForm,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    _categorieController.dispose();
    _stockController.dispose();
    super.dispose();
  }
}
