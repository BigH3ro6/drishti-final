# Drishti Database Schema (Firestore)

## 1. Core Concepts
* **Database:** Cloud Firestore (NoSQL).
* **structure:** Collection -> Document -> Subcollection.
* **Timestamps:** All dates are stored as UTC Timestamps.

## 2. Collections Structure

### A. `users` (Root Collection)
Stores profile data for BOTH Blind Users and Caregivers.
* **Document ID:** `auth_user_uid` (from Firebase Auth)
* **Fields:**
    * `name`: string ("Saman Perera")
    * `role`: string ("BLIND" or "CAREGIVER")
    * `phone`: string ("+94771234567")
    * `fcm_token`: string (Used for sending Push Notifications/SOS)
    * `created_at`: timestamp

### B. `tracking` (Root Collection)
*Dedicated collection for high-frequency location updates to avoid locking user profiles.*
* **Document ID:** `blind_user_uid`
* **Fields:**
    * `lat`: number (6.927079)
    * `lng`: number (79.861244)
    * `battery_level`: number (85)
    * `speed`: number (1.2) // m/s
    * `last_updated`: timestamp
    * `status`: string ("SAFE" | "SOS" | "OFFLINE")

### C. `relationships` (Root Collection)
*Links a Blind User to a Caregiver.*
* **Document ID:** `auto-generated`
* **Fields:**
    * `blind_user_id`: reference (`users/abc...`)
    * `caregiver_id`: reference (`users/xyz...`)
    * `status`: string ("PENDING" | "ACTIVE")
    * `sos_enabled`: boolean (true)

### D. `messages` (Root Collection)
*Stores voice and text chat history.*
* **Document ID:** `auto-generated`
* **Fields:**
    * `participants`: array [`blind_uid`, `caregiver_uid`]
    * `sender_id`: string (`blind_uid`)
    * `type`: string ("VOICE" | "TEXT")
    * `content`: string (URL for audio, or text body)
    * `read_status`: boolean (false)
    * `timestamp`: timestamp

## 3. Storage Buckets (Firebase Storage)
* `/profile_pics/{uid}.jpg`
* `/voice_notes/{chat_id}/{timestamp}.mp3`
* `/incident_logs/{date}/{uid}_snapshot.jpg` (Evidence photo from SOS events)