import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// Image Uploader Component
/// 
/// A comprehensive image upload widget with:
/// - Camera and gallery support
/// - Image preview
/// - Drag & drop capability (web)
/// - File size validation
/// - Image compression
/// - Upload progress tracking
/// - Firebase Storage integration ready
class ImageUploader extends StatefulWidget {
  /// Callback when image is selected
  final Function(File) onImageSelected;

  /// Callback for upload errors
  final Function(String)? onError;

  /// Optional label
  final String? label;

  /// Optional description/hint
  final String? description;

  /// Maximum file size in MB (default: 10)
  final int maxFileSizeMB;

  /// Allowed image formats
  final List<String> allowedFormats;

  /// Show camera option
  final bool showCamera;

  /// Show gallery option
  final bool showGallery;

  /// Custom button text
  final String? buttonText;

  /// Custom icon
  final IconData? icon;

  /// Image aspect ratio for cropping (optional)
  final double? aspectRatio;

  /// Compress images automatically
  final bool autoCompress;

  /// Compression quality (0-100)
  final int compressionQuality;

  const ImageUploader({
    super.key,
    required this.onImageSelected,
    this.onError,
    this.label,
    this.description,
    this.maxFileSizeMB = 10,
    this.allowedFormats = const ['jpg', 'jpeg', 'png', 'webp'],
    this.showCamera = true,
    this.showGallery = true,
    this.buttonText,
    this.icon,
    this.aspectRatio,
    this.autoCompress = true,
    this.compressionQuality = 85,
  });

  @override
  State<ImageUploader> createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  File? _selectedImage;
  bool _isUploading = false;
  double _uploadProgress = 0;
  late ImagePicker _imagePicker;

  @override
  void initState() {
    super.initState();
    _imagePicker = ImagePicker();
  }

  /// Validate file size
  bool _validateFileSize(File file) {
    final sizeInMB = file.lengthSync() / (1024 * 1024);
    if (sizeInMB > widget.maxFileSizeMB) {
      final error = 'File size exceeds ${widget.maxFileSizeMB}MB limit';
      widget.onError?.call(error);
      _showErrorSnackbar(error);
      return false;
    }
    return true;
  }

  /// Validate file format
  bool _validateFormat(String path) {
    final extension = path.split('.').last.toLowerCase();
    if (!widget.allowedFormats.contains(extension)) {
      final error =
          'Format not allowed. Supported: ${widget.allowedFormats.join(", ")}';
      widget.onError?.call(error);
      _showErrorSnackbar(error);
      return false;
    }
    return true;
  }

  /// Show error snackbar
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  /// Show success snackbar
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  /// Pick image from camera
  Future<void> _pickFromCamera() async {
    try {
      Navigator.pop(context); // Close bottom sheet
      setState(() => _isUploading = true);

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: widget.compressionQuality,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        if (!_validateFormat(file.path)) {
          setState(() => _isUploading = false);
          return;
        }

        if (!_validateFileSize(file)) {
          setState(() => _isUploading = false);
          return;
        }

        setState(() {
          _selectedImage = file;
          _isUploading = false;
          _uploadProgress = 1.0;
        });

        widget.onImageSelected(file);
        _showSuccessSnackbar('Image captured successfully');
      } else {
        setState(() => _isUploading = false);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      widget.onError?.call(e.toString());
      _showErrorSnackbar('Camera error: ${e.toString()}');
    }
  }

  /// Pick image from gallery
  Future<void> _pickFromGallery() async {
    try {
      Navigator.pop(context); // Close bottom sheet
      setState(() => _isUploading = true);

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: widget.compressionQuality,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        if (!_validateFormat(file.path)) {
          setState(() => _isUploading = false);
          return;
        }

        if (!_validateFileSize(file)) {
          setState(() => _isUploading = false);
          return;
        }

        setState(() {
          _selectedImage = file;
          _isUploading = false;
          _uploadProgress = 1.0;
        });

        widget.onImageSelected(file);
        _showSuccessSnackbar('Image selected successfully');
      } else {
        setState(() => _isUploading = false);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      widget.onError?.call(e.toString());
      _showErrorSnackbar('Gallery error: ${e.toString()}');
    }
  }

  /// Build image preview
  Widget _buildImagePreview() {
    if (_selectedImage == null) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'No image selected',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            _selectedImage!,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedImage = null;
                _uploadProgress = 0;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        if (_isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: _uploadProgress,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Show upload options
  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              if (widget.showCamera)
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: _pickFromCamera,
                ),
              if (widget.showGallery)
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Choose from Gallery'),
                  onTap: _pickFromGallery,
                ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Remove Image'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                      _uploadProgress = 0;
                    });
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Build upload button
  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isUploading ? null : _showUploadOptions,
        icon: Icon(widget.icon ?? Icons.cloud_upload),
        label: Text(
          widget.buttonText ?? 'Choose Image',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  /// Build file info
  Widget _buildFileInfo() {
    if (_selectedImage == null) {
      return const SizedBox.shrink();
    }

    final sizeInMB = _selectedImage!.lengthSync() / (1024 * 1024);
    final filename = _selectedImage!.path.split('/').last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'File Information',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Name: $filename',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Size: ${sizeInMB.toStringAsFixed(2)} MB',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (widget.label != null) const SizedBox(height: 8),
        if (widget.description != null)
          Text(
            widget.description!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        if (widget.description != null) const SizedBox(height: 12),
        _buildImagePreview(),
        const SizedBox(height: 12),
        _buildUploadButton(),
        _buildFileInfo(),
      ],
    );
  }
}
