const SVG_NS = "http://www.w3.org/2000/svg";
const XLINK_NS = "http://www.w3.org/1999/xlink";

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

class ColaGraphElement extends HTMLElement {
  static get observedAttributes() {
    return ["data-graph"];
  }

  constructor() {
    super();
    this._root = this.attachShadow({ mode: "open" });
    this._themeObserver = null;
    this._themeMql = null;
    this._onThemeChange = this.renderGraph.bind(this);
  }

  connectedCallback() {
    this.setupThemeReactivity();
    this.renderGraph();
  }

  disconnectedCallback() {
    this.teardownThemeReactivity();
  }

  attributeChangedCallback(name, _oldValue, _newValue) {
    if (name === "data-graph") {
      this.renderGraph();
    }
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

  renderGraph() {
    const graph = parseGraphData(this.getAttribute("data-graph"));
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
    `;
    this._root.appendChild(style);

    if (!graph || graph.nodes.length === 0) {
      const empty = document.createElement("div");
      empty.textContent = "";
      this._root.appendChild(empty);
      return;
    }

    const darkMode = isDarkMode(this);
    const width = 1200;
    const height = graph.graphName === "page" ? 860 : 980;

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

    if (!window.cola || !window.cola.Layout) {
      const message = document.createElement("div");
      message.textContent = "Cola layout unavailable.";
      this._root.appendChild(message);
      return;
    }

    const layout = new window.cola.Layout();
    layout
      .size([width, height])
      .nodes(nodes)
      .links(links)
      .linkDistance(function (link) {
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
      })
      .avoidOverlaps(true)
      .start(90, 0, 0, 0, false);

    for (let i = 0; i < 350; i += 1) {
      if (layout.tick()) {
        break;
      }
    }

    const positionedNodes = nodes.filter(function (node) {
      return Number.isFinite(node.x) && Number.isFinite(node.y);
    });

    if (positionedNodes.length === 0) {
      const message = document.createElement("div");
      message.textContent = "Graph layout failed.";
      this._root.appendChild(message);
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

    nodes.forEach(function (node) {
      const palette = nodePalette(node, darkMode, this);
      const hoverFill = nodeHoverFill(node, darkMode, this);
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
    });

    this._root.appendChild(svg);
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

    const viewLeft = clamp(horizontalScrollRegion.scrollLeft, 0, contentWidth);
    const viewTop = clamp(verticalScrollRegion.scrollTop, 0, contentHeight);
    const viewWidth = clamp(horizontalScrollRegion.clientWidth, 8, contentWidth);
    const viewHeight = clamp(verticalScrollRegion.clientHeight, 8, contentHeight);

    navigatorHost.style.position = "fixed";
    navigatorHost.style.right = Math.max(window.innerWidth - scrollRect.right + 8, 8) + "px";
    navigatorHost.style.top = Math.max(scrollRect.top + 8, 8) + "px";
    navigatorHost.style.zIndex = "12";
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
    miniSurface.style.background = "var(--chrome-bg, #f6f8ef)";
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

    viewport.style.position = "absolute";
    viewport.style.left = viewLeft * scaleX + "px";
    viewport.style.top = viewTop * scaleY + "px";
    viewport.style.width = Math.max(viewWidth * scaleX, 12) + "px";
    viewport.style.height = Math.max(viewHeight * scaleY, 12) + "px";
    viewport.style.border = "2px solid var(--focus-ring, #7c3aed)";
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
