# Admin Setup Guide

## Setting up Admin Claims in Firebase

To make a user an admin in your Firebase project, you need to set custom claims. Here are the steps:

### Method 1: Using Firebase Admin SDK (Recommended)

1. **Install Firebase Admin SDK** (if you haven't already):
   ```bash
   npm install firebase-admin
   ```

2. **Create a setup script** (`setup-admin.js`):
   ```javascript
   const admin = require('firebase-admin');

   // Initialize Firebase Admin SDK
   // Replace 'path/to/your/serviceAccountKey.json' with your actual service account key path
   const serviceAccount = require('./path/to/your/serviceAccountKey.json');

   admin.initializeApp({
     credential: admin.credential.cert(serviceAccount),
     // Add your database URL if needed
     // databaseURL: 'https://your-project.firebaseio.com'
   });

   async function setAdminClaim(email) {
     try {
       const user = await admin.auth().getUserByEmail(email);
       await admin.auth().setCustomUserClaims(user.uid, { admin: true });
       console.log(`Successfully set admin claim for ${email}`);
     } catch (error) {
       console.error('Error setting admin claim:', error);
     }
   }

   // Replace 'admin@example.com' with the actual admin email
   setAdminClaim('admin@example.com');
   ```

3. **Run the script**:
   ```bash
   node setup-admin.js
   ```

### Method 2: Using Firebase Functions

1. **Create a Cloud Function**:
   ```javascript
   const functions = require('firebase-functions');
   const admin = require('firebase-admin');

   admin.initializeApp();

   exports.addAdminRole = functions.https.onCall((data, context) => {
     // Check if the user is already an admin
     if (context.auth.token.admin !== true) {
       return { error: 'Request not authorized. User must be an admin to assign roles.' };
     }

     const email = data.email;
     return admin.auth().getUserByEmail(email).then(user => {
       return admin.auth().setCustomUserClaims(user.uid, {
         admin: true
       });
     }).then(() => {
       return {
         message: `Success! ${email} has been made an admin.`
       };
     }).catch(err => {
       return err;
     });
   });
   ```

2. **Deploy the function**:
   ```bash
   firebase deploy --only functions
   ```

### Method 3: Using Firebase Console (Manual)

1. Go to Firebase Console → Authentication → Users
2. Find your admin user
3. Click on the user to view details
4. Go to the "Custom Claims" section
5. Add a new claim:
   - Key: `admin`
   - Value: `true`

## Testing Admin Access

1. **Login with your admin account**
2. **Check the console logs** - you should see the claims printed
3. **Verify navigation** - admin users should see the Admin Dashboard instead of the regular user interface

## Admin Features Available

- **Bookings Management**: View all bookings with filtering by status
- **Schedule Management**: Create and manage bus schedules
- **Route Management**: Add and manage bus routes
- **Bus Management**: Add buses and companies
- **Logout**: Secure logout functionality

## Troubleshooting

- **Claims not updating**: Try logging out and logging back in
- **Still seeing user interface**: Check that the admin claim is set correctly
- **Console errors**: Check the Firebase console for any authentication errors

## Security Notes

- Admin claims are checked on every login
- Claims are cached by Firebase Auth, so changes may take a few minutes to take effect
- Always use HTTPS in production
- Consider implementing additional security measures for admin functions

