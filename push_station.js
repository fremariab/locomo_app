const fs = require('fs');
const admin = require('firebase-admin');

// 🔑 Your Firebase service account key
const serviceAccount = require('./service_account.json');

// 🔥 Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// ✏️ List the collections to export
const collectionsToExport = ['stations', 'stops', 'fares'];

async function exportCollectionToJson(collectionName) {
  try {
    const snapshot = await db.collection(collectionName).get();

    if (snapshot.empty) {
      console.log(`⚠️ No documents found in collection: ${collectionName}`);
      return;
    }

    const data = [];
    snapshot.forEach(doc => {
      data.push({
        id: doc.id,
        ...doc.data()
      });
    });

    const fileName = `${collectionName}.json`;
    fs.writeFileSync(fileName, JSON.stringify(data, null, 2));
    console.log(`✅ Exported ${data.length} docs from "${collectionName}" → ${fileName}`);
  } catch (error) {
    console.error(`❌ Failed to export "${collectionName}":`, error);
  }
}

async function exportAllCollections() {
  for (const name of collectionsToExport) {
    await exportCollectionToJson(name);
  }
}

exportAllCollections();
