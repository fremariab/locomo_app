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
    const snapshot = await db.collection("routes").get();
    let matchedRoutes = [];

    snapshot.forEach(doc => {
      const data = doc.data();

      const stops = data.stops.map(stop => stop.toLowerCase());
      const originIndex = stops.indexOf(origin.toLowerCase());
      const destinationIndex = stops.indexOf(destination.toLowerCase());

      // Origin and destination must both exist and be in the correct order
      if (originIndex !== -1 && destinationIndex !== -1 && originIndex < destinationIndex) {
        const subStops = stops.slice(originIndex, destinationIndex + 1);

        // Estimate fare (optional logic or fixed)
        const fare = data.fare || 3.5; // fallback if fare not stored

        // Check budget
        if (!budget || fare <= budget) {
          matchedRoutes.push({
            routeId: data.id || doc.id,
            routeName: data.routeName,
            origin: origin,
            destination: destination,
            stops: subStops,
            fare: fare,
            transfers: 0,
            time: (subStops.length * 2), // mock 2 mins per stop
            firstStation: origin,
            lastStation: destination
          });
        }
      }
    });

    // Sort results based on user preference
    if (preference === "shortest_time") {
      matchedRoutes.sort((a, b) => a.time - b.time);
    } else if (preference === "lowest_fare") {
      matchedRoutes.sort((a, b) => a.fare - b.fare);
    } else if (preference === "fewest_transfers") {
      matchedRoutes.sort((a, b) => a.transfers - b.transfers);
    }

    return res.status(200).json({ results: matchedRoutes });
  } catch (err) {
    console.error("❌ Backend error:", err);
    return res.status(500).json({ error: "Something went wrong" });
  }
});
