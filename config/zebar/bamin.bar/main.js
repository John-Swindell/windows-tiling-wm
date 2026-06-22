/* managed-by: winwm-dotfiles */

const state = {
  output: {},
  providerReady: false,
};

const els = {
  bar: document.querySelector(".bar"),
  workspaces: document.querySelector("#workspaces"),
  title: document.querySelector("#title"),
  mode: document.querySelector("#mode"),
  cpu: document.querySelector("#cpu"),
  network: document.querySelector("#network"),
  battery: document.querySelector("#battery"),
  clock: document.querySelector("#clock"),
};

const workspaceNames = ["1", "2", "3", "4", "5", "6", "7", "8", "9"];

function text(value, fallback = "") {
  if (value === null || value === undefined || value === "") {
    return fallback;
  }

  return String(value);
}

function setHidden(el, hidden) {
  el.classList.toggle("hidden", hidden);
}

function isWorkspaceFocused(workspace, output) {
  const focused = output.glazewm?.focusedWorkspace;
  return Boolean(
    workspace.isFocused ||
      workspace.hasFocus ||
      workspace.name === focused?.name ||
      workspace.displayName === focused?.displayName,
  );
}

function workspaceHasWindows(workspace) {
  if (typeof workspace.numWindows === "number") {
    return workspace.numWindows > 0;
  }

  if (Array.isArray(workspace.children)) {
    return workspace.children.length > 0;
  }

  return Boolean(workspace.hasWindows);
}

function workspaceLabel(workspace) {
  return text(workspace.displayName, text(workspace.name, "?"));
}

function fallbackWorkspaces() {
  return workspaceNames.map((name, index) => ({
    name,
    displayName: name,
    isFocused: index === 0,
  }));
}

function renderWorkspaces(output) {
  const glazewm = output.glazewm;
  const workspaces =
    glazewm?.currentWorkspaces ||
    glazewm?.allWorkspaces ||
    fallbackWorkspaces();

  els.workspaces.replaceChildren();

  for (const workspace of workspaces) {
    const node = document.createElement("button");
    node.type = "button";
    node.className = "workspace";
    node.textContent = workspaceLabel(workspace);
    node.classList.toggle("is-focused", isWorkspaceFocused(workspace, output));
    node.classList.toggle("is-visible", Boolean(workspace.isDisplayed || workspace.isVisible));
    node.classList.toggle("has-windows", workspaceHasWindows(workspace));
    node.title = `Workspace ${workspaceLabel(workspace)}`;

    node.addEventListener("click", () => {
      const command = `focus --workspace ${workspace.name || workspace.displayName}`;
      output.glazewm?.runCommand?.(command);
    });

    els.workspaces.append(node);
  }
}

function focusedTitle(output) {
  const container = output.glazewm?.focusedContainer;
  return text(
    container?.title,
    text(container?.window?.title, text(container?.name, "GlazeWM")),
  );
}

function renderMode(output) {
  const modes = output.glazewm?.bindingModes || [];
  const mode = modes[0]?.name || modes[0];

  if (mode) {
    els.mode.textContent = String(mode).toUpperCase();
    setHidden(els.mode, false);
  } else {
    setHidden(els.mode, true);
  }
}

function renderMetric(el, label, value, options = {}) {
  if (value === null || value === undefined || Number.isNaN(value)) {
    setHidden(el, true);
    return;
  }

  const formatted = options.percent ? `${Math.round(value)}%` : text(value);
  el.textContent = `${label} ${formatted}`;
  el.classList.toggle("hot", options.hotAt !== undefined && Number(value) >= options.hotAt);
  setHidden(el, false);
}

function renderBattery(output) {
  const battery = output.battery;

  if (!battery) {
    setHidden(els.battery, true);
    return;
  }

  const suffix = battery.isCharging ? "+" : "";
  els.battery.textContent = `BAT ${Math.round(battery.chargePercent)}%${suffix}`;
  els.battery.classList.toggle("hot", battery.chargePercent <= 20 && !battery.isCharging);
  setHidden(els.battery, false);
}

function renderNetwork(output) {
  const network = output.network;
  const address = network?.defaultInterface?.ipv4Addresses?.[0] || network?.defaultInterface?.name;

  if (!address) {
    setHidden(els.network, true);
    return;
  }

  els.network.textContent = `NET ${address}`;
  setHidden(els.network, false);
}

function renderClock(output) {
  const providerTime = output.date?.formatted;
  if (providerTime) {
    els.clock.textContent = providerTime;
    return;
  }

  els.clock.textContent = new Intl.DateTimeFormat([], {
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).format(new Date());
}

function render() {
  const output = state.output;
  els.bar.dataset.providerState = state.providerReady ? "ready" : "fallback";

  renderWorkspaces(output);
  els.title.textContent = focusedTitle(output);
  renderMode(output);
  renderMetric(els.cpu, "CPU", output.cpu?.usage, { percent: true, hotAt: 85 });
  renderNetwork(output);
  renderBattery(output);
  renderClock(output);
}

async function loadZebarApi() {
  if (window.zebar?.createProviderGroup) {
    return window.zebar;
  }

  try {
    // Zebar's webview has no bundler/import map, so a bare "zebar" specifier
    // can't resolve. Load the client API from the CDN like the starter pack,
    // pinned to the installed Zebar version.
    return await import("https://esm.sh/zebar@3.3");
  } catch {
    return null;
  }
}

async function startProviders() {
  const zebar = await loadZebarApi();

  if (!zebar?.createProviderGroup) {
    render();
    window.setInterval(renderClock, 1000, state.output);
    return;
  }

  const providers = zebar.createProviderGroup({
    glazewm: { type: "glazewm" },
    date: { type: "date", formatting: "EEE d MMM HH:mm" },
    cpu: { type: "cpu", refreshInterval: 2500 },
    network: { type: "network", refreshInterval: 5000 },
    battery: { type: "battery", refreshInterval: 5000 },
  });

  state.providerReady = true;
  state.output = providers.outputMap || {};
  render();

  providers.onOutput(() => {
    state.output = providers.outputMap || {};
    render();
  });
}

render();
startProviders().catch(() => {
  state.providerReady = false;
  render();
});
