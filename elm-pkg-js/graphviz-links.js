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

  if (normalized === "black") {
    return { r: 0, g: 0, b: 0 };
  }

  if (normalized === "white") {
    return { r: 255, g: 255, b: 255 };
  }

  const shortHexMatch = normalized.match(/^#([0-9a-f]{3})$/i);
  if (shortHexMatch) {
    return {
      r: parseInt(shortHexMatch[1][0] + shortHexMatch[1][0], 16),
      g: parseInt(shortHexMatch[1][1] + shortHexMatch[1][1], 16),
      b: parseInt(shortHexMatch[1][2] + shortHexMatch[1][2], 16),
    };
  }

  const hexMatch = normalized.match(/^#([0-9a-f]{6})$/i);
  if (hexMatch) {
    return {
      r: parseInt(hexMatch[1].slice(0, 2), 16),
      g: parseInt(hexMatch[1].slice(2, 4), 16),
      b: parseInt(hexMatch[1].slice(4, 6), 16),
    };
  }

  const rgbMatch = normalized.match(
    /^rgb\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*\)$/
  );
  if (rgbMatch) {
    return {
      r: parseInt(rgbMatch[1], 10),
      g: parseInt(rgbMatch[2], 10),
      b: parseInt(rgbMatch[3], 10),
    };
  }

  return null;
}

function isWarningRed(color) {
  if (!color) {
    return false;
  }

  const normalized = color.trim().toLowerCase();
  return normalized === "#dc2626" || normalized === "rgb(220,38,38)";
}

function warningHoverFill(darkMode) {
  return darkMode
    ? "var(--danger-link-bg-hover, #4a1f25)"
    : "var(--danger-link-bg-hover, #f7cdcd)";
}

function hasWarningSvgColor(element, attributeName, baseDatasetName) {
  if (!element) {
    return false;
  }

  const currentColor =
    getEffectiveSvgColor(element, attributeName) || element.getAttribute(attributeName);
  if (isWarningRed(currentColor)) {
    return true;
  }

  return !!(baseDatasetName && isWarningRed(element.dataset[baseDatasetName]));
}

