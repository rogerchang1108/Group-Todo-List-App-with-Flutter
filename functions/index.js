/**
 * Import function triggers from their respective submodules:
 *
 * const {onRequest} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const logger = require("firebase-functions/logger");

const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const {
  onDocumentCreated,
  onDocumentDeleted,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");

initializeApp();
const db = getFirestore();

// Increments the itemCount for a user when a new grocery item is created.
// This function ensures data consistency and prevents duplicate processing
// through the use of idempotency keys.
exports.shoppingAppIncrementUserItemCount = onDocumentCreated(
  {
    document: "apps/group-todo-list/users/{userId}/todo-items/{itemId}",
    region: "us-west1",
  },
  async (event) => {
    const userId = event.params.userId;
    const itemId = event.params.itemId;

    const userRef = db.doc(`apps/group-todo-list/users/${userId}`);
    // Utilizes the unique event ID provided by Firebase to ensure idempotency.
    // This ID remains consistent across retries of the same event, preventing
    // duplicate increments of the itemCount in case the function is invoked
    // multiple times for the same creation event.
    const idempotencyRef = db.doc(`idempotencyKeys/${event.id}`);

    try {
      await db.runTransaction(async (transaction) => {
        // Logs if the function has already processed this event, ensuring
        // that itemCount is only incremented once per grocery item creation.
        const idempotencyDoc = await transaction.get(idempotencyRef);
        if (idempotencyDoc.exists) {
          logger.info(
            "shoppingAppIncrementUserItemCount: User.itemCount already incremented"
          );
          return;
        }

        const userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          logger.warn("shoppingAppIncrementUserItemCount: User not found");
          return;
        }
        const userData = userDoc.data();
        const itemCount = userData.itemCount ? userData.itemCount + 1 : 1;
        transaction.update(userRef, { itemCount });

        // Marks this creation event as processed by setting an idempotency record.
        // This record uses Firebase's server timestamp to indicate when the event
        // was processed, providing a traceable log for debugging and audit purposes.
        transaction.set(idempotencyRef, {
          processedAt: FieldValue.serverTimestamp(),
        });
      });
      logger.debug(
        "shoppingAppIncrementUserItemCount: User.itemCount incremented"
      );
    } catch (error) {
      logger.error(
        "shoppingAppIncrementUserItemCount: Error incrementing User.itemCount",
        error
      );
    }
  }
);

// Decrements the itemCount for a user when a new grocery item is deleted
exports.shoppingAppDecrementUserItemCount = onDocumentDeleted(
  {
    document: "apps/group-todo-list/users/{userId}/todo-items/{itemId}",
    region: "us-west1",
  },
  async (event) => {
    const userId = event.params.userId;
    const itemId = event.params.itemId;

    const userRef = db.doc(`apps/group-todo-list/users/${userId}`);
    const idempotencyRef = db.doc(`idempotencyKeys/${event.id}`);

    try {
      await db.runTransaction(async (transaction) => {
        // Check if the operation has already been processed
        const idempotencyDoc = await transaction.get(idempotencyRef);
        if (idempotencyDoc.exists) {
          logger.info(
            "shoppingAppDecrementUserItemCount: User.itemCount already decremented"
          );
          return;
        }

        const userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          logger.warn("shoppingAppDecrementUserItemCount: User not found");
          return;
        }
        const userData = userDoc.data();
        const itemCount =
          userData.itemCount && userData.itemCount > 0
            ? userData.itemCount - 1
            : 0;
        transaction.update(userRef, { itemCount });

        // Mark the operation as processed
        transaction.set(idempotencyRef, {
          processedAt: FieldValue.serverTimestamp(),
        });
      });
      logger.debug(
        "shoppingAppDecrementUserItemCount: User.itemCount decremented"
      );
    } catch (error) {
      logger.error(
        "shoppingAppDecrementUserItemCount: Error decrementing Usr.itemCount",
        error
      );
    }
  }
);

// Handles user deletions and reassigns their tasks to other users
exports.shoppingAppHandleUserDeletion = onDocumentDeleted(
  {
    document: "apps/group-todo-list/users/{userId}",
    region: "us-west1",
  },
  async (event) => {
    const userId = event.params.userId;
    const userTasksRef = db.collection(`apps/group-todo-list/users/${userId}/todo-items`);
    const usersRef = db.collection("apps/group-todo-list/users");

    try {
      // Get all tasks for the deleted user
      const userTasksSnapshot = await userTasksRef.get();
      if (userTasksSnapshot.empty) {
        logger.info("shoppingAppHandleUserDeletion: No tasks to reassign");
        return;
      }

      // Get all other users to reassign tasks
      const usersSnapshot = await usersRef.get();
      const otherUsers = usersSnapshot.docs.filter(doc => doc.id !== userId);

      if (otherUsers.length === 0) {
        logger.warn("shoppingAppHandleUserDeletion: No other users to reassign tasks to");
        return;
      }

      await db.runTransaction(async (transaction) => {
        // Reassign each task to a random user from the remaining users
        userTasksSnapshot.docs.forEach((taskDoc) => {
          const randomUser = otherUsers[Math.floor(Math.random() * otherUsers.length)];
          const newTaskRef = db.collection(`apps/group-todo-list/users/${randomUser.id}/todo-items`).doc(taskDoc.id);

          // Reassign the task
          transaction.set(newTaskRef, taskDoc.data());

          // Delete the task from the original user's collection
          transaction.delete(taskDoc.ref);
        });

        // Mark the user document as deleted
        const userRef = db.doc(`apps/group-todo-list/users/${userId}`);
        transaction.delete(userRef);
      });

      logger.debug("shoppingAppHandleUserDeletion: Tasks reassigned and user deleted");
    } catch (error) {
      logger.error("shoppingAppHandleUserDeletion: Error handling user deletion", error);
    }
  }
);
