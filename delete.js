const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function deleteRoutes() {
  const routesRef = db.collection("routes");
  const snapshot = await routesRef.get();

  if (snapshot.empty) {
    console.log("No routes to delete.");
    return;
  }

  const batch = db.batch();

  snapshot.forEach((doc) => {
    batch.delete(doc.ref);
  });

  await batch.commit();
  console.log("✅ All routes deleted.");
}

deleteRoutes().catch((err) => {
  console.error("❌ Error deleting routes:", err);
});
