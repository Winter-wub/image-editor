import 'dart:io';
import 'dart:js_interop';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:js/js.dart';
import 'package:path_provider/path_provider.dart';
import 'package:web/web.dart' as web;

@JS('URL')
external _URL get urlObject;

@JS()
@staticInterop
class _URL {}

extension URLExtension on _URL {
  external String createObjectURL(web.Blob blob);
  external void revokeObjectURL(String url);
}

class ImageEditorPage extends StatefulWidget {
  const ImageEditorPage({Key? key}) : super(key: key);

  @override
  State<ImageEditorPage> createState() => _ImageEditorPageState();
}

class _TextOverlay {
  String text;
  Color color;
  double fontSize;
  String fontFamily;
  Offset position;
  double width;
  double height;
  bool selected;

  _TextOverlay({
    required this.text,
    required this.color,
    required this.fontSize,
    required this.fontFamily,
    required this.position,
  })  : width = 150,
        height = 50,
        selected = false;
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  File? _imageFile;
  Uint8List? _webImageBytes; // For web image
  final List<_TextOverlay> _textOverlays = [];
  final GlobalKey _canvasKey = GlobalKey();
  int? _selectedIndex;
  final TextEditingController _textController = TextEditingController();
  Color _currentColor = Colors.white;
  double _currentFontSize = 24;
  String _currentFontFamily = 'Arial';
  bool _isDragging = false;
  Offset? _dragStart;
  Offset? _dragOrigin;
  bool _isResizing = false;
  Offset? _resizeStart;
  double? _resizeOriginWidth;
  double? _resizeOriginHeight;

  final List<String> _fontFamilies = [
    'Arial',
    'Verdana',
    'Helvetica',
    'Times New Roman',
    'Courier New',
    'Tahoma',
    'Impact',
  ];

