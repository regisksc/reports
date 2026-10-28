globalThis.ReportsUI = {
  normalize(row) {
    const evidence = row.evidence;
    const number = (pattern) => { const match = evidence.match(pattern); return match ? Number(match[1]) : null; };
    const boundary = evidence.match(/location boundary ([^;]+)/);
    return { ...row, id: row.name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, ''), mode: evidence.includes('anonymous available') ? 'guest-form' : evidence.includes('contact required') ? 'contact-required' : evidence.includes('account required') ? 'account-required' : 'unknown', boundary: boundary ? boundary[1] : null, attachmentLimit: number(/advertised limit (\d+)/), attachments: evidence.includes('required attachments') ? 'required' : evidence.includes('optional attachments') ? 'optional' : evidence.includes('no upload control') ? 'none' : 'unknown', questionCount: number(/(\d+) configured questions/), preliminaryCount: number(/(\d+) preliminary questions/) };
  },
  search(catalog, query) {
    const term = query.trim().toLowerCase();
    return catalog.filter((service) => `${service.name} ${service.group}`.toLowerCase().includes(term));
  },
  escape(value) {
    return String(value).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;').replaceAll("'", '&#39;');
  },
  services(catalog, query) {
    const e = this.escape;
    const rows = query.trim() ? this.search(catalog, query).map((s) => `<button class="list-button" data-service="${e(s.id)}"><span>${e(s.name)}<small>${e(s.group)}</small></span><span aria-hidden="true">›</span></button>`) : [...new Set(catalog.map((s) => s.group))].map((group) => {
      const count = catalog.filter((s) => s.group === group).length;
      return `<button class="list-button" data-group="${e(group)}"><span>${e(group)}<small>${count} service${count === 1 ? '' : 's'}</small></span><span aria-hidden="true">›</span></button>`;
    });
    return `<section data-od-id="services"><h1 class="page-title">Services</h1><p class="intro">Find the right place to start. Browse by category or search by name.</p><label class="sr-only" for="service-search">Search services</label><input class="search" id="service-search" data-search value="${e(query)}" placeholder="Search services"><div class="stack">${rows.length ? rows.join('') : '<div class="empty"><strong>No services found</strong>Try a different search.</div>'}</div></section>`;
  },
  category(catalog, group) {
    const e = this.escape;
    return `<section data-od-id="category"><button class="back" data-route="services">← All services</button><h1 class="page-title">${e(group)}</h1><p class="intro">Choose the service that best matches your concern.</p><div class="stack">${catalog.filter((s) => s.group === group).map((s) => `<button class="list-button" data-service="${e(s.id)}"><span>${e(s.name)}</span><span aria-hidden="true">›</span></button>`).join('')}</div></section>`;
  },
  service(service) {
    const e = this.escape;
    const contact = { 'guest-form': 'No account is needed to explore this report.', 'contact-required': 'Your contact details are required for this service.', 'account-required': 'A City account is required to request this service.', unknown: 'Availability is still being confirmed.' }[service.mode];
    const photo = service.attachments === 'required' ? 'A photo is required for this service.' : service.attachments === 'optional' ? 'Photos are optional for this service.' : service.attachments === 'none' ? 'No photo is needed for this service.' : 'Photo requirements will be shown when this service is available.';
    const action = service.mode === 'account-required' ? '<p class="notice">Sign-in is shown as a local demo. No City account will be accessed.</p><button class="btn btn-primary" data-route="signin">Explore demo sign in</button>' : service.mode === 'unknown' ? '<p class="notice">The next steps for this service are not verified yet.</p>' : '<p class="notice">This is a local preview. No report is sent to the City.</p><button class="btn btn-primary" data-action="start-flow">Start demo report</button>';
    return `<section data-od-id="service-detail"><button class="back" data-group="${e(service.group)}">← ${e(service.group)}</button><p class="eyebrow">Service information</p><h1 class="page-title">${e(service.name)}</h1><p class="intro">${e(service.group)}</p><div class="card"><h2>Before you start</h2><p>${e(contact)}</p><p>${e(photo)}</p></div><div class="actions">${action}</div></section>`;
  },
  reports(reports) {
    const e = this.escape;
    return reports.length ? `<div class="stack">${reports.map((report) => `<button class="list-button" data-report="${e(report.id)}"><span>${e(report.name)}<small>${e(report.status)} · ${e(report.id)}</small></span><span aria-hidden="true">›</span></button>`).join('')}</div>` : '<div class="empty"><strong>No local reports yet</strong>Start a report to see a draft or preview here.</div>';
  },
  report(report) {
    const e = this.escape;
    return `<section data-od-id="report-detail"><button class="back" data-route="history">← My Reports</button><p class="eyebrow">Local demo record · ${e(report.id)}</p><h1 class="page-title">${e(report.name)}</h1><span class="tag">${e(report.status)}</span><div class="timeline"><p><strong>Local preview</strong><br><span class="muted">Saved on this device</span></p><p><strong>City status not available</strong><br><span class="muted">No request was sent.</span></p></div><div class="notice">City actions to edit or cancel are not verified. You can manage only the local preview.</div><div class="actions">${report.status === 'Draft' ? '<button class="btn btn-primary" data-action="resume">Resume draft</button>' : ''}<button class="btn" data-action="follow">${report.following ? 'Unfollow locally' : 'Follow locally'}</button><button class="btn" data-action="delete-local">Remove local preview</button></div></section>`;
  },
  mount(doc, catalog, flow, storage, dev = false, navigation = {}) {
    const main = doc.querySelector('main');
    if (dev) doc.querySelector('[data-developer]').hidden = false;
    const home = main.innerHTML;
    let route = navigation.initialRoute || 'home';
    let group = '';
    let service = null;
    let query = '';
    let draft = null;
    let reportId = '';
    let message = '';
    const reports = JSON.parse(storage.getItem('reports-demo-records') || '[]');
    const settings = JSON.parse(storage.getItem('reports-demo-settings') || '{}');
    const profile = JSON.parse(storage.getItem('reports-demo-profile') || '{}');
    const save = () => {
      const record = { id: reportId, name: service.name, serviceId: service.id, status: draft.confirmation ? 'Preview complete' : 'Draft', draft };
      const index = reports.findIndex((item) => item.id === reportId);
      if (index < 0) reports.push(record); else reports[index] = { ...reports[index], ...record };
      storage.setItem('reports-demo-records', JSON.stringify(reports));
    };
    const draw = () => {
      main.innerHTML = route === 'home' ? home : route === 'services' ? this.services(catalog, query) : route === 'category' ? this.category(catalog, group) : route === 'service' ? this.service(service) : route === 'flow' ? flow.render(draft, service, this.escape) : route === 'report' ? this.report(reports.find((item) => item.id === reportId)) : route === 'history' ? this.page(route).replace('<div id="report-list"></div>', this.reports(reports)) : this.page(route);
      if (message) main.innerHTML += `<p class="notice" role="status">${this.escape(message)}</p>`;
      doc.querySelectorAll('[data-setting]').forEach((field) => { if (Object.hasOwn(settings, field.dataset.setting)) { if (field.type === 'checkbox') field.checked = settings[field.dataset.setting]; else field.value = settings[field.dataset.setting]; } });
      doc.querySelectorAll('[data-profile]').forEach((field) => { if (Object.hasOwn(profile, field.dataset.profile)) field.value = profile[field.dataset.profile]; });
      doc.querySelectorAll('.bottom-nav button').forEach((button) => { if (button.dataset.route === route) button.setAttribute('aria-current', 'page'); else button.removeAttribute('aria-current'); });
    };
    doc.addEventListener('click', (event) => {
      const target = event.target.closest('[data-route],[data-group],[data-service],[data-report],[data-action]');
      if (!target) return;
      event.preventDefault();
      message = '';
      if (target.dataset.route) { route = target.dataset.route; query = ''; }
      if (target.dataset.group) { group = target.dataset.group; route = 'category'; }
      if (target.dataset.service) { service = catalog.find((item) => item.id === target.dataset.service); route = 'service'; }
      if (target.dataset.report) { reportId = target.dataset.report; route = 'report'; }
      if (target.dataset.action === 'start-flow') { draft = flow.create(service); reportId = `local-${Date.now()}-${reports.length + 1}`; route = 'flow'; }
      if (target.dataset.action === 'resume') { const record = reports.find((item) => item.id === reportId); service = catalog.find((item) => item.id === record.serviceId); draft = record.draft; route = 'flow'; }
      if (target.dataset.action === 'follow') { const record = reports.find((item) => item.id === reportId); record.following = !record.following; storage.setItem('reports-demo-records', JSON.stringify(reports)); }
      if (target.dataset.action === 'delete-local') { reports.splice(reports.findIndex((item) => item.id === reportId), 1); storage.setItem('reports-demo-records', JSON.stringify(reports)); route = 'history'; }
      if (target.dataset.action === 'nearby-filter') message = 'Filters are saved locally. Nearby results are not live.';
      if (target.dataset.action === 'nearby-clear') { Object.assign(settings, { area: '', startDate: '', endDate: '', nearbyStatus: 'All statuses', nearbyType: '', neighborhoodDistrict: '', councilDistrict: '', nearbyView: 'List' }); storage.setItem('reports-demo-settings', JSON.stringify(settings)); message = 'Demo filters cleared.'; }
      if (target.dataset.action && target.dataset.action.startsWith('flow-')) {
        const action = target.dataset.action.slice(5);
        draft = flow.handle(draft, service, action, { index: target.dataset.index });
        if (action === 'save' || draft.confirmation) save();
        if (action === 'save') route = 'history';
      }
      draw();
      main.focus();
    });
    doc.addEventListener('input', (event) => {
      if ('setting' in event.target.dataset) { settings[event.target.dataset.setting] = event.target.type === 'checkbox' ? event.target.checked : event.target.value; storage.setItem('reports-demo-settings', JSON.stringify(settings)); return; }
      if ('flowField' in event.target.dataset) {
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
        draft = flow.handle(draft, service, 'field', { field: event.target.dataset.flowField, value });
        if (event.target.type === 'checkbox' || event.target.tagName === 'SELECT') { draw(); doc.querySelector(`[data-flow-field="${event.target.dataset.flowField}"]`).focus(); }
        return;
      }
      if (!('search' in event.target.dataset)) return;
      query = event.target.value;
      draw();
      const input = doc.getElementById('service-search');
      input.focus();
      input.setSelectionRange(query.length, query.length);
    });
    doc.addEventListener('submit', (event) => {
      const form = event.target.dataset.form;
      if (!form) return;
      event.preventDefault();
      const data = Object.fromEntries([...event.target.elements].filter((field) => field.name && field.name !== 'password').map((field) => [field.name, field.value]));
      if (form === 'lookup') {
        const match = reports.find((item) => item.id === data.reference);
        if (match) { reportId = match.id; route = 'report'; message = ''; } else { route = 'lookup'; message = 'No local preview matches that reference. City lookup is not connected.'; }
      } else if (form === 'recovery') { route = 'recovery'; message = 'Demo only: no email was sent.'; }
      else { Object.assign(profile, data); storage.setItem('reports-demo-profile', JSON.stringify(profile)); route = 'account'; message = 'Demo profile saved locally. No City account was changed.'; }
      draw();
      main.focus();
    });
    if (route !== 'home') draw();
  },
  page(route) {
    const pages = {
      developer: `<button class="back" data-route="home">← Home</button><h1 class="page-title">Developer preview</h1><p class="intro">Explicitly enabled for this session.</p><div class="notice">No network tools or City actions are available in this design demo.</div>`,
      nearby: `<h1 class="page-title">Nearby</h1><p class="intro">Explore how nearby requests could be filtered.</p><div class="notice">Not live. The City request map and results are not connected in this demo. The observed City view has a 2,000-record maximum.</div><label class="field">Search an area<input placeholder="Street or neighborhood" data-setting="area"></label><label class="field">Start date<input type="date" data-setting="startDate"></label><label class="field">End date<input type="date" data-setting="endDate"></label><label class="field">Status<select data-setting="nearbyStatus"><option>All statuses</option><option>Open</option><option>Closed</option></select></label><label class="field">Request type<input placeholder="All services" data-setting="nearbyType"></label><label class="field">Neighborhood Council District<input data-setting="neighborhoodDistrict" placeholder="All districts"></label><label class="field">Council District<input data-setting="councilDistrict" placeholder="All districts"></label><label class="field">Map or list<select data-setting="nearbyView"><option>List</option><option>Map</option></select></label><div class="actions"><button class="btn" data-action="nearby-filter">Apply demo filters</button><button class="btn" data-action="nearby-clear">Clear filters</button></div><div class="empty"><strong>No live results</strong>Location and City records are unavailable in this preview.</div>`,
      history: `<h1 class="page-title">My Reports</h1><p class="intro">Your drafts and completed previews stay on this device.</p><div id="report-list"></div><div class="actions"><button class="btn" data-route="lookup">Look up a request</button><button class="btn btn-primary" data-route="services">Start a report</button></div>`,
      account: `<h1 class="page-title">Your account</h1><p class="intro">Explore account tools without connecting to a City account.</p><div class="card"><h2>Demo account</h2><p>Sign in, registration and profile changes are simulated locally.</p><div class="actions"><button class="btn btn-primary" data-route="signin">Sign in to demo</button><button class="btn" data-route="register">Create demo account</button></div></div><div class="stack" style="margin-top:16px"><button class="list-button" data-route="profile">Profile <span>›</span></button><button class="list-button" data-route="settings">Preferences & accessibility <span>›</span></button><button class="list-button" data-route="help">Help <span>›</span></button></div>`,
      signin: `<button class="back" data-route="account">← Account</button><h1 class="page-title">Sign in</h1><p class="intro">Demo only. Do not enter a real password.</p><form data-form="signin"><label class="field">Email<input type="email" name="email" required autocomplete="off"></label><label class="field">Demo password<input type="password" name="password" required autocomplete="off"></label><button class="btn btn-primary" type="submit">Continue in demo</button></form><div class="actions"><button class="btn" data-route="recovery">Forgot password?</button><button class="btn" data-route="register">Create account</button></div>`,
      register: `<button class="back" data-route="account">← Account</button><h1 class="page-title">Create a demo account</h1><p class="intro">No real account will be created.</p><form data-form="register"><label class="field">Name<input name="name" required></label><label class="field">Email<input type="email" name="email" required></label><button class="btn btn-primary" type="submit">Create local profile</button></form>`,
      recovery: `<button class="back" data-route="signin">← Sign in</button><h1 class="page-title">Recover access</h1><p class="intro">This preview does not send recovery emails.</p><form data-form="recovery"><label class="field">Email<input type="email" name="email" required></label><button class="btn btn-primary" type="submit">Preview recovery</button></form>`,
      profile: `<button class="back" data-route="account">← Account</button><h1 class="page-title">Profile</h1><p class="intro">These details are saved only in this browser.</p><form data-form="profile"><label class="field">Display name<input name="name" data-profile="name"></label><label class="field">Email<input type="email" name="email" data-profile="email"></label><button class="btn btn-primary" type="submit">Save demo profile</button></form>`,
      settings: `<button class="back" data-route="account">← Account</button><h1 class="page-title">Preferences</h1><p class="intro">Your choices stay on this device.</p><div class="card"><label><input type="checkbox" data-setting="updates"> Updates for demo reports</label><p>Notifications are not sent in this prototype.</p></div><div class="card" style="margin-top:12px"><h2>Accessibility</h2><p>Use your device’s text size, keyboard navigation and reduced-motion settings.</p></div><div class="actions"><button class="btn" data-route="help">Accessibility help</button></div>`,
      help: `<button class="back" data-route="home">← Home</button><h1 class="page-title">Help & accessibility</h1><p class="intro">This is a design demo, not an emergency service.</p><div class="stack"><div class="card"><h2>Emergency?</h2><p>For an immediate emergency, call 911.</p></div><div class="card"><h2>About this preview</h2><p>Reports, account details and preferences remain local. No City services are contacted.</p></div><div class="card"><h2>Accessibility</h2><p>Controls support keyboard focus and the reduced-motion setting on your device.</p></div></div><div class="actions"><button class="btn" data-route="services">Explore services</button></div>`,
      lookup: `<button class="back" data-route="history">← My Reports</button><h1 class="page-title">Look up a request</h1><p class="intro">City lookup is not connected in this preview.</p><form data-form="lookup"><label class="field">Demo reference<input name="reference" required placeholder="Enter a local reference"></label><button class="btn btn-primary" type="submit">Find local preview</button></form>`
    };
    return `<section data-od-id="${this.escape(route)}">${pages[route]}</section>`;
  }
};
