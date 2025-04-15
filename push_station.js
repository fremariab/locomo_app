const admin = require("firebase-admin");
const serviceAccount = require("./service_account.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const newStops = [
  {
    id: "bubuashie",
    name: "Bubuashie",
    coordinates: null,
    nearbyStationId: null,
    type: "stop"
  },
  {
    id: "lapaz",
    name: "Lapaz",
    coordinates: null,
    nearbyStationId: null,
    type: "stop"
  },
  {
    id: "mccarthy_hill",
    name: "McCarthy Hill",
    coordinates: null,
    nearbyStationId: null,
    type: "stop"
  },
  {
    id: "santa_maria",
    name: "Santa Maria",
    coordinates: null,
    nearbyStationId: null,
    type: "stop"
  },
  {
    id: "sowutuom",
    name: "Sowutuom",
    coordinates: null,
    nearbyStationId: null,
    type: "stop"
  },
  {
    id: "tabora",
    name: "Tabora",
    coordinates: null,
    nearbyStationId: null,
    type: "stop"
  },
  {
    id: "dansoman_roundabout",
    name: "Dansoman Roundabout",
    coordinates: null,
    nearbyStationId: null,
    type: "stop"
  }
];

const pushStops = async () => {
  try {
    for (const stop of newStops) {
      await db.collection("stops").doc(stop.id).set(stop);
    }
    console.log("✅ New stops uploaded successfully!");
    process.exit(0);
  } catch (err) {
    console.error("❌ Error uploading stops:", err);
    process.exit(1);
  }
};

pushStops();
