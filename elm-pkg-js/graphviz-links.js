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

function parseColorToRgb(color) {
  if (!color) {
    return null;
  }

  const normalized = color.trim().toLowerCase();

  if (normalized === "white") {
    return { r: 255, g: 255, b: 255 };
  }

  const hexMatch = normalized.match(/^#([0-9a-f]{6})$/i);
  if (hexMatch) {
    return {
      r: parseInt(hexMatch[1].slice(0, 2), 16),
      g: parseInt(hexMatch[1].slice(2, 4), 16),
      b: parseInt(hexMatch[1].slice(4, 6), 16),
    };
  }

  return null;
}

function rgbToHex(rgb) {
  function toHex(value) {
    return Math.max(0, Math.min(255, value)).toString(16).padStart(2, "0");
  }

  return "#" + toHex(rgb.r) + toHex(rgb.g) + toHex(rgb.b);
}

function tintFillColor(fillColor) {
  const rgb = parseColorToRgb(fillColor);
  if (!rgb) {
    return null;
  }

  const amount = 18;
  return rgbToHex({
    r: rgb.r - amount,
    g: rgb.g - amount,
    b: rgb.b - amount,
  });
}

function isWarningRed(color) {
  if (!color) {
    return false;
  }

  const normalized = color.trim().toLowerCase();
  return normalized === "#dc2626" || normalized === "rgb(220,38,38)";
}

function fallbackHoverFillForShape(shape, nodeGroup) {
  const shapeStroke = shape.getAttribute("stroke");
  if (isWarningRed(shapeStroke)) {
    return "#fde2e2";
  }

  const nodeText = nodeGroup.querySelector("text");
  if (nodeText && isWarningRed(nodeText.getAttribute("fill"))) {
    return "#fde2e2";
  }

  return "var(--chrome-bg, #ecefe3)";
}

function readAnchorHref(anchor) {
  return (
    anchor.getAttribute("href") ||
    anchor.getAttributeNS(XLINK_NS, "href") ||
    anchor.getAttribute("xlink:href") ||
    ""
  );
}

function stripGraphvizLinkAttrs(anchor) {
  anchor.removeAttribute("href");
  anchor.removeAttribute("title");
  anchor.removeAttribute("xlink:href");
  anchor.removeAttribute("xlink:title");
  anchor.removeAttributeNS(XLINK_NS, "href");
  anchor.removeAttributeNS(XLINK_NS, "title");
}

function ensureNodeHitbox(nodeGroup) {
  if (nodeGroup.querySelector(":scope > rect[data-sow-graphviz-hitbox='1']")) {
    return;
  }

  let bbox;
  try {
    bbox = nodeGroup.getBBox();
  } catch (_) {
    return;
  }

  if (!bbox || bbox.width <= 0 || bbox.height <= 0) {
    return;
  }

  const hitbox = document.createElementNS("http://www.w3.org/2000/svg", "rect");
  hitbox.setAttribute("x", String(bbox.x));
  hitbox.setAttribute("y", String(bbox.y));
  hitbox.setAttribute("width", String(bbox.width));
  hitbox.setAttribute("height", String(bbox.height));
  hitbox.setAttribute("fill", "transparent");
  hitbox.setAttribute("pointer-events", "all");
  hitbox.setAttribute("data-sow-graphviz-hitbox", "1");

  nodeGroup.insertBefore(hitbox, nodeGroup.firstChild);
}

function nodeBackgroundShapes(nodeGroup) {
  return Array.from(nodeGroup.querySelectorAll("polygon, rect, ellipse, path")).filter(
    function (shape) {
      return shape.getAttribute("data-sow-graphviz-hitbox") !== "1";
    }
  );
}

function applyNodeHoverState(nodeGroup, hovered) {
  const shapes = nodeBackgroundShapes(nodeGroup);

  shapes.forEach(function (shape) {
    if (!shape.dataset.sowGraphvizBaseFill) {
      const baseFill = shape.getAttribute("fill");
      shape.dataset.sowGraphvizBaseFill = baseFill || "__none__";

      const hoverFill = baseFill ? tintFillColor(baseFill) : null;
      shape.dataset.sowGraphvizHoverFill =
        hoverFill || fallbackHoverFillForShape(shape, nodeGroup);
    }

    const baseFill = shape.dataset.sowGraphvizBaseFill;
    const hoverFill = shape.dataset.sowGraphvizHoverFill;
    if (!hoverFill) {
      return;
    }

    if (hovered) {
      shape.setAttribute("fill", hoverFill);
    } else if (baseFill === "__none__") {
      shape.removeAttribute("fill");
    } else {
      shape.setAttribute("fill", baseFill);
    }
  });
}

function decorateNodeGroup(nodeGroup) {
  if (nodeGroup.dataset.sowGraphvizBound === "1") {
    ensureNodeHitbox(nodeGroup);
    return;
  }

  const anchor = nodeGroup.querySelector("a");
  if (!anchor) {
    return;
  }

  const hrefRaw = readAnchorHref(anchor);
  if (!hrefRaw) {
    return;
  }

  let parsedUrl;
  try {
    parsedUrl = new URL(hrefRaw, window.location.href);
  } catch (_) {
    return;
  }

  if (!isSameOriginPathNavigation(parsedUrl)) {
    return;
  }

  stripGraphvizLinkAttrs(anchor);
  nodeGroup.style.cursor = "pointer";
  ensureNodeHitbox(nodeGroup);

  nodeGroup.addEventListener("click", function onGraphvizNodeClick(event) {
    if (!isPrimaryUnmodifiedClick(event)) {
      return;
    }

    event.preventDefault();
    event.stopPropagation();
    navigateInSpa(parsedUrl);
  });

  nodeGroup.addEventListener("mouseenter", function onGraphvizNodeEnter() {
    applyNodeHoverState(nodeGroup, true);
  });

  nodeGroup.addEventListener("mouseleave", function onGraphvizNodeLeave() {
    applyNodeHoverState(nodeGroup, false);
  });

  nodeGroup.dataset.sowGraphvizBound = "1";
}

function decorateHost(host) {
  const root = host.shadowRoot;
  if (!root) {
    return;
  }

  root.querySelectorAll("g.node").forEach(decorateNodeGroup);
}

function attachHostObserver(host) {
  if (host.dataset.sowGraphvizObserverBound === "1") {
    decorateHost(host);
    return;
  }

  const root = host.shadowRoot;
  if (!root) {
    return;
  }

  const observer = new MutationObserver(function onGraphvizMutation() {
    decorateHost(host);
  });
  observer.observe(root, { childList: true, subtree: true });

  decorateHost(host);
  host.dataset.sowGraphvizObserverBound = "1";
}

function bindGraphvizHosts() {
  document.querySelectorAll("graphviz-graph").forEach(attachHostObserver);
}

exports.init = function init(_app) {
  bindGraphvizHosts();

  const docObserver = new MutationObserver(function onDocumentMutation() {
    bindGraphvizHosts();
  });
  docObserver.observe(document.documentElement, {
    childList: true,
    subtree: true,
  });
};
