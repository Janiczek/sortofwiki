/**
 * Inline script sets window.MathJax config; the real bundle is `defer` and runs
 * after the document (including Elm) finishes parsing. Custom elements connect
 * before that, so we must wait for tex2svgPromise instead of returning forever.
 */
var mathJaxReadyPromise = null;

function whenMathJaxReady() {
  if (!mathJaxReadyPromise) {
    mathJaxReadyPromise = new Promise(function (resolve) {
      function tick() {
        var MJ = window.MathJax;
        if (MJ && typeof MJ.tex2svgPromise === "function") {
          var startup = MJ.startup;
          var p = startup && startup.promise;
          if (p) {
            p.then(
              function () {
                resolve(MJ);
              },
              function (err) {
                console.warn("MathJax startup failed:", err);
                resolve(null);
              }
            );
          } else {
            resolve(MJ);
          }
          return;
        }
        requestAnimationFrame(tick);
      }
      tick();
    });
  }
  return mathJaxReadyPromise;
}

function defineEquationElement(tagName, display) {
  if (customElements.get(tagName)) {
    return;
  }

  class EquationElement extends HTMLElement {
    static get observedAttributes() {
      return ["data-equation"];
    }

    constructor() {
      super();
      this.attachShadow({ mode: "open" });
      this._renderVersion = 0;
    }

    connectedCallback() {
      this._renderMath();
    }

    attributeChangedCallback(name, oldValue, newValue) {
      if (name === "data-equation" && oldValue !== newValue) {
        this._renderMath();
      }
    }

    async _renderMath() {
      const currentRender = ++this._renderVersion;
      const shadowRoot = this.shadowRoot;

      if (!shadowRoot) {
        return;
      }

      shadowRoot.replaceChildren();

      const equation = this.getAttribute("data-equation");
      if (!equation) {
        return;
      }

      let MJ;
      try {
        MJ = await whenMathJaxReady();
      } catch (_) {
        MJ = null;
      }

      if (
        !MJ ||
        typeof MJ.tex2svgPromise !== "function" ||
        !this.isConnected ||
        currentRender !== this._renderVersion
      ) {
        return;
      }

      try {
        if (!this.isConnected || currentRender !== this._renderVersion) {
          return;
        }

        const metrics =
          typeof MJ.getMetricsFor === "function"
            ? MJ.getMetricsFor(this, display)
            : { display: display };

        const svgNode = await MJ.tex2svgPromise(equation, metrics);

        if (!this.isConnected || currentRender !== this._renderVersion) {
          return;
        }

        const styleElement = document.createElement("style");
        styleElement.textContent =
          equationShadowSvgStyles(display) + mathJaxSvgStyles(MJ);

        shadowRoot.replaceChildren(styleElement, svgNode);
      } catch (err) {
        if (this.isConnected && currentRender === this._renderVersion) {
          console.warn(tagName + " MathJax:", err);
        }
      }
    }
  }

  customElements.define(tagName, EquationElement);
}

/* Host typography lives in head.html; document CSS cannot reach shadow children. */
function equationShadowSvgStyles(display) {
  return display
    ? [
        "svg {",
        "  display: block;",
        "  max-width: 100%;",
        "}",
      ].join("\n")
    : [
        "svg {",
        "  display: inline-block;",
        "}",
      ].join("\n");
}

function mathJaxSvgStyles(MJ) {
  if (typeof MJ.svgStylesheet !== "function") {
    return "";
  }

  const styleSheet = MJ.svgStylesheet();
  const adaptor = MJ.startup && MJ.startup.adaptor;

  if (adaptor && typeof adaptor.cssText === "function") {
    return "\n" + adaptor.cssText(styleSheet);
  }

  return "\n" + (styleSheet.textContent || "");
}

exports.init = function init(_app) {
  defineEquationElement("inline-equation", false);
  defineEquationElement("block-equation", true);
};
