import 'package:flutter/material.dart';

import '../../memes/domain/calm_meme.dart';
import '../../memes/presentation/meme_gallery_modal.dart';

const List<String> kToneOptions = [
  '[Prayer Request]',
  '[Comfort Only]',
  '[Bible Deep-Dive]',
  '[Special Interest Infodump]',
  '[Autism & Faith Meme]',
  '[Giving Thanks]',
  '[Question]',
  '[Resource]',
];

/// Composer card allowing members to declare an intent tag, attach calm memes, and publish reflections.
class ReflectionComposer extends StatefulWidget {
  final String selectedSpace;
  final Color primaryColor;
  final bool isContrast;
  final Future<void> Function({
    required String content,
    required String toneTag,
    String? specialInterestTag,
  }) onSubmit;

  const ReflectionComposer({
    super.key,
    required this.selectedSpace,
    required this.primaryColor,
    required this.isContrast,
    required this.onSubmit,
  });

  @override
  State<ReflectionComposer> createState() => _ReflectionComposerState();
}

class _ReflectionComposerState extends State<ReflectionComposer> {
  String _selectedTone = '[Prayer Request]';
  CalmMeme? _attachedMeme;
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _specialInterestController =
      TextEditingController();

  @override
  void dispose() {
    _contentController.dispose();
    _specialInterestController.dispose();
    super.dispose();
  }

  void _handleSelectMeme(CalmMeme meme) {
    setState(() {
      _attachedMeme = meme;
      _selectedTone = '[Autism & Faith Meme]';
      _specialInterestController.text = meme.tag;
      if (_contentController.text.trim().isEmpty) {
        _contentController.text =
            '${meme.icon} "${meme.title}"\n\n${meme.body}';
      }
    });
  }

  Future<void> _handlePublish() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) return;

    final specialInterest = _specialInterestController.text.trim().isNotEmpty
        ? _specialInterestController.text.trim()
        : (_selectedTone.contains('Meme') ? 'Faith & Neurodiversity' : null);

    _contentController.clear();
    _specialInterestController.clear();
    setState(() {
      _attachedMeme = null;
    });

    await widget.onSubmit(
      content: text,
      toneTag: _selectedTone,
      specialInterestTag: specialInterest,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: widget.isContrast
              ? Colors.white
              : Theme.of(context).dividerColor,
          width: widget.isContrast ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Intent Tag: ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: _selectedTone,
                isDense: true,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.primaryColor,
                ),
                underline: const SizedBox(),
                items: kToneOptions.map((tone) {
                  return DropdownMenuItem(value: tone, child: Text(tone));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTone = val);
                },
              ),
            ],
          ),
          if (_selectedTone.contains('Special Interest') ||
              _selectedTone.contains('Meme') ||
              widget.selectedSpace == 'special_interests') ...[
            const SizedBox(height: 6),
            TextField(
              controller: _specialInterestController,
              decoration: InputDecoration(
                hintText:
                    'Special Interest tag (e.g. Church Acoustics, Markan Chiasms, Liturgy)...',
                hintStyle: const TextStyle(fontSize: 11),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Share an unhurried thought, Scripture insight, or relatable reflection...',
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              contentPadding: const EdgeInsets.all(12.0),
            ),
          ),
          const SizedBox(height: 8),
          if (_attachedMeme != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.amber.shade700),
              ),
              child: Row(
                children: [
                  Text(_attachedMeme!.icon,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attached: ${_attachedMeme!.title}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: widget.isContrast
                            ? Colors.yellow
                            : Colors.amber.shade900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _attachedMeme = null),
                    child: const Icon(Icons.close, size: 14),
                  ),
                ],
              ),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  side: BorderSide(
                    color: widget.isContrast
                        ? Colors.white
                        : Theme.of(context).dividerColor,
                  ),
                ),
                onPressed: () => showMemeGalleryModal(
                  context,
                  onSelectedMeme: _handleSelectMeme,
                ),
                icon: const Icon(Icons.sentiment_very_satisfied_outlined,
                    size: 14),
                label: Text(
                  _attachedMeme != null ? 'Change Meme' : 'Add Meme / GIF',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor:
                      widget.isContrast ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: _handlePublish,
                icon: const Icon(Icons.send_rounded, size: 14),
                label: const Text(
                  'Publish Reflection',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
