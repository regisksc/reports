part of 'report_flow_page.dart';

const debrisLocations = [
  'Alley',
  'Center Median',
  'Cul-de-Sac',
  'Curb',
  'Dead End',
  'Easement/Pedestrian Walk',
  'On Bridge',
  'Side Street',
  'Stairway',
  'Under Bridge',
  'Under Freeway',
];

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
          const Text('Sent to MyLA311. Service Request number:'),
          const SizedBox(height: 8),
          Text(number, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          const Text('Keep this number to follow up with 311.'),
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
              () => _position = (latitude: point.latitude, longitude: point.longitude),
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

  Widget _itemsStep() => Column(
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
                  const Icon(Icons.camera_alt_outlined, size: 48),
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
                  'Add up to 3 photos from your camera or library. A clear description works too.',
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
        'Describe the dumped items',
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

  Widget _reviewStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _notice(
        'You’re in control. This anonymous report will be sent to the City of Los Angeles. No account is needed.',
      ),
      const SizedBox(height: 18),
      _reviewSection(
        'Location',
        '${_position!.latitude.toStringAsFixed(6)}, ${_position!.longitude.toStringAsFixed(6)}',
        0,
      ),
      _reviewSection(
        'Items',
        '$_quantity ${_quantity == 1 ? 'item' : 'items'} · $_debris',
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
      _reviewSection('Description', _desc.text.trim(), 3),
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
