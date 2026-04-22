// Bundled for `lamdera deploy`; `lamdera live` auto-includes each file in elm-pkg-js/.
// @see https://dashboard.lamdera.app/docs/elm-pkg-js

const color_theme = require("./elm-pkg-js/color-theme");
const graphviz_links = require("./elm-pkg-js/graphviz-links");
const math_jax = require("./elm-pkg-js/math-jax");

exports.init = async function init(app) {
  color_theme.init(app);
  graphviz_links.init(app);
  math_jax.init(app);
};
