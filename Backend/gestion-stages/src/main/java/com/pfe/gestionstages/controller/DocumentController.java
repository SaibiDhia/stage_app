package com.pfe.gestionstages.controller;

import com.google.firebase.messaging.FirebaseMessagingException;
import com.pfe.gestionstages.dto.DocumentDTO;
import com.pfe.gestionstages.model.Document;
import com.pfe.gestionstages.model.Statut;
import com.pfe.gestionstages.model.User;
import com.pfe.gestionstages.dto.DocumentDTO;
import com.pfe.gestionstages.repository.DocumentRepository;
import com.pfe.gestionstages.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import com.pfe.gestionstages.repository.FcmTokenRepository;
import com.pfe.gestionstages.service.NotificationService;


import java.io.IOException;
import java.nio.file.*;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api/documents")
@RequiredArgsConstructor
public class DocumentController {

    private final DocumentRepository documentRepository;
    private final UserRepository userRepository;
    private final FcmTokenRepository fcmTokenRepository;
    private final NotificationService notificationService;

    private final Path rootLocation = Paths.get("uploads");

    private boolean isAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof User user) {
            return user.getRole().name().equals("ADMIN");
        }
        return false;
    }

    private boolean isMaxVersionReached(String type, int count) {
        return switch (type) {
            case "Bilan Version 1", "Bilan Version 2", "Bilan Version 3" -> count >= 1;
            case "Rapport Version 1", "Rapport Version 2" -> count >= 1;
            case "Journal de Bord" -> count >= 1;
            default -> false;
        };
    }

    @PostMapping("/upload")
public ResponseEntity<?> uploadDocument(
        @RequestParam("file") MultipartFile file,
        @RequestParam("type") String type,
        @RequestParam("userId") Long userId) {

    try {
        // Vérifie si le dossier uploads existe
        if (!Files.exists(rootLocation)) {
            Files.createDirectories(rootLocation);
        }

        // Vérifie si l'utilisateur existe
        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) return ResponseEntity.badRequest().body("Utilisateur non trouvé");

        // 🔒 Vérifie si le max de versions est atteint pour ce type
        Optional<Document> existingDoc = documentRepository.findTopByUtilisateurIdAndTypeOrderByDateDepotDesc(userId, type);

if (existingDoc.isPresent()) {
    Statut statut = existingDoc.get().getStatut();

    if (statut == Statut.EN_ATTENTE) {
        return ResponseEntity.badRequest().body("❌ Un document est déjà en attente de validation.");
    }

    if (statut == Statut.VALIDE) {
        return ResponseEntity.badRequest().body("✅ Cette version a déjà été validée. Attendez la version suivante.");
    }}

        // Génère un nom de fichier unique
        String filename = UUID.randomUUID() + "_" + file.getOriginalFilename();
        Path filePath = rootLocation.resolve(filename);
        Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

        // Crée et sauvegarde le document
        Document doc = Document.builder()
                .nomFichier(filename)
                .type(type)
                .cheminFichier(filePath.toString())
                .dateDepot(LocalDate.now())
                .statut(Statut.EN_ATTENTE)
                .utilisateur(userOpt.get())
                .build();

        documentRepository.save(doc);

        return ResponseEntity.ok("✅ Document déposé avec succès");

    } catch (IOException e) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Erreur lors du dépôt : " + e.getMessage());
    }
}



    @GetMapping("/all")
public ResponseEntity<?> getAllDocuments() {
    if (!isAdmin()) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé : admin uniquement.");
    }
    List<DocumentDTO> docs = documentRepository.findAll()
        .stream()
        .map(DocumentDTO::new)
        .toList();
    return ResponseEntity.ok(docs);
}

    @GetMapping("/users/{userId}")
    public List<Document> getDocumentsByUser(@PathVariable Long userId) {
        return documentRepository.findByUtilisateurId(userId);
    }

    // Spring Boot
