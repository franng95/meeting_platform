/**
 * Cloud Functions for Meeting Platform
 * Automatically creates meetings when invitations are accepted
 */

const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, Timestamp, FieldValue} = require("firebase-admin/firestore");

// Initialize Firebase Admin
initializeApp();

console.log("🚀 Cloud Functions loaded - waiting for triggers...");

/**
 * Trigger: When an invitation document is updated
 * Action: If status changes to "accepted", create a meeting
 */
exports.onInvitationUpdate = onDocumentUpdated(
    "invitations/{invitationId}",
    async (event) => {
      console.log("🔔 FUNCTION TRIGGERED!");
      console.log("📍 Event received at:", new Date().toISOString());
      
      // Get the invitation data before and after the update
      const beforeData = event.data.before.data();
      const afterData = event.data.after.data();
      const invitationId = event.params.invitationId;

      console.log(`🔨 Invitation ${invitationId} updated`);
      console.log(`   Before status: ${beforeData.status}`);
      console.log(`   After status: ${afterData.status}`);

      // Check if status changed to "accepted"
      if (beforeData.status !== "accepted" && afterData.status === "accepted") {
        console.log("✅ Status changed to accepted! Creating meeting...");

        try {
          const db = getFirestore();

          // Create a new meeting document
          const meetingRef = await db.collection("meetings").add({
            participants: [afterData.senderId, afterData.receiverId],
            scheduledFor: Timestamp.fromDate(
                // Default: 7 days from now
                new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
            ),
            createdAt: FieldValue.serverTimestamp(),
            createdFromInvitation: invitationId,
          });

          console.log(`✅✅✅ Meeting created successfully: ${meetingRef.id}`);
          console.log(`📧 Participants: ${afterData.senderId}, ${afterData.receiverId}`);
          return {success: true, meetingId: meetingRef.id};
        } catch (error) {
          console.error("❌ Error creating meeting:", error);
          throw error;
        }
      } else {
        console.log("⭐ Status not accepted, skipping meeting creation");
        return {success: false, reason: "not_accepted"};
      }
    },
);

console.log("✅ Cloud Function 'onInvitationUpdate' registered");