package com.pfe.gestionstages.service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.*;

import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.util.Map;

@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);
    private static final String PROJECT_ID = "gestion-stages-notifs";
    private static final String SERVICE_ACCOUNT_PATH = "service-account.json";

    @PostConstruct
    public void init() {
        log.info("🔧 Initialisation Firebase Admin SDK… (projectId={})", PROJECT_ID);

        try {
            InputStream serviceAccount =
                    getClass().getClassLoader().getResourceAsStream(SERVICE_ACCOUNT_PATH);

            if (serviceAccount == null) {
                throw new IllegalStateException("Fichier " + SERVICE_ACCOUNT_PATH + " introuvable dans /resources");
            }

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .setProjectId(PROJECT_ID)
                        .build();
                FirebaseApp.initializeApp(options);
                log.info("✅ Firebase initialisé (appName={})", FirebaseApp.getInstance().getName());
            } else {
                log.info("ℹ️ Firebase déjà initialisé (appName={})", FirebaseApp.getInstance().getName());
            }
        } catch (Exception e) {
            log.error("❌ Échec d'initialisation Firebase Admin SDK : {}", e.getMessage(), e);
            throw new RuntimeException("Init Firebase échouée", e);
        }
    }

    public void envoyerNotification(String token, String titre, String message) throws FirebaseMessagingException {
        log.info("📤 Envoi FCM → token={}, titre='{}', message='{}'",
                maskToken(token), titre, message);

        // Notification de base
        Notification notification = Notification.builder()
                .setTitle(titre)
                .setBody(message)
                .build();

        // (Optionnel) pousser la priorité Android & son par défaut
        AndroidConfig android = AndroidConfig.builder()
                .setPriority(AndroidConfig.Priority.HIGH)
                .setNotification(AndroidNotification.builder().setSound("default").build())
                .build();

        ApnsConfig apns = ApnsConfig.builder()
                .setAps(Aps.builder().setContentAvailable(true).build())
                .build();

        Message msg = Message.builder()
                .setToken(token)
                .setNotification(notification)
                .setAndroidConfig(android)
                .setApnsConfig(apns)
                .putAllData(Map.of("click_action", "FLUTTER_NOTIFICATION_CLICK"))
                .build();

        try {
            String response = FirebaseMessaging.getInstance().send(msg);
            log.info("✅ FCM envoyé avec succès (responseId={})", response);
        } catch (FirebaseMessagingException e) {
            log.error("❌ Envoi FCM échoué (code={}): {}", e.getErrorCode(), e.getMessage(), e);
            throw e;
        }
    }

    private String maskToken(String t) {
        if (t == null) return "null";
        int n = t.length();
        return (n <= 12) ? "***" : t.substring(0, 6) + "…" + t.substring(n - 6);
    }
}
