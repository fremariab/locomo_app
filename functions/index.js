/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();

exports.searchRoutes = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  const { origin, destination, preference = "none", budget = null } = req.body;

  try {
    const snapshot = await db.collection("routes")
      .where("origin", "==", origin)
      .where("destination", "==", destination)
      .get();

    let results = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      if (!budget || data.fare <= budget) {
        results.push(data);
      }
    });

    if (preference === "shortest_time") {
      results.sort((a, b) => a.time - b.time);
    } else if (preference === "lowest_fare") {
      results.sort((a, b) => a.fare - b.fare);
    } else if (preference === "fewest_transfers") {
      results.sort((a, b) => a.transfers - b.transfers);
    }

    return res.status(200).json({ results });
  } catch (err) {
    console.error("Error:", err);
    return res.status(500).json({ error: "Something went wrong" });
  }
});

