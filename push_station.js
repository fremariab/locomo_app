// // Import the Firebase Admin SDK
// const admin = require("firebase-admin");

// // Load your service account key JSON file
// const serviceAccount = require("./service-account.json");

// // Initialize the Firebase Admin SDK with your service account and database URL
// admin.initializeApp({
//   credential: admin.credential.cert(serviceAccount),
//   databaseURL: "https://your-database-name.firebaseio.com"  // Replace with your actual database URL
// });

// // Reference to your Firebase Realtime Database
// const db = admin.database();

// // Define the path (collection) where you want to push your stations
// const stationsRef = db.ref("stations");

// // Define your station data object, following your desired structure
// const newStation = {
//   name: "Kaneshie Station",
//   coordinates: {
//     lat: 5.5655,
//     lng: -0.2352
//   },
//   region: "Greater Accra",
//   connections: [
//     {
//       stationId: "another_station_id",
//       fare: 4,
//       direct: true
//     }
//   ]
// };

// // Push the new station to the database
// stationsRef.push(newStation)
//   .then(() => {
//     console.log("New station added successfully!");
//     process.exit(0);
//   })
//   .catch((error) => {
//     console.error("Error adding new station:", error);
//     process.exit(1);
//   });
// Import the Firebase Admin SDK
// Import the Firebase Admin SDK
const admin = require("firebase-admin");

// Load your service account key JSON file
const serviceAccount = require("./service-account.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// ---------------- STATIONS ----------------
const testStations = [
  {
    id: "kaneshie_station",
    name: "Kaneshie Station",
    coordinates: { lat: 5.5655, lng: -0.2352 },
    region: "Greater Accra",
    type: "station",
    connections: [
      {
        stationId: "achimota_station",
        fare: 5,
        direct: true
      }
    ]
  },
  {
    id: "achimota_station",
    name: "Achimota Station",
    coordinates: { lat: 5.6266, lng: -0.2360 },
    region: "Greater Accra",
    type: "station",
    connections: [
      {
        stationId: "kaneshie_station",
        fare: 5,
        direct: true
      }
    ]
  }
];

// ---------------- STOPS ----------------
const testStops = [
  {
    id: "golf_park",
    name: "Golf Park",
    coordinates: { lat: 5.6401, lng: -0.2212 },
    type: "stop",
    nearbyStationId: "achimota_station"
  },
  {
    id: "circle_overhead",
    name: "Circle Overhead",
    coordinates: { lat: 5.5607, lng: -0.2056 },
    type: "stop",
    nearbyStationId: "kaneshie_station"
  }
];

// ---------------- FARES ----------------
const testFares = {
  station_to_station: {
    achimota_station_kaneshie_station: 5
  },
  stop_to_stop: {
    golf_park_circle_overhead: 3.5
  }
};

// ---------------- ROUTES ----------------
const testRoutes = [
  {
    id: "route_241",
    routeName: "Trotro 241",
    origin: "Bawaleshie",
    destination: "Circle Overhead",
    stops: [
      "Bawaleshie", "Mensvic", "Emmanuel Eye Clinic", "Shiashie", "Spanner", "Shangrila",
      "Airport First", "Airport Second", "Opeibea First", "Opeibea Second", "37", "37 Hospital",
      "37 Water Works", "Flagstaff House", "Sankara", "GBC", "Mobil / Kanda Overhead", "Nima Junction",
      "Paloma", "Equip", "Circle Overhead"
    ]
  },
  {
    id: "route_81",
    routeName: "Trotro 81",
    origin: "Achimota",
    destination: "Adenta Station",
    fare: 6.0,
    stops: [
      "Achimota", "Achimota Club House", "PWD", "Achimota Hospital", "Golf Park", "Christian Village",
      "Pure Fire", "Airways Junction", "Supermarket", "Agbogba Junction", "Atomic First", "Atomic Second",
      "Madina Zongo Junction", "Ritz Junction", "Assemblies", "SDA", "Goil Filling Station", "Wass",
      "Adenta Barrier", "Adenta Station"
    ]
  }
];

// ---------------- PUSH FUNCTION ----------------
const pushAll = async () => {
  try {
    // Push stations
    for (const station of testStations) {
      await db.collection("stations").doc(station.id).set(station);
    }

    // Push stops
    for (const stop of testStops) {
      await db.collection("stops").doc(stop.id).set(stop);
    }

    // Push fares
    await db.collection("fares").doc("station_to_station").set(testFares.station_to_station);
    await db.collection("fares").doc("stop_to_stop").set(testFares.stop_to_stop);

    // Push routes
    for (const route of testRoutes) {
      await db.collection("routes").doc(route.id).set(route);
    }

    console.log("✅ All data (stations, stops, fares, routes) added to Firestore!");
    process.exit(0);
  } catch (error) {
    console.error("❌ Error adding data:", error);
    process.exit(1);
  }
};

pushAll();
