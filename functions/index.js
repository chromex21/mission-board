const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// ============================================================================
// PUSH NOTIFICATIONS
// ============================================================================

/**
 * Send push notification when a new message is created
 */
exports.sendMessageNotification = functions.firestore
    .document('conversations/{conversationId}/messages/{messageId}')
    .onCreate(async (snap, context) => {
      const message = snap.data();
      const conversationId = context.params.conversationId;
      
      try {
        // Get conversation to find recipients
        const conversationDoc = await db.collection('conversations')
            .doc(conversationId).get();
        
        if (!conversationDoc.exists) return null;
        
        const conversation = conversationDoc.data();
        const participants = conversation.participants || [];
        const senderId = message.senderId;
        
        // Get sender info
        const senderDoc = await db.collection('users').doc(senderId).get();
        const senderName = senderDoc.data()?.displayName || 
                          senderDoc.data()?.username || 
                          'Someone';
        
        // Send notification to each participant (except sender)
        const notifications = [];
        for (const participantId of participants) {
          if (participantId === senderId) continue;
          
          // Get participant's FCM token
          const userDoc = await db.collection('users').doc(participantId).get();
          const fcmToken = userDoc.data()?.fcmToken;
          
          if (fcmToken) {
            // Prepare notification content
            let body = '';
            if (message.type === 'text') {
              body = message.content;
            } else if (message.type === 'image') {
              body = '📷 Sent an image';
            } else if (message.type === 'gif') {
              body = '🎬 Sent a GIF';
            } else if (message.type === 'voice') {
              body = '🎤 Sent a voice note';
            } else if (message.type === 'file') {
              body = '📎 Sent a file';
            }
            
            // Send FCM notification
            const payload = {
              notification: {
                title: senderName,
                body: body,
              },
              data: {
                type: 'message',
                actionId: conversationId,
                senderId: senderId,
              },
              token: fcmToken,
            };
            
            notifications.push(admin.messaging().send(payload));
          }
        }
        
        await Promise.all(notifications);
        console.log(`Sent ${notifications.length} message notifications`);
        
      } catch (error) {
        console.error('Error sending message notification:', error);
      }
      
      return null;
    });

/**
 * Send push notification when friend request is created
 */
exports.sendFriendRequestNotification = functions.firestore
    .document('friendRequests/{requestId}')
    .onCreate(async (snap, context) => {
      const request = snap.data();
      
      try {
        // Get sender info
        const senderDoc = await db.collection('users')
            .doc(request.senderId).get();
        const senderName = senderDoc.data()?.displayName || 
                          senderDoc.data()?.username || 
                          'Someone';
        
        // Get receiver's FCM token
        const receiverDoc = await db.collection('users')
            .doc(request.receiverId).get();
        const fcmToken = receiverDoc.data()?.fcmToken;
        
        if (fcmToken) {
          const payload = {
            notification: {
              title: 'New Friend Request',
              body: `${senderName} sent you a friend request`,
            },
            data: {
              type: 'friendRequest',
              actionId: context.params.requestId,
              senderId: request.senderId,
            },
            token: fcmToken,
          };
          
          await admin.messaging().send(payload);
          console.log('Sent friend request notification');
        }
      } catch (error) {
        console.error('Error sending friend request notification:', error);
      }
      
      return null;
    });

/**
 * Send push notification when mission is assigned
 */
exports.sendMissionNotification = functions.firestore
    .document('missions/{missionId}')
    .onCreate(async (snap, context) => {
      const mission = snap.data();
      
      if (!mission.assignedTo) return null;
      
      try {
        // Get creator info
        const creatorDoc = await db.collection('users')
            .doc(mission.createdBy).get();
        const creatorName = creatorDoc.data()?.displayName || 
                           creatorDoc.data()?.username || 
                           'Someone';
        
        // Get assignee's FCM token
        const assigneeDoc = await db.collection('users')
            .doc(mission.assignedTo).get();
        const fcmToken = assigneeDoc.data()?.fcmToken;
        
        if (fcmToken) {
          const payload = {
            notification: {
              title: 'New Mission Assigned',
              body: `${creatorName} assigned you: ${mission.title}`,
            },
            data: {
              type: 'mission',
              actionId: context.params.missionId,
              creatorId: mission.createdBy,
            },
            token: fcmToken,
          };
          
          await admin.messaging().send(payload);
          console.log('Sent mission notification');
        }
      } catch (error) {
        console.error('Error sending mission notification:', error);
      }
      
      return null;
    });

// ============================================================================
// SCHEDULED TASKS
// ============================================================================

/**
 * Delete notifications older than 30 days (runs daily at 2 AM UTC)
 */
