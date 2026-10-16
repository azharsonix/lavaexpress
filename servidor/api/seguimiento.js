// Vista generada en el SERVIDOR (función serverless de Vercel).
// vercel.json envía /seguimiento/<idPedido> aquí; la función lee el pedido
// con Firebase Admin SDK y responde HTML ya armado, sin JavaScript en el cliente.
//
// Variable de entorno requerida en Vercel (secreta):
//   FIREBASE_SERVICE_ACCOUNT = contenido JSON de la clave de servicio de Firebase
const { initializeApp, cert, getApps } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { paginaPedido, paginaNoEncontrado } = require("../lib/pagina");

function db() {
  if (!getApps().length) {
    initializeApp({ credential: cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)) });
  }
  return getFirestore();
}

module.exports = async (req, res) => {
  const id = String(req.query.id || "");
  res.setHeader("Content-Type", "text/html; charset=utf-8");
  res.setHeader("Cache-Control", "private, max-age=30");

  // Los id de Firestore son 20 caracteres alfanuméricos.
  if (!/^[A-Za-z0-9]{10,40}$/.test(id)) {
    res.status(404).send(paginaNoEncontrado());
    return;
  }

  const doc = await db().collection("pedidos").doc(id).get();
  if (!doc.exists) {
    res.status(404).send(paginaNoEncontrado());
    return;
  }

  const d = doc.data();
  res.status(200).send(
    paginaPedido({
      folio: d.folio,
      estado: d.estado,
      domicilio: d.domicilio,
      servicioNombre: d.servicioNombre,
      horario: d.horario,
      fecha: d.fecha.toDate(),
      pesoKg: d.pesoKg,
      precioPorKg: d.precioPorKg,
      total: d.total,
      historial: (d.historial || []).map((h) => ({ estado: h.estado, fecha: h.fecha.toDate() })),
    }),
  );
};
