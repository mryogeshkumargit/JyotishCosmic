import 'dart:async';
import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../core/l10n.dart';

/// Place-of-birth search over the bundled (offline) city database.
class CityAutocomplete extends StatefulWidget {
  final ValueChanged<LocationResult> onSelected;
  final String? initialText;

  const CityAutocomplete({super.key, required this.onSelected, this.initialText});

  @override
  State<CityAutocomplete> createState() => _CityAutocompleteState();
}

class _CityAutocompleteState extends State<CityAutocomplete> {
  final LocationService _locationService = LocationService();
  late final TextEditingController _controller = TextEditingController(text: widget.initialText ?? '');
  final FocusNode _focusNode = FocusNode();

  List<LocationResult> _options = [];
  bool _isLoading = false;
  Timer? _debounce;
  bool _showDropdown = false;
  int _searchId = 0;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Delay hiding slightly so taps on items register.
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showDropdown = false);
        });
      } else if (_options.isNotEmpty) {
        setState(() => _showDropdown = true);
      }
    });
  }

  @override
  void didUpdateWidget(covariant CityAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != oldWidget.initialText && widget.initialText != null) {
      _controller.text = widget.initialText!;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _options = [];
        _showDropdown = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showDropdown = true;
    });

    final int id = ++_searchId;
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final results = await _locationService.searchCity(query);
      if (mounted && id == _searchId) {
        setState(() {
          _options = results;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          style: TextStyle(color: scheme.onSurface),
          decoration: InputDecoration(
            labelText: tr('Place of Birth', 'जन्म स्थान'),
            hintText: tr('Start typing a city name...', 'शहर का नाम लिखना शुरू करें...'),
            prefixIcon: Icon(Icons.location_city, color: scheme.secondary),
            suffixIcon: _isLoading
                ? Container(
                    width: 20,
                    height: 20,
                    padding: const EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2, color: scheme.secondary),
                  )
                : null,
          ),
        ),
        if (_showDropdown && !_isLoading && _options.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(tr('No matching city. You can enter coordinates manually below.', 'कोई शहर नहीं मिला। आप नीचे अक्षांश-देशांतर स्वयं लिख सकते हैं।'),
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          ),
        if (_showDropdown && _options.isNotEmpty) ...[
          const SizedBox(height: 8),
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: scheme.surfaceContainerHighest,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _options.length,
                itemBuilder: (context, index) {
                  final option = _options[index];
                  return ListTile(
                    dense: true,
                    title: Text(option.displayName, style: TextStyle(color: scheme.onSurface, fontSize: 14)),
                    subtitle: Text(
                      '${option.lat.toStringAsFixed(2)}, ${option.lon.toStringAsFixed(2)}  •  ${option.tzName ?? ''}',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
                    ),
                    onTap: () {
                      _controller.text = option.displayName;
                      widget.onSelected(option);
                      setState(() => _showDropdown = false);
                      _focusNode.unfocus();
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