  final List<Color> _presetColors = [
    Colors.black,
    Colors.white, // เพิ่มสีขาว
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.brown,
    Colors.pink,
    Colors.teal,
    Colors.cyan,
    Colors.lime,
    Colors.indigo,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {}); // Refresh UI when text changes
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _imageFile = null;
          _textOverlays.clear();
          _selectedIndex = null;
        });
      } else {
        setState(() {
          _imageFile = File(picked.path);
          _webImageBytes = null;
          _textOverlays.clear();
          _selectedIndex = null;
        });
      }
    }
  }

  void _addTextOverlay() {
    if (_textController.text.trim().isEmpty) return;
    setState(() {
      _textOverlays.add(_TextOverlay(
        text: _textController.text.trim(),
        color: _currentColor,
        fontSize: _currentFontSize,
        fontFamily: _currentFontFamily,
        position: const Offset(100, 100),
      ));
      _selectedIndex = _textOverlays.length - 1;
      _textController.clear();
    });
  }

  void _editSelectedOverlayText(String newText) {
    if (_selectedIndex == null) return;
    setState(() {
      _textOverlays[_selectedIndex!].text = newText;
    });
  }

  void _selectOverlay(int? index) {
    setState(() {
      _selectedIndex = index;
      for (int i = 0; i < _textOverlays.length; i++) {
        _textOverlays[i].selected = (i == index);
      }
      if (index != null) {
        final overlay = _textOverlays[index];
        _currentColor = overlay.color;
        _currentFontSize = overlay.fontSize;
        _currentFontFamily = overlay.fontFamily;
        _textController.text = overlay.text; // Autofill text for editing
      } else {
        _textController.clear();
      }
    });
  }

  void _deleteSelectedOverlay() {
    if (_selectedIndex == null) return;
    setState(() {
      _textOverlays.removeAt(_selectedIndex!);
      _selectedIndex = null;
    });
  }

  void _updateSelectedOverlayStyle() {
    if (_selectedIndex == null) return;
    setState(() {
      final overlay = _textOverlays[_selectedIndex!];
      overlay.color = _currentColor;
      overlay.fontSize = _currentFontSize;
      overlay.fontFamily = _currentFontFamily;
    });
  }

  Future<void> _exportImage() async {
    if (_imageFile == null && _webImageBytes == null) return;
    try {
      RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      if (kIsWeb) {
        // Download for web using package:web and dart:js_interop only
        final jsArray = [pngBytes.toJS].toJS;
        final blob = web.Blob(jsArray);
        final url = urlObject.createObjectURL(blob);
        final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
        anchor.href = url;
        anchor.download = 'edited_image.png';
        anchor.click();
        urlObject.revokeObjectURL(url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ดาวน์โหลดรูปภาพเรียบร้อย')),
        );
      } else {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/edited_image.png');
        await file.writeAsBytes(pngBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกรูปภาพที่ ${file.path}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกรูปภาพ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แอปแก้ไขรูปภาพและเพิ่มข้อความ', 
          style: TextStyle(color: Colors.white)
        ),
        backgroundColor: const Color(0xFF3498db),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // ปุ่มลบข้อความที่เลือก (อยู่ด้านบน)
              if (_selectedIndex != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _deleteSelectedOverlay,
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text('ลบข้อความที่เลือก'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text('อัพโหลดรูปภาพ'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: (_imageFile != null || _webImageBytes != null) ? _exportImage : null,
                    child: const Text('ดาวน์โหลดรูปภาพ'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_imageFile != null || _webImageBytes != null)
                RepaintBoundary(
                  key: _canvasKey,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    width: MediaQuery.of(context).size.width * 0.9,
                    constraints: const BoxConstraints(maxWidth: 600, minHeight: 300),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Listener(
                              behavior: HitTestBehavior.translucent,
                              onPointerDown: (event) {
                                // ตรวจสอบว่ากดโดน overlay หรือไม่
                                final RenderBox box = _canvasKey.currentContext!.findRenderObject() as RenderBox;
                                final localPosition = box.globalToLocal(event.position);
                                bool tappedOnOverlay = false;
                                for (final overlay in _textOverlays) {
                                  final rect = Rect.fromLTWH(
                                    overlay.position.dx,
                                    overlay.position.dy,
                                    overlay.width,
                                    overlay.height,
                                  );
                                  if (rect.contains(localPosition)) {
                                    tappedOnOverlay = true;
                                    break;
                                  }
                                }
                                if (!tappedOnOverlay) {

                                   for (final overlay in _textOverlays) {
                              overlay.selected = false;
                            }
                                  setState(() {
                                    _selectedIndex = null;
                                    _textController.clear();
                                  });
                                }
                              },
                              child: kIsWeb && _webImageBytes != null
                                  ? Image.memory(_webImageBytes!, fit: BoxFit.contain)
                                  : _imageFile != null
                                      ? Image.file(_imageFile!, fit: BoxFit.contain)
                                      : const SizedBox.shrink(),
                            ),
                          ),
                          ..._textOverlays.asMap().entries.map((entry) {
                            final i = entry.key;
                            final overlay = entry.value;
                            return Positioned(
                              left: overlay.position.dx,
                              top: overlay.position.dy,
                              child: GestureDetector(
                                onTap: () => _selectOverlay(i),
                                onPanStart: (details) {
                                  if (_selectedIndex == i) {
                                    _isDragging = true;
                                    _dragStart = details.globalPosition;
                                    _dragOrigin = overlay.position;
                                  }
                                },
                                onPanUpdate: (details) {
                                  if (_isDragging && _selectedIndex == i) {
                                    setState(() {
                                      final dx = details.globalPosition.dx - _dragStart!.dx;
                                      final dy = details.globalPosition.dy - _dragStart!.dy;
                                      overlay.position = Offset(
                                        (_dragOrigin!.dx + dx).clamp(0.0, MediaQuery.of(context).size.width * 0.9 - overlay.width),
                                        (_dragOrigin!.dy + dy).clamp(0.0, 600 - overlay.height),
                                      );
                                    });
                                  }
                                },
                                onPanEnd: (_) {
                                  _isDragging = false;
                                },
                                child: Stack(
                                  children: [
                                    Container(
                                      width: overlay.width,
                                      height: overlay.height,
                                      decoration: BoxDecoration(
                                        border: overlay.selected
                                            ? Border.all(color: const Color(0xFF3498db), style: BorderStyle.solid, width: 2)
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        overlay.text,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: overlay.color,
                                          fontSize: overlay.fontSize,
                                          fontFamily: overlay.fontFamily,
                                        ),
                                      ),
                                    ),
                                    if (overlay.selected)
                                      Positioned(
                                        right: -16, // ขยายจุด scale ออกไปด้านขวาอีก
                                        bottom: -16, // ขยายจุด scale ออกไปด้านล่างอีก
                                        child: GestureDetector(
                                          onPanStart: (details) {
                                            _isResizing = true;
                                            _resizeStart = details.globalPosition;
                                            _resizeOriginWidth = overlay.width;
                                            _resizeOriginHeight = overlay.height;
                                          },
                                          onPanUpdate: (details) {
                                            if (_isResizing) {
                                              setState(() {
                                                final dx = details.globalPosition.dx - _resizeStart!.dx;
                                                final dy = details.globalPosition.dy - _resizeStart!.dy;
                                                overlay.width = (_resizeOriginWidth! + dx).clamp(50.0, 400.0);
                                                overlay.height = (_resizeOriginHeight! + dy).clamp(20.0, 200.0);
                                              });
                                            }
                                          },
                                          onPanEnd: (_) {
                                            _isResizing = false;
                                          },
                                          child: Container(
                                            width: 32, // ขยายขนาดจุด scale
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3498db),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: Colors.white, width: 3),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.3),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(Icons.open_in_full, size: 20, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'ใส่ข้อความที่นี่',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (val) {
                        if (_selectedIndex != null) {
                          _editSelectedOverlayText(val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: (_imageFile != null || _webImageBytes != null) && _textController.text.trim().isNotEmpty ? _addTextOverlay : null,
                    child: const Text('เพิ่มข้อความ'),
                  ),
                  if (_selectedIndex != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            // ยกเลิกการเลือกข้อความและลบกรอบ selection
                            for (final overlay in _textOverlays) {
                              overlay.selected = false;
                            }
                            _selectedIndex = null;
                            _textController.clear();
                          });
                        },
                        child: const Text('ยกเลิกการแก้ไข'),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Preset color picker
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: _selectedIndex != null
                          ? () async {
                              Color? picked = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('เลือกสีข้อความ'),
                                  content: SingleChildScrollView(
                                    child: BlockPicker(
                                      pickerColor: _currentColor,
                                      onColorChanged: (color) {
                                        Navigator.of(context).pop(color);
                                      },
                                      availableColors: _presetColors,
                                    ),
                                  ),
                                ),
                              );
                              if (picked != null) {
                                setState(() {
                                  _currentColor = picked;
                                  _updateSelectedOverlayStyle();
                                });
                              }
                            }
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _currentColor,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  DropdownButton<double>(
                    value: _currentFontSize,
                    items: [8, 10, 12, 16, 20, 24, 32, 40, 48, 64]
                        .map((size) => DropdownMenuItem(
                              value: size.toDouble(),
                              child: Text('${size}px'),
                            ))
                        .toList(),
                    onChanged: _selectedIndex != null
                        ? (val) {
                            setState(() {
                              _currentFontSize = val!;
                              _updateSelectedOverlayStyle();
                            });
                          }
                        : null,
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _currentFontFamily,
                    items: _fontFamilies
                        .map((family) => DropdownMenuItem(
                              value: family,
                              child: Text(family),
                            ))
                        .toList(),
                    onChanged: _selectedIndex != null
                        ? (val) {
                            setState(() {
                              _currentFontFamily = val!;
                              _updateSelectedOverlayStyle();
                            });
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(color: Color(0xFF3498db), width: 5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('วิธีใช้งาน:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('• อัพโหลดรูปภาพที่ต้องการแก้ไข'),
                    Text('• พิมพ์ข้อความและกดปุ่ม "เพิ่มข้อความ"'),
                    Text('• แตะข้อความเพื่อเลือก และลากเพื่อเปลี่ยนตำแหน่ง'),
                    Text('• ใช้จุดลากที่มุมขวาล่างเพื่อปรับขนาดข้อความ'),
                    Text('• เลือกข้อความและกดปุ่ม "ลบข้อความที่เลือก" เพื่อลบข้อความ'),
                    Text('• กดปุ่ม "ดาวน์โหลดรูปภาพ" เมื่อแก้ไขเสร็จ'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
