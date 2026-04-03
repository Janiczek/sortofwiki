const STORAGE_KEY = "sortofwiki-color-theme";

function readPreference() {
  try {
    const v = localStorage.getItem(STORAGE_KEY);
    if (v === "light" || v === "dark") {
      return v;
    }
  } catch (_) {}
  return "system";
}

function systemSchemeLabel() {
  return window.matchMedia("(prefers-color-scheme: dark)").matches
    ? "dark"
    : "light";
}

exports.init = function init(app) {
  const ports = app.ports;
  if (!ports || !ports.colorThemeFromJs || !ports.colorThemeToJs) {
    return;
  }

  function sendSync() {
    ports.colorThemeFromJs.send({
      kind: "sync",
      preference: readPreference(),
      systemScheme: systemSchemeLabel(),
    });
  }

  sendSync();

  const mq = window.matchMedia("(prefers-color-scheme: dark)");
  function onSystemChange() {
    ports.colorThemeFromJs.send({
      kind: "system",
      systemScheme: systemSchemeLabel(),
    });
  }
  if (mq.addEventListener) {
    mq.addEventListener("change", onSystemChange);
  } else {
    mq.addListener(onSystemChange);
  }

  ports.colorThemeToJs.subscribe(function (value) {
    const pref = value && value.preference;
    if (pref !== "system" && pref !== "light" && pref !== "dark") {
      return;
    }
    try {
      if (pref === "system") {
        localStorage.removeItem(STORAGE_KEY);
      } else {
        localStorage.setItem(STORAGE_KEY, pref);
      }
    } catch (_) {}
  });
};
