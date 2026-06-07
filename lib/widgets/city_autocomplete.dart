import 'dart:async';
import 'package:flutter/material.dart';
import '../services/location_service.dart';

class CityAutocomplete extends StatefulWidget {
  final Function(LocationResult) onSelected;

  const CityAutocomplete({super.key, required this.onSelected});

  @override
  State<CityAutocomplete> createState() => _CityAutocompleteState();
}

class _CityAutocompleteState extends State<CityAutocomplete> {
  final LocationService _locationService = LocationService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  List<LocationResult> _options = [];
  bool _isLoading = false;
  Timer? _debounce;
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Delay hiding slightly so taps on items register
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showDropdown = false);
        });
      } else {
        if (_options.isNotEmpty) {
          setState(() => _showDropdown = true);
        }
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.length < 3) {
      setState(() {
        _options = [];
        _showDropdown = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showDropdown = true;
    });

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final results = await _locationService.searchCity(query);
      if (mounted) {
        setState(() {
          _options = results;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: 'Place of Birth',
            labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            hintText: 'Start typing city name...',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
            prefixIcon: Icon(Icons.location_city, color: Theme.of(context).colorScheme.secondary),
            suffixIcon: _isLoading 
                ? Container(
                    width: 20, 
                    height: 20, 
                    padding: const EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.secondary),
                  ) 
                : null,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_showDropdown && (_options.isNotEmpty || _isLoading)) ...[
          const SizedBox(height: 8),
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _options.length,
                itemBuilder: (context, index) {
                  final option = _options[index];
                  return ListTile(
                    title: Text(option.displayName, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
                    onTap: () {
                      _controller.text = option.displayName;
                      widget.onSelected(option);
                      setState(() {
                        _showDropdown = false;
                        _focusNode.unfocus();
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ]
      ],
    );
  }
}
