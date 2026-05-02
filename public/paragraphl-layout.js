/**
 * Standalone ParaGraphL-style Fruchterman–Reingold layout (WebGL / GPGPU).
 * Adapted from ParaGraphL (sigma.layout.paragraphl.js) + GPGPUtility.js.
 * Computes node x/y only; no graph rendering.
 *
 * Exposes:
 *   window.paraGraphLLayoutBegin(config) -> { ok, reason? } | { ok, tick, finish, dispose }
 *   window.paraGraphLLayout(config)      -> { ok, reason? }  (synchronous, all iterations)
 */
(function () {
  "use strict";

  /* ---- GPGPUtility (Vizit Solutions, Apache-2.0) — minified to project needs ---- */
  window.vizit = window.vizit || {};
  window.vizit.utility = window.vizit.utility || {};

  (function (ns) {
    ns.GPGPUtility = function (width_, height_, attributes_) {
      var attributes;
      var canvas;
      var gl;
      var canvasHeight, canvasWidth;
      var problemHeight, problemWidth;
      var standardVertexShader;
      var standardVertices;
      var textureFloat;

      this.getCanvas = function () {
        return canvas;
      };

      this.getGLContext = function () {
        if (!gl) {
          gl =
            canvas.getContext("webgl", attributes) ||
            canvas.getContext("experimental-webgl", attributes);
        }
        return gl;
      };

      this.getStandardGeometry = function () {
        return new Float32Array([
          -1.0, 1.0, 0.0, 0.0, 1.0, -1.0, -1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, -1.0, 0.0, 1.0, 0.0,
        ]);
      };

      this.getStandardVertices = function () {
        if (!standardVertices) {
          standardVertices = gl.createBuffer();
          gl.bindBuffer(gl.ARRAY_BUFFER, standardVertices);
          gl.bufferData(gl.ARRAY_BUFFER, this.getStandardGeometry(), gl.STATIC_DRAW);
        } else {
          gl.bindBuffer(gl.ARRAY_BUFFER, standardVertices);
        }
        return standardVertices;
      };

      this.isFloatingTexture = function () {
        return textureFloat != null;
      };

      this.getComputeContext = function () {
        if (problemWidth != canvasWidth || problemHeight != canvasHeight) {
          gl.viewport(0, 0, problemWidth, problemHeight);
        }
        return gl;
      };

      this.makeSizedTexture = function (width, height, type, data) {
        var texture = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, texture);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, type, data);
        gl.bindTexture(gl.TEXTURE_2D, null);
        return texture;
      };

      this.makeTexture = function (type, data) {
        return this.makeSizedTexture(problemWidth, problemHeight, type, data);
      };

      this.attachFrameBuffer = function (texture) {
        var frameBuffer = gl.createFramebuffer();
        gl.bindFramebuffer(gl.FRAMEBUFFER, frameBuffer);
        gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0);
        return frameBuffer;
      };

      this.frameBufferIsComplete = function () {
        var status = gl.checkFramebufferStatus(gl.FRAMEBUFFER);
        if (status === gl.FRAMEBUFFER_COMPLETE) {
          return { isComplete: true, message: "Framebuffer is complete." };
        }
        return { isComplete: false, message: "Framebuffer incomplete: " + status };
      };

      this.compileShader = function (shaderSource, shaderType) {
        var shader = gl.createShader(shaderType);
        gl.shaderSource(shader, shaderSource);
        gl.compileShader(shader);
        if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
          throw new Error("Shader compile failed: " + gl.getShaderInfoLog(shader));
        }
        return shader;
      };

      this.getStandardVertexShader = function () {
        if (!standardVertexShader) {
          var vertexShaderSource =
            "attribute vec3 position;" +
            "attribute vec2 textureCoord;" +
            "varying highp vec2 vTextureCoord;" +
            "void main()" +
            "{" +
            "  gl_Position = vec4(position, 1.0);" +
            "  vTextureCoord = textureCoord;" +
            "}";
          standardVertexShader = this.compileShader(vertexShaderSource, gl.VERTEX_SHADER);
        }
        return standardVertexShader;
      };

      this.createProgram = function (vertexShaderSource, fragmentShaderSource) {
        var fragmentShader;
        var program;
        var vertexShader;
        program = gl.createProgram();
        if (typeof vertexShaderSource !== "string") {
          vertexShader = this.getStandardVertexShader();
        } else {
          vertexShader = this.compileShader(vertexShaderSource, gl.VERTEX_SHADER);
        }
        fragmentShader = this.compileShader(fragmentShaderSource, gl.FRAGMENT_SHADER);
        gl.attachShader(program, vertexShader);
        gl.attachShader(program, fragmentShader);
        gl.linkProgram(program);
        if (vertexShader !== standardVertexShader) {
          gl.deleteShader(vertexShader);
        }
        gl.deleteShader(fragmentShader);
        return program;
      };

      this.getAttribLocation = function (program, name) {
        var loc = gl.getAttribLocation(program, name);
        if (loc === -1) {
          throw new Error("Attribute not found: " + name);
        }
        return loc;
      };

      this.getUniformLocation = function (program, name) {
        var ref = gl.getUniformLocation(program, name);
        if (ref === null || ref === -1) {
          throw new Error("Uniform not found: " + name);
        }
        return ref;
      };

      canvasHeight = height_;
      problemHeight = canvasHeight;
      canvasWidth = width_;
      problemWidth = canvasWidth;
      attributes = typeof attributes_ === "undefined" ? ns.GPGPUtility.STANDARD_CONTEXT_ATTRIBUTES : attributes_;
      canvas = document.createElement("canvas");
      canvas.width = canvasWidth;
      canvas.height = canvasHeight;
      gl = this.getGLContext();
      textureFloat = gl.getExtension("OES_texture_float");
    };

    ns.GPGPUtility.STANDARD_CONTEXT_ATTRIBUTES = { alpha: false, depth: false, antialias: false };
  })(window.vizit.utility);

  /* ---- ParaGraphL FR layout core ---- */

  var defaultSettings = {
    autoArea: true,
    area: 1,
    gravity: 10,
    speed: 0.1,
    iterations: 100,
  };

  function extend(dst, src) {
    var out = {};
    var k;
    for (k in dst) {
      if (Object.prototype.hasOwnProperty.call(dst, k)) {
        out[k] = dst[k];
      }
    }
    for (k in src) {
      if (Object.prototype.hasOwnProperty.call(src, k)) {
        out[k] = src[k];
      }
    }
    return out;
  }

  /** GLSL ES 1.0: literals without '.' are int; min(int, float) has no overload. */
  function glslFloatLiteral(n) {
    var s = String(n);
    if (/^[+-]?\d+$/.test(s)) {
      return s + ".0";
    }
    return s;
  }

  function FruchtermanReingoldGL() {
    var self = this;

    this.config = defaultSettings;
    this.nodes = null;
    this.edges = null;
    this.running = false;
    this.iterCount = 0;
    this.nodesCount = 0;
    this.textureSize = 0;
    this.maxEdgePerVetex = 0;
    this.maxDisplace = 0;
    this.k = 0;
    this.k_2 = 0;
    this.texture_input = null;
    this.texture_output = null;
    this.gl = null;
    this.gpgpUtility = null;
    this.program = null;
    this.positionHandle = null;
    this.textureCoordHandle = null;
    this.textureHandle = null;
    this.setupOk = false;
    this._saved = false;

    this.buildTextureData = function (nodes, edges, nodesCount, edgesCount) {
      var dataArray = [];
      var nodeDict = [];
      var i;
      var j;
      for (i = 0; i < nodesCount; i++) {
        var n = nodes[i];
        dataArray.push(n.x);
        dataArray.push(n.y);
        dataArray.push(0);
        dataArray.push(0);
        nodeDict.push([]);
      }
      for (i = 0; i < edgesCount; i++) {
        var e = edges[i];
        var si = e.source;
        var ti = e.target;
        if (si === ti || si < 0 || ti < 0 || si >= nodesCount || ti >= nodesCount) {
          continue;
        }
        nodeDict[si].push(ti);
        nodeDict[ti].push(si);
      }
      this.maxEdgePerVetex = 0;
      for (i = 0; i < nodesCount; i++) {
        var offset = dataArray.length;
        var dests = nodeDict[i];
        var len = dests.length;
        dataArray[i * 4 + 2] = offset;
        dataArray[i * 4 + 3] = dests.length;
        this.maxEdgePerVetex = Math.max(this.maxEdgePerVetex, dests.length);
        for (j = 0; j < len; j += 1) {
          dataArray.push(+dests[j]);
        }
      }
      while (dataArray.length % 4 !== 0) {
        dataArray.push(0);
      }
      return new Float32Array(dataArray);
    };

    this.createProgram = function () {
      var gl = this.gl;
      var gpgpUtility = this.gpgpUtility;
      var sourceCode =
        "#ifdef GL_FRAGMENT_PRECISION_HIGH\nprecision highp float;\n#else\nprecision mediump float;\n#endif\n" +
        "uniform sampler2D m;\n" +
        "varying vec2 vTextureCoord;\n" +
        "void main()\n" +
        "{\n" +
        "  float dx = 0.0, dy = 0.0;\n" +
        "  int i = int(floor(vTextureCoord.s * float(" +
        this.textureSize +
        ") + 0.5));\n" +
        "  vec4 node_i = texture2D(m, vec2(vTextureCoord.s, 1));\n" +
        "  gl_FragColor = node_i;\n" +
        "  if (i > " +
        this.nodesCount +
        ") return;\n" +
        "  for (int j = 0; j < " +
        this.nodesCount.toString() +
        "; j++) {\n" +
        "    if (i != j + 1) {\n" +
        "      vec4 node_j = texture2D(m, vec2((float(j) + 0.5) / float(" +
        this.textureSize +
        ") , 1));\n" +
        "      float xDist = node_i.r - node_j.r;\n" +
        "      float yDist = node_i.g - node_j.g;\n" +
        "      float dist = sqrt(xDist * xDist + yDist * yDist) + 0.01;\n" +
        "      if (dist > 0.0) {\n" +
        "        float repulsiveF = " +
        glslFloatLiteral(this.k_2) +
        " / dist;\n" +
        "        dx += xDist / dist * repulsiveF;\n" +
        "        dy += yDist / dist * repulsiveF;\n" +
        "      }\n" +
        "    }\n" +
        "  }\n" +
        "  int arr_offset = int(floor(node_i.b + 0.5));\n" +
        "  int length = int(floor(node_i.a + 0.5));\n" +
        "  vec4 node_buffer;\n" +
        "  for (int p = 0; p < " +
        String(this.maxEdgePerVetex) +
        "; p++) {\n" +
        "    if (p >= length) break;\n" +
        "    int arr_idx = arr_offset + p;\n" +
        "    int buf_offset = arr_idx - arr_idx / 4 * 4;\n" +
        "    if (p == 0 || buf_offset == 0) {\n" +
        "      node_buffer = texture2D(m, vec2((float(arr_idx / 4) + 0.5) /\n" +
        "                                          float(" +
        this.textureSize +
        ") , 1));\n" +
        "    }\n" +
        "    float float_j = buf_offset == 0 ? node_buffer.r :\n" +
        "                    buf_offset == 1 ? node_buffer.g :\n" +
        "                    buf_offset == 2 ? node_buffer.b :\n" +
        "                                      node_buffer.a;\n" +
        "    vec4 node_j = texture2D(m, vec2((float_j + 0.5) /\n" +
        "                                    float(" +
        this.textureSize +
        "), 1));\n" +
        "    float xDist = node_i.r - node_j.r;\n" +
        "    float yDist = node_i.g - node_j.g;\n" +
        "    float dist = sqrt(xDist * xDist + yDist * yDist) + 0.01;\n" +
        "    float attractiveF = dist * dist / " +
        glslFloatLiteral(this.k) +
        ";\n" +
        "    if (dist > 0.0) {\n" +
        "      dx -= xDist / dist * attractiveF;\n" +
        "      dy -= yDist / dist * attractiveF;\n" +
        "    }\n" +
        "  }\n" +
        "  float d = sqrt(node_i.r * node_i.r + node_i.g * node_i.g);\n" +
        "  float gf = " +
        glslFloatLiteral(0.01 * this.k * self.config.gravity) +
        " * d;\n" +
        "  dx -= gf * node_i.r / d;\n" +
        "  dy -= gf * node_i.g / d;\n" +
        "  dx *= " +
        glslFloatLiteral(self.config.speed) +
        ";\n" +
        "  dy *= " +
        glslFloatLiteral(self.config.speed) +
        ";\n" +
        "  float dist = sqrt(dx * dx + dy * dy);\n" +
        "  if (dist > 0.0) {\n" +
        "    float limitedDist = min(" +
        glslFloatLiteral(this.maxDisplace * self.config.speed) +
        ", dist);\n" +
        "    gl_FragColor.r += dx / dist * limitedDist;\n" +
        "    gl_FragColor.g += dy / dist * limitedDist;\n" +
        "  }\n" +
        "}\n";

      var program = gpgpUtility.createProgram(null, sourceCode);
      this.positionHandle = gpgpUtility.getAttribLocation(program, "position");
      gl.enableVertexAttribArray(this.positionHandle);
      this.textureCoordHandle = gpgpUtility.getAttribLocation(program, "textureCoord");
      gl.enableVertexAttribArray(this.textureCoordHandle);
      this.textureHandle = gl.getUniformLocation(program, "m");
      if (!this.textureHandle) {
        throw new Error("uniform m (sampler) missing");
      }
      this.program = program;
    };

    this.atomicGo = function (input, output) {
      if (!this.running || this.iterCount < 1) {
        return false;
      }
      this.iterCount -= 1;
      this.running = this.iterCount > 0;

      var gl = this.gl;
      var gpgpUtility = this.gpgpUtility;
      gpgpUtility.attachFrameBuffer(output);
      gl.useProgram(this.program);
      gpgpUtility.getStandardVertices();
      gl.vertexAttribPointer(this.positionHandle, 3, gl.FLOAT, gl.FALSE, 20, 0);
      gl.vertexAttribPointer(this.textureCoordHandle, 2, gl.FLOAT, gl.FALSE, 20, 12);
      gl.activeTexture(gl.TEXTURE0);
      gl.bindTexture(gl.TEXTURE_2D, input);
      gl.uniform1i(this.textureHandle, 0);
      gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
      return true;
    };

    this.saveDataToNode = function () {
      var nodes = this.nodes;
      var gl = this.gpgpUtility.getGLContext();
      var nodesCount = nodes.length;
      var output_arr = new Float32Array(nodesCount * 4);
      gl.readPixels(0, 0, nodesCount, 1, gl.RGBA, gl.FLOAT, output_arr);
      var i;
      for (i = 0; i < nodesCount; i += 1) {
        nodes[i].x = output_arr[4 * i];
        nodes[i].y = output_arr[4 * i + 1];
      }
    };

    this.setupGo = function () {
      var nodes = this.nodes;
      var edges = this.edges;
      var nodesCount = nodes.length;
      var edgesCount = edges.length;
      this.nodesCount = nodesCount;
      this.config.area = this.config.autoArea ? nodesCount * nodesCount : this.config.area;
      this.maxDisplace = Math.sqrt(this.config.area) / 10;
      this.k_2 = this.config.area / (1 + nodesCount);
      this.k = Math.sqrt(this.k_2);

      var textureSize = nodesCount + parseInt((edgesCount * 2 + 3) / 4, 10);
      this.textureSize = textureSize;
      var gpgpUtility = new window.vizit.utility.GPGPUtility(textureSize, 1, { premultipliedAlpha: false });
      this.gpgpUtility = gpgpUtility;

      if (!gpgpUtility.isFloatingTexture()) {
        return { ok: false, reason: "Float textures (OES_texture_float) not supported." };
      }

      this.gl = gpgpUtility.getGLContext();

      var data = this.buildTextureData(nodes, edges, nodesCount, edgesCount);
      this.texture_input = gpgpUtility.makeTexture(WebGLRenderingContext.FLOAT, data);
      this.texture_output = gpgpUtility.makeTexture(WebGLRenderingContext.FLOAT, data);

      this.createProgram();

      gpgpUtility.attachFrameBuffer(this.texture_output);
      var bufferStatus = gpgpUtility.frameBufferIsComplete();
      if (!bufferStatus.isComplete) {
        return { ok: false, reason: bufferStatus.message || "Framebuffer incomplete." };
      }

      this.iterCount = Math.max(1, this.config.iterations);
      this.running = true;
      this._saved = false;
      return { ok: true };
    };

    /**
     * One simulation step. Returns true when layout finished and positions written to nodes.
     */
    this.step = function () {
      if (!this.setupOk || this._saved) {
        return true;
      }
      if (!this.running) {
        this.saveDataToNode();
        this._saved = true;
        return true;
      }
      var tmp = this.texture_input;
      this.texture_input = this.texture_output;
      this.texture_output = tmp;
      this.atomicGo(this.texture_input, this.texture_output);
      if (!this.running) {
        this.saveDataToNode();
        this._saved = true;
      }
      return this._saved;
    };

    this.dispose = function () {
      this.nodes = null;
      this.edges = null;
      this.gl = null;
      this.gpgpUtility = null;
      this.program = null;
      this.texture_input = null;
      this.texture_output = null;
      this.setupOk = false;
      this._saved = false;
    };
  }

  function initNodePositions(nodes) {
    var i;
    var n;
    for (i = 0; i < nodes.length; i += 1) {
      n = nodes[i];
      if (!Number.isFinite(n.x) || !Number.isFinite(n.y)) {
        n.x = (Math.random() - 0.5) * 2;
        n.y = (Math.random() - 0.5) * 2;
      }
    }
  }

  /**
   * @param {object} config
   * @param {Array<object>} config.nodes — mutated; must have x,y (filled if missing)
   * @param {Array<{source:number,target:number}>} config.links — vertex indices
   * @param {number} [config.iterations]
   * @param {number} [config.gravity]
   * @param {number} [config.speed]
   * @param {boolean} [config.autoArea]
   * @param {number} [config.area]
   */
  function paraGraphLLayoutBegin(config) {
    if (!config || !Array.isArray(config.nodes) || config.nodes.length === 0) {
      return { ok: false, reason: "Missing or empty nodes." };
    }
    var nodes = config.nodes;
    var links = Array.isArray(config.links) ? config.links : [];
    initNodePositions(nodes);

    var engine = new FruchtermanReingoldGL();
    engine.nodes = nodes;
    engine.edges = links;
    engine.config = extend(defaultSettings, {
      iterations:
        typeof config.iterations === "number" && config.iterations > 0
          ? Math.max(1, Math.floor(config.iterations))
          : defaultSettings.iterations,
      gravity: typeof config.gravity === "number" ? config.gravity : defaultSettings.gravity,
      speed: typeof config.speed === "number" ? config.speed : defaultSettings.speed,
      autoArea: typeof config.autoArea === "boolean" ? config.autoArea : defaultSettings.autoArea,
      area: typeof config.area === "number" ? config.area : defaultSettings.area,
    });

    var setup = engine.setupGo();
    if (!setup.ok) {
      engine.dispose();
      return { ok: false, reason: setup.reason || "WebGL layout setup failed." };
    }
    engine.setupOk = true;

    var disposed = false;
    return {
      ok: true,
      tick: function () {
        return engine.step();
      },
      dispose: function () {
        if (disposed) {
          return;
        }
        disposed = true;
        engine.dispose();
      },
    };
  }

  function paraGraphLLayout(config) {
    var r = paraGraphLLayoutBegin(config);
    if (!r.ok) {
      return r;
    }
    while (!r.tick()) {
      /* drain iterations */
    }
    r.dispose();
    return { ok: true };
  }

  window.paraGraphLLayoutBegin = paraGraphLLayoutBegin;
  window.paraGraphLLayout = paraGraphLLayout;
})();
