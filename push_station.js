// Import the Firebase Admin SDK
const admin = require("firebase-admin");

// Load your service account key JSON file
const serviceAccount = require("./service-account.json");

// Initialize the Firebase Admin SDK with your service account and database URL
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://your-database-name.firebaseio.com"  // Replace with your actual database URL
});

// Reference to your Firebase Realtime Database
const db = admin.database();

// Define the path (collection) where you want to push your stations
const stationsRef = db.ref("stations");

// Define your station data object, following your desired structure
const newStation = {
  name: "Kaneshie Station",
  coordinates: {
    lat: 5.5655,
    lng: -0.2352
  },
  region: "Greater Accra",
  connections: [
    {
      stationId: "another_station_id",
      fare: 4,
      direct: true
    }
  ]
};

// Push the new station to the database
stationsRef.push(newStation)
  .then(() => {
    console.log("New station added successfully!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("Error adding new station:", error);
    process.exit(1);
  });
