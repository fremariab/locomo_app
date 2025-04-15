const { onRequest } = require("firebase-functions/v2/https");
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// This function handles incoming requests to search for possible routes
exports.searchRoutes = functions.https.onRequest(async (req, res) => {
  // Only allow POST requests
  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  // Get user input from the request
  const { origin, destination, preference = "none", budget = null } = req.body;

  try {
    // Get all route documents from Firestore
    const snapshot = await db.collection("routes").get();
    let matchedRoutes = [];

    snapshot.forEach(doc => {
      const data = doc.data();

      // Convert all stops to lowercase to make comparison easier
      const stops = data.stops.map(stop => stop.toLowerCase());
      const originIndex = stops.indexOf(origin.toLowerCase());
      const destinationIndex = stops.indexOf(destination.toLowerCase());

      // Only continue if both origin and destination exist and are in order
      if (originIndex !== -1 && destinationIndex !== -1 && originIndex < destinationIndex) {
        const subStops = stops.slice(originIndex, destinationIndex + 1);

        // If fare is missing, use a default of 3.5
        const fare = data.fare || 3.5;

        // If no budget is provided or fare is within budget, include the route
        if (!budget || fare <= budget) {
          matchedRoutes.push({
            routeId: data.id || doc.id,
            routeName: data.routeName,
            origin: origin,
            destination: destination,
            stops: subStops,
            fare: fare,
            transfers: 0,
            time: (subStops.length * 2), // Assume each stop takes 2 minutes
            firstStation: origin,
            lastStation: destination
          });
        }
      }
    });

    // Sort results based on the user's selected preference
    if (preference === "shortest_time") {
      matchedRoutes.sort((a, b) => a.time - b.time);
    } else if (preference === "lowest_fare") {
      matchedRoutes.sort((a, b) => a.fare - b.fare);
    } else if (preference === "fewest_transfers") {
      matchedRoutes.sort((a, b) => a.transfers - b.transfers);
    }

    // Return the matched routes
    return res.status(200).json({ results: matchedRoutes });

  } catch (err) {
    console.error("Error while searching routes:", err);
    return res.status(500).json({ error: "Something went wrong" });
  }
});
