const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// This is a temporary, simplified function to create the FIRST admin.
// After you have created your first admin, you should redeploy the secure version.
exports.addAdminRole = functions.https.onCall((data, context) => {
  // Get user and add custom claim (admin)
  return admin.auth().getUserByEmail(data.email).then(user => {
    return admin.auth().setCustomUserClaims(user.uid, {
      admin: true
    });
  }).then(() => {
    return {
      message: `Success! ${data.email} has been made an admin.`
    }
  }).catch(err => {
    return err;
  });
});