exports.cleanupOldNotifications = functions.pubsub
    .schedule('0 2 * * *')
    .timeZone('UTC')
    .onRun(async (context) => {
      const cutoffTime = Date.now() - (30 * 24 * 60 * 60 * 1000); // 30 days
      
      try {
        const oldNotifications = await db.collection('notifications')
            .where('createdAt', '<', cutoffTime)
            .get();
        
        if (oldNotifications.empty) {
          console.log('No old notifications to delete');
          return null;
        }
        
        const batch = db.batch();
        oldNotifications.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });
        
        await batch.commit();
        console.log(`Deleted ${oldNotifications.size} old notifications`);
      } catch (error) {
        console.error('Error cleaning up notifications:', error);
      }
      
      return null;
    });

/**
 * Delete old messages in conversations (runs weekly on Sunday at 3 AM UTC)
 * Only deletes messages older than 90 days
 */
exports.cleanupOldMessages = functions.pubsub
    .schedule('0 3 * * 0')
    .timeZone('UTC')
    .onRun(async (context) => {
      const cutoffTime = Date.now() - (90 * 24 * 60 * 60 * 1000); // 90 days
      
      try {
        const conversations = await db.collection('conversations').get();
        let totalDeleted = 0;
        
        for (const convDoc of conversations.docs) {
          const oldMessages = await convDoc.ref.collection('messages')
              .where('timestamp', '<', cutoffTime)
              .get();
          
          if (!oldMessages.empty) {
            const batch = db.batch();
            oldMessages.docs.forEach((doc) => {
              batch.delete(doc.ref);
            });
            
            await batch.commit();
            totalDeleted += oldMessages.size;
          }
        }
        
        console.log(`Deleted ${totalDeleted} old messages`);
      } catch (error) {
        console.error('Error cleaning up messages:', error);
      }
      
      return null;
    });

/**
 * Expire friend requests older than 30 days (runs weekly on Sunday)
 */
exports.expireFriendRequests = functions.pubsub
    .schedule('0 4 * * 0')
    .timeZone('UTC')
    .onRun(async (context) => {
      const cutoffTime = Date.now() - (30 * 24 * 60 * 60 * 1000); // 30 days
      
      try {
        const oldRequests = await db.collection('friendRequests')
            .where('createdAt', '<', cutoffTime)
            .where('status', '==', 'pending')
            .get();
        
        if (oldRequests.empty) {
          console.log('No old friend requests to expire');
          return null;
        }
        
        const batch = db.batch();
        oldRequests.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });
        
        await batch.commit();
        console.log(`Expired ${oldRequests.size} old friend requests`);
      } catch (error) {
        console.error('Error expiring friend requests:', error);
      }
      
      return null;
    });

/**
 * Mark overdue missions (runs every hour)
 */
exports.markOverdueMissions = functions.pubsub
    .schedule('0 * * * *')
    .timeZone('UTC')
    .onRun(async (context) => {
      const now = Date.now();
      
      try {
        const overdueMissions = await db.collection('missions')
            .where('status', '==', 'in-progress')
            .where('deadline', '<', now)
            .get();
        
        if (overdueMissions.empty) {
          console.log('No overdue missions');
          return null;
        }
        
        const batch = db.batch();
        const notifications = [];
        
        for (const doc of overdueMissions.docs) {
          const mission = doc.data();
          
          // Update mission status
          batch.update(doc.ref, {status: 'overdue'});
          
          // Create notification for assigned user
          if (mission.assignedTo) {
            notifications.push(
                db.collection('notifications').add({
                  userId: mission.assignedTo,
                  type: 'missionOverdue',
                  title: 'Mission Overdue',
                  message: `Mission "${mission.title}" is past its deadline`,
                  actorId: mission.createdBy,
                  actionId: doc.id,
                  isRead: false,
                  createdAt: now,
                }),
            );
            
            // Send push notification if user has FCM token
            const userDoc = await db.collection('users')
                .doc(mission.assignedTo).get();
            const fcmToken = userDoc.data()?.fcmToken;
            
            if (fcmToken) {
              notifications.push(
                  admin.messaging().send({
                    notification: {
                      title: 'Mission Overdue!',
                      body: `"${mission.title}" is past its deadline`,
                    },
                    data: {
                      type: 'mission',
                      actionId: doc.id,
                    },
                    token: fcmToken,
                  }),
              );
            }
          }
        }
        
        await batch.commit();
        await Promise.all(notifications);
        
        console.log(`Marked ${overdueMissions.size} missions as overdue`);
      } catch (error) {
        console.error('Error marking overdue missions:', error);
      }
      
      return null;
    });

