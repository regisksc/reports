(() => {
  const steps = ['details', 'location', 'photos', 'contact', 'review', 'confirmation'];
  const namedRequired = (service) => service.mode === 'contact-required';
  const validate = (draft, service) => {
    const answers = draft.answers;
    if (draft.step === 'details') {
      if (!answers.description.trim()) return 'Describe what needs attention.';
      if (answers.extra && !answers.extraDetail.trim()) return 'Add the extra detail you selected.';
    }
    if (draft.step === 'location') {
      if (!answers.address.trim()) return 'Enter an address or nearby intersection.';
      if (!answers.locationConfirmed) return 'Confirm the location before continuing.';
    }
    if (draft.step === 'photos' && service.attachments === 'required' && !draft.photos.length) return 'Add a sample photo to preview this required evidence step.';
    if (draft.step === 'contact') {
      if (!answers.contactMode) return 'Choose how to provide contact information.';
      if (namedRequired(service) && answers.contactMode !== 'named') return 'This service requires contact details.';
      if (answers.contactMode === 'named') {
        if (!answers.name.trim()) return 'Enter a name for this local demonstration.';
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(answers.email)) return 'Enter a valid email for this local demonstration.';
      }
    }
    return '';
  };
  const button = (action, label) => `<button type="button" class="btn btn-primary" data-action="flow-${action}">${label}</button>`;
  const field = (name, label, value, escape, type = 'text') => `<label class="flow-field">${label}<input type="${type}" data-flow-field="${name}" value="${escape(value)}"></label>`;
  const checkbox = (name, label, checked) => `<label class="flow-check"><input type="checkbox" data-flow-field="${name}"${checked ? ' checked' : ''}>${label}</label>`;
  globalThis.ReportsFlow = {
    create(service) {
      return { serviceId: service.id, step: 'details', answers: { description: '', extra: false, extraDetail: '', address: '', reference: '', locationConfirmed: false, contactMode: '', name: '', email: '', phone: '', updates: true, similarReviewed: false, reviewConsent: false }, photos: [], error: '', confirmation: false };
    },
    handle(draft, service, action, payload = {}) {
      if (action === 'field') {
        if (!Object.hasOwn(draft.answers, payload.field)) return draft;
        const answers = { ...draft.answers, reviewConsent: false, [payload.field]: payload.value };
        if (payload.field === 'address') answers.locationConfirmed = false;
        return { ...draft, answers, error: '' };
      }
      if (action === 'confirm') return { ...draft, answers: { ...draft.answers, locationConfirmed: Boolean(draft.answers.address.trim()) }, error: '' };
      if (action === 'save') return { ...draft, saved: true, error: '' };
      if (action === 'add-photo') {
        if (service.attachments === 'none') return draft;
        if (Number.isFinite(service.attachmentLimit) && draft.photos.length >= service.attachmentLimit) return { ...draft, error: 'The advertised attachment limit has been reached.' };
        return { ...draft, answers: { ...draft.answers, reviewConsent: false }, photos: [...draft.photos, { name: 'Sample evidence', sample: true }], error: '' };
      }
      if (action === 'remove-photo') return { ...draft, answers: { ...draft.answers, reviewConsent: false }, photos: [...draft.photos.slice(0, payload.index), ...draft.photos.slice(Number(payload.index) + 1)], error: '' };
      if (action === 'back') {
        const index = steps.indexOf(draft.step);
        return index > 0 ? { ...draft, step: steps[index - 1], confirmation: false, error: '' } : draft;
      }
      if (action === 'submit' && draft.step === 'review') {
        if (!draft.answers.reviewConsent) return { ...draft, error: 'Please confirm that this creates a local demo receipt only.' };
        return { ...draft, step: 'confirmation', confirmation: true, error: '' };
      }
      if (action === 'next' && steps.indexOf(draft.step) < 4) {
        const error = validate(draft, service);
        return error ? { ...draft, error } : { ...draft, step: steps[steps.indexOf(draft.step) + 1], error: '' };
      }
      return draft;
    },
    render(draft, service, escape) {
      const answers = draft.answers;
      let content = '';
      if (draft.step === 'details') {
        const prompt = service.name === 'Flooding' ? 'Where is water collecting?' : 'What needs attention?';
        content = `<h1>${escape(service.name)}</h1><p>Example questions</p><p>These example questions illustrate the design. The live service may ask for more details.</p><label class="flow-field">${prompt}<textarea data-flow-field="description" rows="4">${escape(answers.description)}</textarea></label>${checkbox('extra', 'Add a useful extra detail', answers.extra)}${answers.extra ? field('extraDetail', 'Extra detail', answers.extraDetail, escape) : ''}`;
      }
      if (draft.step === 'location') content = `<h1>Place it on the map.</h1><p>Use an address or intersection. This sample pin stays in the prototype.</p><div class="flow-map" role="img" aria-label="Illustrative location pin, not a live map"><span aria-hidden="true">⌖</span><strong>${escape(service.boundary)}</strong></div>${field('address', 'Address or intersection', answers.address, escape)}${field('reference', 'Nearby landmark (optional)', answers.reference, escape)}${button('confirm', answers.locationConfirmed ? 'Location confirmed' : 'Confirm sample pin')}`;
      if (draft.step === 'photos') content = `<h1>A little more context.</h1><p>${service.attachments === 'none' ? 'No photos are needed for this service.' : service.attachments === 'required' ? 'Photos are required for this service.' : 'Evidence is optional in this design example.'}</p><p>Sample evidence previews the design only. No photo is uploaded.</p><div class="flow-photos">${draft.photos.map((photo, index) => `<div class="flow-photo"><span aria-hidden="true">▧</span><span>${escape(photo.name)} · illustration</span><button type="button" data-action="flow-remove-photo" data-index="${index}" aria-label="Remove sample photo ${index + 1}">Remove</button></div>`).join('')}</div>${service.attachments === 'none' ? '' : button('add-photo', 'Add sample evidence')}`;
      if (draft.step === 'contact') content = `<h1>How should we reach you?</h1><p>Demonstration only. Contact details stay in the local prototype.</p><label class="flow-field">Contact choice<select data-flow-field="contactMode"><option value="">Choose an option</option>${namedRequired(service) ? '' : `<option value="anonymous"${answers.contactMode === 'anonymous' ? ' selected' : ''}>No contact details</option>`}<option value="named"${answers.contactMode === 'named' ? ' selected' : ''}>Provide contact details</option></select></label>${answers.contactMode === 'named' ? `${field('name', 'Full name', answers.name, escape)}${field('email', 'Email', answers.email, escape, 'email')}${field('phone', 'Phone (optional)', answers.phone, escape, 'tel')}${checkbox('updates', 'Preview email updates', answers.updates)}` : '<p>No contact details are included.</p>'}`;
      if (draft.step === 'review') content = `<h1>One last look.</h1><p>Review this local example before creating a demo receipt.</p><dl class="flow-review"><dt>Service</dt><dd>${escape(service.name)}</dd><dt>Details</dt><dd>${escape(answers.description)}</dd><dt>Location</dt><dd>${escape(answers.address)}</dd><dt>Evidence</dt><dd>${draft.photos.length} sample photo(s)</dd><dt>Contact</dt><dd>${answers.contactMode === 'named' ? `${escape(answers.name)} · ${escape(answers.email)}` : 'No contact details'}</dd></dl>${checkbox('reviewConsent', 'I understand this creates a local demo receipt. Nothing is sent to the City.', answers.reviewConsent)}`;
      if (draft.step === 'confirmation') content = `<div class="flow-success" aria-hidden="true">✓</div><h1>Demo receipt saved.</h1><p>No request was sent to the City.</p><p>Your design preview for ${escape(service.name)} is complete. No Service Request number has been created.</p>`;
      const next = draft.step === 'review' ? button('submit', 'Create demo receipt') : button('next', 'Continue');
      return `<section class="flow-panel" data-od-id="report-${draft.step}"><p class="step-kicker">Local report preview · Step ${steps.indexOf(draft.step) + 1} of 6</p>${content}${draft.error ? `<p class="flow-error" role="alert">${escape(draft.error)}</p>` : ''}<div class="flow-actions">${draft.step === 'confirmation' ? '' : next}${button('save', 'Save draft')}${button('back', 'Back')}</div></section>`;
    }
  };
})();