@GetMapping("/statut")
public ResponseEntity<String> getStatut(
        @RequestParam Long userId,
        @RequestParam String type) {

    Optional<Document> docOpt = documentRepository
            .findTopByUtilisateurIdAndTypeOrderByDateDepotDesc(userId, type);

    if (docOpt.isEmpty()) {
        return ResponseEntity.ok("NON_DEPOSE");
    }

    return ResponseEntity.ok(docOpt.get().getStatut().name());
}



    @PutMapping("/{id}/valider")
public ResponseEntity<?> validerDocument(@PathVariable Long id) {
    if (!isAdmin()) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé : admin uniquement.");
    }

    return documentRepository.findById(id).map(doc -> {
        doc.setStatut(Statut.VALIDE);
        documentRepository.save(doc);

        // 🔔 Envoi de notification à l'étudiant
        User etudiant = doc.getUtilisateur();
        fcmTokenRepository.findByUser(etudiant).ifPresent(token -> {
            try {
                notificationService.envoyerNotification(
   token.getToken(),
   "Document validé",
   "Votre document '" + doc.getType() + "' a été validé."
);
            } catch (FirebaseMessagingException e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            }
        });

        return ResponseEntity.ok("Document validé");
    }).orElse(ResponseEntity.status(HttpStatus.NOT_FOUND).body("Document non trouvé"));
}

    @PutMapping("/{id}/rejeter")
public ResponseEntity<?> rejeterDocument(@PathVariable Long id) {
    if (!isAdmin()) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé : admin uniquement.");
    }

    return documentRepository.findById(id).map(doc -> {
        doc.setStatut(Statut.REJETE);
        documentRepository.save(doc);

        // 🔔 Envoi de notification à l'étudiant
        User etudiant = doc.getUtilisateur();
        fcmTokenRepository.findByUser(etudiant).ifPresent(token -> {
            try {
                notificationService.envoyerNotification(
   token.getToken(),
   "Document validé",
   "Votre document '" + doc.getType() + "' a été validé."
);
            } catch (FirebaseMessagingException e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            }
        });

        return ResponseEntity.ok("Document rejeté");
    }).orElse(ResponseEntity.status(HttpStatus.NOT_FOUND).body("Document non trouvé"));
}

    // Récupérer tous les dépôts (versions) pour un type et un user
@GetMapping("/historique")
public ResponseEntity<List<Document>> getHistorique(
        @RequestParam Long userId,
        @RequestParam String baseType) {
    // Ici on prend tous les documents dont le type commence par la baseType (ex: "Bilan", "Rapport", ...)
    List<Document> docs = documentRepository
        .findByUtilisateurIdAndTypeStartingWithOrderByDateDepotAsc(userId, baseType);

    return ResponseEntity.ok(docs);
}

@GetMapping("/download/{id}")
public ResponseEntity<?> downloadDocument(@PathVariable Long id) {
    // Récupère l’utilisateur courant
    Authentication auth = SecurityContextHolder.getContext().getAuthentication();
    if (auth == null || !(auth.getPrincipal() instanceof User user)) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Non authentifié");
    }

    Optional<Document> docOpt = documentRepository.findById(id);
    if (docOpt.isEmpty()) {
        return ResponseEntity.notFound().build();
    }
    Document doc = docOpt.get();

    // Autoriser uniquement l’admin OU l’utilisateur qui a uploadé le fichier
    boolean isAdmin = user.getRole().name().equals("ADMIN");
    boolean isOwner = doc.getUtilisateur().getId().equals(user.getId());
    if (!isAdmin && !isOwner) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Non autorisé");
    }

    try {
        Path path = Paths.get(doc.getCheminFichier());
        byte[] fileBytes = Files.readAllBytes(path);

        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + doc.getNomFichier() + "\"")
            .contentType(MediaType.APPLICATION_OCTET_STREAM)
            .body(fileBytes);

    } catch (IOException e) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("Erreur lors du téléchargement : " + e.getMessage());
    }
}


}
