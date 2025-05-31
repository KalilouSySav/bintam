/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// const {onRequest} = require("firebase-functions/v2/https");
// const logger = require("firebase-functions/logger");

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// Configure your Gmail account (for testing use App Passwords)
const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
        user: process.env.gmail_email,
        pass: process.env.gmail_password,
    }
});

// Trigger on new or updated orders
exports.sendOrderNotification = functions.firestore
    .document("orders/{orderId}")
    .onWrite(async (change, context) => {
        // const orderData = change.after.exists ? change.after.data() : null;
        const isNew = !change.before.exists;
        const recipientEmail = process.env.gmail_email;

        if (!recipientEmail) return null;

        const mailOptions = {
            from: '"BintaM" <yourgmail@gmail.com>',
            to: recipientEmail,
            subject: isNew ? "Confirmation d'une nouvelle commande" : "Notification de changement dans le statut de la commande",
            text: isNew
                ? `Une nouvelle commande a été effectué! Le numéro de la commande est ${context.params.orderId}.`
                : `La commande ${context.params.orderId} a été modifié.`,
        };

        try {
            await transporter.sendMail(mailOptions);
            console.log("Email sent to", recipientEmail);
        } catch (error) {
            console.error("Error sending email:", error);
        }
    });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
