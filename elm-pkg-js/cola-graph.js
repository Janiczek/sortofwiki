const SVG_NS = "http://www.w3.org/2000/svg";
const XLINK_NS = "http://www.w3.org/1999/xlink";

/** ParaGraphL iterations (GPU layout seed before Cola); wiki graph only. */
const PARAGRAPHL_LAYOUT_TICKS = 100;

/** Cola refinement ticks after ParaGraphL seeds positions (wiki graph). */
const COLA_LAYOUT_TICKS = 5;

/** Cola ticks for page graph — circle seed, no ParaGraphL. */
const PAGE_GRAPH_COLA_TICKS = 10;

function layoutNodesOnCircle(nodes) {
  const n = nodes.length;
  const radius = 80 + n * 6;
  nodes.forEach(function (node, i) {
    const a = (2 * Math.PI * i) / Math.max(n, 1);
    node.x = Math.cos(a) * radius;
    node.y = Math.sin(a) * radius;
  });
}

/**
 * ParaGraphL FR coordinates can sit in a tiny numeric range on large graphs;
 * center and scale so the bbox has a minimum span (roughly Cola-like spread).
 * Identical coordinates cannot be fixed by scaling — use a circle fallback.
 */
function colaLinkDistance(graph, link) {
  if (graph.graphName === "page") {
    if (link.deemphasized) {
      return 165;
    }
    return link.kind === "tag" ? 145 : 125;
  }
  if (link.deemphasized) {
    return 145;
  }
  return link.kind === "tag" ? 130 : 120;
}

function normalizeLayoutSpread(nodes) {
  if (!nodes || nodes.length === 0) {
    return;
  }
  let minX = Infinity;
  let maxX = -Infinity;
  let minY = Infinity;
  let maxY = -Infinity;
  nodes.forEach(function (node) {
    if (Number.isFinite(node.x) && Number.isFinite(node.y)) {
      minX = Math.min(minX, node.x);
      maxX = Math.max(maxX, node.x);
      minY = Math.min(minY, node.y);
      maxY = Math.max(maxY, node.y);
    }
  });
  if (!Number.isFinite(minX) || !Number.isFinite(maxX)) {
    layoutNodesOnCircle(nodes);
    return;
  }
  const w = maxX - minX;
  const h = maxY - minY;
  const span = Math.max(w, h);
  if (span < 1e-6) {
    layoutNodesOnCircle(nodes);
    return;
  }
  const count = nodes.length;
  const minSpan = 140 + Math.sqrt(count) * 110 + count * 4;
  if (span >= minSpan) {
    return;
  }
  const midX = (minX + maxX) / 2;
  const midY = (minY + maxY) / 2;
  const scale = minSpan / span;
  nodes.forEach(function (node) {
    if (Number.isFinite(node.x) && Number.isFinite(node.y)) {
      node.x = (node.x - midX) * scale;
      node.y = (node.y - midY) * scale;
    }
  });
}

/**
 * Page graph: Cola only, fixed tick budget (no progress UI).
 * Mutates nodes in place.
 */
function runPageGraphColaTicks(graph, nodes, links) {
  const colaLayout = new window.cola.Layout();
  colaLayout
    .nodes(nodes)
    .links(links)
    .linkDistance(function (link) {
      return colaLinkDistance(graph, link);
    })
    .avoidOverlaps(true)
    .start(90, 0, 0, 0, false);
  let t = 0;
  while (t < PAGE_GRAPH_COLA_TICKS) {
    if (colaLayout.tick()) {
      break;
    }
    t += 1;
  }
}

function isPrimaryUnmodifiedClick(event) {
  return (
    event.button === 0 &&
    !event.defaultPrevented &&
    !event.metaKey &&
    !event.ctrlKey &&
    !event.shiftKey &&
    !event.altKey
  );
}

function isSameOriginPathNavigation(url) {
  return (
    url.origin === window.location.origin &&
    (url.protocol === "http:" || url.protocol === "https:")
  );
}