/**
 * Send mission deadline reminders (runs every 6 hours)
 * Reminds users 24 hours before deadline
 */
exports.sendMissionReminders = functions.pubsub
    .schedule('0 */6 * * *')
    .timeZone('UTC')
    .onRun(async (context) => {
      const now = Date.now();
      const reminderWindow = 24 * 60 * 60 * 1000; // 24 hours
      const reminderTime = now + reminderWindow;
      
      try {
        const upcomingMissions = await db.collection('missions')
            .where('status', '==', 'in-progress')
            .where('deadline', '>', now)
            .where('deadline', '<', reminderTime)
            .get();
        
        if (upcomingMissions.empty) {
          console.log('No missions needing reminders');
          return null;
        }
        
        const notifications = [];
        
        for (const doc of upcomingMissions.docs) {
          const mission = doc.data();
          
          // Check if reminder already sent
          if (mission.reminderSent) continue;
          
          if (mission.assignedTo) {
            // Create notification
            notifications.push(
                db.collection('notifications').add({
                  userId: mission.assignedTo,
                  type: 'missionReminder',
                  title: 'Mission Deadline Soon',
                  message: `"${mission.title}" is due in 24 hours`,
                  actorId: mission.createdBy,
                  actionId: doc.id,
                  isRead: false,
                  createdAt: now,
                }),
            );
            
            // Send push notification
            const userDoc = await db.collection('users')
                .doc(mission.assignedTo).get();
            const fcmToken = userDoc.data()?.fcmToken;
            
            if (fcmToken) {
              notifications.push(
                  admin.messaging().send({
                    notification: {
                      title: '⏰ Deadline Reminder',
                      body: `"${mission.title}" is due in 24 hours`,
                    },
                    data: {
                      type: 'mission',
                      actionId: doc.id,
                    },
                    token: fcmToken,
                  }),
              );
            }
            
            // Mark reminder as sent
            notifications.push(
                doc.ref.update({reminderSent: true}),
            );
          }
        }
        
        await Promise.all(notifications);
        console.log(`Sent ${upcomingMissions.size} mission reminders`);
      } catch (error) {
        console.error('Error sending mission reminders:', error);
      }
      
      return null;
    });

/**
 * Calculate and update leaderboard rankings (runs daily at 3 AM UTC)
 */
exports.updateLeaderboard = functions.pubsub
    .schedule('0 3 * * *')
    .timeZone('UTC')
    .onRun(async (context) => {
      try {
        const users = await db.collection('users').get();
        const rankings = [];
        
        for (const userDoc of users.docs) {
          const userId = userDoc.id;
          
          // Count completed missions
          const completedMissions = await db.collection('missions')
              .where('assignedTo', '==', userId)
              .where('status', '==', 'completed')
              .get();
          
          // Calculate score (100 points per completed mission)
          const score = completedMissions.size * 100;
          
          rankings.push({
            userId: userId,
            score: score,
            completedMissions: completedMissions.size,
          });
        }
        
        // Sort by score descending
        rankings.sort((a, b) => b.score - a.score);
        
        // Update user ranks
        const batch = db.batch();
        rankings.forEach((ranking, index) => {
          const userRef = db.collection('users').doc(ranking.userId);
          batch.update(userRef, {
            rank: index + 1,
            score: ranking.score,
            completedMissions: ranking.completedMissions,
          });
        });
        
        await batch.commit();
        console.log(`Updated leaderboard for ${rankings.length} users`);
      } catch (error) {
        console.error('Error updating leaderboard:', error);
      }
      
      return null;
    });

// ============================================================================
// LOBBY INITIALIZATION (One-time setup)
// ============================================================================

/**
 * Initialize default lobbies (HTTP function - call once)
 * https://us-central1-mission-board-b8dbc.cloudfunctions.net/initializeLobbies
 */
exports.initializeLobbies = functions.https.onRequest(async (req, res) => {
  try {
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

    const batch = db.batch();
    const results = [];

    for (const lobby of lobbies) {
      const { id, ...data } = lobby;
      const ref = db.collection('lobbies').doc(id);
      
      // Check if lobby already exists
      const existing = await ref.get();
      if (existing.exists) {
        results.push({ id, status: 'already_exists', name: data.name });
        continue;
      }

      batch.set(ref, {
        ...data,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      results.push({ id, status: 'created', name: data.name });
    }

    await batch.commit();

    res.status(200).json({
      success: true,
      message: 'Lobbies initialized successfully',
      results: results,
    });
  } catch (error) {
    console.error('Error initializing lobbies:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});
