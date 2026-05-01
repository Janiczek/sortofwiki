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

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
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

  clonedSvg.querySelectorAll("g.node").forEach(function (nodeGroup) {
    const nodeShapes = Array.from(nodeGroup.querySelectorAll("polygon, rect, ellipse, path"));
    const nodeTexts = Array.from(nodeGroup.querySelectorAll("text"));
    const isMissingNode =
      nodeShapes.some(function (shape) {
        return isWarningRed(getEffectiveSvgColor(shape, "stroke"));
      }) ||
      nodeTexts.some(function (textEl) {
        return isWarningRed(getEffectiveSvgColor(textEl, "fill"));
      });

    const nodeColor = isMissingNode ? "#dc2626" : "#000000";

    nodeShapes.forEach(function (shape) {
      shape.setAttribute("fill", nodeColor);
      shape.setAttribute("stroke", nodeColor);
    });

    nodeTexts.forEach(function (textEl) {
      textEl.setAttribute("fill", nodeColor);
    });
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
  const graphHost = document.getElementById("wiki-graphviz");
  const loadingHost = document.getElementById("wiki-graph-loading");
  const scrollRegion = document.getElementById("app-main-scroll");
  if (!navigatorHost || !graphHost || !scrollRegion) {
    return;
  }

  const setLoadingVisible = function setLoadingVisible(visible) {
    if (!loadingHost) {
      return;
    }
    loadingHost.style.display = visible ? "flex" : "none";
  };

  const isGraphSvgReady = function isGraphSvgReady() {
    const root = graphHost.shadowRoot;
    if (!root) {
      return false;
    }
    return !!(root.querySelector("svg") && root.querySelector("g.graph"));
  };

  if (!isGraphSvgReady()) {
    setLoadingVisible(true);
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
    setLoadingVisible(false);
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
    const scrollRect = scrollRegion.getBoundingClientRect();
    const contentWidth = Math.max(scrollRegion.scrollWidth || 0, scrollRegion.clientWidth || 0, 1);
    const contentHeight = Math.max(scrollRegion.scrollHeight || 0, scrollRegion.clientHeight || 0, 1);
    navigatorHost.style.visibility = "visible";

    const maxMiniWidth = 190;
    const minMiniHeight = 96;
    const maxMiniHeight = 190;
    const miniWidth = maxMiniWidth;
    const miniHeight = clamp((contentHeight / contentWidth) * miniWidth, minMiniHeight, maxMiniHeight);
    const scaleX = miniWidth / contentWidth;
    const scaleY = miniHeight / contentHeight;

    const viewLeft = clamp(scrollRegion.scrollLeft, 0, contentWidth);
    const viewTop = clamp(scrollRegion.scrollTop, 0, contentHeight);
    const viewWidth = clamp(scrollRegion.clientWidth, 8, contentWidth);
    const viewHeight = clamp(scrollRegion.clientHeight, 8, contentHeight);

    navigatorHost.style.position = "fixed";
    navigatorHost.style.right = Math.max(window.innerWidth - scrollRect.right + 8, 8) + "px";
    navigatorHost.style.top = Math.max(scrollRect.top + 8, 8) + "px";
    navigatorHost.style.zIndex = "12";
    navigatorHost.style.borderRadius = "0.625rem";
    navigatorHost.style.border = "1px solid var(--border-subtle, #8aa06a)";
    navigatorHost.style.background = "color-mix(in srgb, var(--chrome-bg, #f6f8ef) 92%, transparent)";
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
    const xRatio = clamp((clientX - surfaceRect.left) / Math.max(surfaceRect.width, 1), 0, 1);
    const yRatio = clamp((clientY - surfaceRect.top) / Math.max(surfaceRect.height, 1), 0, 1);

    const contentWidth = Math.max(scrollRegion.scrollWidth || 0, scrollRegion.clientWidth || 0, 1);
    const contentHeight = Math.max(scrollRegion.scrollHeight || 0, scrollRegion.clientHeight || 0, 1);
    const targetScrollLeft = xRatio * contentWidth - scrollRegion.clientWidth / 2;
    const targetScrollTop = yRatio * contentHeight - scrollRegion.clientHeight / 2;
    const maxScrollLeft = Math.max(contentWidth - scrollRegion.clientWidth, 0);
    const maxScrollTop = Math.max(contentHeight - scrollRegion.clientHeight, 0);

    scrollRegion.scrollLeft = clamp(targetScrollLeft, 0, maxScrollLeft);
    scrollRegion.scrollTop = clamp(targetScrollTop, 0, maxScrollTop);
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

  scrollRegion.addEventListener("scroll", scheduleRender, { passive: true });
  window.addEventListener("resize", scheduleRender);

  const observer = new MutationObserver(function onGraphMutation() {
    state.previewDirty = true;
    scheduleRender();
  });
  observer.observe(graphHost, { attributes: true, attributeFilter: ["graph"] });

  navigatorHost.dataset.sowGraphNavigatorBound = "1";
  setLoadingVisible(false);

  scheduleRender();
}

exports.init = function init(_app) {
  bindGraphvizHosts();
  setupWikiGraphNavigator();

  const docObserver = new MutationObserver(function onDocumentMutation() {
    bindGraphvizHosts();
    setupWikiGraphNavigator();
  });
  docObserver.observe(document.documentElement, {
    childList: true,
    subtree: true,
  });
};