function navigateInSpa(url) {
  const nextUrl = url.pathname + url.search + url.hash;
  const currentUrl =
    window.location.pathname + window.location.search + window.location.hash;

  if (nextUrl === currentUrl) {
    return;
  }

  window.history.pushState({}, "", nextUrl);
  window.dispatchEvent(new PopStateEvent("popstate"));
}

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function parseCssColorToRgb(colorValue) {
  if (!colorValue || typeof colorValue !== "string") {
    return null;
  }

  const value = colorValue.trim().toLowerCase();
  const rgbMatch = value.match(
    /^rgba?\(\s*([0-9]+(?:\.[0-9]+)?)\s*,\s*([0-9]+(?:\.[0-9]+)?)\s*,\s*([0-9]+(?:\.[0-9]+)?)(?:\s*,\s*[0-9.]+\s*)?\)$/
  );
  if (rgbMatch) {
    return {
      r: clamp(Number(rgbMatch[1]), 0, 255),
      g: clamp(Number(rgbMatch[2]), 0, 255),
      b: clamp(Number(rgbMatch[3]), 0, 255),
    };
  }

  const hexMatch = value.match(/^#([0-9a-f]{3}|[0-9a-f]{6})$/i);
  if (hexMatch) {
    const hex = hexMatch[1];
    if (hex.length === 3) {
      return {
        r: parseInt(hex[0] + hex[0], 16),
        g: parseInt(hex[1] + hex[1], 16),
        b: parseInt(hex[2] + hex[2], 16),
      };
    }
    return {
      r: parseInt(hex.slice(0, 2), 16),
      g: parseInt(hex.slice(2, 4), 16),
      b: parseInt(hex.slice(4, 6), 16),
    };
  }

  return null;
}

function relativeLuminance(rgb) {
  if (!rgb) {
    return null;
  }

  const srgbToLinear = function srgbToLinear(channel) {
    const v = channel / 255;
    if (v <= 0.03928) {
      return v / 12.92;
    }
    return Math.pow((v + 0.055) / 1.055, 2.4);
  };

  const r = srgbToLinear(rgb.r);
  const g = srgbToLinear(rgb.g);
  const b = srgbToLinear(rgb.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function isDarkMode(host) {
  if (!host) {
    return false;
  }

  const appRoot = host.closest(".app-root");
  if (!appRoot) {
    return false;
  }

  const styles = getComputedStyle(appRoot);
  const bgColor = styles.getPropertyValue("--bg").trim() || styles.backgroundColor;
  const parsedBg = parseCssColorToRgb(bgColor);
  const luminance = relativeLuminance(parsedBg);
  if (luminance !== null) {
    return luminance < 0.35;
  }

  return appRoot.classList.contains("dark");
}

function appThemeVar(host, variableName, fallback) {
  if (!host) {
    return fallback;
  }
  const appRoot = host.closest(".app-root");
  if (!appRoot) {
    return fallback;
  }
  const value = getComputedStyle(appRoot).getPropertyValue(variableName).trim();
  return value || fallback;
}

function inboundScale(inboundCount) {
  return clamp(Math.log(inboundCount + 1) / Math.log(11), 0, 1);
}

const NODE_FONT_SIZE = 12;

const NODE_CLEARANCE_PX = 6;

function nodePenWidth(node) {
  const base = 0.5 + inboundScale(node.inboundCount || 0);
  if (node.kind === "focused" || node.kind === "missingFocused") {
    return Math.max(2, base);
  }
  return base;
}

function projectFromCenterToRectBoundary(centerX, centerY, halfWidth, halfHeight, dx, dy) {
  if (!Number.isFinite(dx) || !Number.isFinite(dy) || (dx === 0 && dy === 0)) {
    return { x: centerX, y: centerY };
  }

  const tx = dx === 0 ? Infinity : halfWidth / Math.abs(dx);
  const ty = dy === 0 ? Infinity : halfHeight / Math.abs(dy);
  const t = Math.min(tx, ty);

  return {
    x: centerX + dx * t,
    y: centerY + dy * t,
  };
}

function edgeEndpoints(source, target) {
  const dx = target.x - source.x;
  const dy = target.y - source.y;
  const sourceWidth = Number.isFinite(source.visualWidth)
    ? source.visualWidth
    : source.width;
  const sourceHeight = Number.isFinite(source.visualHeight)
    ? source.visualHeight
    : source.height;
  const targetWidth = Number.isFinite(target.visualWidth)
    ? target.visualWidth
    : target.width;
  const targetHeight = Number.isFinite(target.visualHeight)
    ? target.visualHeight
    : target.height;

  const sourcePoint = projectFromCenterToRectBoundary(
    source.x,
    source.y,
    sourceWidth / 2,
    sourceHeight / 2,
    dx,
    dy
  );
  const targetPoint = projectFromCenterToRectBoundary(
    target.x,
    target.y,
    targetWidth / 2,
    targetHeight / 2,
    -dx,
    -dy
  );

  return {
    x1: sourcePoint.x,
    y1: sourcePoint.y,
    x2: targetPoint.x,
    y2: targetPoint.y,
  };
}

function measureNodeBox(node) {
  const fontSize = NODE_FONT_SIZE;
  const charWidth = fontSize * 0.56;
  const labelWidth = Math.max((node.id || "").length * charWidth + 28, 66);
  const labelHeight = 28;
  const emphasisPad = (node.inboundCount || 0) > 0 ? 6 : 0;
  const visualWidth = Math.round(labelWidth + emphasisPad);
  const visualHeight = labelHeight;
  return {
    width: visualWidth + NODE_CLEARANCE_PX * 2,
    height: visualHeight + NODE_CLEARANCE_PX * 2,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
  };
}

function parseGraphData(raw) {
  if (!raw) {
    return null;
  }
  try {
    const parsed = JSON.parse(raw);
    if (
      !parsed ||
      typeof parsed !== "object" ||
      !Array.isArray(parsed.nodes) ||
      !Array.isArray(parsed.edges)
    ) {
      return null;
    }
    return parsed;
  } catch (_) {
    return null;
  }
}

const WIKI_GRAPH_CACHE_PREFIX = "sortofwiki_wikigraph_";
const WIKI_GRAPH_CACHE_VERSION_SUFFIX = "_version";
const WIKI_GRAPH_CACHE_GRAPH_SUFFIX = "_graph";
const MAX_WIKI_GRAPH_CACHE_ENTRIES = 24;
const MAX_WIKI_GRAPH_CACHE_BYTES = 2000000;

function wikiGraphCacheKeys(wikiSlug) {
  return {
    versionKey:
      WIKI_GRAPH_CACHE_PREFIX + wikiSlug + WIKI_GRAPH_CACHE_VERSION_SUFFIX,
    graphKey: WIKI_GRAPH_CACHE_PREFIX + wikiSlug + WIKI_GRAPH_CACHE_GRAPH_SUFFIX,
  };
}

function readLocalStorageSafe(key) {
  try {
    return window.localStorage.getItem(key);
  } catch (_) {
    return null;
  }
}

function writeLocalStorageSafe(key, value) {
  try {
    window.localStorage.setItem(key, value);
    return true;
  } catch (_) {
    return false;
  }
}

function removeLocalStorageSafe(key) {
  try {
    window.localStorage.removeItem(key);
  } catch (_) {
    /* no-op */
  }
}

function parseContentVersion(value) {
  if (typeof value !== "string" || value.trim() === "") {
    return null;
  }
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 0) {
    return null;
  }
  return parsed;
}

function getWikiGraphCacheContext(host) {
  const wikiSlugAttr = host.getAttribute("data-graph-wiki-slug");
  const contentVersionAttr = host.getAttribute("data-graph-content-version");
  const wikiSlug = typeof wikiSlugAttr === "string" ? wikiSlugAttr.trim() : "";
  const contentVersion = parseContentVersion(contentVersionAttr);
  if (!wikiSlug || contentVersion === null) {
    return null;
  }
  const keys = wikiGraphCacheKeys(wikiSlug);
  return {
    wikiSlug: wikiSlug,
    contentVersion: contentVersion,
    versionKey: keys.versionKey,
    graphKey: keys.graphKey,
  };
}

function parseCachedGraphPayload(raw) {
  if (!raw) {
    return null;
  }
  try {
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object" || !Array.isArray(parsed.nodePositions)) {
      return null;
    }
    return parsed;
  } catch (_) {
    return null;
  }
}

function applyCachedNodePositions(nodes, cachedPayload) {
  if (!Array.isArray(cachedPayload.nodePositions)) {
    return false;
  }
  const positionsById = new Map(
    cachedPayload.nodePositions
      .filter(function (entry) {
        return (
          entry &&
          typeof entry.id === "string" &&
          Number.isFinite(entry.x) &&
          Number.isFinite(entry.y)
        );
      })
      .map(function (entry) {
        return [entry.id, entry];
      })
  );
  if (positionsById.size === 0) {
    return false;
  }

  let appliedCount = 0;
  nodes.forEach(function (node) {
    const cached = positionsById.get(node.id);
    if (!cached) {
      return;
    }
    node.x = cached.x;
    node.y = cached.y;
    appliedCount += 1;
  });

  return appliedCount > 0 && appliedCount === nodes.length;
}

function readCachedWikiGraphPayload(cacheContext) {
  const expectedVersion = String(cacheContext.contentVersion);
  const storedVersion = readLocalStorageSafe(cacheContext.versionKey);
  if (storedVersion !== expectedVersion) {
    removeLocalStorageSafe(cacheContext.graphKey);
    return null;
  }
  const cached = parseCachedGraphPayload(readLocalStorageSafe(cacheContext.graphKey));
  if (!cached) {
    return null;
  }
  return cached;
}

function estimateJsonBytes(jsonValue) {
  return jsonValue.length * 2;
}

function collectWikiGraphCacheEntries() {
  const entries = [];
  try {
    for (let i = 0; i < window.localStorage.length; i += 1) {
      const key = window.localStorage.key(i);
      if (
        typeof key !== "string" ||
        !key.startsWith(WIKI_GRAPH_CACHE_PREFIX) ||
        !key.endsWith(WIKI_GRAPH_CACHE_VERSION_SUFFIX)
      ) {
        continue;
      }
      const wikiSlug = key.slice(
        WIKI_GRAPH_CACHE_PREFIX.length,
        key.length - WIKI_GRAPH_CACHE_VERSION_SUFFIX.length
      );
      if (!wikiSlug) {
        continue;
      }
      const keys = wikiGraphCacheKeys(wikiSlug);
      const graphRaw = readLocalStorageSafe(keys.graphKey);
      const parsed = parseCachedGraphPayload(graphRaw);
      entries.push({
        wikiSlug: wikiSlug,
        versionKey: keys.versionKey,
        graphKey: keys.graphKey,
        savedAtMs:
          parsed && Number.isFinite(parsed.savedAtMs) ? parsed.savedAtMs : 0,
      });
    }
  } catch (_) {
    return [];
  }
  return entries;
}

function enforceWikiGraphCacheBounds() {
  const entries = collectWikiGraphCacheEntries();
  if (entries.length <= MAX_WIKI_GRAPH_CACHE_ENTRIES) {
    return;
  }
  entries.sort(function (a, b) {
    return a.savedAtMs - b.savedAtMs;
  });
  const removeCount = entries.length - MAX_WIKI_GRAPH_CACHE_ENTRIES;
  for (let i = 0; i < removeCount; i += 1) {
    removeLocalStorageSafe(entries[i].versionKey);
    removeLocalStorageSafe(entries[i].graphKey);
  }
}

function writeCachedWikiGraphPayload(cacheContext, nodes) {
  const payload = {
    savedAtMs: Date.now(),
    nodePositions: nodes.map(function (node) {
      const x = Number.isFinite(node.x) ? node.x : 0;
      const y = Number.isFinite(node.y) ? node.y : 0;
      return {
        id: node.id,
        x: x,
        y: y,
      };
    }),
  };
  const json = JSON.stringify(payload);
  if (estimateJsonBytes(json) > MAX_WIKI_GRAPH_CACHE_BYTES) {
    return;
  }
  if (!writeLocalStorageSafe(cacheContext.graphKey, json)) {
    return;
  }
  if (
    !writeLocalStorageSafe(
      cacheContext.versionKey,
      String(cacheContext.contentVersion)
    )
  ) {
    removeLocalStorageSafe(cacheContext.graphKey);
    return;
  }
  enforceWikiGraphCacheBounds();
}

function resolveNodeRef(nodeRef, nodes) {
  if (typeof nodeRef === "number") {
    return nodes[nodeRef];
  }
  if (nodeRef && typeof nodeRef === "object") {
    return nodeRef;
  }
  return undefined;
}

function edgeColor(edge, darkMode) {
  if (edge.kind === "tag") {
    if (edge.deemphasized) {
      return darkMode ? "#8f6fd099" : "#7c3aed66";
    }
    return "#7c3aed";
  }

  if (edge.deemphasized) {
    return darkMode ? "#96a07f99" : "#6b728066";
  }
  return darkMode ? "#93a27f" : "#6b7280";
}

function nodePalette(node, darkMode, host) {
  const missing = node.kind === "missing" || node.kind === "missingFocused";
  const focused = node.kind === "focused" || node.kind === "missingFocused";
  const inputBg = appThemeVar(host, "--input-bg", darkMode ? "#1c2312" : "#ffffff");
  const fg = appThemeVar(host, "--fg", darkMode ? "#f1f1e9" : "#0f172a");
  const border = appThemeVar(host, "--border", darkMode ? "#667944" : "#2f3f22");
  const danger = appThemeVar(host, "--danger", "#dc2626");
  const dangerBg = appThemeVar(host, "--danger-bg", darkMode ? "#2c1418" : "#fff5f5");
  const focusRing = appThemeVar(host, "--focus-ring", darkMode ? "#a3cf6e" : "#1f3d1f");

  if (missing) {
    return {
      fill: darkMode ? dangerBg : "#fef2f2",
      stroke: danger,
      text: danger,
      dash: "5 4",
      focusRing: focused ? danger : null,
    };
  }

  return {
    fill: darkMode ? inputBg : "#f8faf6",
    stroke: border,
    text: fg,
    dash: null,
    focusRing: focused ? focusRing : null,
  };
}

function nodeHoverFill(node, darkMode, host) {
  const missing = node.kind === "missing" || node.kind === "missingFocused";
  const tableRowHover = appThemeVar(
    host,
    "--table-row-hover",
    darkMode ? "#3f4f2b" : "#eef5e7"
  );

  if (missing) {
    return darkMode ? "#4a1f25" : "#fee2e2";
  }

  return darkMode ? tableRowHover : "#eef5e7";
}

function createLayoutProgressUI(maxTicks) {
  const wrap = document.createElement("div");
  wrap.className = "layout-progress";
  wrap.setAttribute("role", "status");
  wrap.setAttribute("aria-live", "polite");
  const label = document.createElement("span");
  label.className = "layout-progress-label";
  const progress = document.createElement("progress");
  progress.className = "layout-progress-bar";
  progress.max = maxTicks;
  progress.value = 0;
  label.textContent = "Loading… 0/" + maxTicks;
  wrap.appendChild(label);
  wrap.appendChild(progress);
  return {
    root: wrap,
    setTickIndex: function setTickIndex(tickIndex) {
      const n = Math.min(Math.max(tickIndex, 0), maxTicks);
      progress.value = n;
      label.textContent = "Loading… " + n + "/" + maxTicks;
    },
    remove: function remove() {
      if (wrap.parentNode) {
        wrap.parentNode.removeChild(wrap);
      }
    },
  };
}

function appendGraphSvgToColaHost(host, graph, nodes, links, darkMode) {
  normalizeLayoutSpread(nodes);

  const positionedNodes = nodes.filter(function (node) {
    return Number.isFinite(node.x) && Number.isFinite(node.y);
  });

  if (positionedNodes.length === 0) {
    const message = document.createElement("div");
    message.textContent = "Graph layout failed.";
    host._root.appendChild(message);
    return;
  }

  const bounds = positionedNodes.reduce(
    function (acc, node) {
      const left = node.x - node.width / 2;
      const right = node.x + node.width / 2;
      const top = node.y - node.height / 2;
      const bottom = node.y + node.height / 2;
      return {
        minX: Math.min(acc.minX, left),
        maxX: Math.max(acc.maxX, right),
        minY: Math.min(acc.minY, top),
        maxY: Math.max(acc.maxY, bottom),
      };
    },
    { minX: Infinity, maxX: -Infinity, minY: Infinity, maxY: -Infinity }
  );

  const padX = 48;
  const padY = 42;
  const minX = bounds.minX - padX;
  const minY = bounds.minY - padY;
  const vbWidth = Math.max(bounds.maxX - bounds.minX + padX * 2, 320);
  const vbHeight = Math.max(bounds.maxY - bounds.minY + padY * 2, 240);

  const svg = document.createElementNS(SVG_NS, "svg");
  svg.setAttribute("viewBox", `${minX} ${minY} ${vbWidth} ${vbHeight}`);
  svg.setAttribute("width", String(Math.round(vbWidth)));
  svg.setAttribute("height", String(Math.round(vbHeight)));
  svg.setAttribute("data-intrinsic-size", "true");
  svg.setAttribute("aria-label", `${graph.graphName || "wiki"} graph`);

  const defs = document.createElementNS(SVG_NS, "defs");
  const marker = document.createElementNS(SVG_NS, "marker");
  marker.setAttribute("id", "arrowhead");
  marker.setAttribute("markerWidth", "8");
  marker.setAttribute("markerHeight", "8");
  marker.setAttribute("refX", "7");
  marker.setAttribute("refY", "4");
  marker.setAttribute("orient", "auto");
  marker.setAttribute("markerUnits", "strokeWidth");
  const markerPath = document.createElementNS(SVG_NS, "path");
  markerPath.setAttribute("d", "M 0 0 L 8 4 L 0 8 z");
  markerPath.setAttribute("fill", darkMode ? "#95a37f" : "#6b7280");
  marker.appendChild(markerPath);
  defs.appendChild(marker);
  svg.appendChild(defs);

  links.forEach(function (link) {
    const source = resolveNodeRef(link.source, nodes);
    const target = resolveNodeRef(link.target, nodes);
    if (!source || !target) {
      return;
    }
    if (
      !Number.isFinite(source.x) ||
      !Number.isFinite(source.y) ||
      !Number.isFinite(target.x) ||
      !Number.isFinite(target.y)
    ) {
      return;
    }
    const points = edgeEndpoints(source, target);

    const line = document.createElementNS(SVG_NS, "line");
    line.setAttribute("x1", String(points.x1));
    line.setAttribute("y1", String(points.y1));
    line.setAttribute("x2", String(points.x2));
    line.setAttribute("y2", String(points.y2));
    line.setAttribute("stroke", edgeColor(link, darkMode));
    line.setAttribute("stroke-width", link.deemphasized ? "0.9" : "1.25");
    line.setAttribute("opacity", link.deemphasized ? "0.85" : "1");
    if (link.kind === "tag") {
      line.setAttribute("stroke-dasharray", "5 4");
    }
    if (link.direction === "directed") {
      line.setAttribute("marker-end", "url(#arrowhead)");
    }
    svg.appendChild(line);
  });

  nodes.forEach(
    function (node) {
      const palette = nodePalette(node, darkMode, host);
      const hoverFill = nodeHoverFill(node, darkMode, host);
      let parsedNodeUrl = null;
      try {
        parsedNodeUrl = new URL(node.href, window.location.href);
      } catch (_) {
        parsedNodeUrl = null;
      }
      const visualWidth = Number.isFinite(node.visualWidth)
        ? node.visualWidth
        : node.width;
      const visualHeight = Number.isFinite(node.visualHeight)
        ? node.visualHeight
        : node.height;
      const nodeLink = document.createElementNS(SVG_NS, "a");
      nodeLink.setAttribute("class", "node");
      if (parsedNodeUrl) {
        nodeLink.setAttribute("href", parsedNodeUrl.href);
        nodeLink.setAttributeNS(XLINK_NS, "xlink:href", parsedNodeUrl.href);
      }
      nodeLink.setAttribute("target", "_self");

      const group = document.createElementNS(SVG_NS, "g");
      group.setAttribute("transform", `translate(${node.x},${node.y})`);

      const rect = document.createElementNS(SVG_NS, "rect");
      rect.setAttribute("x", String(-visualWidth / 2));
      rect.setAttribute("y", String(-visualHeight / 2));
      rect.setAttribute("width", String(visualWidth));
      rect.setAttribute("height", String(visualHeight));
      rect.setAttribute("rx", "5");
      rect.setAttribute("ry", "5");
      rect.setAttribute("fill", palette.fill);
      rect.setAttribute("stroke", palette.stroke);
      rect.setAttribute("stroke-width", String(nodePenWidth(node)));
      if (palette.dash) {
        rect.setAttribute("stroke-dasharray", palette.dash);
      }
      group.appendChild(rect);

      group.addEventListener("mouseenter", function onNodeEnter() {
        rect.setAttribute("fill", hoverFill);
      });
      group.addEventListener("mouseleave", function onNodeLeave() {
        rect.setAttribute("fill", palette.fill);
      });

      if (palette.focusRing) {
        const ring = document.createElementNS(SVG_NS, "rect");
        ring.setAttribute("x", String(-visualWidth / 2 - 3));
        ring.setAttribute("y", String(-visualHeight / 2 - 3));
        ring.setAttribute("width", String(visualWidth + 6));
        ring.setAttribute("height", String(visualHeight + 6));
        ring.setAttribute("rx", "8");
        ring.setAttribute("ry", "8");
        ring.setAttribute("fill", "none");
        ring.setAttribute("stroke", palette.focusRing);
        ring.setAttribute("stroke-width", "1");
        ring.setAttribute("pointer-events", "none");
        group.appendChild(ring);
      }

      const label = document.createElementNS(SVG_NS, "text");
      label.setAttribute("x", "0");
      label.setAttribute("y", "4");
      label.setAttribute("text-anchor", "middle");
      label.setAttribute("fill", palette.text);
      label.textContent = node.id;
      group.appendChild(label);

      const title = document.createElementNS(SVG_NS, "title");
      title.textContent = node.id;
      group.appendChild(title);

      nodeLink.addEventListener("click", function onNodeClick(event) {
        if (!isPrimaryUnmodifiedClick(event)) {
          return;
        }

        if (!parsedNodeUrl) {
          return;
        }

        if (!isSameOriginPathNavigation(parsedNodeUrl)) {
          return;
        }

        event.preventDefault();
        event.stopPropagation();
        navigateInSpa(parsedNodeUrl);
      });

      nodeLink.appendChild(group);
      svg.appendChild(nodeLink);
    },
    host
  );

  host._root.appendChild(svg);
}

class ColaGraphElement extends HTMLElement {
  static get observedAttributes() {
    return [
      "data-graph",
      "data-graph-wiki-slug",
      "data-graph-content-version",
    ];
  }

  constructor() {
    super();
    this._root = this.attachShadow({ mode: "open" });
    this._themeObserver = null;
    this._themeMql = null;
    this._lastRenderKey = null;
    this._onThemeChange = this.renderGraph.bind(this);
    this._onStorageChange = this.handleStorageChange.bind(this);
  }

  connectedCallback() {
    this.setupThemeReactivity();
    window.addEventListener("storage", this._onStorageChange);
    this.renderGraph();
  }

  disconnectedCallback() {
    this.teardownThemeReactivity();
    window.removeEventListener("storage", this._onStorageChange);
  }

  attributeChangedCallback(name, _oldValue, _newValue) {
    if (
      name === "data-graph" ||
      name === "data-graph-wiki-slug" ||
      name === "data-graph-content-version"
    ) {
      this.renderGraph();
    }
  }

  handleStorageChange(event) {
    const cacheContext = getWikiGraphCacheContext(this);
    if (!cacheContext) {
      return;
    }
    if (event && event.storageArea && event.storageArea !== window.localStorage) {
      return;
    }
    if (
      event &&
      event.key &&
      event.key !== cacheContext.versionKey &&
      event.key !== cacheContext.graphKey
    ) {
      return;
    }
    this.renderGraph({ force: true });
  }

  setupThemeReactivity() {
    this.teardownThemeReactivity();

    const appRoot = this.closest(".app-root");
    if (appRoot) {
      this._themeObserver = new MutationObserver(this._onThemeChange);
      this._themeObserver.observe(appRoot, {
        attributes: true,
        attributeFilter: ["class", "style"],
      });
    }

    if (window.matchMedia) {
      this._themeMql = window.matchMedia("(prefers-color-scheme: dark)");
      if (this._themeMql.addEventListener) {
        this._themeMql.addEventListener("change", this._onThemeChange);
      } else if (this._themeMql.addListener) {
        this._themeMql.addListener(this._onThemeChange);
      }
    }
  }

  teardownThemeReactivity() {
    if (this._themeObserver) {
      this._themeObserver.disconnect();
      this._themeObserver = null;
    }

    if (this._themeMql) {
      if (this._themeMql.removeEventListener) {
        this._themeMql.removeEventListener("change", this._onThemeChange);
      } else if (this._themeMql.removeListener) {
        this._themeMql.removeListener(this._onThemeChange);
      }
      this._themeMql = null;
    }
  }

  renderGraph(options) {
    const force = options && options.force === true;
    const rawGraph = this.getAttribute("data-graph");
    const cacheContext = getWikiGraphCacheContext(this);
    const darkMode = isDarkMode(this);
    const renderKey = JSON.stringify({
      darkMode: darkMode,
      rawGraph: rawGraph || "",
      cacheWikiSlug: cacheContext ? cacheContext.wikiSlug : "",
      cacheVersion: cacheContext ? cacheContext.contentVersion : -1,
    });

    if (!force && this._lastRenderKey === renderKey) {
      return;
    }
    this._lastRenderKey = renderKey;
    this._layoutGeneration = (this._layoutGeneration || 0) + 1;
    const layoutGeneration = this._layoutGeneration;
    this._root.innerHTML = "";

    const style = document.createElement("style");
    style.textContent = `
      :host {
        display: block;
        width: max-content;
        min-width: 100%;
        max-width: none;
      }
      svg {
        display: block;
        background: transparent;
      }
      svg[data-intrinsic-size="true"] {
        max-width: none;
        display: block;
      }
      .node {
        cursor: pointer;
      }
      .node:hover rect {
        filter: none;
      }
      text {
        font-family: 'Source Serif 4', system-ui, sans-serif;
        font-size: ${NODE_FONT_SIZE}px;
        pointer-events: none;
        user-select: none;
      }
      .layout-progress {
        display: flex;
        flex-direction: column;
        gap: 0.35rem;
        width: 100%;
        max-width: 100%;
        box-sizing: border-box;
        margin-bottom: 0.5rem;
        padding: 0.15rem 0 0.25rem;
      }
      .layout-progress-label {
        font-family: 'Source Serif 4', system-ui, sans-serif;
        font-size: 12px;
        color: var(--fg-muted, #5c6b52);
      }
      .layout-progress-bar {
        width: 100%;
        height: 8px;
        border-radius: 4px;
        overflow: hidden;
        accent-color: var(--focus-ring, #7c3aed);
      }
    `;
    this._root.appendChild(style);

    const graph = parseGraphData(rawGraph);
    if (!graph || graph.nodes.length === 0) {
      const empty = document.createElement("div");
      empty.textContent = "";
      this._root.appendChild(empty);
      return;
    }

    const nodes = graph.nodes.map(function (node) {
      const box = measureNodeBox(node);
      return {
        id: node.id,
        href: node.href,
        inboundCount: node.inboundCount || 0,
        kind: node.kind || "normal",
        width: box.width,
        height: box.height,
        visualWidth: box.visualWidth,
        visualHeight: box.visualHeight,
      };
    });

    const nodeIndexById = new Map(
      nodes.map(function (node, index) {
        return [node.id, index];
      })
    );

    const links = graph.edges
      .map(function (edge) {
        const source = nodeIndexById.get(edge.from);
        const target = nodeIndexById.get(edge.to);
        if (source === undefined || target === undefined) {
          return null;
        }
        return {
          source: source,
          target: target,
          direction: edge.direction || "directed",
          kind: edge.kind || "link",
          deemphasized: !!edge.deemphasized,
        };
      })
      .filter(Boolean);

    let usedCachedLayout = false;
    if (cacheContext) {
      const cachedGraph = readCachedWikiGraphPayload(cacheContext);
      if (cachedGraph) {
        usedCachedLayout = applyCachedNodePositions(nodes, cachedGraph);
      }
    }

    if (!usedCachedLayout) {
      if (graph.graphName === "page") {
        if (!window.cola || !window.cola.Layout) {
          const message = document.createElement("div");
          message.textContent = "Cola layout unavailable.";
          this._root.appendChild(message);
          return;
        }
        layoutNodesOnCircle(nodes);
        runPageGraphColaTicks(graph, nodes, links);
        appendGraphSvgToColaHost(this, graph, nodes, links, darkMode);
        return;
      }

      if (!window.paraGraphLLayoutBegin) {
        const message = document.createElement("div");
        message.textContent = "ParaGraphL layout unavailable.";
        this._root.appendChild(message);
        return;
      }

      const layoutTickBudget = PARAGRAPHL_LAYOUT_TICKS;
      const progressTotal = layoutTickBudget + COLA_LAYOUT_TICKS;

      const layoutRunner = window.paraGraphLLayoutBegin({
        nodes: nodes,
        links: links,
        iterations: layoutTickBudget,
        gravity: 10,
        speed: 0.1,
        autoArea: true,
      });

      if (!layoutRunner.ok) {
        const message = document.createElement("div");
        message.textContent =
          layoutRunner.reason || "ParaGraphL layout failed.";
        this._root.appendChild(message);
        return;
      }

      const progressUI = createLayoutProgressUI(progressTotal);
      this._root.appendChild(progressUI.root);
      progressUI.setTickIndex(0);

      const host = this;
      let tickIndex = 0;

      const finishAfterLayout = function finishAfterLayout() {
        if (layoutGeneration !== host._layoutGeneration) {
          return;
        }
        progressUI.setTickIndex(progressTotal);
        progressUI.remove();
        appendGraphSvgToColaHost(host, graph, nodes, links, darkMode);
        if (cacheContext && graph.graphName === "wiki") {
          writeCachedWikiGraphPayload(cacheContext, nodes);
        }
      };

      const runColaRefinement = function runColaRefinement() {
        if (layoutGeneration !== host._layoutGeneration) {
          return;
        }
        if (!window.cola || !window.cola.Layout) {
          finishAfterLayout();
          return;
        }

        const colaLayout = new window.cola.Layout();
        colaLayout
          .nodes(nodes)
          .links(links)
          .linkDistance(function (link) {
            return colaLinkDistance(graph, link);
          })
          .avoidOverlaps(true)
          .start(90, 0, 0, 0, false);

        let colaTick = 0;

        const colaStep = function colaStep() {
          if (layoutGeneration !== host._layoutGeneration) {
            return;
          }
          progressUI.setTickIndex(layoutTickBudget + colaTick);
          if (colaLayout.tick()) {
            finishAfterLayout();
            return;
          }
          colaTick += 1;
          if (colaTick >= COLA_LAYOUT_TICKS) {
            finishAfterLayout();
            return;
          }
          window.requestAnimationFrame(colaStep);
        };

        window.requestAnimationFrame(colaStep);
      };

      const tickStep = function tickStep() {
        if (layoutGeneration !== host._layoutGeneration) {
          layoutRunner.dispose();
          return;
        }
        if (tickIndex >= layoutTickBudget) {
          layoutRunner.dispose();
          normalizeLayoutSpread(nodes);
          runColaRefinement();
          return;
        }
        progressUI.setTickIndex(tickIndex);
        if (layoutRunner.tick()) {
          layoutRunner.dispose();
          normalizeLayoutSpread(nodes);
          runColaRefinement();
          return;
        }
        tickIndex += 1;
        window.requestAnimationFrame(tickStep);
      };

      window.requestAnimationFrame(tickStep);
      return;
    }

    appendGraphSvgToColaHost(this, graph, nodes, links, darkMode);

  }
}

function syncMiniGraphPreview(miniPreview, graphHost) {
  const root = graphHost.shadowRoot;
  if (!root) {
    return;
  }

  const sourceSvg = root.querySelector("svg");
  if (!sourceSvg) {
    return;
  }

  const clonedSvg = sourceSvg.cloneNode(true);
  clonedSvg.removeAttribute("width");
  clonedSvg.removeAttribute("height");
  clonedSvg.style.width = "100%";
  clonedSvg.style.height = "100%";
  clonedSvg.style.display = "block";
  clonedSvg.style.pointerEvents = "none";
  clonedSvg.querySelectorAll("a.node g").forEach(function (group) {
    const rect = group.querySelector("rect");
    if (!rect) {
      return;
    }
    const borderColor = rect.getAttribute("stroke");
    if (!borderColor) {
      return;
    }
    rect.setAttribute("fill", borderColor);
    const text = group.querySelector("text");
    if (text) {
      text.setAttribute("fill", borderColor);
    }
  });

  miniPreview.innerHTML = "";
  miniPreview.appendChild(clonedSvg);
}

function setupWikiGraphNavigator() {
  const page = document.getElementById("wiki-graph-page");
  if (!page) {
    return;
  }

  const navigatorHost = document.getElementById("wiki-graph-navigator");
  const graphHost = document.getElementById("wiki-graph");
  const horizontalScrollRegion =
    document.getElementById("wiki-graph-scroll-region") ||
    document.getElementById("app-main-scroll");
  const verticalScrollRegion = document.getElementById("app-main-scroll");
  if (!navigatorHost || !graphHost || !horizontalScrollRegion || !verticalScrollRegion) {
    return;
  }

  const isGraphSvgReady = function isGraphSvgReady() {
    const root = graphHost.shadowRoot;
    if (!root) {
      return false;
    }
    return !!root.querySelector("svg");
  };

  if (!isGraphSvgReady()) {
    if (graphHost.dataset.sowGraphNavigatorWaitingForSvg === "1") {
      return;
    }

    const root = graphHost.shadowRoot;
    if (!root) {
      return;
    }

    const readyObserver = new MutationObserver(function onGraphReadyMutation() {
      if (!isGraphSvgReady()) {
        return;
      }
      readyObserver.disconnect();
      delete graphHost.dataset.sowGraphNavigatorWaitingForSvg;
      setupWikiGraphNavigator();
    });
    readyObserver.observe(root, { childList: true, subtree: true });
    graphHost.dataset.sowGraphNavigatorWaitingForSvg = "1";
    return;
  }

  if (navigatorHost.dataset.sowGraphNavigatorBound === "1") {
    return;
  }

  let miniSurface = navigatorHost.querySelector("[data-sow-nav='surface']");
  let miniPreview = navigatorHost.querySelector("[data-sow-nav='preview']");
  let viewport = navigatorHost.querySelector("[data-sow-nav='viewport']");
  if (!miniSurface || !miniPreview || !viewport) {
    navigatorHost.innerHTML = "";
    miniSurface = document.createElement("div");
    miniPreview = document.createElement("div");
    viewport = document.createElement("div");
    miniSurface.setAttribute("data-sow-nav", "surface");
    miniPreview.setAttribute("data-sow-nav", "preview");
    viewport.setAttribute("data-sow-nav", "viewport");
    miniSurface.appendChild(miniPreview);
    miniSurface.appendChild(viewport);
    navigatorHost.appendChild(miniSurface);
  }

  const state = { dragging: false, previewDirty: true };
  const render = function renderNavigator() {
    const scrollRect = verticalScrollRegion.getBoundingClientRect();
    const contentWidth = Math.max(
      horizontalScrollRegion.scrollWidth || 0,
      horizontalScrollRegion.clientWidth || 0,
      1
    );
    const contentHeight = Math.max(
      verticalScrollRegion.scrollHeight || 0,
      verticalScrollRegion.clientHeight || 0,
      1
    );
    navigatorHost.style.visibility = "visible";

    const maxMiniWidth = 190;
    const minMiniHeight = 96;
    const maxMiniHeight = 190;
    const miniWidth = maxMiniWidth;
    const miniHeight = clamp(
      (contentHeight / contentWidth) * miniWidth,
      minMiniHeight,
      maxMiniHeight
    );
    const scaleX = miniWidth / contentWidth;
    const scaleY = miniHeight / contentHeight;

    const maxScrollLeft = Math.max(
      contentWidth - horizontalScrollRegion.clientWidth,
      0
    );
    const maxScrollTop = Math.max(
      contentHeight - verticalScrollRegion.clientHeight,
      0
    );
    const viewLeft = clamp(horizontalScrollRegion.scrollLeft, 0, maxScrollLeft);
    const viewTop = clamp(verticalScrollRegion.scrollTop, 0, maxScrollTop);
    const viewWidth = clamp(horizontalScrollRegion.clientWidth, 8, contentWidth);
    const viewHeight = clamp(verticalScrollRegion.clientHeight, 8, contentHeight);

    navigatorHost.style.position = "fixed";
    navigatorHost.style.right = Math.max(window.innerWidth - scrollRect.right + 8, 8) + "px";
    navigatorHost.style.top = Math.max(scrollRect.top + 8, 8) + "px";
    navigatorHost.style.zIndex = "3"; // WikiGraphMinimap in UI.ZIndex
    navigatorHost.style.borderRadius = "0.625rem";
    navigatorHost.style.border = "1px solid var(--border-subtle, #8aa06a)";
    navigatorHost.style.background =
      "color-mix(in srgb, var(--chrome-bg, #f6f8ef) 92%, transparent)";
    navigatorHost.style.backdropFilter = "blur(2px)";
    navigatorHost.style.padding = "0.4rem";
    navigatorHost.style.boxShadow = "0 2px 10px rgba(0,0,0,0.12)";
    navigatorHost.style.userSelect = "none";
    navigatorHost.style.touchAction = "none";
    navigatorHost.style.cursor = state.dragging ? "grabbing" : "grab";

    miniSurface.style.position = "relative";
    miniSurface.style.width = miniWidth + "px";
    miniSurface.style.height = miniHeight + "px";
    miniSurface.style.border = "1px solid var(--border, #667944)";
    miniSurface.style.borderRadius = "0.4rem";
    miniSurface.style.background =
      "color-mix(in srgb, var(--chrome-bg, #f6f8ef) 85%, var(--bg, #ffffff))";
    miniSurface.style.overflow = "hidden";

    miniPreview.style.position = "absolute";
    miniPreview.style.inset = "0";
    miniPreview.style.pointerEvents = "none";
    miniPreview.style.opacity = "0.92";
    miniPreview.style.transform = "scale(0.96)";
    miniPreview.style.transformOrigin = "center";

    if (state.previewDirty) {
      syncMiniGraphPreview(miniPreview, graphHost);
      state.previewDirty = false;
    }

    const viewportBorderWidth = 2;
    const minViewportOuterSize = 12;
    const viewportEndInset = viewportBorderWidth;
    const viewportWidth = Math.min(
      Math.max(viewWidth * scaleX, Math.max(minViewportOuterSize, viewportBorderWidth * 2)),
      Math.max(miniWidth - viewportEndInset, 0)
    );
    const viewportHeight = Math.min(
      Math.max(viewHeight * scaleY, Math.max(minViewportOuterSize, viewportBorderWidth * 2)),
      Math.max(miniHeight - viewportEndInset, 0)
    );
    const viewportTravelX = Math.max(miniWidth - viewportWidth - viewportEndInset, 0);
    const viewportTravelY = Math.max(miniHeight - viewportHeight - viewportEndInset, 0);
    const viewportLeft = maxScrollLeft > 0 ? (viewLeft / maxScrollLeft) * viewportTravelX : 0;
    const viewportTop = maxScrollTop > 0 ? (viewTop / maxScrollTop) * viewportTravelY : 0;

    viewport.style.position = "absolute";
    viewport.style.left = viewportLeft + "px";
    viewport.style.top = viewportTop + "px";
    viewport.style.width = viewportWidth + "px";
    viewport.style.height = viewportHeight + "px";
    viewport.style.boxSizing = "border-box";
    viewport.style.border = `${viewportBorderWidth}px solid var(--focus-ring, #7c3aed)`;
    viewport.style.boxShadow = "none";
    viewport.style.borderRadius = "0.25rem";
    viewport.style.background = "rgba(124,58,237,0.12)";
    viewport.style.pointerEvents = "none";
  };

  let frameRequested = false;
  const scheduleRender = function scheduleRender() {
    if (frameRequested) {
      return;
    }
    frameRequested = true;
    window.requestAnimationFrame(function onFrame() {
      frameRequested = false;
      render();
    });
  };

  const panToClientPoint = function panToClientPoint(clientX, clientY) {
    const surfaceRect = miniSurface.getBoundingClientRect();
    const xRatio = clamp(
      (clientX - surfaceRect.left) / Math.max(surfaceRect.width, 1),
      0,
      1
    );
    const yRatio = clamp(
      (clientY - surfaceRect.top) / Math.max(surfaceRect.height, 1),
      0,
      1
    );

    const contentWidth = Math.max(
      horizontalScrollRegion.scrollWidth || 0,
      horizontalScrollRegion.clientWidth || 0,
      1
    );
    const contentHeight = Math.max(
      verticalScrollRegion.scrollHeight || 0,
      verticalScrollRegion.clientHeight || 0,
      1
    );
    const targetScrollLeft =
      xRatio * contentWidth - horizontalScrollRegion.clientWidth / 2;
    const targetScrollTop =
      yRatio * contentHeight - verticalScrollRegion.clientHeight / 2;
    const maxScrollLeft = Math.max(
      contentWidth - horizontalScrollRegion.clientWidth,
      0
    );
    const maxScrollTop = Math.max(
      contentHeight - verticalScrollRegion.clientHeight,
      0
    );

    horizontalScrollRegion.scrollLeft = clamp(targetScrollLeft, 0, maxScrollLeft);
    verticalScrollRegion.scrollTop = clamp(targetScrollTop, 0, maxScrollTop);
    scheduleRender();
  };

  navigatorHost.addEventListener("pointerdown", function onPointerDown(event) {
    event.preventDefault();
    state.dragging = true;
    navigatorHost.style.cursor = "grabbing";
    if (navigatorHost.setPointerCapture) {
      navigatorHost.setPointerCapture(event.pointerId);
    }
    panToClientPoint(event.clientX, event.clientY);
  });

  navigatorHost.addEventListener("pointermove", function onPointerMove(event) {
    if (!state.dragging) {
      return;
    }
    event.preventDefault();
    panToClientPoint(event.clientX, event.clientY);
  });

  navigatorHost.addEventListener("pointerup", function onPointerUp(event) {
    state.dragging = false;
    navigatorHost.style.cursor = "grab";
    if (navigatorHost.releasePointerCapture) {
      try {
        navigatorHost.releasePointerCapture(event.pointerId);
      } catch (_) {
        /* no-op */
      }
    }
  });

  navigatorHost.addEventListener("pointercancel", function onPointerCancel() {
    state.dragging = false;
    navigatorHost.style.cursor = "grab";
  });

  horizontalScrollRegion.addEventListener("scroll", scheduleRender, {
    passive: true,
  });
  if (verticalScrollRegion !== horizontalScrollRegion) {
    verticalScrollRegion.addEventListener("scroll", scheduleRender, {
      passive: true,
    });
  }
  window.addEventListener("resize", scheduleRender);

  const observer = new MutationObserver(function onGraphMutation() {
    state.previewDirty = true;
    scheduleRender();
  });
  observer.observe(graphHost, {
    attributes: true,
    attributeFilter: ["data-graph"],
  });
  if (graphHost.shadowRoot) {
    const shadowObserver = new MutationObserver(function onGraphShadowMutation() {
      state.previewDirty = true;
      scheduleRender();
    });
    shadowObserver.observe(graphHost.shadowRoot, {
      childList: true,
      subtree: true,
    });
  }

  navigatorHost.dataset.sowGraphNavigatorBound = "1";
  scheduleRender();
}

function ensureCustomElementDefined() {
  if (!customElements.get("cola-graph")) {
    customElements.define("cola-graph", ColaGraphElement);
  }
}

exports.init = function init(_app) {
  ensureCustomElementDefined();
  setupWikiGraphNavigator();

  const docObserver = new MutationObserver(function onDocumentMutation() {
    setupWikiGraphNavigator();
  });
  docObserver.observe(document.documentElement, {
    childList: true,
    subtree: true,
    attributes: true,
  });
};
