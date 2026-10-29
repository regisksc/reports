part of 'report_flow_page.dart';

const debrisLocations = IllegalDumpingCatalog.locations;

extension _ReportFlowSteps on _ReportFlowPageState {
  Widget _notice(String text) => Card(
    color: ReportsStyle.surface,
    child: Padding(padding: const EdgeInsets.all(16), child: Text(text)),
  );

  Widget _receipt(String number) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: reportStatusColor(ReportState.submitted),
            size: 56,
          ),
          const SizedBox(height: 20),
          Text(
            'Report received.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Submitted',
            style: TextStyle(
              color: reportStatusColor(ReportState.submitted),
              fontWeight: FontWeight.w800,
            ),
          ),
          const Text('Sent to MyLA311.'),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ReportsStyle.surface,
              border: Border.all(color: ReportsStyle.border, width: 2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Text('Service Request number'),
                const SizedBox(height: 8),
                Text(number, style: Theme.of(context).textTheme.headlineMedium),
                TextButton.icon(
                  onPressed: () async {
                    try {
                      await Clipboard.setData(ClipboardData(text: number));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Number copied')),
                        );
                      }
                    } on Object {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not copy the number'),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copy number'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Keep this number to follow up with 311.'),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => _leaveReceipt(home: true),
            child: const Text('Back to home'),
          ),
        ],
      ),
    ),
  );

  Widget _locationStep() {
    final position = _position;
    final error = _locationError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _locked || _locating ? null : _locate,
          icon: const Icon(Icons.my_location),
          label: Text(position == null ? 'Use my location' : 'Location set ✓'),
        ),
        const SizedBox(height: 18),
        LocationMap(
          position: position == null
              ? null
              : (latitude: position.latitude, longitude: position.longitude),
          enabled: !_locked && !_locating,
          onSelected: (point) {
            _update(
              () => _position = (
                latitude: point.latitude,
                longitude: point.longitude,
              ),
            );
            _persistDraft();
          },
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  List<ReportItem> get _selectedItems => _controller.itemFamily == null
      ? [
          ReportItem(
            name: 'Loose/Miscellaneous Debris',
            quantity: _qty.text,
            location: _debris,
          ),
        ]
      : _controller.items;

  Widget _itemsStep() {
    final catalog = _controller.itemCatalog;
    final familyName = _controller.itemFamily ?? "I'm not sure";
    final families = catalog?.families ?? [];
    final matches = families.where((family) => family.name == familyName);
    final family = matches.isEmpty ? null : matches.first;
    final selected = _selectedItems;
    final featured = switch (familyName) {
      'Bulky Items' => ['Mattress', 'Sofa', 'Chair', 'Table (Wood)'],
      'Electronic Waste' => [
        'Computers',
        'TV (Any Size)',
        'Monitors',
        'Microwaves',
      ],
      'Metal/Household Appliances' => [
        'Air Conditioner',
        'Refrigerator/Freezer',
        'Scrap Metal',
        'Stove/Oven',
      ],
      _ => ['Loose/Miscellaneous Debris', 'Trash Bags', 'Tires', 'Wood'],
    };
    final choices = family?.items.where((item) {
      if (_itemQuery.trim().isNotEmpty) {
        return item.name.toLowerCase().contains(
          _itemQuery.trim().toLowerCase(),
        );
      }
      return _showAllItems || featured.contains(item.name);
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'What kind of material is it?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text('Choose the closest description.'),
        const SizedBox(height: 12),
        if (catalog == null) ...[
          if (_controller.itemCatalogError == null)
            const Text('Loading item choices…')
          else ...[
            Text(_controller.itemCatalogError!),
            TextButton(
              onPressed: _controller.loadItemCatalog,
              child: const Text('Try again'),
            ),
          ],
        ] else ...[
          _itemGrid([
            for (final option in families)
              _itemChoice(
                label: option.name,
                selected: option.name == familyName,
                onTap: () {
                  _update(() {
                    _itemQuery = '';
                    _showAllItems = false;
                  });
                  _controller.updateItems(option.name, []);
                },
              ),
          ]),
          const SizedBox(height: 24),
          Text(
            'Which items do you see?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Choose only the items that match what you see.'),
          const SizedBox(height: 12),
          TextField(
            key: ValueKey('item-search-$familyName'),
            enabled: !_locked,
            decoration: const InputDecoration(
              labelText: 'Find an item',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => _update(() => _itemQuery = value),
          ),
          const SizedBox(height: 12),
          _itemGrid([
            for (final item in choices ?? [])
              _itemChoice(
                label: item.name == 'Loose/Miscellaneous Debris'
                    ? 'Loose / miscellaneous debris'
                    : item.name,
                selected: selected.any((entry) => entry.name == item.name),
                itemIcon: _itemIcon(item.name),
                description: switch (item.name) {
                  'Loose/Miscellaneous Debris' => 'Loose or mixed material',
                  'Trash Bags' => 'Bagged trash',
                  'Tires' => 'Loose tires',
                  'Wood' => 'Wood pieces',
                  _ => 'Add quantity and placement',
                },
                onTap: () {
                  final next = selected
                      .where((entry) => entry.name != item.name)
                      .toList();
                  if (next.length == selected.length) {
                    next.add(ReportItem(name: item.name, quantity: ''));
                  }
                  _controller.updateItems(familyName, next);
                },
              ),
          ]),
          if (choices?.isEmpty == true)
            const Text('No matching items. Try another search.'),
          if (_itemQuery.isEmpty && family != null)
            TextButton(
              onPressed: _locked
                  ? null
                  : () => _update(() => _showAllItems = !_showAllItems),
              child: Text(
                _showAllItems
                    ? 'Show fewer items'
                    : 'Show all ${family.items.length} items',
              ),
            ),
        ],
        const SizedBox(height: 16),
        if (_controller.itemFamily == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _legacyItemFields(),
            ),
          )
        else
          for (final item in selected) _selectedItemFields(item),
      ],
    );
  }

  Widget _itemGrid(List<Widget> choices) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 1 : 2;
      return Column(
        children: [
          for (var start = 0; start < choices.length; start += columns) ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var column = 0; column < columns; column++) ...[
                    if (column > 0) const SizedBox(width: 10),
                    Expanded(
                      child: start + column < choices.length
                          ? choices[start + column]
                          : const SizedBox(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      );
    },
  );

  Widget _itemChoice({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? itemIcon,
    String? description,
  }) => Semantics(
    selected: selected,
    child: OutlinedButton(
      style: ReportsStyle.raisedButtonStyle(
        shadowColor: selected ? ReportsStyle.orangeDark : ReportsStyle.border,
        backgroundColor: selected
            ? Color.alphaBlend(ReportsStyle.orange.withAlpha(24), Colors.white)
            : Colors.white,
        side: BorderSide(
          color: selected ? ReportsStyle.orangeDark : ReportsStyle.border,
          width: 2,
        ),
      ).copyWith(padding: const WidgetStatePropertyAll(EdgeInsets.all(14))),
      onPressed: _locked ? null : onTap,
      child: Row(
        children: [
          if (itemIcon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ReportsStyle.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(itemIcon),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (description != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(selected ? Icons.check_circle : Icons.circle_outlined, size: 20),
        ],
      ),
    ),
  );

  IconData _itemIcon(String name) => switch (name) {
    'Loose/Miscellaneous Debris' => Icons.grain,
    'Trash Bags' => Icons.delete_outline,
    'Tires' => Icons.radio_button_unchecked,
    'Wood' => Icons.forest_outlined,
    _ => switch (_controller.itemFamily) {
      'Electronic Waste' => Icons.devices_other_outlined,
      'Metal/Household Appliances' => Icons.kitchen_outlined,
      _ => Icons.weekend_outlined,
    },
  };

  void _changeSelectedItem(
    ReportItem item, {
    String? quantity,
    String? location,
  }) {
    _controller.updateItems(_controller.itemFamily!, [
      for (final old in _controller.items)
        old.name == item.name
            ? ReportItem(
                name: old.name,
                quantity: quantity ?? old.quantity,
                location: location ?? old.location,
              )
            : old,
    ]);
  }

  Widget _selectedItemFields(ReportItem item) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(item.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('item-location-${item.name}'),
            initialValue: debrisLocations.contains(item.location)
                ? item.location
                : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Where is it?'),
            items: [
              for (final location in debrisLocations)
                DropdownMenuItem(value: location, child: Text(location)),
            ],
            onChanged: _locked
                ? null
                : (value) => _changeSelectedItem(item, location: value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('item-quantity-${item.name}'),
            initialValue: item.quantity,
            enabled: !_locked,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: const InputDecoration(
              labelText: 'How many?',
              hintText: '1 to 999',
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              final number = int.tryParse(value ?? '');
              return number != null && number >= 1 && number <= 999
                  ? null
                  : 'Enter a number from 1 to 999.';
            },
            onChanged: (value) => _changeSelectedItem(item, quantity: value),
          ),
        ],
      ),
    ),
  );

  Widget _legacyItemFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Where is the debris?',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        initialValue: _debris,
        isExpanded: true,
        hint: const Text('Choose one'),
        items: [
          for (final d in debrisLocations)
            DropdownMenuItem(value: d, child: Text(d)),
        ],
        onChanged: _locked
            ? null
            : (value) {
                _update(() => _debris = value);
                _persistDraft();
              },
      ),
      const SizedBox(height: 24),
      Text('How many items?', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 10),
      TextField(
        key: const Key('report-quantity'),
        controller: _qty,
        enabled: !_locked,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        onChanged: (_) {
          _update(() {});
          _persistDraft();
        },
        decoration: InputDecoration(
          hintText: '1 to 999',
          errorText: _quantityError,
        ),
      ),
    ],
  );

  Widget _photoStep() {
    final photos = _photoPaths;
    final error = _photoError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: ReportsStyle.surface,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (photos.isEmpty)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, size: 32),
                  ),
                for (var index = 0; index < photos.length; index++) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(photos[index]),
                      height: 190,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton.icon(
                    key: ValueKey('remove-photo-$index'),
                    onPressed: _locked || _pickingPhoto
                        ? null
                        : () async {
                            _update(() {
                              _photoPaths.removeAt(index);
                              _photoError = null;
                            });
                            await _persistDraft();
                          },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove photo'),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'A little context helps.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add up to 3 photos from your camera or library. Up to 10 MB each.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _locked || _pickingPhoto || photos.length >= 3
                      ? null
                      : () => _pickPhoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take photo'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _locked || _pickingPhoto || photos.length >= 3
                      ? null
                      : () => _pickPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose from library'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Keep personal details out of the frame. Avoid faces, license plates, and private documents.',
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  Widget _detailsStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Describe the dumped items (optional)',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 10),
      TextField(
        key: const Key('report-description'),
        controller: _desc,
        enabled: !_locked,
        maxLines: 5,
        maxLength: 750,
        onChanged: (_) {
          _update(() {});
          _persistDraft();
        },
        decoration: const InputDecoration(
          hintText: 'e.g. Couch and mattress dumped on sidewalk',
        ),
      ),
      const SizedBox(height: 16),
      const Text('Please leave out sensitive or personal information.'),
    ],
  );

  Widget _contactStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3;
          if (stacked) {
            return Column(
              children: [
                _contactChoice(true),
                const SizedBox(height: 12),
                _contactChoice(false),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _contactChoice(true)),
              const SizedBox(width: 12),
              Expanded(child: _contactChoice(false)),
            ],
          );
        },
      ),
      const SizedBox(height: 16),
      if (_controller.contact?.anonymous == false) ...[
        for (final field in <(String, TextEditingController, TextInputType)>[
          ('First name', _first, TextInputType.name),
          ('Last name', _last, TextInputType.name),
          ('Email address', _email, TextInputType.emailAddress),
          ('Phone number (optional)', _phone, TextInputType.phone),
        ]) ...[
          const SizedBox(height: 12),
          TextField(
            controller: field.$2,
            keyboardType: field.$3,
            enabled: !_locked,
            decoration: InputDecoration(
              labelText: field.$1,
              errorText: identical(field.$2, _email)
                  ? _controller.contactEmailError
                  : null,
            ),
            onChanged: (_) {
              _update(() {});
              _persistDraft();
            },
          ),
        ],
        SwitchListTile(
          title: const Text('Remember my contact details'),
          subtitle: const Text(
            'Reuse them in your next report on this device.',
          ),
          value: _controller.rememberContact,
          onChanged: _locked ? null : _remember,
        ),
        const Text(
          'Contact details remain in this draft and any saved receipt.',
        ),
      ],
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ReportsStyle.surface,
          border: Border.all(color: ReportsStyle.border, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined),
            SizedBox(height: 8),
            Text(
              'Your draft stays on this device. If you include contact details, they are sent to the City with your report.',
            ),
          ],
        ),
      ),
      if (_contactStorageError != null) ...[
        const SizedBox(height: 12),
        _notice(_contactStorageError!),
      ],
    ],
  );

  Widget _contactChoice(bool anonymous) {
    final selected = _controller.contact?.anonymous == anonymous;
    final border = selected ? ReportsStyle.orangeDark : ReportsStyle.border;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? const Color(0xfffff1d9) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _locked
              ? null
              : () {
                  _update(() {
                    _controller.contact = anonymous
                        ? const ReportContact(anonymous: true)
                        : ReportContact(
                            anonymous: false,
                            firstName: _first.text,
                            lastName: _last.text,
                            email: _email.text,
                            phone: _phone.text,
                          );
                  });
                  _persistDraft();
                },
          child: Container(
            constraints: const BoxConstraints(minHeight: 174),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? const Color(0xfffff1d9) : Colors.white,
              border: Border.all(color: border, width: 2),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: border, offset: const Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: ReportsStyle.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        anonymous ? Icons.shield_outlined : Icons.mail_outline,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  anonymous
                      ? 'Without contact details'
                      : 'Include my contact details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  anonymous
                      ? 'Keep your name and email out of this report.'
                      : 'Share your name and email with the City.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _reviewStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _notice(
        _controller.contact?.anonymous == false
            ? 'This report and your contact details will be sent to the City of Los Angeles.'
            : 'This anonymous report will be sent to the City of Los Angeles. No account is needed.',
      ),
      const SizedBox(height: 18),
      _reviewSection(
        'Location',
        '${_position!.latitude.toStringAsFixed(6)}, ${_position!.longitude.toStringAsFixed(6)}',
        0,
      ),
      _reviewSection(
        'Items',
        _controller.itemFamily == null
            ? '$_quantity ${_quantity == 1 ? 'item' : 'items'} · $_debris'
            : '${_controller.itemFamily}\n${_controller.items.map((item) => '${item.quantity} × ${item.name} · ${item.location ?? 'Location needed'}').join('\n')}',
        1,
      ),
      _reviewSection(
        'Photo',
        _photoPaths.isEmpty
            ? 'No photo added'
            : _photoPaths.length == 1
            ? 'Photo attached'
            : '${_photoPaths.length} photos attached',
        2,
      ),
      _reviewSection(
        'Description',
        _desc.text.trim().isEmpty ? 'No details added' : _desc.text.trim(),
        3,
      ),
      _reviewSection(
        'Contact',
        _controller.contact?.anonymous == false
            ? '${_first.text} ${_last.text} · ${_email.text}'
            : 'Without contact details',
        4,
      ),
    ],
  );

  Widget _reviewSection(String title, String value, int step) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 10, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Flexible(
                child: TextButton(
                  onPressed: _locked
                      ? null
                      : () => _changeStep(step, fromReview: true),
                  child: Text('Edit $title'),
                ),
              ),
            ],
          ),
          Text(value),
        ],
      ),
    ),
  );
}
