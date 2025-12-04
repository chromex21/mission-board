// Run this in Firebase Functions environment or locally with admin SDK
// node scripts/init-lobbies-simple.js

const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

// Initialize Firebase Admin
initializeApp();
const db = getFirestore();

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
    },
  ];

  try {
    const batch = db.batch();
    
    for (const lobby of lobbies) {
      const { id, ...data } = lobby;
      const ref = db.collection('lobbies').doc(id);
      batch.set(ref, {
        ...data,
        createdAt: new Date(),
      });
      console.log(`✅ Queued lobby: ${data.iconEmoji} ${data.name}`);
    }
    
    await batch.commit();
    console.log('\n🎉 All lobbies created successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating lobbies:', error);
    process.exit(1);
  }
}

createDefaultLobbies();
