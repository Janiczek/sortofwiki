// Bundled for `lamdera deploy`; `lamdera live` auto-includes each file in elm-pkg-js/.
// @see https://dashboard.lamdera.app/docs/elm-pkg-js

const color_theme = require("./elm-pkg-js/color-theme");

exports.init = async function init(app) {
  color_theme.init(app);
};