function fallbackHoverFillForShape(shape, nodeGroup) {
  const host = nodeGroup.closest("graphviz-graph");
  const darkMode = isHostInDarkTheme(host);
  if (hasWarningSvgColor(shape, "stroke", "sowGraphvizThemeBaseStroke")) {
    return warningHoverFill(darkMode);
  }

  const nodeText = nodeGroup.querySelector("text");
  if (hasWarningSvgColor(nodeText, "fill", "sowGraphvizThemeBaseFill")) {
    return warningHoverFill(darkMode);
  }

  return darkMode
    ? "var(--chrome-bg-hover, #313629)"
    : "var(--chrome-bg-hover, #e7e8dd)";
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

function nodeHasWarningStyling(nodeGroup) {
  const shapes = nodeBackgroundShapes(nodeGroup);
  const shapeHasWarningStroke = shapes.some(function (shape) {
    return hasWarningSvgColor(shape, "stroke", "sowGraphvizThemeBaseStroke");
  });
  if (shapeHasWarningStroke) {
    return true;
  }

  const nodeTexts = Array.from(nodeGroup.querySelectorAll("text"));
  return nodeTexts.some(function (textEl) {
    return hasWarningSvgColor(textEl, "fill", "sowGraphvizThemeBaseFill");
  });
}

function applyNodeHoverState(nodeGroup, hovered, darkMode) {
  const shapes = nodeBackgroundShapes(nodeGroup);
  const warningNode = nodeHasWarningStyling(nodeGroup);

  shapes.forEach(function (shape) {
    if (!shape.dataset.sowGraphvizBaseFill) {
      const baseFill = shape.getAttribute("fill");
      shape.dataset.sowGraphvizBaseFill = baseFill || "__none__";
      shape.dataset.sowGraphvizHoverFill = fallbackHoverFillForShape(shape, nodeGroup);
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

function isHostInDarkTheme(host) {
  if (!host) {
    return false;
  }

  const appRoot = host.closest(".app-root");
  return !!(appRoot && appRoot.classList.contains("dark"));
}

function isNeutralLightFill(color) {
  const rgb = parseColorToRgb(color);
  return !!rgb && rgb.r >= 236 && rgb.g >= 236 && rgb.b >= 236;
}

function isNeutralDarkStroke(color) {
  const rgb = parseColorToRgb(color);
  return !!rgb && rgb.r <= 40 && rgb.g <= 40 && rgb.b <= 40;
}

function getEffectiveSvgColor(element, attributeName) {
  const attrValue = element.getAttribute(attributeName);
  if (attrValue) {
    return attrValue;
  }

  const inlineStyleValue = element.style && element.style[attributeName];
  if (inlineStyleValue) {
    return inlineStyleValue;
  }

  try {
    const computed = window.getComputedStyle(element);
    return computed ? computed[attributeName] : null;
  } catch (_) {
    return null;
  }
}

function applyGraphTheme(host) {
  const root = host.shadowRoot;
  if (!root) {
    return;
  }

  const darkMode = isHostInDarkTheme(host);
  const svg = root.querySelector("svg");
  if (svg) {
    svg.style.background = "transparent";
    /* Auto zoom to fit the viewport.
    svg.setAttribute("width", "100%");
    svg.removeAttribute("height");
    svg.style.maxHeight = "80vh";
    svg.style.display = "block";
    svg.style.height = "auto";
    */
  }

  root.querySelectorAll("g.graph > polygon").forEach(function (shape) {
    if (!shape.dataset.sowGraphvizThemeBaseFill) {
      shape.dataset.sowGraphvizThemeBaseFill = shape.getAttribute("fill") || "__none__";
    }

    if (darkMode && isNeutralLightFill(shape.getAttribute("fill"))) {
      shape.setAttribute("fill", "transparent");
    } else if (!darkMode) {
      const baseFill = shape.dataset.sowGraphvizThemeBaseFill;
      if (baseFill === "__none__") {
        shape.removeAttribute("fill");
      } else {
        shape.setAttribute("fill", baseFill);
      }
    }
  });

  root.querySelectorAll("g.node").forEach(function (nodeGroup) {
    nodeBackgroundShapes(nodeGroup).forEach(function (shape) {
      const fill = shape.getAttribute("fill");
      const stroke = shape.getAttribute("stroke");

      if (!shape.dataset.sowGraphvizThemeBaseFill) {
        shape.dataset.sowGraphvizThemeBaseFill = fill || "__none__";
      }
      if (!shape.dataset.sowGraphvizThemeBaseStroke) {
        shape.dataset.sowGraphvizThemeBaseStroke = stroke || "__none__";
      }

      if (darkMode) {
        if (isNeutralLightFill(fill)) {
          shape.setAttribute("fill", "var(--input-bg, #1c2312)");
        }
        if (isNeutralDarkStroke(stroke) && !isWarningRed(stroke)) {
          shape.setAttribute("stroke", "var(--border, #667944)");
        }
      } else {
        const baseFill = shape.dataset.sowGraphvizThemeBaseFill;
        const baseStroke = shape.dataset.sowGraphvizThemeBaseStroke;

        if (baseFill === "__none__") {
          shape.removeAttribute("fill");
        } else {
          shape.setAttribute("fill", baseFill);
        }
        if (baseStroke === "__none__") {
          shape.removeAttribute("stroke");
        } else {
          shape.setAttribute("stroke", baseStroke);
        }
      }
    });
  });

  root.querySelectorAll("g.node text").forEach(function (textEl) {
    const fill = getEffectiveSvgColor(textEl, "fill");
    if (!textEl.dataset.sowGraphvizThemeBaseFill) {
      textEl.dataset.sowGraphvizThemeBaseFill = textEl.getAttribute("fill") || "__none__";
    }

    if (darkMode) {
      if (isNeutralDarkStroke(fill) && !isWarningRed(fill)) {
        textEl.setAttribute("fill", "var(--fg, #f0f4e5)");
      }
    } else {
      const baseFill = textEl.dataset.sowGraphvizThemeBaseFill;
      if (baseFill === "__none__") {
        textEl.removeAttribute("fill");
      } else {
        textEl.setAttribute("fill", baseFill);
      }
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
    const host = nodeGroup.closest("graphviz-graph");
    applyNodeHoverState(nodeGroup, true, isHostInDarkTheme(host));
  });

  nodeGroup.addEventListener("mouseleave", function onGraphvizNodeLeave() {
    const host = nodeGroup.closest("graphviz-graph");
    applyNodeHoverState(nodeGroup, false, isHostInDarkTheme(host));
  });

  nodeGroup.dataset.sowGraphvizBound = "1";
}

function decorateHost(host) {
  const root = host.shadowRoot;
  if (!root) {
    return;
  }

  applyGraphTheme(host);
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
