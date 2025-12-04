const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function createDefaultLobbies() {
  console.log('🚀 Creating default lobbies...\n');

  const lobbies = [
    {
      id: 'global',
      name: 'Global Lobby',
      topic: 'General Discussion',
      description: 'Main community space for everyone',
      iconEmoji: '🌍',
      onlineCount: 0,
      totalMembers: 0,
      type: 'global',
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {
      id: 'gaming',
      name: 'Gaming Zone',
      topic: 'Gaming & Esports',
      description: 'Talk gaming, share clips, find teammates',
      iconEmoji: '🎮',
      onlineCount: 0,
      totalMembers: 0,
      type: 'topic',
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {
      id: 'coding',
      name: 'Code & Build',
      topic: 'Programming & Development',
      description: 'Developers, projects, tech discussions',
      iconEmoji: '💻',
      onlineCount: 0,
      totalMembers: 0,
      type: 'topic',
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {
      id: 'hustle',
      name: 'Hustle Hub',
      topic: 'Business & Entrepreneurship',
      description: 'Startups, side hustles, making money moves',
      iconEmoji: '💸',
      onlineCount: 0,
      totalMembers: 0,
      type: 'topic',
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {
      id: 'random',
      name: 'Random Chat',
      topic: 'Anything Goes',
      description: 'Chill, vibe, talk about whatever',
      iconEmoji: '💬',
      onlineCount: 0,
      totalMembers: 0,
      type: 'topic',
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
  ];

  try {
    for (const lobby of lobbies) {
      const { id, ...data } = lobby;
      await db.collection('lobbies').doc(id).set(data);
      console.log(`✅ Created lobby: ${data.iconEmoji} ${data.name}`);
    }
    
    console.log('\n🎉 All lobbies created successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating lobbies:', error);
    process.exit(1);
  }
}

createDefaultLobbies();
