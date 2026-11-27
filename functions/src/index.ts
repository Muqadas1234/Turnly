// Firebase Cloud Functions (Node.js / TypeScript) for Turnly.
// TODO (run `firebase init functions` in the project root first):
//  - bookToken        : callable. Transaction: check daily limit, assign next token number, create token doc, send "booked" FCM
//  - onTokenUpdated   : Firestore trigger. When queue changes, send FCM when 2-3 patients ahead / when token is called
//  - calcWaitingTime  : avg consultation time x patients ahead
//  - onHospitalStatus : Firestore trigger. FCM to manager when hospital approved/rejected
//  - suggestDepartment: (optional) Gemini API call for the AI Department Guide
export {};
