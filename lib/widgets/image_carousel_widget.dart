import 'dart:convert';
import 'package:flutter/material.dart';

class ImageCarousel extends StatefulWidget {
  final String mainImageUrl;
  final List<String> secondaryImages;
  final String heroTag;
  final double iconSize;
  final double paddingValue;

  const ImageCarousel({
    Key? key,
    required this.mainImageUrl,
    required this.secondaryImages,
    required this.heroTag,
    required this.iconSize,
    required this.paddingValue,
  }) : super(key: key);

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _currentImageIndex = 0;
  late List<String> _allImages;

  @override
  void initState() {
    super.initState();
    _allImages = [widget.mainImageUrl, ...widget.secondaryImages];
  }

  @override
  Widget build(BuildContext context) {
    // Si une seule image, affichage simple
    if (_allImages.length <= 1 || widget.secondaryImages.isEmpty) {
      return _buildSingleImage();
    }

    return Column(
      children: [
        // Image principale
        Expanded(
          child: GestureDetector(
            onTap: () => _showImageZoom(context),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey[100]!,
                    Colors.grey[200]!,
                  ],
                ),
              ),
              child: _allImages[_currentImageIndex].isNotEmpty
                  ? Hero(
                tag: widget.heroTag,
                child: Image.memory(
                  base64Decode(_allImages[_currentImageIndex]),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildErrorWidget();
                  },
                ),
              )
                  : _buildPlaceholderWidget(),
            ),
          ),
        ),

        // Miniatures en bas
        Container(
          height: 60,
          padding: EdgeInsets.all(widget.paddingValue * 0.5),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _allImages.length,
            itemBuilder: (context, index) {
              final isSelected = index == _currentImageIndex;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
                child: Container(
                  width: 50,
                  height: 50,
                  margin: EdgeInsets.only(right: widget.paddingValue * 0.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _allImages[index].isNotEmpty
                        ? Image.memory(
                      base64Decode(_allImages[index]),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    )
                        : Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_outlined,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSingleImage() {
    return GestureDetector(
      onTap: () => _showImageZoom(context),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[100]!,
              Colors.grey[200]!,
            ],
          ),
        ),
        child: widget.mainImageUrl.isNotEmpty
            ? Hero(
          tag: widget.heroTag,
          child: Image.memory(
            base64Decode(widget.mainImageUrl),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorWidget();
            },
          ),
        )
            : _buildPlaceholderWidget(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[200]!, Colors.grey[300]!],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: widget.iconSize * 2,
              color: Colors.grey[600],
            ),
            SizedBox(height: widget.iconSize * 0.3),
            Text(
              'Image indisponible',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: widget.iconSize * 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[100]!, Colors.grey[200]!],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: widget.iconSize * 2.5,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  void _showImageZoom(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ImageZoomDialog(
          images: _allImages,
          initialIndex: _currentImageIndex,
          heroTag: widget.heroTag,
        );
      },
    );
  }
}

class ImageZoomDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String heroTag;

  const ImageZoomDialog({
    Key? key,
    required this.images,
    required this.initialIndex,
    required this.heroTag,
  }) : super(key: key);

  @override
  State<ImageZoomDialog> createState() => _ImageZoomDialogState();
}

class _ImageZoomDialogState extends State<ImageZoomDialog> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black87,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Images avec PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: widget.images[index].isNotEmpty
                      ? Image.memory(
                    base64Decode(widget.images[index]),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: Colors.white54,
                          ),
                        ),
                      );
                    },
                  )
                      : Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Bouton fermer
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                shape: const CircleBorder(),
              ),
            ),
          ),

          // Indicateur de page (si plusieurs images)
          if (widget.images.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

          // Flèches de navigation (si plusieurs images)
          if (widget.images.length > 1) ...[
            // Flèche gauche
            if (_currentIndex > 0)
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 32),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      shape: const CircleBorder(),
                    ),
                  ),
                ),
              ),

            // Flèche droite
            if (_currentIndex < widget.images.length - 1)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 32),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      shape: const CircleBorder(),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}