// Arma en el servidor el HTML de la página pública de seguimiento.
// Está separado de api/seguimiento.js para poder probarlo sin Firebase (node --test).

// La app está en Firebase Hosting; esta página vive en otro dominio (Vercel).
const URL_APP = "https://lavaexpress-a35d3.web.app";

const ESTADOS = [
  ["solicitud_recibida", "Solicitud recibida", "Recibimos tu solicitud."],
  ["ropa_recibida", "Ropa recibida", "Ya tenemos tu ropa y registramos su peso."],
  ["en_proceso", "En proceso", "Tu ropa se está lavando."],
  ["lista_para_entregar", "Lista para entregar", "Tu ropa está limpia y lista."],
  ["en_camino", "En camino", "Vamos en camino a entregarte tu ropa."],
  ["entregada", "Entregada", "Pedido entregado. ¡Gracias por elegir LavaExpress!"],
];

const ENTIDADES = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" };
const escapar = (t) => String(t ?? "").replace(/[&<>"']/g, (c) => ENTIDADES[c]);

const folio = (n) => "#" + String(n).padStart(3, "0");

const zona = "America/Mexico_City";
const fechaLarga = (d) =>
  d.toLocaleDateString("es-MX", { weekday: "long", day: "numeric", month: "long", timeZone: zona });
const fechaHora = (d) =>
  d.toLocaleString("es-MX", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit", timeZone: zona });
const moneda = (n) => n.toLocaleString("es-MX", { style: "currency", currency: "MXN" });

/** Datos del pedido → HTML. Solo muestra datos que no identifican al cliente. */
function paginaPedido(p, generado = new Date()) {
  const flujo = ESTADOS.filter(([clave]) => p.domicilio || clave !== "en_camino");
  const actual = Math.max(0, flujo.findIndex(([clave]) => clave === p.estado));
  const fechas = Object.fromEntries((p.historial || []).map((h) => [h.estado, h.fecha]));
  const [, etiqueta, mensaje] = flujo[actual];

  const pasos = flujo
    .map(([clave, texto], i) => {
      const clase = i < actual ? "hecho" : i === actual ? "actual" : "";
      const cuando = fechas[clave] ? `<small>${escapar(fechaHora(fechas[clave]))}</small>` : "";
      return `<li class="${clase}"><span></span><div><b>${escapar(texto)}</b>${cuando}</div></li>`;
    })
    .join("");

  const total =
    p.total == null ? "Pendiente de pesar" : `${moneda(p.total)} (${p.pesoKg} kg × ${moneda(p.precioPorKg)})`;
  const avance = Math.round(((actual + 1) / flujo.length) * 100);

  return plantilla(
    `Pedido ${folio(p.folio)}`,
    `<p class="etiqueta">Pedido ${escapar(folio(p.folio))}</p>
     <h1>${escapar(etiqueta)}</h1>
     <p class="mensaje">${escapar(mensaje)}</p>
     <div class="barra"><i style="width:${avance}%"></i></div>
     <dl>
       <dt>Servicio</dt><dd>${escapar(p.servicioNombre)}</dd>
       <dt>Entrega</dt><dd>${p.domicilio ? "Recolección y entrega a domicilio" : "En la lavandería"}</dd>
       <dt>Cita</dt><dd>${escapar(fechaLarga(p.fecha))} · ${escapar(p.horario)}</dd>
       <dt>Total</dt><dd>${escapar(total)}</dd>
     </dl>
     <h2>Seguimiento</h2>
     <ol class="pasos">${pasos}</ol>`,
    generado,
  );
}

function paginaNoEncontrado(generado = new Date()) {
  return plantilla(
    "Pedido no encontrado",
    `<h1>Pedido no encontrado</h1><p class="mensaje">Revisa que el enlace esté completo.</p>`,
    generado,
  );
}

function plantilla(titulo, contenido, generado) {
  return `<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>${escapar(titulo)} · LavaExpress</title>
<link rel="icon" href="${URL_APP}/favicon.png">
<style>
  :root { --azul:#1D4ED8; --agua:#38BDF8; --texto:#0F172A; --suave:#64748B; --borde:#E2E8F0; --fondo:#F1F5F9; --tarjeta:#fff; }
  @media (prefers-color-scheme: dark) {
    :root { --texto:#E2E8F0; --suave:#94A3B8; --borde:#1F2A3C; --fondo:#0B1120; --tarjeta:#111827; }
  }
  * { box-sizing: border-box; }
  body { margin:0; background:var(--fondo); color:var(--texto); font:15px/1.5 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif; }
  header { background:linear-gradient(135deg,#0B63CE,var(--azul)); color:#fff; padding:18px 16px; }
  header div { max-width:560px; margin:auto; display:flex; align-items:center; gap:10px; font-weight:800; font-size:18px; letter-spacing:-.3px; }
  header img { width:32px; height:32px; border-radius:8px; }
  header b { color:var(--agua); }
  main { max-width:560px; margin:0 auto; padding:0 16px 32px; }
  .tarjeta { background:var(--tarjeta); border:1px solid var(--borde); border-radius:12px; padding:22px; margin-top:16px; }
  .etiqueta { margin:0; color:var(--suave); font-size:13px; font-weight:600; text-transform:uppercase; letter-spacing:.6px; }
  h1 { margin:4px 0 2px; font-size:26px; letter-spacing:-.4px; }
  h2 { font-size:15px; margin:24px 0 8px; }
  .mensaje { margin:0; color:var(--suave); }
  .barra { height:6px; background:var(--borde); border-radius:6px; margin:18px 0; overflow:hidden; }
  .barra i { display:block; height:100%; background:var(--azul); }
  dl { display:grid; grid-template-columns:auto 1fr; gap:6px 16px; margin:0; }
  dt { color:var(--suave); }
  dd { margin:0; font-weight:600; }
  .pasos { list-style:none; margin:0; padding:0; }
  .pasos li { display:flex; gap:12px; padding:6px 0; color:var(--suave); }
  .pasos span { width:12px; height:12px; margin-top:5px; border-radius:50%; border:2px solid var(--borde); flex:none; }
  .pasos .hecho, .pasos .actual { color:var(--texto); }
  .pasos .hecho span { background:var(--azul); border-color:var(--azul); }
  .pasos .actual span { background:var(--agua); border-color:var(--agua); box-shadow:0 0 0 4px rgba(56,189,248,.25); }
  .pasos small { display:block; color:var(--suave); }
  footer { text-align:center; color:var(--suave); font-size:12px; margin-top:20px; }
  footer a { color:var(--azul); }
</style>
</head>
<body>
<header><div><img src="${URL_APP}/icons/Icon-192.png" alt="">Lava<b>Express</b></div></header>
<main>
  <section class="tarjeta">${contenido}</section>
  <footer>Página generada en el servidor el ${escapar(fechaHora(generado))} · <a href="${URL_APP}">Abrir la app</a></footer>
</main>
</body>
</html>`;
}

module.exports = { paginaPedido, paginaNoEncontrado, escapar };
