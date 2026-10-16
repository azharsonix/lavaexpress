const test = require("node:test");
const assert = require("node:assert");
const { paginaPedido, paginaNoEncontrado, escapar } = require("../lib/pagina");

const base = {
  folio: 7,
  estado: "en_proceso",
  domicilio: false,
  servicioNombre: "Lavado y secado",
  horario: "09:00 - 11:00",
  fecha: new Date("2026-10-16T15:00:00Z"),
  pesoKg: 4.5,
  precioPorKg: 30,
  total: 135,
  historial: [{ estado: "solicitud_recibida", fecha: new Date("2026-10-16T14:00:00Z") }],
};

test("muestra folio, estado actual y total", () => {
  const html = paginaPedido(base);
  assert.match(html, /Pedido #007/);
  assert.match(html, /<h1>En proceso<\/h1>/);
  assert.match(html, /\$135\.00/);
});

test("sin peso muestra 'Pendiente de pesar'", () => {
  const html = paginaPedido({ ...base, pesoKg: null, total: null, estado: "solicitud_recibida" });
  assert.match(html, /Pendiente de pesar/);
});

test("'En camino' solo aparece en pedidos a domicilio", () => {
  assert.doesNotMatch(paginaPedido(base), /En camino/);
  assert.match(paginaPedido({ ...base, domicilio: true }), /En camino/);
});

test("escapa HTML para evitar inyección", () => {
  assert.strictEqual(escapar('<script>"x"</script>'), "&lt;script&gt;&quot;x&quot;&lt;/script&gt;");
  const html = paginaPedido({ ...base, servicioNombre: "<img src=x onerror=alert(1)>" });
  assert.doesNotMatch(html, /<img src=x/);
});

test("página de no encontrado", () => {
  assert.match(paginaNoEncontrado(), /Pedido no encontrado/);
});
