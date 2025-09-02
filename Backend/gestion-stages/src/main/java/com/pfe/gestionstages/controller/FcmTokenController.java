package com.pfe.gestionstages.controller;

import com.pfe.gestionstages.model.FcmToken;
import com.pfe.gestionstages.model.User;
import com.pfe.gestionstages.repository.FcmTokenRepository;
import com.pfe.gestionstages.repository.UserRepository;
import lombok.RequiredArgsConstructor;

import java.util.Map;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication; // ✅ bon import
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class FcmTokenController {

  private static final Logger log = LoggerFactory.getLogger(FcmTokenController.class);

  private final FcmTokenRepository fcmTokenRepository;
  private final UserRepository userRepository;

  @PostMapping("/{userId}/fcm-token")
  @PreAuthorize("hasAnyRole('ETUDIANT','ADMIN')")
  public ResponseEntity<?> saveToken(
      @PathVariable Long userId,
      @RequestBody Map<String, String> body,
      Authentication auth) {

    if (auth == null || !(auth.getPrincipal() instanceof User current)) {
      return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Non authentifié");
    }

    String token = body.get("token");
    if (token == null || token.isBlank()) {
      return ResponseEntity.badRequest().body("Token manquant");
    }

    // ✅ Si ETUDIANT : il ne peut sauver que son propre token
    boolean isAdmin = "ADMIN".equals(current.getRole().name());
    if (!isAdmin && !current.getId().equals(userId)) {
      return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Non autorisé");
    }

    Optional<User> userOpt = userRepository.findById(userId);
    if (userOpt.isEmpty()) {
      return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Utilisateur introuvable");
    }
    User user = userOpt.get();

    // Upsert : 1 token par user (remplace si existe)
    fcmTokenRepository.findByUser(user).ifPresentOrElse(
      ft -> {
        ft.setToken(token);
        fcmTokenRepository.save(ft);
        log.info("🔄 FCM token mis à jour pour user {} ({})", user.getId(), user.getEmail());
      },
      () -> {
        fcmTokenRepository.save(new FcmToken(null, token, user));
        log.info("✅ FCM token enregistré pour user {} ({})", user.getId(), user.getEmail());
      }
    );

    return ResponseEntity.ok().build();
  }
}
